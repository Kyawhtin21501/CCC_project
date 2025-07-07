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
  List<String> selectedStaffNames = [];
  String? festivalStatus;

  List<String> availableStaffNames = [];

  @override
  void initState() {
    super.initState();
    _loadStaffList();
  }

  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      setState(() {
        availableStaffNames = staffList;
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

  Future<void> _submitAndShowPrediction() async {
    if (_formKey.currentState!.validate() && _selectedDate != null && festivalStatus != null) {
      if (!_validateStaffCountMatchesNames()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('スタッフ数とスタッフ名の数が一致していません')),
        );
        return;
      }
      final payload = _buildPayload();

      try {
        final response = await ApiService.postPrediction(payload);
        if (response.statusCode == 200) {
          final resultData = jsonDecode(response.body);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PredictionResultScreen(
                predictedSales: resultData['predicted_sales'].toString(),
                predictedStaff: resultData['predicted_staff'].toString(),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('予測エラー (${response.statusCode})')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通信エラー: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('全ての項目を正しく入力してください')),
      );
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
      appBar: AppBar(title: const Text('売上・スタッフ予測ダッシュボード')),
      drawer: AppDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(60),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const Text(
                '売上・スタッフ数・祭り情報の入力',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2b5797)),
              ),
              const SizedBox(height: 24),
              ListTile(
                title: const Text("日付"),
                subtitle: Text(
                  _selectedDate == null
                      ? '日付を選択'
                      : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}',
                ),
                trailing: IconButton(
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
              _buildNumberField(salesController, '売上（円）', allowNegative: false),
              _buildNumberField(customerController, '客数'),
              _buildNumberField(staffCountController, 'スタッフ数'),
              _buildStaffMultiSelect(),
              DropdownButtonFormField<String>(
                value: festivalStatus,
                decoration: const InputDecoration(labelText: '祭りの有無'),
                items: const [
                  DropdownMenuItem(value: '1', child: Text('あり')),
                  DropdownMenuItem(value: '0', child: Text('なし')),
                ],
                onChanged: (value) => setState(() => festivalStatus = value),
                validator: (value) => value == null ? '祭りの有無を選択してください' : null,
              ),
              const SizedBox(height: 20),
              Center(
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.save),
                  label: const Text('保存のみ'),
                  onPressed: _saveDataOnly,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.grey[700], foregroundColor: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, {bool allowNegative = true}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(labelText: label),
      validator: (value) {
        if (value == null || value.isEmpty) return '$label を入力してください';
        final number = int.tryParse(value);
        if (number == null) return '数値を入力してください';
        if (!allowNegative && number < 0) return '0以上の値を入力してください';
        return null;
      },
    );
  }

  Widget _buildStaffMultiSelect() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text('スタッフ名を選択（複数選択可）'),
        MultiSelectDialogField<String>(
          items: availableStaffNames.map((name) => MultiSelectItem<String>(name, name)).toList(),
          title: const Text("スタッフ名"),
          selectedColor: Colors.blueAccent,
          buttonText: const Text("スタッフを選択"),
          initialValue: selectedStaffNames,
          onConfirm: (values) {
            setState(() {
              selectedStaffNames = List<String>.from(values);
            });
          },
          chipDisplay: MultiSelectChipDisplay(
            onTap: (value) {
              setState(() {
                selectedStaffNames.remove(value);
              });
            },
          ),
          validator: (values) {
            if (values == null || values.isEmpty) {
              return 'スタッフを1人以上選んでください';
            }
            return null;
          },
        ),
      ],
    );
  }
}
