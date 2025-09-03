import 'package:flutter/material.dart';
import 'package:predictor_web/screens/daily_report.dart';
import 'package:predictor_web/theme_provider/them.dart';
import 'package:predictor_web/theme_provider/theme_color.dart';
import 'package:provider/provider.dart';


void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: '今日もお疲れさま〜',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeProvider.themeMode,
      home: const DashboardScreen(),
    );
  }
}
