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

/// =======================================================
/// SHIFT TABLE WIDGET
/// =======================================================
class ShiftTableWidget extends StatelessWidget {
  final List<Map<String, dynamic>> shiftData;

  const ShiftTableWidget({
    super.key,
    required this.shiftData,
  });

  String _getShiftLabel(String startTime) {
    final hour = int.tryParse(startTime.split(':').first) ?? 0;
    if (hour < 12) return '早番';
    if (hour < 18) return '遅番';
    return '夜勤';
  }

  Widget _cell(String text, {double width = 90}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
        style: const TextStyle(fontSize: 13),
        overflow: TextOverflow.ellipsis,
        softWrap: false,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (shiftData.isEmpty) {
      return const Center(child: Text('シフトデータがありません'));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: Colors.grey.shade300),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 44,
          dataRowHeight: 48,
          headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
          columns: const [
            DataColumn(label: Text('日付', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('スタッフ', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('開始', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('終了', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('区分', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: shiftData.map((shift) {
            final startTime = shift['start_time'] as String;
            final endTime = shift['end_time'] as String;

            return DataRow(
              cells: [
                DataCell(_cell(shift['date'] ?? '', width: 100)),
                DataCell(_cell('スタッフ ${shift['staff_id'] ?? ''}')),
                DataCell(_cell(startTime, width: 60)),
                DataCell(_cell(endTime, width: 60)),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      _getShiftLabel(startTime),
                      style: const TextStyle(fontSize: 11, color: Colors.blue),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}