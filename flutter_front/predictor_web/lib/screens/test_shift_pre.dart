import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/api_services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';

class DashboardEdScreen extends StatefulWidget {
  const DashboardEdScreen({super.key});

  @override
  State<DashboardEdScreen> createState() => _DashboardEdScreenState();
}

class _DashboardEdScreenState extends State<DashboardEdScreen> {
  List<Map<String, dynamic>> _shiftCache = [];
  List<Map<String, dynamic>> _salesCache = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  /// filter to keep only the next 7 days
  List<Map<String, dynamic>> filterNextWeek(List<Map<String, dynamic>> data) {
    final today = DateTime.now();
    final nextWeek = today.add(const Duration(days: 7));

    return data.where((entry) {
      final date = DateTime.parse(entry['date']); // must be "YYYY-MM-DD"
      return date.isAfter(today.subtract(const Duration(days: 1))) &&
             date.isBefore(nextWeek.add(const Duration(days: 1)));
    }).toList();
  }

  Future<void> _loadData() async {
    try {
      final results = await Future.wait([
        ApiService.fetchShiftTableDashboard(),
        ApiService.getPredSales(),
      ]);

      final shiftData = results[0] as List<Map<String, dynamic>>;
      final salesData = results[1] as List<Map<String, dynamic>>;

      setState(() {
        _shiftCache = filterNextWeek(shiftData);
        _salesCache = filterNextWeek(salesData);
        _loading = false;
      });
    } catch (e) {
      setState(() => _loading = false);
      debugPrint("Error loading data: $e");
    }
  }

  /// build line chart for sales
  Widget _buildSalesChart() {
    if (_salesCache.isEmpty) {
      return const Center(child: Text("No sales data for next week"));
    }

    return LineChart(
      LineChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _salesCache.length) {
                  return Text(_salesCache[index]['date'].toString().substring(5));
                }
                return const Text("");
              },
            ),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: _salesCache.asMap().entries.map((e) {
              return FlSpot(e.key.toDouble(), (e.value['predicted_sales'] as num).toDouble());
            }).toList(),
            isCurved: true,
            dotData: FlDotData(show: true),
          ),
        ],
      ),
    );
  }

  /// build bar chart for shifts
  Widget _buildShiftChart() {
    if (_shiftCache.isEmpty) {
      return const Center(child: Text("No shift data for next week"));
    }

    return BarChart(
      BarChartData(
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                int index = value.toInt();
                if (index >= 0 && index < _shiftCache.length) {
                  return Text(_shiftCache[index]['date'].toString().substring(5));
                }
                return const Text("");
              },
            ),
          ),
        ),
        barGroups: _shiftCache.asMap().entries.map((e) {
          return BarChartGroupData(
            x: e.key,
            barRods: [
              BarChartRodData(
                toY: (e.value['staff_count'] as num).toDouble(),
                width: 18,
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text("Dashboard"),
      ),
      drawer: AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    const Text("📈 Predicted Sales (Next 7 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 250, child: _buildSalesChart()),
                    const SizedBox(height: 32),
                    const Text("👥 Staff Shifts (Next 7 Days)", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    SizedBox(height: 250, child: _buildShiftChart()),
                  ],
                ),
              ),
            ),
    );
  }
}
