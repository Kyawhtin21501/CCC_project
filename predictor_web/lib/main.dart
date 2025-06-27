import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:predictor_web/prediction_result_screen.dart';

void main() {
  runApp(const ShiftAIApp());
}

class ShiftAIApp extends StatelessWidget {
  const ShiftAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftAI Dashboard',
      theme: ThemeData(fontFamily: 'Segoe UI'),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

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
  final TextEditingController staffNameController = TextEditingController();
  String? festivalStatus;

  /// Send data and get prediction result
  Future<void> _submitAndShowPrediction() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        festivalStatus != null) {
      final url = Uri.parse('http://127.0.0.1:5000/predict');

      final payload = {
        "date": _selectedDate!.toIso8601String().split('T').first,
        "day": _selectedDate!.weekday.toString(),
        "event": festivalStatus == '1' ? "True" : "False", // ✅ Fixed typo
        "customer_count": int.tryParse(customerController.text) ?? 0,
        "sales": int.tryParse(salesController.text) ?? 0,
        "staff_names": staffNameController.text
            .split(',')
            .map((e) => e.trim())
            .toList(), // ✅ Convert comma-separated to list
        "staff_count": int.tryParse(staffCountController.text) ?? 0,
      };

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
          final resultData = jsonDecode(response.body);

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PredictionResultScreen(
                predictedSales:
                    resultData['predicted_sales'].toString(), // Keep as string
                predictedStaff:
                    resultData['predicted_staff'].toString(), // Keep as string
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存または予測エラー (${response.statusCode})')),
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

  /// Just save data without showing prediction
  Future<void> _saveDataOnly() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        festivalStatus != null) {
      final url = Uri.parse('http://127.0.0.1:5000/save'); // ⚠️ Create this in Flask

      final payload = {
        "date": _selectedDate!.toIso8601String().split('T').first,
        "day": _selectedDate!.weekday.toString(),
        "event": festivalStatus == '1' ? "True" : "False",
        "customer_count": int.tryParse(customerController.text) ?? 0,
        "sales": int.tryParse(salesController.text) ?? 0,
        "staff_names": staffNameController.text
            .split(',')
            .map((e) => e.trim())
            .toList(),
        "staff_count": int.tryParse(staffCountController.text) ?? 0,
      };

      try {
        final response = await http.post(
          url,
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(payload),
        );

        if (response.statusCode == 200) {
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('売上・スタッフ予測ダッシュボード')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              '売上・スタッフ数・祭り情報の入力',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2b5797),
              ),
            ),
            const SizedBox(height: 24),
            Form(
              key: _formKey,
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(blurRadius: 10, color: Colors.black12)
                  ],
                ),
                child: Column(
                  children: [
                    ListTile(
                      title: const Text("日付"),
                      subtitle: Text(_selectedDate == null
                          ? '日付を選択'
                          : '${_selectedDate!.year}/${_selectedDate!.month}/${_selectedDate!.day}'),
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
                    TextFormField(
                      controller: salesController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '売上（円）'),
                      validator: (value) =>
                          value == null || value.isEmpty ? '売上を入力してください' : null,
                    ),
                    TextFormField(
                      controller: customerController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: '客数'),
                      validator: (value) =>
                          value == null || value.isEmpty ? '客数を入力してください' : null,
                    ),
                    TextFormField(
                      controller: staffCountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'スタッフ数'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'スタッフ数を入力してください' : null,
                    ),
                    TextFormField(
                      controller: staffNameController,
                      decoration: const InputDecoration(labelText: 'スタッフ名前（カンマ区切り）'),
                      validator: (value) =>
                          value == null || value.isEmpty ? 'スタッフ名を入力してください' : null,
                    ),
                    DropdownButtonFormField<String>(
                      value: festivalStatus,
                      decoration: const InputDecoration(labelText: '祭りの有無'),
                      items: const [
                        DropdownMenuItem(value: '1', child: Text('あり')),
                        DropdownMenuItem(value: '0', child: Text('なし')),
                      ],
                      onChanged: (value) => setState(() => festivalStatus = value),
                      validator: (value) =>
                          value == null ? '祭りの有無を選択してください' : null,
                    ),
                    const SizedBox(height: 20),

                    /// Two buttons: save + prediction
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        ElevatedButton.icon(
                          icon: const Icon(Icons.save),
                          label: const Text('保存のみ'),
                          onPressed: _saveDataOnly,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[700],
                            foregroundColor: Colors.white,
                          ),
                        ),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.trending_up),
                          label: const Text('保存と予測'),
                          onPressed: _submitAndShowPrediction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF2b5797),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
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
}
