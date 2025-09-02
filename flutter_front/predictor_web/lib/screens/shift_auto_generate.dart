import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:predictor_web/widgets/appdrawer.dart';

class ShiftAutoScreen extends StatefulWidget {
  const ShiftAutoScreen({super.key});

  @override
  State<ShiftAutoScreen> createState() => _ShiftAutoScreenState();
}

class _ShiftAutoScreenState extends State<ShiftAutoScreen> {
  final _maxHoursCtrl = TextEditingController(text: '8');
  final _minStaffCtrl = TextEditingController(text: '3');

  DateTime _start = DateTime(DateTime.now().year, 8, 10);
  DateTime _end = DateTime(DateTime.now().year, 8, 16);
  bool _breakRule = true;

  /// 日付 → { shiftName: staffId }
  Map<DateTime, Map<String, String>> _assign = {};

  void _createShift() {
    // dummy data logic
    setState(() {
      _assign = {};
      DateTime cur = _start;
      int staffCounter = 1;
      while (cur.isBefore(_end.add(const Duration(days: 1)))) {
        _assign[cur] = {
          "Morning": "S${(staffCounter % 3) + 1}",
          "Afternoon": "S${((staffCounter + 1) % 3) + 1}",
          "Night": "S${((staffCounter + 2) % 3) + 1}",
        };
        cur = cur.add(const Duration(days: 1));
        staffCounter++;
      }
    });

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('ダミー: シフトを作成しました')));
  }

  void _clear() {
    setState(() {
      _assign.clear();
    });
  }

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存しました（ダミー）')));
  }
//user select START date of the shift
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _start = picked;
      });
    }
  }
//user select END date of the shift
  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        _end = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    //dateformat 
    final df = DateFormat('MM/dd');

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6F8),
      appBar: AppBar(
        title: const Text("シフト自動作成"),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      drawer: AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // User enters the condition for auto shift assignment
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('シフト自動作成'),
                    const SizedBox(height: 10),
                    Text(
                      '条件を入力してボタンを押すだけで自動作成',
                      style: TextStyle(color: Colors.black.withValues()),
                    ),
                    const SizedBox(height: 30),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const _Label('日付範囲'),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _DateBox(text: df.format(_start), onTap: _pickStartDate),
                            const SizedBox(width: 12),
                            _DateBox(text: df.format(_end), onTap: _pickEndDate),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _NumberField(label: '1日の最大勤務時間', controller: _maxHoursCtrl),
                        const SizedBox(height: 20),
                        _NumberField(label: '最低必要スタッフ数', controller: _minStaffCtrl),
                        const SizedBox(height: 30),
                        Row(
                          children: [
                            const _Label('休憩ルール'),
                            const SizedBox(width: 12),
                            Switch(
                              value: _breakRule,
                              activeColor: Colors.blue,
                              onChanged: (v) => setState(() => _breakRule = v),
                            ),
                            const SizedBox(width: 8),
                            const Text('6時間超えたら1時間休憩'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        FilledButton.icon(
                          onPressed: _createShift,
                          label: const Text('シフト作成'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // AUTO SHIFT ASSIGNMENT!!!!!
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('シフト結果'),
                    const SizedBox(height: 12),
//if 1- the assign is empty or  2- the user click clear button , there will be the prompt of NO DATA ...whereas it is shown the dummy data in datatable
                    _assign.isEmpty
                        ? const Text('結果なし', style: TextStyle(color: Colors.black54))
                        : SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: const [
                                DataColumn(label: Text("Date")),
                                DataColumn(label: Text("Morning")),
                                DataColumn(label: Text("Afternoon")),
                                DataColumn(label: Text("Night")),
                              ],
                              rows: _assign.entries.map((entry) {
                                final date = entry.key;
                                final shifts = entry.value;
                                return DataRow(cells: [
                                  DataCell(Text(df.format(date))),
                                  DataCell(Text(shifts["Morning"] ?? "-")),
                                  DataCell(Text(shifts["Afternoon"] ?? "-")),
                                  DataCell(Text(shifts["Night"] ?? "-")),
                                ]);
                              }).toList(),
                            ),
                          ),

                    const SizedBox(height: 12),
                    Row(
                      children: [
                        OutlinedButton(onPressed: _clear, child: const Text('クリア')),
                        const SizedBox(width: 8),
                        OutlinedButton(onPressed: _save, child: const Text('保存')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// --- UI widgets for reusability and run-time saving ---
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(blurRadius: 12, offset: Offset(0, 6), color: Color(0x1F000000)),
        ],
      ),
      child: child,
    );
  }
}

class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700));
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
}

class _DateBox extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _DateBox({required this.text, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF7F8FA),
          border: Border.all(color: Colors.black12),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  const _NumberField({required this.label, required this.controller});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 190,
      child: TextField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: label,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
