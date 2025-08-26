import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/api_services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();

  // Form controllers
  DateTime? _selectedDate;
  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController staffCountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // Staff selection
  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];

  // Event status
  String? festivalStatus;
  bool _loading = false;
  String? error;

  // Cached data for charts
  List<Map<String, dynamic>>? _shiftScheduleCache;
  List<Map<String, dynamic>>? _salesDataCache;

  @override
  void initState() {
    super.initState();
    _loadStaffList();
    _loadChartData();
  }

  // === API Calls ===
  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      setState(() {
        availableStaffNames = staffList.map((e) => e.toString()).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('スタッフリスト取得エラー: $e')));
    }
  }

  Future<void> _loadChartData() async {
    try {
      final shiftData = await ApiService.fetchShiftTableDashboard();
      final salesData = await ApiService.getPredSales();
      setState(() {
        _shiftScheduleCache = shiftData;
        _salesDataCache = salesData;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  // Build payload for API
  Map<String, dynamic> _buildPayload() {
    return {
      "date": _selectedDate?.toIso8601String().split('T').first ?? '',
      "day": _selectedDate?.weekday.toString() ?? '',
      "event": festivalStatus == '1' ? "True" : "False",
      "customer_count": int.tryParse(customerController.text) ?? 0,
      "sales": int.tryParse(salesController.text) ?? 0,
      "staff_names": selectedStaffNames,
      "staff_count": int.tryParse(staffCountController.text) ?? 0,
    };
  }

  // Ensure staff count matches selected names
  bool _validateStaffCountMatchesNames() {
    final enteredCount = int.tryParse(staffCountController.text) ?? 0;
    return enteredCount == selectedStaffNames.length;
  }

  // Save user input and reload charts
  Future<void> _saveDataAndRefresh() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        festivalStatus != null) {
      if (!_validateStaffCountMatchesNames()) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('スタッフ数とスタッフ名の数が一致していません')));
        return;
      }

      final payloadUserInput = _buildPayload();

      try {
        setState(() => _loading = true);
        final response = await ApiService.postUserInput(payloadUserInput);
        setState(() => _loading = false);

        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存エラー (${response.statusCode})')));
          return;
        }

        _clearForm();
        await _loadChartData();

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('データが保存され、最新シフトが取得されました')));
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('通信エラー: $e')));
      }
    }
  }

  // Clear form values
  void _clearForm() {
    setState(() {
      _selectedDate = null;
      salesController.clear();
      customerController.clear();
      staffCountController.clear();
      selectedStaffNames.clear();
      festivalStatus = null;
      dateController.clear();
    });
  }

  @override
  void dispose() {
    salesController.dispose();
    customerController.dispose();
    staffCountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  // === UI Build ===
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("Dashboard"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                _buildDashboardForm(),
                const SizedBox(height: 24),
                if (error != null)
                  Text('Error: $error',
                      style: const TextStyle(color: Colors.red)),
                if (_shiftScheduleCache != null) ...[
                  ShiftChartWidget(shiftSchedule: _shiftScheduleCache!),
                  const SizedBox(height: 20),
                ],
                if (_salesDataCache != null)
                  SalesPredictionChartWidget(salesData: _salesDataCache!),
              ],
            ),
    );
  }

  // === Form Card ===
Widget _buildDashboardForm() {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 4,
    color: Colors.blue.shade50,
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Report',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    )),
            const SizedBox(height: 20),

            // Grid with improved ratio
            GridView.count(
              shrinkWrap:true,
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              children: [
                _buildDatePicker(),
                _buildNumberField(salesController, 'Sale'),
                  _buildNumberField(customerController, 'Customer'),
                  _buildNumberField(staffCountController, 'Numbers of Staff'),
               
                _buildStaffMultiSelect(),
                _buildEventDropdown(),
              ],
            ),

            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: _clearForm,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _saveDataAndRefresh,
                  icon: const Icon(Icons.save,color: Colors.white,),
                  label: const Text('Save & Refresh',style: TextStyle(color: Colors.white),),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    ),
  );
}




  // === Form Fields ===
  Widget _buildDatePicker() {
    return _formFieldWrapper(
      label: "Date",
      child: TextFormField(
        controller: dateController,
        readOnly: true,
        
        decoration: InputDecoration(
           border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          hintText: 'yyyy/mm/dd',
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  dateController.text =
                      '${date.year}/${date.month}/${date.day}';
                });
              }
            },
          ),
        ),
        validator: (value) =>
            _selectedDate == null ? 'Please select a date' : null,
      ),
    );
  }

  Widget _buildNumberField(
      TextEditingController controller, String label) {
    return _formFieldWrapper(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: const InputDecoration(hintText: 'Enter value'),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label is required';
          if (int.tryParse(value) == null) return 'Enter a valid number';
          return null;
        },
      ),
    );
  }

  Widget _buildStaffMultiSelect() {
    return _formFieldWrapper(
      label: "Staff",
      child: MultiSelectDialogField<String>(
        items: availableStaffNames
            .map((name) => MultiSelectItem<String>(name, name))
            .toList(),
        title: const Text("Select Staff"),
        selectedColor: Colors.blueAccent,
        buttonText: const Text("Select"),
        initialValue: selectedStaffNames,
        onConfirm: (values) {
          setState(() {
            selectedStaffNames = values;
          });
        },
        chipDisplay: MultiSelectChipDisplay(
          items: selectedStaffNames
              .map((name) => MultiSelectItem<String>(name, name))
              .toList(),
          onTap: (value) {
            setState(() {
              selectedStaffNames.remove(value);
            });
          },
        ),
        validator: (values) {
          if (values == null || values.isEmpty) {
            return 'Please select at least one staff';
          }
          return null;
        },
      ),
    );
  }

  Widget _buildEventDropdown() {
    return _formFieldWrapper(
      label: "Event",
      child: DropdownButtonFormField<String>(
        value: festivalStatus,
        items: const [
          DropdownMenuItem(value: '1', child: Text('あり')),
          DropdownMenuItem(value: '0', child: Text('なし')),
        ],
        onChanged: (value) => setState(() => festivalStatus = value),
        validator: (value) =>
            value == null ? 'Please select event status' : null,
      ),
    );
  }

  // Helper to add label + spacing
  Widget _formFieldWrapper({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}

// =======================
// Charts
// =======================

class ShiftChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> shiftSchedule;
  const ShiftChartWidget({super.key, required this.shiftSchedule});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Shift Schedule",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),

            // Legend row
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                _legendItem("Morning", Colors.blueAccent),
                _legendItem("Afternoon", Colors.greenAccent),
                _legendItem("Night", Colors.orangeAccent),
              ],
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  minY: 6,
                  maxY: 24,
                  gridData: FlGridData(show: true, horizontalInterval: 2),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) =>
                            Text('${value.toInt()}:00'),
                      ),
                    ),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < shiftSchedule.length) {
                            DateTime date =
                                DateTime.parse(shiftSchedule[index]["date"]);
                            return Text("${date.month}/${date.day}");
                          }
                          return const SizedBox(width: 30);
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(shiftSchedule.length, (index) {
                    final shift = shiftSchedule[index]["shift"];
                    double startHour = shift == "morning"
                        ? 8
                        : shift == "afternoon"
                            ? 13
                            : 18;
                    double endHour = startHour + 4;
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          fromY: startHour,
                          toY: endHour,
                          width: 16,
                          color: shift == "morning"
                              ? Colors.blueAccent
                              : shift == "afternoon"
                                  ? Colors.greenAccent
                                  : Colors.orangeAccent,
                          borderRadius: BorderRadius.zero,
                        ),
                      ],
                    );
                  }),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }
}

class SalesPredictionChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  const SalesPredictionChartWidget({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Predicted Sales",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, horizontalInterval: 5000),
                  titlesData: FlTitlesData(
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) =>
                            Text(value.toInt().toString()),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 50,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();
                          if (index >= 0 && index < salesData.length) {
                            DateTime date =
                                DateTime.parse(salesData[index]["date"]);
                            return Text("${date.month}/${date.day}");
                          }
                          return const SizedBox(width: 30);
                        },
                      ),
                    ),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: true),

                  // Line Chart
                  lineBarsData: [
                    LineChartBarData(
                      isCurved: true,
                      spots: List.generate(salesData.length, (index) {
                        final sales =
                            salesData[index]["predicted_sales"] ?? 0;
                        return FlSpot(index.toDouble(), sales.toDouble());
                      }),
                      color: Colors.redAccent,
                      dotData: FlDotData(show: false),
                      isStrokeCapRound: true,
                      barWidth: 3,
                    ),
                  ],

                  // Tooltips on hover
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                    //  tooltipBgColor: Colors.blueGrey.withOpacity(0.8),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final date =
                              salesData[spot.x.toInt()]["date"] ?? "";
                          final sales = spot.y.toInt();
                          return LineTooltipItem(
                            "$date\nSales: $sales",
                            const TextStyle(color: Colors.white),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
