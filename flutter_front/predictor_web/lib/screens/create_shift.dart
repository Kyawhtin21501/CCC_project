import 'package:flutter/material.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
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

      // Success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("$staff さんの希望を保存しました")),
      );

      // Reset checkboxes after saving
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

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text("シフト希望登録"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
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
                          borderRadius: BorderRadius.circular(16)),
                      elevation: 4,
                      color: Colors.white,
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
                            ),
                            const SizedBox(height: 16),
                            Text(
                              "希望日: ${selectedDate.toLocal().toString().split(" ")[0]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
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
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        color: Colors.blue.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Staff name
                              Text(
                                staff,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                                          Text(shift),
                                          Checkbox(
                                            value: preferences[selectedDate]![
                                                staff]![shift]!,
                                            onChanged: (val) {
                                              setState(() {
                                                preferences[selectedDate]![
                                                    staff]![shift] = val!;
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
                                    backgroundColor: Colors.blue.shade600,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 10),
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
