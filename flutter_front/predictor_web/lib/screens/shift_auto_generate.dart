import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:predictor_web/theme_provider/them.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

/// シフト自動作成画面 (Auto Shift Assignment Screen)
class ShiftAutoScreen extends StatefulWidget {
  const ShiftAutoScreen({super.key});

  @override
  State<ShiftAutoScreen> createState() => _ShiftAutoScreenState();
}

class _ShiftAutoScreenState extends State<ShiftAutoScreen> {
  // /// --- User input controllers ---
  // final _maxHoursCtrl = TextEditingController(text: '8'); // max hours/day
  // final _minStaffCtrl = TextEditingController(text: '3'); // min staff/day

  /// --- Default date range (Aug 10–16 this year) ---
  DateTime _start = DateTime(DateTime.now().year, 8, 10);
  DateTime _end = DateTime(DateTime.now().year, 8, 16);

  // /// --- Business rules ---
  // bool _breakRule = true; // if work > 6h → 1h break

  /// --- UI states ---
  bool _loading = false;
  String? _error;

  /// --- Backend base URL ---
  /// ⚠️ Emulator-specific: Android = 10.0.2.2, iOS = localhost, device = LAN IP
  final String _baseUrl = 'http://127.0.0.1:5000';

  /// --- Shift assignment results ---
  /// Format: { Date: { "Morning": "Alice", "Afternoon": "Bob", "Night": "Chris" } }
  Map<DateTime, Map<String, String>> _assign = {};

  /// Call backend to auto-generate shifts
  Future<void> _createShift() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final String startStr = DateFormat('yyyy-MM-dd').format(_start);
    final String endStr = DateFormat('yyyy-MM-dd').format(_end);

    try {
      // === Primary API call: /shift ===
      final res = await http.post(
        Uri.parse('$_baseUrl/shift'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start_date': startStr,
          'end_date': endStr,
          // If backend uses GPS, include here:
          'latitude': 35.6762,
          'longitude': 139.6503,
        }),
      );
print("####################################post shift api in auto generated page${res.statusCode}##################################################");
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
          
        final List<dynamic> schedule = (data['shift_schedule'] ?? []) as List;
         print("#####################################$schedule######################################");
        final Map<DateTime, Map<String, String>> built = {};

        for (final row in schedule) {
          final r = row as Map<String, dynamic>;

          final String staff = (r['name'] ?? r['name_level'] ?? '-').toString();

          // Normalize shift label ("Morning", "Afternoon", "Night")
          String shift = (r['shift'] ?? '').toString();
          if (shift.isEmpty) continue;
          shift = shift[0].toUpperCase() + shift.substring(1).toLowerCase();

          final dt = DateTime.parse(r['date'].toString());
          final key = DateTime(dt.year, dt.month, dt.day);

          // Default structure for each day
          built.putIfAbsent(key, () => {
                'Morning': '-',
                'Afternoon': '-',
                'Night': '-',
              });

          if (built[key]!.containsKey(shift)) {
            built[key]![shift] = staff;
          }
        }

        setState(() {
          _assign = built;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('シフトを取得しました')),
        );
        return;
      }

      // === Fallback API call: /shift_table/dashboard (CSV-backed) ===
      final res2 = await http.get(Uri.parse('$_baseUrl/shift_table/dashboard'));
      if (res2.statusCode == 200) {
        final List<dynamic> rows = jsonDecode(res2.body) as List;
    
        final Map<DateTime, Map<String, String>> built = {};

        for (final row in rows) {
          final r = row as Map<String, dynamic>;
          final dt = DateTime.parse(r['date'].toString());
          final key = DateTime(dt.year, dt.month, dt.day);
          final String staff = (r['name_level'] ?? r['name'] ?? '-').toString();

          String shift = (r['shift'] ?? '').toString();
          shift = shift[0].toUpperCase() + shift.substring(1).toLowerCase();

          built.putIfAbsent(key, () => {
                'Morning': '-',
                'Afternoon': '-',
                'Night': '-',
              });

          if (built[key]!.containsKey(shift)) {
            built[key]![shift] = staff;
          }
        }

        setState(() {
          _assign = built;
          _loading = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ダッシュボード用データから読み込みました')),
        );
        return;
      }

      // === If both fail ===
      setState(() {
        _loading = false;
        _error = 'バックエンドから取得できませんでした（${res.statusCode}）';
      });
    } catch (e) {
      setState(() {
        _loading = false;
        _error = '通信エラー: $e';
      });
    }
  }

  /// Reset the assignment table
  void _clear() {
    setState(() {
      _assign.clear();
    });
  }

  /// Dummy save handler (replace with backend POST later)
  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存しました（ダミー）')));
  }

  /// Select shift start date
  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _start = picked);
    }
  }

  /// Select shift end date
  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _end = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MM/dd'); // date format for UI
 final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text("ダッシュボード"),
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
      drawer: AppDrawer(),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// === Input Card: Shift Conditions ===
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('シフト自動作成'),
                    const SizedBox(height: 10),
                    Text(
                      '条件を入力してボタンを押すだけで自動作成',
                      style: TextStyle(color: Colors.black.withOpacity(0.6)),
                    ),
                    const SizedBox(height: 30),

                    /// Date range
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

                    // /// Max hours / min staff
                    // _NumberField(label: '1日の最大勤務時間', controller: _maxHoursCtrl),
                    // const SizedBox(height: 20),
                    // _NumberField(label: '最低必要スタッフ数', controller: _minStaffCtrl),
                    // const SizedBox(height: 30),

                    // /// Break rule toggle
                    // Row(
                    //   children: [
                    //     const _Label('休憩ルール'),
                    //     const SizedBox(width: 12),
                    //     Switch(
                    //       value: _breakRule,
                    //       activeColor: Colors.blue,
                    //       onChanged: (v) => setState(() => _breakRule = v),
                    //     ),
                    //     const SizedBox(width: 8),
                    //     const Text('6時間超えたら1時間休憩'),
                    //   ],
                    // ),
                    // const SizedBox(height: 20),

                    /// Generate button
                    FilledButton.icon(
                      onPressed: _createShift,
                      label: const Text('シフト作成'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 28, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              /// === Output Card: Shift Results ===
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _Title('シフト結果'),
                    const SizedBox(height: 12),

                    if (_loading) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    ] else if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                    ] else if (_assign.isEmpty) ...[
                      const Text('結果なし',
                          style: TextStyle(color: Colors.black54)),
                    ] else ...[
                      SingleChildScrollView(
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
                    ],

                    const SizedBox(height: 12),

                    /// Action buttons
                    Row(
                      children: [
                        OutlinedButton(
                            onPressed: _clear, child: const Text('クリア')),
                        const SizedBox(width: 8),
                        OutlinedButton(
                            onPressed: _save, child: const Text('保存')),
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

/// === UI helper widgets ===

/// Card wrapper with shadow + padding
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
          BoxShadow(
              blurRadius: 12,
              offset: Offset(0, 6),
              color: Color(0x1F000000)), // subtle shadow
        ],
      ),
      child: child,
    );
  }
}

/// Title text (section headers)
class _Title extends StatelessWidget {
  final String text;
  const _Title(this.text);
  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700));
}

/// Bold label
class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) =>
      Text(text, style: const TextStyle(fontWeight: FontWeight.w600));
}

/// Date selector box with calendar icon
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

/// Numeric input field
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
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}
