import 'package:flutter/material.dart';

class DateRangeScreen extends StatefulWidget {
  const DateRangeScreen({super.key});

  @override
  State<DateRangeScreen> createState() => _DateRangeScreenState();
}

class _DateRangeScreenState extends State<DateRangeScreen> {
  final TextEditingController _startDateController = TextEditingController();
  final TextEditingController _endDateController = TextEditingController();

  Future<void> _selectDate(TextEditingController controller) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        controller.text = picked.toLocal().toString().split(' ')[0]; // yyyy-MM-dd
      });
    }
  }

  void _onSubmit() {
    final startDate = _startDateController.text;
    final endDate = _endDateController.text;

    if (startDate.isEmpty || endDate.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both start and end dates')),
      );
      return;
    }

    // TODO: Do something with the selected date range
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selected Dates'),
        content: Text('Start: $startDate\nEnd: $endDate'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
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
      appBar: AppBar(title: const Text('Select Date Range')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            TextField(
              controller: _startDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Start Date',
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDate(_startDateController),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _endDateController,
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'End Date',
                suffixIcon: const Icon(Icons.calendar_today),
                border: OutlineInputBorder(),
              ),
              onTap: () => _selectDate(_endDateController),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: _onSubmit,
              child: const Text('Submit'),
            ),
          ],
        ),
      ),
    );
  }
}
