import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// =======================================================
/// SALES PREDICTION LINE CHART
/// =======================================================
class SalesPredictionChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;

  const SalesPredictionChartWidget({
    super.key,
    required this.salesData,
  });

  @override
  Widget build(BuildContext context) {
    if (salesData.isEmpty) {
      return const Center(child: Text('売上データがありません'));
    }

    final List<Map<String, dynamic>> parsed = [];
    for (final item in salesData) {
      final date = safeParseDate(item['date']);
      if (date == null) continue;

      // Ensure we treat the value as a double then cast to int if needed for display
      final sales = (item['pred_sales'] ?? item['predicted_sales'] ?? 0).toDouble();
      parsed.add({'date': date, 'sales': sales});
    }

    if (parsed.isEmpty) return const Center(child: Text('売上データがありません'));

    parsed.sort((a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime));
    final data = parsed.length > 7 ? parsed.sublist(parsed.length - 7) : parsed;

    final rawMax = data.map((e) => e['sales'] as double).reduce((a, b) => a > b ? a : b);
    final maxY = rawMax <= 0 ? 10000.0 : rawMax * 1.3;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(" 週間売上予測 (円)", 
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 10),
        SizedBox(
          height: 220,
          width: double.infinity,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: maxY / 4,
                getDrawingHorizontalLine: (value) => 
                    FlLine(color: Colors.grey.withOpacity(0.2), strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 50,
                    getTitlesWidget: (value, _) {
                      // --- CHANGED HERE: Remove decimals and use Japanese formatting ---
                      if (value == 0) return const Text('0', style: TextStyle(fontSize: 10));
                      
                      String label;
                      if (value >= 10000) {
                        // Display in "Ten Thousand" (万) units without decimals
                        label = '${(value / 10000).toInt()}万';
                      } else {
                        // Display in "k" units without decimals
                        label = '${(value / 1000).toInt()}k';
                      }
                      return Text(label, style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, _) {
                      final index = value.toInt();
                      if (index < 0 || index >= data.length) return const SizedBox.shrink();
                      final d = data[index]['date'] as DateTime;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(DateFormat('M/d').format(d), 
                          style: const TextStyle(fontSize: 10)),
                      );
                    },
                  ),
                ),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: List.generate(data.length, (i) => 
                      FlSpot(i.toDouble(), data[i]['sales'] as double)),
                  isCurved: true,
                  barWidth: 4,
                  color: Colors.blueAccent,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.blueAccent.withOpacity(0.1),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  DateTime? safeParseDate(dynamic value) {
    if (value == null) return null;
    try {
      return DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz').parse(value);
    } catch (_) {
      try { return DateTime.parse(value); } catch (_) { return null; }
    }
  }
}