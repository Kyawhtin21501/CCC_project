import 'package:flutter/material.dart';
import 'package:predictor_web/widgets/appdrawer.dart';

// ignore: must_be_immutable

const String apiUrl = 'http://192.168.0.12:5000/services/sale_prediction_staff_count';
class PredictionResultScreen extends StatelessWidget {
  // final String predictedSales;
  // final String predictedStaff;
  String predictedSales="";
  String predictedStaff=" ";
  PredictionResultScreen({
    super.key,
    required this.predictedSales,
    required this.predictedStaff,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
     appBar: AppBar(),
     drawer: AppDrawer(),
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(60),
          margin: const EdgeInsets.symmetric(horizontal: 16),
          constraints: const BoxConstraints(maxWidth: 700),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                blurRadius: 16,
                color: Colors.black12,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '来週の予測結果',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B5797),
                ),
              ),
              const SizedBox(height: 24),
              const Text('売上予測', style: TextStyle(fontSize: 18)),
              Text(
                '¥$predictedSales',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          const Text('必要スタッフ数の予測', style: TextStyle(fontSize: 18)),
          Text(
            '$predictedStaff 人',
            style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 36),
          ElevatedButton.icon(
            icon: const Icon(Icons.arrow_back),
            label: const Text('戻る'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    ),
  ),
);
  }}