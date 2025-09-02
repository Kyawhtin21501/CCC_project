import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ShiftChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> shiftSchedule;
  const ShiftChartWidget({super.key, required this.shiftSchedule});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Decide layout based on screen width
        bool isMobile = constraints.maxWidth < 600;
        bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

        double chartHeight = isMobile ? 200 : isTablet ? 250 : 350;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0), // same as dashboard
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("シフト予測表",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),

                // Legend responsive (column for mobile, row for bigger screens)
                isMobile
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _legendItem("Morning", Colors.blueAccent),
                          _legendItem("Afternoon", Colors.greenAccent),
                          _legendItem("Night", Colors.orangeAccent),
                        ],
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          _legendItem("Morning", Colors.blueAccent),
                          _legendItem("Afternoon", Colors.greenAccent),
                          _legendItem("Night", Colors.orangeAccent),
                        ],
                      ),

                const SizedBox(height: 12),

                // Chart itself
                SizedBox(
                  height: chartHeight,
                  child: BarChart(
                    BarChartData(
                      minY: 6,
                      maxY: 24,
                      gridData: FlGridData(show: true, horizontalInterval: 2),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            interval: 2,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) =>
                                Text('${value.toInt()}:00'),
                          ),
                        ),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 &&
                                  index < shiftSchedule.length) {
                                DateTime date = DateTime.parse(
                                    shiftSchedule[index]["date"]);
                                return Transform.rotate(
                                  angle: -1,
                                  child: Text("${date.month}/${date.day}"),
                                );
                              }
                              return const SizedBox(width: 30);
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final shift =
                                shiftSchedule[group.x.toInt()]["staff_id"] ?? "";
                            final date = shiftSchedule[group.x.toInt()]["date"] ??
                                "";
                            return BarTooltipItem(
                              "$date\nStaff: $shift",
                              const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ),
                      barGroups:
                          List.generate(shiftSchedule.length, (index) {
                        final shift = shiftSchedule[index]["shift"];
                        double startHour = shift == "morning"
                            ? 8
                            : shift == "afternoon"
                                ? 13
                                : 18;
                        double endHour = startHour + 4;
                        return BarChartGroupData(
                         
                          x: index,
                         
                          barRods: [
                            BarChartRodData(
                              
                              fromY: startHour,
                              toY: endHour,
                              width: 16,
                              color: shift == "morning"
                                  ? Colors.blueAccent
                                  : shift == "afternoon"
                                      ? Colors.greenAccent
                                      : Colors.orangeAccent,
                              borderRadius: BorderRadius.zero,
                            ),
                          ],
                        );
                      }),
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

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 12, height: 12, color: color),
          const SizedBox(width: 4),
          Text(text),
        ],
      ),
    );
  }
}

class SalesPredictionChartWidget extends StatelessWidget {
  final List<Map<String, dynamic>> salesData;
  const SalesPredictionChartWidget({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        bool isMobile = constraints.maxWidth < 600;
        bool isTablet = constraints.maxWidth >= 600 && constraints.maxWidth < 1024;

        double chartHeight = isMobile ? 200 : isTablet ? 250 : 350;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("売上予測表",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                SizedBox(
                  height: chartHeight,
                  child: LineChart(
                    LineChartData(
                      gridData:
                          FlGridData(show: true, horizontalInterval: 5000),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 50,
                            getTitlesWidget: (value, meta) =>
                                Text(value.toInt().toString()),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, meta) {
                              int index = value.toInt();
                              if (index >= 0 && index < salesData.length) {
                                DateTime date = DateTime.parse(
                                    salesData[index]["date"]);
                                return Text("${date.month}/${date.day}");
                              }
                              return const SizedBox(width: 30);
                            },
                          ),
                        ),
                        topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: true),

                      // Line Chart
                      lineBarsData: [
                        LineChartBarData(
                          isCurved: true,
                          spots: List.generate(salesData.length, (index) {
                            final sales =
                                salesData[index]["predicted_sales"] ?? 0;
                            return FlSpot(
                                index.toDouble(), sales.toDouble());
                          }),
                          color: Colors.redAccent,
                          dotData: FlDotData(show: false),
                          isStrokeCapRound: true,
                          barWidth: 3,
                        ),
                      ],

                      // Tooltips
                      lineTouchData: LineTouchData(
                        touchTooltipData: LineTouchTooltipData(
                          getTooltipItems: (touchedSpots) {
                            return touchedSpots.map((spot) {
                              final date =
                                  salesData[spot.x.toInt()]["date"] ?? "";
                              final sales = spot.y.toInt();
                              return LineTooltipItem(
                                "$date\nSales: $sales",
                                const TextStyle(color: Colors.white),
                              );
                            }).toList();
                          },
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
