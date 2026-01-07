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
    // 1. Prepare date strings for filtering the shifts list
    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final tomorrowStr = DateFormat('yyyy-MM-dd').format(now.add(const Duration(days: 1)));

    // 2. Filter data for each tab
    final todayShifts = shifts.where((s) => s['date'] == todayStr).toList();
    final tomorrowShifts = shifts.where((s) => s['date'] == tomorrowStr).toList();

    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Navigation: Today vs Tomorrow
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
          
          // Tab Content Area
          SizedBox(
            height: 400, // Fixed height to allow internal scrolling of the table
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

  /// Generates a horizontal-scrolling table showing staff on the Y-axis 
  /// and hours (10:00 - 24:00) on the X-axis.
  Widget _buildDayTable(BuildContext context, List<Map<String, dynamic>> shiftData) {
    if (shiftData.isEmpty) {
      return const Center(child: Text("シフトデータがありません"));
    }

    // Extract unique staff names and define the operating hours
    final staffNames = shiftData.map((s) => s['name'].toString()).toSet().toList();
    final hours = List.generate(15, (index) => index + 10); // Represents 10:00 AM to 12:00 PM

    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Table(
            // column 0 (names) is wider; other columns (hours) are narrow squares
            defaultColumnWidth: const FixedColumnWidth(45),
            columnWidths: const {0: FixedColumnWidth(100)}, 
            border: TableBorder.all(
              color: Theme.of(context).dividerColor.withOpacity(0.3),
              width: 0.5,
            ),
            children: [
              // --- HEADER ROW (Hours) ---
              TableRow(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                ),
                children: [
                  const TableCell(child: Padding(padding: EdgeInsets.all(8), child: Text("氏名", style: TextStyle(fontWeight: FontWeight.bold)))),
                  ...hours.map((h) => TableCell(child: Center(child: Padding(padding: const EdgeInsets.all(8), child: Text("$h"))))),
                ],
              ),
              
              // --- DATA ROWS (Staff Assignments) ---
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
                      // Logic to determine if this cell should be highlighted
                      final bool isWorking = shiftData.any((s) => s['name'] == name && s['hour'] == h);
                      
                      // -1 is a special ID from the backend indicating a "Required but unfilled" slot
                      final bool isShortage = shiftData.any((s) => s['hour'] == h && s['staff_id'] == -1);

                      return TableCell(
                        child: Container(
                          height: 38,
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: isWorking 
                                ? Theme.of(context).colorScheme.primary // Blue block for work
                                : (isShortage ? Colors.red.withOpacity(0.15) : Colors.transparent),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: (isShortage && !isWorking) 
                              ? const Icon(Icons.warning, color: Colors.red, size: 14) // Warning icon for gaps
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