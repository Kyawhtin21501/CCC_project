import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '飲食店のシフトと売上予測',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.blue),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final TextEditingController customerController = TextEditingController();
  final TextEditingController salesController = TextEditingController();
  DateTime selectedDate = DateTime.now();
  String selectedDay = '月曜日';
  String selectedEvent = 'なし';
  String salesPrediction = '-';
  String staffPrediction = '-';

  Future<void> fetchPredictions() async {
    final url = Uri.parse('http://127.0.0.1:5000/predict');

    final body = {
      'date': selectedDate.toIso8601String(),
      'day': selectedDay,
      'event': selectedEvent,
      'customer_count': int.tryParse(customerController.text) ?? 0,
      'sales': int.tryParse(salesController.text) ?? 0,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        salesPrediction = data['predicted_sales'].toString();
        staffPrediction = data['predicted_staff'].toString();
      });
    } else {
      setState(() {
        salesPrediction = 'Error';
        staffPrediction = 'Error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF5F8FB),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("ダッシュボード", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                Text("飲食店のシフトと売上予測", style: TextStyle(fontSize: 18)),
              ],
            ),
            SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 1,
                  child: CalendarDatePicker(
                    initialDate: selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    onDateChanged: (date) {
                      setState(() => selectedDate = date);
                    },
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("日次データ入力", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                              SizedBox(height: 10),
                              Text("日付: ${selectedDate.toString().split(' ')[0]}", style: TextStyle(fontSize: 16)),
                              DropdownButton<String>(
                                value: selectedDay,
                                onChanged: (val) => setState(() => selectedDay = val!),
                                items: ['月曜日', '火曜日', '水曜日', '木曜日', '金曜日', '土曜日', '日曜日']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                              ),
                              TextField(
                                controller: customerController,
                                decoration: InputDecoration(labelText: '来客数'),
                                keyboardType: TextInputType.number,
                              ),
                              TextField(
                                controller: salesController,
                                decoration: InputDecoration(labelText: '売上'),
                                keyboardType: TextInputType.number,
                              ),
                              DropdownButton<String>(
                                value: selectedEvent,
                                onChanged: (val) => setState(() => selectedEvent = val!),
                                items: ['なし', '祝日', 'イベント', 'セール']
                                    .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                                    .toList(),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton(
                                onPressed: fetchPredictions,
                                child: Center(child: Text("保存")),
                                style: ElevatedButton.styleFrom(minimumSize: Size(double.infinity, 40)),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          PredictionCard(title: '売上の予測', value: salesPrediction),
                          PredictionCard(title: 'スタッフの予測', value: staffPrediction),
                        ],
                      )
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}

class PredictionCard extends StatelessWidget {
  final String title;
  final String value;

  PredictionCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        padding: EdgeInsets.all(20),
        width: 150,
        child: Column(
          children: [
            Text(title, style: TextStyle(fontSize: 16)),
            SizedBox(height: 10),
            Text(value, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}
