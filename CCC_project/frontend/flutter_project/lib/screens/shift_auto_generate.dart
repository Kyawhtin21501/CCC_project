import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:provider/provider.dart';
import 'package:predictor_web/theme_provider/them.dart';
import 'package:shimmer/shimmer.dart';

class ShiftAutoScreen extends StatefulWidget {
  const ShiftAutoScreen({super.key});

  @override
  State<ShiftAutoScreen> createState() => _ShiftAutoScreenState();
}

class _ShiftAutoScreenState extends State<ShiftAutoScreen> {
  DateTime _start =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _end =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 7);

  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _shiftTable = [];

  Future<void> _loadShiftTable() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.fetchAutoShiftTableDashboard(_start, _end);
      setState(() {
        _shiftTable = data;
      });
    } catch (e) {
      setState(() {
        _error = "Error: $e";
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  void _clear() {
    setState(() {
      _shiftTable = [];
      _error = null;
      _loading = false;
    });
  }

  Map<String, Map<String, List<Map<String, dynamic>>>> _groupByDateShift(
      List<Map<String, dynamic>> data) {
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var item in data) {
      String date = item['date'].toString();
      String shift = item['shift'].toString();
      int staffId = int.tryParse(item['ID'].toString()) ?? 0;
      String staffName = item['Name']?.toString() ?? 'Unknown';
      if (staffId == 0) continue;
      grouped.putIfAbsent(date, () => {});
      grouped[date]!.putIfAbsent(shift, () => []);
      grouped[date]![shift]!.add({"ID": staffId, "Name": staffName});
    }
    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MM/dd');
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);
    final grouped = _groupByDateShift(_shiftTable);

    return Scaffold(
       drawer: const AppDrawer(currentScreen: DrawerScreen.shiftCreate),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Builder(
        builder: (context) {
          return Column(
            children: [
              /// Custom Menu Bar
              CustomMenuBar(
                title: 'シフト自動作成',
                onMenuPressed: () {
                 Scaffold.of(context).openDrawer();
                },
              ),
          
              Expanded(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        /// === Input Card ===
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("シフト自動作成",
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 30),
                                Text("日付範囲",
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    _DateBox(
                                        text: df.format(_start),
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _start,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                          if (picked != null) {
                                            setState(() => _start = picked);
                                          }
                                        }),
                                    const SizedBox(width: 12),
                                    _DateBox(
                                        text: df.format(_end),
                                        onTap: () async {
                                          final picked = await showDatePicker(
                                            context: context,
                                            initialDate: _end,
                                            firstDate: DateTime(2020),
                                            lastDate: DateTime(2030),
                                          );
                                          if (picked != null) {
                                            setState(() => _end = picked);
                                          }
                                        }),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: _loadShiftTable,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24, vertical: 12),
                                    backgroundColor: Colors.blue,
                                    foregroundColor: Colors.white,
                                  ),
                                  label: const Text('シフト作成'),
                                  icon: const Icon(Icons.auto_awesome),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
          
                        /// === Output Card ===
                        Card(
                          elevation: 2,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("シフト結果",
                                    style: theme.textTheme.titleLarge
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                const SizedBox(height: 12),
                                if (_loading)
                                  _buildShimmerPlaceholder()
                                else if (_error != null)
                                  Text(_error!,
                                      style:
                                          const TextStyle(color: Colors.red))
                                else if (_shiftTable.isEmpty)
                                  Text("結果なし",
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(color: theme.hintColor))
                                else
                                  _buildShiftTable(grouped, df),
                                const SizedBox(height: 12),
                                Text("注意:",
                                    style: theme.textTheme.bodyMedium
                                        ?.copyWith(fontWeight: FontWeight.w600)),
                                const SizedBox(height: 6),
                                Text(
                                    "シフトなし    :スタッフが不足しているか、そのシフトに利用可能なスタッフがいないこと、スタフが希望日まだ記入してないことを意味します。",
                                    style: theme.textTheme.bodySmall
                                        ?.copyWith(color: theme.hintColor)),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    OutlinedButton(
                                        onPressed: _clear, child: const Text('クリア')),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        }
      ),
    );
  }

  Widget _buildShiftTable(
      Map<String, Map<String, List<Map<String, dynamic>>>> grouped, DateFormat df) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("日付")),
          DataColumn(label: Text("朝シフト（午前）")),
          DataColumn(label: Text("昼シフト（午後）")),
          DataColumn(label: Text("夜シフト（夜間）")),
        ],
        rows: List.generate(
          _end.difference(_start).inDays + 1,
          (i) {
            final currentDate = _start.add(Duration(days: i));
            final dateStr = currentDate.toIso8601String().split("T").first;
            final shifts = grouped[dateStr] ?? {};
            String formatNames(List<Map<String, dynamic>>? staffList) {
              if (staffList == null || staffList.isEmpty) return "シフトなし";
              return staffList.map((s) => s["Name"]).join(", ");
            }
            return DataRow(cells: [
              DataCell(Text(df.format(currentDate))),
              DataCell(Text(formatNames(shifts["morning"]))),
              DataCell(Text(formatNames(shifts["afternoon"]))),
              DataCell(Text(formatNames(shifts["night"]))),
            ]);
          },
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Column(
        children: List.generate(5, (index) {
          return Container(
            margin: const EdgeInsets.symmetric(vertical: 6),
            height: 20,
            width: double.infinity,
            color: Colors.white,
          );
        }),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _DateBox({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}
