import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:predictor_web/api_services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';


class CreatedShiftScreen extends StatefulWidget {
  const CreatedShiftScreen({super.key});

  @override
  State<CreatedShiftScreen> createState() => _CreatedShiftScreenState();
}

class _CreatedShiftScreenState extends State<CreatedShiftScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();
  String? _resultMessage;

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        controller.text = picked.toIso8601String().split("T").first;
      });
    }
  }

  Future<void> _submitShiftRequest() async {
    final start = _startDateController.text;
    final end = _endDateController.text;

    if (start.isEmpty || end.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('開始日と終了日を選択してください')),
      );
      return;
    }

    try {
      final response = await ApiService.postShiftRequest({
        "start_date": start,
        "end_date": end,
        "latitude": 35.6895,
        "longitude": 139.6917
      });

      if (response.statusCode == 200) {
        final List result = jsonDecode(response.body);
        setState(() {
          _resultMessage =
              "受信件数：${result.length}\n\n${result.take(5).map((e) => e.toString()).join('\n\n')}";
        });
      } else {
        setState(() {
          _resultMessage = "エラー: ${response.statusCode}";
        });
      }
    } catch (e) {
      setState(() {
        _resultMessage = '通信エラー: $e';
      });
    }
  }

  @override
  void dispose() {
    _startDateController.dispose();
    _endDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("シフト期間の選択")),
     drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(60),
        child: Column(
          children: [
            _buildDateField("開始日", _startDateController),
            const SizedBox(height: 20),
            _buildDateField("終了日", _endDateController),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _submitShiftRequest,
              child: const Text("シフト予測を取得"),
            ),
            const SizedBox(height: 20),
            if (_resultMessage != null)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(_resultMessage!, style: const TextStyle(fontSize: 14)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      readOnly: true,
      decoration: InputDecoration(
        labelText: label,
        suffixIcon: const Icon(Icons.calendar_today),
        border: const OutlineInputBorder(),
      ),
      onTap: () => _selectDate(controller),
    );
  }
}
