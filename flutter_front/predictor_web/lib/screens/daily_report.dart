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

  DateTime? _selectedDate;
  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController staffCountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];

  String? festivalStatus;
  bool _loading = false;
  String? error;

  late Future<List<Map<String, dynamic>>> predictedResponse;
  late Future<List<Map<String, dynamic>>> salesPredResponse;

  @override
  void initState() {
    super.initState();
    _loadStaffList();
    predictedResponse = ApiService.fetchShiftTableDashboard();
    salesPredResponse = ApiService.getPredSales();  // <-- fetch sales predictions
  }

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

  bool _validateStaffCountMatchesNames() {
    final enteredCount = int.tryParse(staffCountController.text) ?? 0;
    return enteredCount == selectedStaffNames.length;
  }

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

        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('データが保存され、最新シフトが取得されました')));
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('通信エラー: $e')));
      }
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white),
      drawer: AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              color: Colors.white70,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    _buildDashboardForm(),
                    const SizedBox(height: 40),
                    if (error != null)
                      Text(
                        'Error: $error',
                        style: const TextStyle(color: Colors.red),
                      ),
                    FutureBuilder<List<Map<String, dynamic>>>(
                      future: predictedResponse,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const CircularProgressIndicator();
                        } else if (snapshot.hasError) {
                          return Text(
                              'Error loading shifts: ${snapshot.error}');
                        } else if (!snapshot.hasData ||
                            snapshot.data!.isEmpty) {
                          return const Text('No shift data available');
                        }

                        final shiftSchedule = snapshot.data!;
                        return _buildShiftChart(shiftSchedule);
                      },
                    ),
                    SizedBox(height: 20,),
                    FutureBuilder<List<Map<String, dynamic>>>(
  future: salesPredResponse,
  builder: (context, snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const CircularProgressIndicator();
    } else if (snapshot.hasError) {
      return Text('Error loading sales predictions: ${snapshot.error}');
    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
      return const Text('No sales prediction data available');
    }

    final salesData = snapshot.data!;
    return _buildSalesPredictionChart(salesData);
  },
),

                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildShiftChart(List<dynamic> shiftSchedule) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Shift Schedule",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    topTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 2,
                        reservedSize: 40,
                        getTitlesWidget: (value, meta) =>
                            Text('${value.toInt()}:00'),
                      ),
                    ),
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
                          width: 20,
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(4),
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
  Widget _buildSalesPredictionChart(List<Map<String, dynamic>> salesData) {
  return Card(
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    elevation: 2,
    color: Colors.white,
    child: Padding(
      padding: const EdgeInsets.all(32.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Predicted Sales",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 250,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: true, horizontalInterval: 100),
                titlesData: FlTitlesData(
                  topTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles:
                      AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
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
                ),
                borderData: FlBorderData(show: true),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    spots: List.generate(salesData.length, (index) {
                      final sales = salesData[index]["predicted_sales"] ?? 0;
                      return FlSpot(index.toDouble(), sales.toDouble());
                    }),
                    color: Colors.redAccent,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}


  Widget _buildDashboardForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Daily Report',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              Wrap(
                spacing: 20,
                runSpacing: 20,
                children: [
                  _buildDatePicker(),
                  _buildNumberField(salesController, 'Sale'),
                  _buildNumberField(customerController, 'Customer'),
                  _buildNumberField(staffCountController, 'Numbers of Staff'),
                  _buildStaffMultiSelect(),
                  _buildEventDropdown(),
                ],
              ),
              const SizedBox(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton(
                    onPressed: _clearForm,
                    child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _saveDataAndRefresh,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Save & Refresh'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker() {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date'),
          const SizedBox(height: 5),
          TextFormField(
            controller: dateController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'mm/dd/yyyy',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
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
            validator:
                (value) => _selectedDate == null ? 'Please select a date' : null,
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Value',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return '$label is required';
              if (int.tryParse(value) == null) return 'Enter a valid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStaffMultiSelect() {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff'),
          const SizedBox(height: 5),
          MultiSelectDialogField<String>(
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
        ],
      ),
    );
  }

  Widget _buildEventDropdown() {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Event'),
          const SizedBox(height: 5),
          DropdownButtonFormField<String>(
            value: festivalStatus,
            decoration: InputDecoration(
              hintText: 'Select option',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              filled: true,
              fillColor: Colors.grey.shade200,
            ),
            items: const [
              DropdownMenuItem(value: '1', child: Text('あり')),
              DropdownMenuItem(value: '0', child: Text('なし')),
            ],
            onChanged: (value) => setState(() => festivalStatus = value),
            validator: (value) =>
                value == null ? 'Please select event status' : null,
          ),
        ],
      ),
    );
  }
}
