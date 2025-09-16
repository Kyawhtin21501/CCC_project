import 'package:flutter/material.dart';
import 'package:predictor_web/theme_provider/them.dart';

import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:predictor_web/api_services/api_services.dart';

class CreatedShiftScreen extends StatefulWidget {
  const CreatedShiftScreen({super.key});

  @override
  State<CreatedShiftScreen> createState() => _CreatedShiftScreenState();
}

class _CreatedShiftScreenState extends State<CreatedShiftScreen> {
  final List<String> shifts = ['morning', 'afternoon', 'night'];
  List<String> staffList = [];
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // preferences[date][staff][shift] = bool
  Map<DateTime, Map<String, Map<String, bool>>> preferences = {};

  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  /// Fetch staff list from backend API
  Future<void> _fetchStaff() async {
    try {
      final data = await ApiService.fetchStaffList();
      setState(() {
        staffList = data;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'スタッフ一覧の取得に失敗しました: $e';
        _loading = false;
      });
    }
  }

  /// Save shift preferences for a staff member
  Future<void> _saveShiftPreferences(String staff) async {
    final selectedDate = _selectedDay ?? _focusedDay;
    final formattedDate = selectedDate.toLocal().toString().split(" ")[0];
    final shiftsForStaff = preferences[selectedDate]?[staff] ?? {};

    final data = {
      'date': formattedDate,
      'preferences': {
        staff: {
          'morning': shiftsForStaff['morning'],
          'afternoon': shiftsForStaff['afternoon'],
          'night': shiftsForStaff['night'],
        },
      },
    };

    try {
      await ApiService.saveShiftPreferences(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$staff さんの希望を保存しました")),
      );

      setState(() {
        preferences[selectedDate]![staff] = {
          for (var shift in shifts) shift: false,
        };
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("エラー: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDay ?? _focusedDay;
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      appBar:AppBar(
        title: Text("シフト希望登録"),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              final isDark = themeProvider.themeMode == ThemeMode.dark;
              themeProvider.toggleTheme(!isDark);
            },
          ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    // Calendar Card
                    Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            TableCalendar(
                              firstDay: DateTime(2020),
                              lastDay: DateTime(2030),
                              focusedDay: _focusedDay,
                              selectedDayPredicate: (day) =>
                                  isSameDay(_selectedDay, day),
                              onDaySelected: (selected, focused) {
                                setState(() {
                                  _selectedDay = selected;
                                  _focusedDay = focused;
                                });
                              },
                              calendarStyle: CalendarStyle(
                                todayDecoration: BoxDecoration(
                                  color: theme.colorScheme.primary.withOpacity(0.4),
                                  shape: BoxShape.circle,
                                ),
                                selectedDecoration: BoxDecoration(
                                  color: theme.colorScheme.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "希望日: ${selectedDate.toLocal().toString().split(" ")[0]}",
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Staff preference cards
                    ...staffList.map((staff) {
                      preferences[selectedDate] ??= {};
                      preferences[selectedDate]![staff] ??= {
                        for (var shift in shifts) shift: false,
                      };

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                staff,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Shifts with checkboxes
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: shifts.map((shift) {
                                    return Padding(
                                      padding:
                                          const EdgeInsets.only(right: 16),
                                      child: Row(
                                        children: [
                                          Text(shift,
                                              style: theme.textTheme.bodyMedium),
                                          Checkbox(
                                            value: preferences[selectedDate]![staff]![shift]!,
                                            onChanged: (val) {
                                              setState(() {
                                                preferences[selectedDate]![staff]![shift] = val!;
                                              });
                                            },
                                          ),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Save button
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () =>
                                      _saveShiftPreferences(staff),
                                  style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                                  child: const Text("保存"),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                  ],
                ),
    );
  }
}
