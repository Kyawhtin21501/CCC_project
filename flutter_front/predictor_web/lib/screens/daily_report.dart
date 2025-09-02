import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/api_services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/charts.dart';

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

  // Cached chart data
  List<Map<String, dynamic>>? _shiftScheduleCache;
  List<Map<String, dynamic>>? _salesDataCache;

  @override
  void initState() {
    super.initState();
    _loadStaffList();
    _loadChartData();
  }

  /// Fetch staff list for multi-select
  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      setState(() {
        availableStaffNames = staffList.map((e) => e.toString()).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('スタッフリスト取得エラー: $e')),
      );
    }
  }

  /// Fetch chart data from backend
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

  /// Build payload from form input
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

  /// Check staff count matches selected staff names
  bool _validateStaffCountMatchesNames() {
    final enteredCount = int.tryParse(staffCountController.text) ?? 0;
    return enteredCount == selectedStaffNames.length;
  }

  /// Save data and refresh charts
  Future<void> _saveDataAndRefresh() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        festivalStatus != null) {
      if (!_validateStaffCountMatchesNames()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('スタッフ数とスタッフ名の数が一致していません')),
        );
        return;
      }

      final payloadUserInput = _buildPayload();

      try {
        setState(() => _loading = true);
        final response = await ApiService.postUserInput(payloadUserInput);
        setState(() => _loading = false);

        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存エラー (${response.statusCode})')),
          );
          return;
        }

        _clearForm();
        await _loadChartData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('データが保存され、最新シフトが取得されました')),
        );
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通信エラー: $e')),
        );
      }
    }
  }

  /// Reset form values
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

  /// Daily Report Input Form
  Widget _buildDashboardForm() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      color: Colors.white,
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

              // Grid layout for inputs
              GridView.count(
                shrinkWrap: true,
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

              // Buttons
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
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      'Save & Refresh',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
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

  // Label + Field Wrapper
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
