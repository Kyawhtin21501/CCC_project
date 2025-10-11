import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';


class ShiftChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> shiftSchedule;

  const ShiftChartWidget({super.key, required this.shiftSchedule});

  // Helper to format date string to "MM/dd (Day)"
  String _formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    // Get the Japanese day of the week
    final dayOfWeek = ['月', '火', '水', '木', '金', '土', '日'][date.weekday - 1];
    return "${date.month}/${date.day} ($dayOfWeek)";
  }

  @override
  Widget build(BuildContext context) {
    // Extract unique dates and sort
    final dates =
        shiftSchedule.map((e) => e['date']).toSet().toList()
          ..sort((a, b) => DateTime.parse(a).compareTo(DateTime.parse(b)));

    final shifts = ['morning', 'afternoon', 'night'];

    // Define shift colors (Lighter shades for background fill)
    final Map<String, Color> shiftColors = {
      'morning': Colors.blue.shade50,
      'afternoon': Colors.green.shade50,
      'night': Colors.orange.shade50,
    };

    // Responsive width calculation
    final screenWidth = MediaQuery.of(context).size.width;
    // Calculate table width by subtracting card margins and padding
    final double tableWidth = screenWidth - 12 * 2 - 16 * 2;
    final double cellWidth = tableWidth / (dates.length + 1);

    // Styling constants
    const double rowVerticalPadding = 8;
    const double cellMargin = 4;
    const double cellPadding = 8;

    return Center(
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 6, // Increased elevation for a clearer lift
        margin: const EdgeInsets.all(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "シフト一覧表（7日間）",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              // Table Layout - Use SingleChildScrollView for horizontal scrolling
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Table(
                  defaultVerticalAlignment: TableCellVerticalAlignment.middle,
                  columnWidths: {
                    0: FixedColumnWidth(cellWidth * 0.8), // Shift labels column
                    for (int i = 1; i <= dates.length; i++)
                      i: FixedColumnWidth(cellWidth),
                  },
                  // Use horizontal dividers but no vertical ones
                  border: const TableBorder(
                    horizontalInside: BorderSide(
                      width: 0.5,
                    //  color: Colors.grey,
                    ),
                  ),
                  children: [
                    // Header Row
                    TableRow(
                      // decoration: BoxDecoration(
                      //   color:
                      //       Colors.grey.shade100, // Light background for header
                      // ),
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: rowVerticalPadding,
                            horizontal: 8,
                          ),
                          child: Text(
                            "シフト",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        ...dates.map((d) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: rowVerticalPadding,
                                horizontal: 4,
                              ),
                              child: Text(
                                _formatDate(d),
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),

                    // Shift Rows
                    //  "morning": list(range(9, 14)),      # 9:00 to 13:59
                    // "afternoon": list(range(14, 19)),   # 14:00 to 18:59
                    // "night": list(range(19, 24))        # 19:00 to 23:59
                    ...shifts.map((shift) {
                      final shiftJp =
                          shift == "morning"
                              ? "朝 (9:00 to 13:59)"
                              : shift == "afternoon"
                              ? "昼 (14:00 to 18:59)"
                              : "夜 (19:00 to 23:59)";
                      return TableRow(
                        children: [
                          // Shift label (Styled background)
                          Container(
                            // color: Colors.blueGrey.shade50, // Subtle background for the label column
                            padding: const EdgeInsets.symmetric(
                              vertical: rowVerticalPadding,
                              horizontal: 8,
                            ),
                            child: Text(
                              shiftJp,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.blueGrey,
                              ),
                            ),
                          ),

                          // Cells for each date
                          ...dates.map((d) {
                            final names =
                                shiftSchedule
                                    .where(
                                      (e) =>
                                          e['date'] == d && e['shift'] == shift,
                                    )
                                    .map((e) => e['Name'])
                                    .toList();

                            return Container(
                              margin: const EdgeInsets.all(cellMargin),
                              decoration: BoxDecoration(
                                color: shiftColors[shift],
                                borderRadius: BorderRadius.circular(
                                  6,
                                ), // Rounded corners for cells
                                border: Border.all(
                                  color: shiftColors[shift]!,
                                  width: 1,
                                ),
                              ),
                              constraints: const BoxConstraints(
                                minHeight: 80,
                              ), // Set minimum height for cells
                              child:
                                  names.isEmpty
                                      ? Center(
                                        child: Text(
                                          "---",
                                          style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 13,
                                          ),
                                        ),
                                      )
                                      : Padding(
                                        padding: const EdgeInsets.all(
                                          cellPadding,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.stretch,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children:
                                              names
                                                  .map(
                                                    (n) => Text(
                                                      n,
                                                      style: TextStyle(
color: Colors.black87,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                      textAlign:
                                                          TextAlign.center,
                                                      maxLines: 1,
                                                      overflow:
                                                          TextOverflow.ellipsis,
                                                    ),
                                                  )
                                                  .toList(),
                                        ),
                                      ),
                            );
                          }),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              
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

  /// Aggregate sales by day (average per day)
  List<Map<String, dynamic>> _aggregateSales(List<Map<String, dynamic>> data) {
    Map<String, double> dailySales = {};
    Map<String, int> dailyCount = {};

    for (var item in data) {
      final date = item["date"].substring(0, 10); // yyyy-MM-dd
      final sales = (item["predicted_sales"] ?? 0).toDouble();

      dailySales[date] = (dailySales[date] ?? 0) + sales;
      dailyCount[date] = (dailyCount[date] ?? 0) + 1;
    }

    // Average sales per day
    List<Map<String, dynamic>> aggregated = dailySales.keys.map((date) {
      return {
        "date": date,
        "predicted_sales": dailySales[date]! / dailyCount[date]!,
      };
    }).toList();

    // Sort by date
    aggregated.sort(
      (a, b) => DateTime.parse(a["date"]).compareTo(DateTime.parse(b["date"])),
    );

    // Keep only the last 7 days
    if (aggregated.length > 7) {
      aggregated = aggregated.sublist(aggregated.length - 7);
    }

    return aggregated;
  }

  /// Convert weekday number to Japanese label
  String _weekdayToJapanese(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return "月";
      case DateTime.tuesday:
        return "火";
      case DateTime.wednesday:
        return "水";
      case DateTime.thursday:
        return "木";
      case DateTime.friday:
        return "金";
      case DateTime.saturday:
        return "土";
      case DateTime.sunday:
        return "日";
      default:
        return "";
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double chartHeight = (constraints.maxHeight * 0.25).clamp(200.0, 400.0);

        final aggregatedData = _aggregateSales(salesData);

        if (aggregatedData.isEmpty) {
          return const Center(child: Text("データがありません"));
        }

        final startDate = DateTime.parse(aggregatedData.first["date"]);
        final totalDays = DateTime.parse(aggregatedData.last["date"])
            .difference(startDate)
            .inDays;

        // Spots
        List<FlSpot> spots = aggregatedData.map((data) {
          final date = DateTime.parse(data["date"]);
          final x = date.difference(startDate).inDays.toDouble();
          final y = (data["predicted_sales"] ?? 0).toDouble();
          return FlSpot(x, y);
        }).toList();

        final double maxSales =
            spots.map((e) => e.y).reduce((a, b) => a > b ? a : b);
        final double maxY = maxSales * 1.1;

        int step = (totalDays ~/ 6).clamp(1, 7);

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "売上予測表（直近7日間）",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: chartHeight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        maxY: maxY,
                        minX: 0,
                        titlesData: FlTitlesData(
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 50,
                             // space between Y labels and chart
                              getTitlesWidget: (value, meta) => Text(
                                value.toInt().toString(),
                                style: const TextStyle(fontSize: 12),
                              ),
                            ),
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              interval: step.toDouble(),
                              getTitlesWidget: (value, meta) {
                                final date = startDate.add(Duration(days: value.toInt()));
                                final weekday = _weekdayToJapanese(date.weekday);
                                return Text(
                                  "${date.month}/${date.day}（$weekday）",
                                  style: const TextStyle(fontSize: 10),
                                );
                              },
                            ),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles:false),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: const Border(
                            left: BorderSide(),
                            bottom: BorderSide(),
                            top: BorderSide(),
                            right: BorderSide(),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            isCurved: false,
                            spots: spots,
                            color: Colors.blueAccent,
                            dotData: FlDotData(show: false),
                            isStrokeCapRound: true,
                            barWidth: 2,
                          ),
                        ],
                        lineTouchData: LineTouchData(
                          touchTooltipData: LineTouchTooltipData(
                            getTooltipItems: (touchedSpots) {
                              return touchedSpots.map((spot) {
                                final date = startDate.add(
                                  Duration(days: spot.x.toInt()),
                                );
                                final weekday = _weekdayToJapanese(date.weekday);
                                final sales = spot.y.toInt();
                                return LineTooltipItem(
                                  "${date.month}/${date.day}（$weekday）\n売上: $sales 円",
                                  const TextStyle(color: Colors.white),
                                );
                              }).toList();
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
