import 'package:flutter/material.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/theme_provider/them.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';


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

  /// preferences[date][staff][shift] = bool
  Map<String, Map<String, Map<String, bool>>> preferences = {};

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
        staffList = data.map<String>((s) => s['name'].toString()).toList();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'スタッフ一覧の取得に失敗しました: $e';
        _loading = false;
      });
    }
  }

  /// Get normalized date string (YYYY-MM-DD)
  String _fmt(DateTime date) => date.toIso8601String().split("T")[0];

  /// Ensure preferences map exists for this date/staff
  Map<String, bool> _getOrInitStaffPrefs(String dateKey, String staff) {
    preferences[dateKey] ??= {};
    preferences[dateKey]![staff] ??= {
      for (final shift in shifts) shift: false,
    };
    return preferences[dateKey]![staff]!;
  }

  /// Save preferences
  Future<void> _saveShiftPreferences(String staff) async {
    final selected = _selectedDay ?? _focusedDay;
    final dateKey = _fmt(selected);

    final pref = _getOrInitStaffPrefs(dateKey, staff);

    final data = {
      'date': dateKey,
      'preferences': {
        staff: {
          'morning': pref['morning'],
          'afternoon': pref['afternoon'],
          'night': pref['night'],
        },
      },
    };

    try {
      await ApiService.saveShiftPreferences(data);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$staff さんの希望を保存しました")),
      );

      // Reset shifts after saving
      setState(() {
        preferences[dateKey]![staff] = {
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
    final selected = _selectedDay ?? _focusedDay;
    final dateKey = _fmt(selected);
    final theme = Theme.of(context);

    return Scaffold(
       drawer: const AppDrawer(currentScreen: DrawerScreen.shiftRequest),
      body: //wrap with Builder
      Builder(
        builder: (context) {
          return Column(
            children: [
              /// Custom Menu Bar
              CustomMenuBar(
                title: 'シフト希望登録',
                onMenuPressed: () => Scaffold.of(context).openDrawer(),
                )
                  
              
              ,
          
              Expanded(
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : _error != null
                        ? Center(child: Text(_error!))
                        : ListView(
                            padding: const EdgeInsets.all(24),
                            children: [
                              /// Calendar
                              Card(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16)),
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
                                            color: theme.colorScheme.primary
                                                .withOpacity(0.4),
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
                                        "希望日: $dateKey",
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 24),
          
                              /// Staff cards
                              ...staffList.map((staff) {
                                final pref = _getOrInitStaffPrefs(dateKey, staff);
          
                                return Card(
                                  margin: const EdgeInsets.symmetric(vertical: 8),
                                  elevation: 1,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          staff,
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
          
                                        Row(
                                          children: shifts.map((shift) {
                                            return Padding(
                                              padding: const EdgeInsets.only(
                                                  right: 16.0),
                                              child: Row(
                                                children: [
                                                  Text(shift),
                                                  Checkbox(
                                                    value: pref[shift] ?? false,
                                                    onChanged: (boolean) {
                                                      setState(() {
                                                        pref[shift] =
                                                            boolean ?? false;
                                                      });
                                                    },
                                                  ),
                                                ],
                                              ),
                                            );
                                          }).toList(),
                                        ),
          
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _saveShiftPreferences(staff),
                                            style: ElevatedButton.styleFrom(
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
              ),
            ],
          );
        }
      ),
    );
  }
}
