import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/api_services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Form key for validation
  final _formKey = GlobalKey<FormState>();

  // Controllers for input fields
  DateTime? _selectedDate;
  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController staffCountController = TextEditingController();

  // Staff lists for multi-select
  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];

  // Festival event status: '1' for Yes, '0' for No
  String? festivalStatus;

  // Loading indicator flag
  bool _loading = false;

  // Error message holder
  String? error;

  // Holds the fetched prediction and shift schedule data
  Map<String, dynamic>? predicted_reponse;

  @override
  void initState() {
    super.initState();
    _loadStaffList(); // Load available staff names on startup
    _fetchInitialPrediction(); // Fetch prediction & shift schedule for today's date on startup
  }

  /// Fetch the list of staff names from API
  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      setState(() {
        // Convert staff list items to string list
        availableStaffNames = staffList.map((e) => e.toString()).toList();
      });
    } catch (e) {
      // Show snackbar on error
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('スタッフリスト取得エラー: $e')));
    }
  }

  /// Fetch prediction and shift schedule for the initial date (today)
  Future<void> _fetchInitialPrediction() async {
    await _fetchPredictionForDate(DateTime.now());
  }

  /// Reusable method to fetch prediction and shift schedule for a given start date
  Future<void> _fetchPredictionForDate(DateTime startDate) async {
    try {
      setState(() => _loading = true); // Show loading spinner

      // Prepare payload with start & end date, plus fixed coordinates (Tokyo here)
      final payloadShift = {
        "start_date": startDate.toIso8601String().split('T').first,
        "end_date":
            startDate
                .add(const Duration(days: 6))
                .toIso8601String()
                .split('T')
                .first,
        "latitude": 35.6895, // Tokyo latitude example
        "longitude": 139.6917, // Tokyo longitude example
      };

      // Fetch data from API service
      final shiftData = await ApiService.fetchShiftAndPrediction(payloadShift);

      setState(() {
        predicted_reponse = shiftData; // Store received data for charts
        _loading = false; // Hide loading spinner
      });
    } catch (e) {
      setState(() => _loading = false); // Hide loading spinner on error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('データ取得エラー: $e')), // Show error message
      );
    }
  }

  /// Build JSON payload from form inputs for daily report saving
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

  /// Validate staff count matches number of selected staff names
  bool _validateStaffCountMatchesNames() {
    final enteredCount = int.tryParse(staffCountController.text) ?? 0;
    return enteredCount == selectedStaffNames.length;
  }

  /// Handle saving daily report data and refreshing the prediction charts
  Future<void> _saveDataAndRefresh() async {
    // Validate form and required fields are set
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        festivalStatus != null) {
      // Check if staff count input matches selected staff names count
      if (!_validateStaffCountMatchesNames()) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('スタッフ数とスタッフ名の数が一致していません')));
        return; // Abort if mismatch
      }

      final payloadUserInput = _buildPayload();

      try {
        setState(() => _loading = true); // Show loading spinner

        // Save daily report to backend
        final response = await ApiService.postUserInput(payloadUserInput);
        if (response.statusCode != 200) {
          setState(() => _loading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存エラー (${response.statusCode})')),
          );
          return;
        }

        // After successful save, fetch new prediction data based on the selected date
        await _fetchPredictionForDate(_selectedDate!);

        // Clear the form after saving
        _clearForm();

        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('データが保存され、最新シフトが取得されました')));
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('通信エラー: $e')));
      }
    }
  }

  /// Reset form fields and selected values
  void _clearForm() {
    setState(() {
      _selectedDate = null;
      salesController.clear();
      customerController.clear();
      staffCountController.clear();
      selectedStaffNames.clear();
      festivalStatus = null;
    });
  }

  @override
  void dispose() {
    // Dispose controllers to free resources
    salesController.dispose();
    customerController.dispose();
    staffCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Extract shift schedule and prediction lists from API response safely
    final shiftSchedule = (predicted_reponse?["shift_schedule"] as List?) ?? [];
    final predictions = (predicted_reponse?["prediction"] as List?) ?? [];

    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.white),
      drawer: AppDrawer(),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(),
              ) // Show spinner if loading
              : Container(
                color: Colors.white70,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      _buildDashboardForm(), // Form input area
                      const SizedBox(height: 40),

                      if (error != null)
                        Text(
                          'Error: $error',
                          style: const TextStyle(color: Colors.red),
                        ),

                      // Row to display two charts side by side
                      _buildShiftChart(shiftSchedule),
                      const SizedBox(width: 32),
                      _buildPredictionChart(predictions),
                    ],
                  ),
                ),
              ),
    );
  }

  /// Widget for Shift Schedule chart visualization using BarChart
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
                minY: 6, // Start hour on vertical axis
                maxY: 24, // End hour on vertical axis
                gridData: FlGridData(show: true, horizontalInterval: 2),
                titlesData: FlTitlesData(
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false), 
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) => Text('${value.toInt()}:00'),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 50,
                      getTitlesWidget: (value, meta) {
                        int index = value.toInt();
                        if (index >= 0 && index < shiftSchedule.length) {
                          // Format date string nicely, e.g. "08 Aug"
                          DateTime date = DateTime.parse(shiftSchedule[index]["date"]);
                          final formattedDate = "${date.month}/${date.day}";
                          return Text(formattedDate);
                        }
                        return const SizedBox(width: 30,);
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


  /// Widget for Prediction chart (sales over coming week)
  Widget _buildPredictionChart(List<dynamic> predictions) {
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
              "Prediction for coming week",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 250,
              child: BarChart(
                BarChartData(
                  gridData: FlGridData(show: true, horizontalInterval: 500),
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget:
                            (value, meta) => Text('¥${value.toInt()}'),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          int index = value.toInt();

                          // Define the input format matching your date string:
                          final inputFormat = DateFormat(
                            "EEE, dd MMM yyyy HH:mm:ss 'GMT'",
                            'en_US',
                          );

                          String rawDate = predictions[index]["date"];
                          DateTime parsedDate = inputFormat.parseUtc(rawDate);

                          // Then format as you want, e.g.:
                          final outputFormat = DateFormat('yyyy-MM-dd');
                          String formattedDate = outputFormat.format(
                            parsedDate,
                          );
                          // Show mm-dd from date string on X axis
                          if (index >= 0 && index < predictions.length) {
                            return Text(formattedDate);
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: List.generate(predictions.length, (index) {
                    final item = predictions[index];
                    return BarChartGroupData(
                      x: index,
                      barRods: [
                        BarChartRodData(
                          toY: item["predicted_sales"].toInt(),
                          color: Colors.black,
                          width: 18,
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

  /// Widget for the Daily Report form UI
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
                      padding: EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      child: Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 20),
                  ElevatedButton(
                    onPressed: _saveDataAndRefresh,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
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

  /// Widget for selecting date with a calendar popup
  Widget _buildDatePicker() {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Date'),
          const SizedBox(height: 5),
          TextFormField(
            readOnly: true,
            controller: TextEditingController(
              text:
                  _selectedDate == null
                      ? ''
                      : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
            ),
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
                  // Show date picker dialog
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                  );
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
            ),
            validator:
                (value) =>
                    _selectedDate == null ? 'Please select a date' : null,
          ),
        ],
      ),
    );
  }

  /// Widget for number input fields with validation
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

  /// Widget for selecting multiple staff members using a dialog
  Widget _buildStaffMultiSelect() {
    return SizedBox(
      width: 350,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Staff'),
          const SizedBox(height: 5),
          MultiSelectDialogField<String>(
            items:
                availableStaffNames
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
              items:
                  selectedStaffNames
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

  /// Widget for selecting the festival event status from a dropdown
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
            validator:
                (value) => value == null ? 'Please select event status' : null,
          ),
        ],
      ),
    );
  }
}
