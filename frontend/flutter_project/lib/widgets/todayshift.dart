import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TodayShiftCard extends StatelessWidget {
  final List<Map<String, dynamic>> shifts;
  final bool isLoading;

  const TodayShiftCard({
    super.key,
    required this.shifts,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // 1. Get Today's Date String to filter data
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    
    // 2. Filter shifts for today and get unique names
    final todayShifts = shifts.where((s) => s['date'].toString().startsWith(todayStr)).toList();
    final names = todayShifts
        .where((s) => s['staff_id'] != -1)
        .map((s) => s['name'].toString())
        .toSet()
        .toList();

    const hours = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.assignment_ind, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            const Text(
              "本日のシフト割当",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (isLoading)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else if (todayShifts.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("本日の確定シフトはありません")))
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline Header (Hours)
                Row(
                  children: [
                    const SizedBox(width: 100), // Name column width
                    ...hours.map((h) => SizedBox(
                          width: 40,
                          child: Center(
                            child: Text("$h", style: TextStyle(fontSize: 11, color: theme.hintColor)),
                          ),
                        )),
                  ],
                ),
                const SizedBox(height: 8),
                // Staff Rows
                ...names.map((name) {
                  final staffShifts = todayShifts.where((s) => s['name'] == name).toList();
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        ),
                        ...hours.map((h) {
                          bool active = staffShifts.any((s) => s['hour'] == h);
                          return Container(
                            width: 38,
                            height: 24,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: active 
                                  ? theme.colorScheme.primary 
                                  : theme.colorScheme.surfaceVariant.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
      ],
    );
  }
}