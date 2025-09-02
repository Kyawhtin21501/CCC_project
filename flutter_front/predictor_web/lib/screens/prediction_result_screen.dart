import 'package:flutter/material.dart';
import 'package:predictor_web/widgets/appdrawer.dart';

/// API URL for prediction services (Flask backend)
/// Example endpoint: /services/sale_prediction_staff_count
/// You can use this constant in your API service class later.
const String apiUrl = 'http://192.168.0.12:5000/services/sale_prediction_staff_count';

/// A screen that displays the sales and staff prediction results.
/// 
/// It receives two values from the backend:
/// - predictedSales (売上予測)
/// - predictedStaff (必要スタッフ数)
/// 
/// These are passed as parameters when navigating to this screen.
class PredictionResultScreen extends StatelessWidget {
  /// Predicted sales amount as String (e.g., "50000").
  final String predictedSales;

  /// Predicted number of staff required as String (e.g., "5").
  final String predictedStaff;

  /// Constructor to initialize the prediction values.
  /// Both values are required to show on this screen.
  const PredictionResultScreen({
    super.key,
    required this.predictedSales,
    required this.predictedStaff,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6), // Light gray background
      appBar: AppBar(), // Simple AppBar
      drawer: const AppDrawer(), // Custom drawer widget (menu on the left)
      body: Center(
        child: Container(
          // Padding inside the card-like container
          padding: const EdgeInsets.all(60),
          // Horizontal margin so it doesn't touch screen edges
          margin: const EdgeInsets.symmetric(horizontal: 16),
          // Maximum width so it's centered and not too wide
          constraints: const BoxConstraints(maxWidth: 700),
          // White card with rounded corners and shadow
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
            mainAxisSize: MainAxisSize.min, // Wrap content vertically
            children: [
              // Title
              const Text(
                '来週の予測結果', // Prediction results for next week
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2B5797), // Blue color for emphasis
                ),
              ),
              const SizedBox(height: 24),

              // Sales prediction label
              const Text('売上予測', style: TextStyle(fontSize: 18)),

              // Display sales value
              Text(
                '¥$predictedSales', // Add Yen symbol
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 24),

              // Staff prediction label
              const Text('必要スタッフ数の予測', style: TextStyle(fontSize: 18)),

              // Display staff count
              Text(
                '$predictedStaff 人', // Add 人 to mean "persons"
                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 36),

              // Back button
              ElevatedButton.icon(
                icon: const Icon(Icons.arrow_back),
                label: const Text('戻る'), // "Back"
                onPressed: () => Navigator.pop(context), // Go back to previous screen
              ),
            ],
          ),
        ),
      ),
    );
  }
}
