import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/api_services/api_services.dart';
import 'package:predictor_web/screens/prediction_result_screen.dart';
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

  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];
  String? festivalStatus;

  @override
  void initState() {
    super.initState();
    _loadStaffList();
  }

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

  Map<String, dynamic> _buildPayload() {
    return {
      "date": _selectedDate!.toIso8601String().split('T').first,
      "day": _selectedDate!.weekday.toString(),
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

  Future<void> _saveDataOnly() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && festivalStatus != null) {
      if (!_validateStaffCountMatchesNames()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('スタッフ数とスタッフ名の数が一致していません')),
        );
        return;
      }
      final payload = _buildPayload();

      try {
        final response = await ApiService.postUserInput(payload);
        if (response.statusCode == 200) {
          _clearForm();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('データが保存されました')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存エラー (${response.statusCode})')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通信エラー: $e')),
        );
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
    });
  }

  @override
  void dispose() {
    salesController.dispose();
    customerController.dispose();
    staffCountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      body: Container(
        color: Colors.white,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(40),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
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
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        child: Text('Clear'),
                      ),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton(
                      
                      onPressed: _saveDataOnly,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Save'),
                    ),
                    
                  ],
                ),
              ],
            ),
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
            readOnly: true,
            controller: TextEditingController(
              text: _selectedDate == null
                  ? ''
                  : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
            ),
            decoration: InputDecoration(
              hintText: 'mm/dd/yyyy',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
                  if (date != null) setState(() => _selectedDate = date);
                },
              ),
            ),
            validator: (value) => _selectedDate == null ? 'Please select a date' : null,
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
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
            items: availableStaffNames.map((name) => MultiSelectItem<String>(name, name)).toList(),
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
              items: selectedStaffNames.map((name) => MultiSelectItem<String>(name, name)).toList(),
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
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              filled: true,
              fillColor: Colors.grey.shade200,
            ),
            items: const [
              DropdownMenuItem(value: '1', child: Text('あり')),
              DropdownMenuItem(value: '0', child: Text('なし')),
            ],
            onChanged: (value) => setState(() => festivalStatus = value),
            validator: (value) => value == null ? 'Please select event status' : null,
          ),
        ],
      ),
    );
  }
}
