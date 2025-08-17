// import 'package:flutter/material.dart';
// import 'package:predictor_web/api_services/api_services.dart';


// class ShiftDashboardScreen extends StatefulWidget {
//   const ShiftDashboardScreen({super.key});

//   @override
//   State<ShiftDashboardScreen> createState() => _ShiftDashboardScreenState();
// }

// class _ShiftDashboardScreenState extends State<ShiftDashboardScreen> {
//   late Future<List<Map<String, dynamic>>> _shiftData;

//   @override
//   void initState() {
//     super.initState();
//     _shiftData = ApiService.fetchShiftTableDashboard();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Shift Dashboard")),
//       body: FutureBuilder<List<Map<String, dynamic>>>(
//         future: _shiftData,
//         builder: (context, snapshot) {
//           if (snapshot.connectionState == ConnectionState.waiting) {
//             return const Center(child: CircularProgressIndicator());
//           } else if (snapshot.hasError) {
//             return Center(child: Text("Error: ${snapshot.error}"));
//           } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
//             return const Center(child: Text("No data available"));
//           }

//           final data = snapshot.data!;
//           final columns = data.first.keys.toList();

//           return SingleChildScrollView(
//             scrollDirection: Axis.horizontal,
//             child: DataTable(
//               columns: columns
//                   .map((col) => DataColumn(label: Text(col)))
//                   .toList(),
//               rows: data
//                   .map((row) => DataRow(
//                         cells: columns
//                             .map((col) =>
//                                 DataCell(Text(row[col]?.toString() ?? "")))
//                             .toList(),
//                       ))
//                   .toList(),
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:predictor_web/api_services/api_services.dart';

class ShiftDashboardScreen extends StatefulWidget {
  const ShiftDashboardScreen({super.key});

  @override
  State<ShiftDashboardScreen> createState() => _ShiftDashboardScreenState();
}

class _ShiftDashboardScreenState extends State<ShiftDashboardScreen> {
  late Future<List<Map<String, dynamic>>> _shiftData;

  @override
  void initState() {
    super.initState();
    _shiftData = ApiService.fetchShiftTableDashboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Shift Dashboard")),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shiftData,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("No data available"));
          }

          final data = snapshot.data!;

          // Build bar groups for the chart
          final barGroups = <BarChartGroupData>[];
          for (int i = 0; i < data.length; i++) {
            final row = data[i];
            final start = double.tryParse(row['start_time'].toString()) ?? 0;
            final end = double.tryParse(row['end_time'].toString()) ?? 0;

            barGroups.add(
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    fromY: start,
                    toY: end,
                    width: 18,
                    color: Colors.blueAccent,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Shift Schedule",
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceBetween,
                          gridData: FlGridData(
                            show: true,
                            drawHorizontalLine: true,
                            drawVerticalLine: true,
                            horizontalInterval: 2,
                            verticalInterval: 1,
                          ),
                          borderData: FlBorderData(show: false),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 40,
                                getTitlesWidget: (value, meta) {
                                  // Show in 2-hour increments
                                  if (value % 2 == 0) {
                                    return Text("${value.toInt()}:00");
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  if (value.toInt() >= 0 &&
                                      value.toInt() < data.length) {
                                    return Text(
                                      data[value.toInt()]['staff_id'].toString(),
                                      style: const TextStyle(fontSize: 10),
                                    );
                                  }
                                  return const SizedBox();
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          minY: 6, // earliest shift hour
                          maxY: 24, // latest shift hour
                          barGroups: barGroups,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
