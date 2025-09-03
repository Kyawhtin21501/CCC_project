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
  DateTime _start = DateTime(DateTime.now().year, 8, 10);
  DateTime _end = DateTime(DateTime.now().year, 8, 16);

  bool _loading = false;
  String? _error;

  final String _baseUrl = 'http://127.0.0.1:5000';

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
      final res = await http.post(
        Uri.parse('$_baseUrl/shift'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'start_date': startStr,
          'end_date': endStr,
          'latitude': 35.6762,
          'longitude': 139.6503,
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        final List<dynamic> schedule = (data['shift_schedule'] ?? []) as List;

        final Map<DateTime, Map<String, String>> built = {};
        for (final row in schedule) {
          final r = row as Map<String, dynamic>;
          final String staff = (r['name'] ?? r['name_level'] ?? '-').toString();

          String shift = (r['shift'] ?? '').toString();
          if (shift.isEmpty) continue;
          shift = shift[0].toUpperCase() + shift.substring(1).toLowerCase();

          final dt = DateTime.parse(r['date'].toString());
          final key = DateTime(dt.year, dt.month, dt.day);

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

      // fallback
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

  void _clear() => setState(() => _assign.clear());

  void _save() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('保存しました（ダミー）')));
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _start,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _end,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) setState(() => _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final df = DateFormat('MM/dd');
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface, // ✅ use theme background
      appBar: AppBar(
        title: const Text("シフト自動作成"),
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
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// === Input Card: Shift Conditions ===
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("シフト自動作成",
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(
                        '条件を入力してボタンを押すだけで自動作成',
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(color: theme.hintColor),
                      ),
                      const SizedBox(height: 30),

                      Text("日付範囲",
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _DateBox(text: df.format(_start), onTap: _pickStartDate),
                          const SizedBox(width: 12),
                          _DateBox(text: df.format(_end), onTap: _pickEndDate),
                        ],
                      ),
                      const SizedBox(height: 20),

                      FilledButton.icon(
                        onPressed: _createShift,
                        label: const Text('シフト作成'),
                        icon: const Icon(Icons.auto_awesome),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 28, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              /// === Output Card: Shift Results ===
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("シフト結果",
                          style: theme.textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),

                      if (_loading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Center(child: CircularProgressIndicator()),
                        )
                      else if (_error != null)
                        Text(_error!,
                            style:
                                theme.textTheme.bodyMedium?.copyWith(color: Colors.red))
                      else if (_assign.isEmpty)
                        Text("結果なし",
                            style: theme.textTheme.bodyMedium
                                ?.copyWith(color: theme.hintColor))
                      else
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

                      const SizedBox(height: 12),

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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Date selector box with calendar icon (keeps theme colors)
class _DateBox extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _DateBox({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 6),
            const Icon(Icons.calendar_today, size: 16),
          ],
        ),
      ),
    );
  }
}
