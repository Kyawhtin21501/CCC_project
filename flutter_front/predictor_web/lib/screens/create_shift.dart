import 'package:flutter/material.dart';
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

  Map<DateTime, Map<String, Map<String, bool>>> preferences = {};
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("$staff さんの希望を保存しました ✅")));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("エラー: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDay ?? _focusedDay;

    return Scaffold(
      appBar: AppBar(title: const Text("シフト希望入力")),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(child: Text(_error!))
              : Column(
                children: [
                  TableCalendar(
                    firstDay: DateTime(2020),
                    lastDay: DateTime(2030),
                    focusedDay: _focusedDay,
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selected, focused) {
                      setState(() {
                        _selectedDay = selected;
                        _focusedDay = focused;
                      });
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "希望日: ${selectedDate.toLocal().toString().split(" ")[0]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ListView.builder(
                      itemCount: staffList.length,
                      itemBuilder: (context, index) {
                        final staff = staffList[index];

                        preferences[selectedDate] ??= {};
                        preferences[selectedDate]![staff] ??= {
                          for (var shift in shifts) shift: false,
                        };

                        return Card(
                          color: const Color.fromARGB(255, 150, 202, 245),
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(
                              staff,
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children:
                                    shifts.map((shift) {
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8.0,
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(shift),
                                            Checkbox(
                                              value:
                                                  preferences[selectedDate]![staff]![shift]!,
                                              onChanged: (val) {
                                                setState(() {
                                                  preferences[selectedDate]![staff]![shift] =
                                                      val!;
                                                });
                                              },
                                            ),
                                          ],
                                        ),
                                      );
                                    }).toList(),
                              ),
                            ),

                            trailing: ElevatedButton(
                              onPressed: () => _saveShiftPreferences(staff),
                              child: const Text("保存"),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
    );
  }
}
