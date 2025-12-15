import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ShiftChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> shiftSchedule;

  const ShiftChartWidget({super.key, required this.shiftSchedule});

  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    final dayOfWeek = ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
    return "${date.month}/${date.day} ($dayOfWeek)";
  }

  @override
  Widget build(BuildContext context) {
    final dates = shiftSchedule.map((e) => e['date']).toSet().toList()
      ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));
    final shifts = ['morning', 'afternoon', 'night'];
    final shiftColors = {
      'morning': Colors.blue.shade50,
      'afternoon': Colors.green.shade50,
      'night': Colors.orange.shade50,
    };

    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // Adaptive sizing
    final tableWidth = (screenWidth - 32).clamp(400, double.infinity);
    final cellWidth = tableWidth / (dates.length + 1);
    final rowHeight = (screenHeight * 0.08).clamp(60, 120);
    final fontSize = (screenWidth / 50).clamp(10, 14);

    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6,
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "シフト一覧表（7日間）",
                style: TextStyle(fontSize: fontSize + 6, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: FixedColumnWidth(cellWidth * 0.8),
                    for (int i = 1; i <= dates.length; i++) i: FixedColumnWidth(cellWidth),
                  },
                  border: const TableBorder(
                    horizontalInside: BorderSide(width: 0.5),
                  ),
                  children: [
                    TableRow(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: rowHeight * 0.1, horizontal: 8),
                          child: Text(
                            "シフト",
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize.toDouble()),
                          ),
                        ),
                        ...dates.map((d) => Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: rowHeight * 0.1, horizontal: 4),
                                child: Text(
                                  _formatDate(d),
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: fontSize - 1),
                                ),
                              ),
                            )),
                      ],
                    ),
                    ...shifts.map((shift) {
                      final shiftJp = shift == "morning"
                          ? "朝 (9:00-13:59)"
                          : shift == "afternoon"
                              ? "昼 (14:00-18:59)"
                              : "夜 (19:00-23:59)";
                      return TableRow(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(vertical: rowHeight * 0.1, horizontal: 8),
                            child: Text(
                              shiftJp,
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: fontSize.toDouble(),
                                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black87),
                            ),
                          ),
                          ...dates.map((d) {
                            final names = shiftSchedule
                                .where((e) => e['date'] == d && e['shift'] == shift)
                                .map((e) => e['Name'])
                                .toList();
                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: shiftColors[shift],
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: shiftColors[shift]!, width: 1),
                              ),
                              constraints: BoxConstraints(minHeight: rowHeight * 0.8),
                              child: names.isEmpty
                                  ? Center(
                                      child: Text(
                                        "---",
                                        style: TextStyle(fontSize: fontSize - 2),
                                      ),
                                    )
                                  : Padding(
                                      padding: const EdgeInsets.all(6),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: names
                                            .map((n) => Text(
                                                  n,
                                                  style: TextStyle(
                                                    color: Colors.black87,
                                                      fontSize: fontSize - 2,
                                                      fontWeight: FontWeight.w600),
                                                  textAlign: TextAlign.center,
                                                  overflow: TextOverflow.ellipsis,
                                                ))
                                            .toList(),
                                      ),
                                    ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SalesPredictionChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  const SalesPredictionChartWidget({super.key, required this.salesData});

  List<Map<String, dynamic>> _aggregateSales(List<Map<String, dynamic>> data) {
    Map<String, double> dailySales = {};
    Map<String, int> dailyCount = {};

    for (var item in data) {
      final date = item["date"].substring(0, 10); // yyyy-MM-dd
      final sales = (item["predicted_sales"] ?? 0).toDouble();

      dailySales[date] = (dailySales[date] ?? 0) + sales;
      dailyCount[date] = (dailyCount[date] ?? 0) + 1;
    }

    List<Map<String, dynamic>> aggregated = dailySales.keys.map((date) {
      return {
        "date": date,
        "predicted_sales": dailySales[date]! / dailyCount[date]!,
      };
    }).toList();

    aggregated.sort((a, b) => DateTime.parse(a["date"])
        .compareTo(DateTime.parse(b["date"])));

    if (aggregated.length > 7) {
      aggregated = aggregated.sublist(aggregated.length - 7);
    }

    return aggregated;
  }

  @override
  Widget build(BuildContext context) {
    final aggregatedData = _aggregateSales(salesData);

    if (aggregatedData.isEmpty) {
      return const Center(child: Text("データがありません"));
    }

    final startDate = DateTime.parse(aggregatedData.first["date"]);
    final List<FlSpot> spots = aggregatedData.asMap().entries.map((entry) {
      final x = entry.key.toDouble();
      final y = (entry.value["predicted_sales"] ?? 0).toDouble();
      return FlSpot(x, y);
    }).toList();

    final maxSales = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    final minSales = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: SizedBox(
        height: 300,
        child: LineChart(
          LineChartData(
            minX: 0,
            maxX: (spots.length - 1).toDouble(),
            minY: 0,
            maxY: maxSales * 1.1,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: true,
              verticalInterval: 1,
              horizontalInterval: (maxSales / 5).ceilToDouble(),
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              ),
              getDrawingVerticalLine: (value) => FlLine(
                color: Colors.grey.shade300,
                strokeWidth: 1,
              ),
            ),
            titlesData: FlTitlesData(
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: false,
                  interval: (maxSales / 5).ceilToDouble(),
                  getTitlesWidget: (value, meta) =>
                      Text(value.toInt().toString(), style: const TextStyle(fontSize: 12)),
                ),
              ),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  interval: 1,
                  getTitlesWidget: (value, meta) {
                    final date = startDate.add(Duration(days: value.toInt()));
                    return Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        DateFormat.E().format(date), // Mon, Tue, ...
                        style: const TextStyle(fontSize: 12),
                      ),
                    );
                  },
                ),
              ),
            ),
            borderData: FlBorderData(
              show: true,
              border: Border.all(color: Colors.grey.shade400),
            ),
            lineBarsData: [
              LineChartBarData(
                spots: spots,
                isCurved: true,
                color: Colors.blueAccent,
                barWidth: 3,
                dotData: FlDotData(show: true),
                belowBarData: BarAreaData(show: false),
              ),
            ],
            lineTouchData: LineTouchData(
              touchTooltipData: LineTouchTooltipData(
               // tooltipBackgroundColor: Colors.blueAccent,
                getTooltipItems: (touchedSpots) => touchedSpots.map((spot) {
                  final date = startDate.add(Duration(days: spot.x.toInt()));
                  return LineTooltipItem(
                    "${DateFormat.Md().format(date)}\n売上: ${spot.y.toInt()}円",
                    const TextStyle(color: Colors.white),
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
