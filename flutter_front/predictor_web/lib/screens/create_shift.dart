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

  @override
  Widget build(BuildContext context) {
    final selectedDate = _selectedDay ?? _focusedDay;

    return Scaffold(
      appBar: AppBar(title: const Text("シフト希望入力")),
      body: _loading
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
                    const SizedBox(height: 12),
                    Text(
                      "希望日: ${selectedDate.toLocal().toString().split(" ")[0]}",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Expanded(
                      child: ListView.builder(
                        itemCount: staffList.length,
                        itemBuilder: (context, index) {
                          final staff = staffList[index];
                          preferences[selectedDate] ??= {};
                          preferences[selectedDate]![staff] ??= {
                            for (var shift in shifts) shift: false
                          };

                          return Card(
                            margin: const EdgeInsets.all(8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(staff, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: shifts.map((shift) {
                                      final selected = preferences[selectedDate]![staff]![shift] ?? false;
                                      return Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 4),
                                        child: ChoiceChip(
                                          label: Text(shift[0].toUpperCase() + shift.substring(1)),
                                          selected: selected,
                                          onSelected: (val) {
                                            setState(() {
                                              preferences[selectedDate]![staff]![shift] = val;
                                            });
                                          },
                                        ),
                                      );
                                    }).toList(),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    )
                  ],
                ),
    );
  }
}
