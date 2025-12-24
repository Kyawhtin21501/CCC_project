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

    /// ---- PARSE ----
    final List<Map<String, dynamic>> parsed = [];

    for (final item in salesData) {
      final date = safeParseDate(item['date']);
      if (date == null) continue;

      final sales = (item['pred_sales'] ?? item['predicted_sales'] ?? 0)
          .toDouble();

      parsed.add({
        'date': date,
        'sales': sales,
      });
    }

    if (parsed.isEmpty) {
      return const Center(child: Text('売上データがありません'));
    }

    parsed.sort(
      (a, b) => (a['date'] as DateTime)
          .compareTo(b['date'] as DateTime),
    );

    final data =
        parsed.length > 7 ? parsed.sublist(parsed.length - 7) : parsed;

    final rawMax =
        data.map((e) => e['sales'] as double).reduce((a, b) => a > b ? a : b);

    final maxY = rawMax <= 0 ? 1 : rawMax * 1.2;

    return SizedBox(
      height: 260,
      width: double.infinity,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY.toDouble(),

          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY / 4,
          ),

          borderData: FlBorderData(show: false),

          titlesData: FlTitlesData(
            topTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                AxisTitles(sideTitles: SideTitles(showTitles: false)),

            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 48,
                getTitlesWidget: (value, _) => Text(
                  '¥${(value / 1000).toInt()}k',
                  style: const TextStyle(fontSize: 10),
                ),
              ),
            ),

            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, _) {
                  final index = value.toInt();
                  if (index < 0 || index >= data.length) {
                    return const SizedBox.shrink();
                  }
                  final d = data[index]['date'] as DateTime;
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      DateFormat('MM/dd').format(d),
                      style: const TextStyle(fontSize: 10),
                    ),
                  );
                },
              ),
            ),
          ),

          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                data.length,
                (i) => FlSpot(
                  i.toDouble(),
                  data[i]['sales'] as double,
                ),
              ),
              isCurved: true,
              barWidth: 3,
              color: Colors.blueAccent,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  DateTime? safeParseDate(dynamic value) {
    if (value == null) return null;

    try {
      return DateFormat('EEE, dd MMM yyyy HH:mm:ss zzz').parse(value);
    } catch (_) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
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

    if (hour < 12) {
      return 'Morning';
    } else if (hour < 18) {
      return 'Afternoon';
    } else {
      return 'Night';
    }
  }

  Widget _cell(String text, {double width = 90}) {
    return SizedBox(
      width: width,
      child: Text(
        text,
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
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columnSpacing: 16,
          headingRowHeight: 44,
          dataRowHeight: 44,

          columns: const [
            DataColumn(label: Text('日付')),
            DataColumn(label: Text('スタッフ')),
            DataColumn(label: Text('開始')),
            DataColumn(label: Text('終了')),
            DataColumn(label: Text('区分')),
          ],

          rows: shiftData.map((shift) {
            final startTime = shift['start_time'] as String;
            final endTime = shift['end_time'] as String;

            return DataRow(
              cells: [
                DataCell(_cell(shift['date'], width: 100)),
                DataCell(_cell('ID ${shift['staff_id']}')),
                DataCell(_cell(startTime, width: 70)),
                DataCell(_cell(endTime, width: 70)),
                DataCell(_cell(_getShiftLabel(startTime), width: 90)),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
