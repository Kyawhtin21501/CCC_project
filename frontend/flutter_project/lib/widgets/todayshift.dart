import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// A dashboard widget that displays shift assignments for Today and Tomorrow.
/// It uses a [TabBar] to switch between days and a grid-style [Table] to 
/// visualize work hours and staffing gaps.
class TodayShiftCard extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;

  const TodayShiftCard({
    super.key,
    required this.shifts,
  });

  @override
  Widget build(BuildContext context) {
    // Prepare date strings
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(
      now.add(const Duration(days: 1)),
    );

    // Filter shifts based on date
    final todayShifts = shifts.where((s) => s['date'] == todayStr).toList();
    final tomorrowShifts = shifts.where((s) => s['date'] == tomorrowStr).toList();

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

  Widget _buildDayTable(BuildContext context, List<Map<String, dynamic>> shiftData) {
    if (shiftData.isEmpty) {
      return const Center(
        child: Text(
          "シフトデータがありません",
          style: TextStyle(color: Colors.grey),
        ),
      );
    }

    // Extract unique staff names, excluding the 'not_enough' flag
    final staffNames = shiftData
        .where((s) => s['name'] != 'not_enough')
        .map((s) => s['name'].toString())
        .toSet()
        .toList();

    // Define business hours (e.g., 9:00 to 24:00)
    final hours = List.generate(16, (i) => i + 9); // 9 to 24

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
              color: Theme.of(context).dividerColor.withOpacity(0.2),
              width: 0.5,
            ),
            children: [
              // --- HEADER ROW ---
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
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
                          child: Text("$h 時", style: const TextStyle(fontSize: 12)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              // --- REGULAR STAFF ROWS ---
              ...staffNames.map((name) {
                return TableRow(
                  children: [
                    TableCell(
                      verticalAlignment: TableCellVerticalAlignment.middle,
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    ...hours.map((h) {
                      final bool isWorking = shiftData.any(
                        (s) => s['name'] == name && s['hour'] == h,
                      );
                      return TableCell(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isWorking
                                ? Theme.of(context).colorScheme.primary
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
                  ],
                );
              }),

              // --- SHORTAGE ROW ---
              TableRow(
                decoration: BoxDecoration(color: Colors.red.withOpacity(0.05)),
                children: [
                  const TableCell(
                    verticalAlignment: TableCellVerticalAlignment.middle,
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Text(
                        "不足\n(Shortage)",
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.red,
                        ),
                      ),
                    ),
                  ),
                  ...hours.map((h) {
                    final bool isShortage = shiftData.any(
                      (s) => s['name'] == 'not_enough' && s['hour'] == h,
                    );

                    return TableCell(
                      child: Container(
                        height: 38,
                        margin: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: isShortage ? Colors.red : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isShortage
                            ? const Icon(
                                Icons.warning_amber_rounded,
                                color: Colors.white,
                                size: 16,
                              )
                            : null,
                      ),
                    );
                  }),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}