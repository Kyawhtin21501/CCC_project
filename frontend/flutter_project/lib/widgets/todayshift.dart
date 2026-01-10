import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A dashboard widget that displays shift assignments for Today and Tomorrow.
/// It uses a TabBar to switch between days and a grid-style Table to visualize
/// work hours and staffing gaps.
class TodayShiftCard extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;

  const TodayShiftCard({super.key, required this.shifts});

  @override
  Widget build(BuildContext context) {
    // Prepare date strings
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr =
        DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    // Filter shifts
    final todayShifts = shifts.where((s) => s['date'] == todayStr).toList();
    final tomorrowShifts =
        shifts.where((s) => s['date'] == tomorrowStr).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
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

          // Content
          SizedBox(
            height: 400,
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

  /// Builds a shift table for a single day
  Widget _buildDayTable(
      BuildContext context, List<Map<String, dynamic>> shiftData) {
    if (shiftData.isEmpty) {
      return const Center(child: Text("シフトデータがありません"));
    }

    // Unique staff list
    final staffNames =
        shiftData.map((s) => s['name'].toString()).toSet().toList();

    // 10:00 - 24:00
    final hours = List.generate(15, (i) => i + 10);

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Table(
            defaultColumnWidth: const FixedColumnWidth(45),
            columnWidths: const {0: FixedColumnWidth(100)},
            border: TableBorder.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 0.5,
            ),
            children: [
              // HEADER ROW
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withOpacity(0.5),
                ),
                children: [
                  const TableCell(
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "氏名",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  ...hours.map(
                    (h) => TableCell(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: Text("$h"),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // STAFF ROWS
              ...staffNames.map((name) {
                return TableRow(
                  children: [
                    // Staff name column
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ),
                    ),

                    // Hour cells
                    ...hours.map((h) {
                      // Staff working?
                      final bool isWorking = shiftData.any(
                        (s) => s['name'] == name && s['hour'] == h,
                      );

                      // Hour-level shortage (staff_id == -1)
                      final bool hourHasShortage = shiftData.any(
                        (s) => s['hour'] == h && s['staff_id'] == -1,
                      );

                      return TableCell(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isWorking
                                ? Theme.of(context).colorScheme.primary
                                : (hourHasShortage
                                    ? Colors.red.withOpacity(0.15)
                                    : Colors.transparent),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: (!isWorking && hourHasShortage)
                              ? const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                  size: 14,
                                )
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
