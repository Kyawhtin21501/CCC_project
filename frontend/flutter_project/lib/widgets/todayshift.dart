import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayShiftCard extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;

  const TodayShiftCard({super.key, required this.shifts});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    final todayShifts = shifts.where((s) => s['date'] == todayStr).toList();
    final tomorrowShifts = shifts.where((s) => s['date'] == tomorrowStr).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Pagination Header
          TabBar(
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).hintColor,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(text: "今日 (Today)"),
              Tab(text: "明日 (Tomorrow)"),
            ],
          ),
          const SizedBox(height: 12),
          // Scrollable Area for the Table
          SizedBox(
            height: 400, // Adjust based on your content needs
            child: TabBarView(
              children: [
                _buildDayTable(context, todayShifts),
                _buildDayTable(context, tomorrowShifts),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayTable(BuildContext context, List<Map<String, dynamic>> shiftData) {
    if (shiftData.isEmpty) {
      return const Center(child: Text("シフトデータがありません"));
    }

    final staffNames = shiftData.map((s) => s['name'].toString()).toSet().toList();
    final hours = List.generate(15, (index) => index + 9); // 9:00 to 23:00

    return SingleChildScrollView(
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(45),
            columnWidths: const {0: FixedColumnWidth(100)}, // Wider for names
            border: TableBorder.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 0.5,
            ),
            children: [
              // Header Row
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                ),
                children: [
                  const TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text("氏名", style: TextStyle(fontWeight: FontWeight.bold)))),
                  ...hours.map((h) => TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(8), child: Text("$h"))))),
                ],
              ),
              // Staff Rows
              ...staffNames.map((name) {
                return TableRow(
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(name, style: const TextStyle(fontSize: 13)),
                      ),
                    ),
                    ...hours.map((h) {
                      final bool isWorking = shiftData.any((s) => s['name'] == name && s['hour'] == h);
                      final bool isShortage = shiftData.any((s) => s['hour'] == h && s['staff_id'] == -1);

                      return TableCell(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isWorking 
                                ? Theme.of(context).colorScheme.primary 
                                : (isShortage ? Colors.red.withOpacity(0.15) : Colors.transparent),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: (isShortage && !isWorking) 
                              ? const Icon(Icons.warning, color: Colors.red, size: 14) 
                              : null,
                        ),
                      );
                    }),
                  ],
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}