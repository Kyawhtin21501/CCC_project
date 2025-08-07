
import 'package:flutter/material.dart';
import 'package:predictor_web/screens/daily_report.dart';


void main() {
  runApp(const ShiftAIApp());
}

class ShiftAIApp extends StatelessWidget {
  const ShiftAIApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ShiftAI Dashboard',
      theme: ThemeData(fontFamily: 'JosefinSans'),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
