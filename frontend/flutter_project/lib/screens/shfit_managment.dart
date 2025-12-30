import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';

enum ShiftMode { manual, auto }

class Staff {
  final String id, name;
  final int? level;

  Staff({required this.id, required this.name, this.level});

  factory Staff.fromMap(Map<String, dynamic> m) => Staff(
        id: (m['staff_id'] ?? m['id'] ?? '0').toString(),
        name: m['name'] ?? '不明',
        level: m['level'],
      );
}

class ShiftManagementScreen extends StatefulWidget {
  const ShiftManagementScreen({super.key});

  @override
  State<ShiftManagementScreen> createState() => _ShiftManagementScreenState();
}

class _ShiftManagementScreenState extends State<ShiftManagementScreen> {
  ShiftMode _selectedMode = ShiftMode.manual;
  List<Staff> staffList = [];
  bool _loading = false;
  bool _isSaving = false;
  bool _isGenerating = false;

  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  // Stores: { "yyyy-MM-dd": { "staffId": { "startTime": "HH:mm", "endTime": "HH:mm" } } }
  Map<String, Map<String, Map<String, String>>> preferences = {};
  List<Map<String, dynamic>> _predictedShifts = [];

  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  final List<String> _timeOptions = List.generate(48, (index) {
    final hour = (index ~/ 2).toString().padLeft(2, '0');
    final minute = (index % 2 == 0) ? '00' : '30';
    return "$hour:$minute";
  });

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // --- API LOGIC ---

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final List<dynamic> data = await ApiService.fetchStaffList();
      if (mounted) {
        setState(() {
          staffList = data.map<Staff>((s) => Staff.fromMap(s)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnackBar("スタッフデータの取得に失敗しました", isError: true);
      }
    }
  }

  Future<void> _savePreference(Staff staff) async {
    setState(() => _isSaving = true);
    final dateKey = _dateKey(_selectedDay ?? _focusedDay);
    final p = _getPrefs(staff.id);
    try {
      await ApiService.saveShiftPreferences({
        'date': dateKey,
        'staff_id': int.parse(staff.id),
        'start_time': p['startTime'],
        'end_time': p['endTime'],
      });
      if (mounted) _showSnackBar("${staff.name}さんの希望を保存しました");
    } catch (e) {
      if (mounted) _showSnackBar("保存に失敗しました", isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generateAutoShifts() async {
    setState(() { _isGenerating = true; _predictedShifts = []; });
    try {
      final data = await ApiService.fetchAutoShiftTable(_startDate, _endDate);
      setState(() => _predictedShifts = List<Map<String, dynamic>>.from(data));
      if (mounted) _showSnackBar("AIシフトを生成しました");
    } catch (e) {
      if (mounted) _showSnackBar("AI生成に失敗しました: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  // --- HELPERS ---

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Map<String, String> _getPrefs(String staffId) {
    final dKey = _dateKey(_selectedDay ?? _focusedDay);
    preferences[dKey] ??= {};
    return preferences[dKey]![staffId] ??= {'startTime': '09:00', 'endTime': '18:00'};
  }

  Map<String, List<Map<String, dynamic>>> _groupShiftsByDate() {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (var s in _predictedShifts) {
      if (s['date'] == null) continue;
      final d = s['date'].toString().split(' ')[0];
      map.putIfAbsent(d, () => []).add(s);
    }
    return map;
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 700;

    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.shiftManagement),
      body: Stack(
        children: [
          Positioned.fill(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(isMobile ? 12 : 24, 110, isMobile ? 12 : 24, 40),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMode == ShiftMode.manual ? "スタッフの出勤希望入力" : "AIシフト自動生成・分析",
                              style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
                            ),
                            const SizedBox(height: 24),
                            _buildModeToggle(theme),
                            const SizedBox(height: 32),
                            _selectedMode == ShiftMode.manual
                                ? _buildManualView(theme, isMobile)
                                : _buildAutoView(theme),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
          Positioned(
            top: 28, left: 16, right: 16,
            child: Builder(
              builder: (scaffoldContext) => CustomMenuBar(
                title: 'シフト作成・管理',
                onMenuPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
              ),
            ),
          ),
          if (_isSaving) Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ShiftMode>(
        segments: const [
          ButtonSegment(value: ShiftMode.manual, label: Text('希望入力'), icon: Icon(Icons.edit_calendar)),
          ButtonSegment(value: ShiftMode.auto, label: Text('AI予測'), icon: Icon(Icons.auto_awesome)),
        ],
        selected: {_selectedMode},
        onSelectionChanged: (set) => setState(() => _selectedMode = set.first),
      ),
    );
  }

  // --- MANUAL VIEW ---

  Widget _buildManualView(ThemeData theme, bool isMobile) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarCard(theme),
        const SizedBox(height: 32),
        Row(
          children: [
            const Icon(Icons.people_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              "${DateFormat('MM月dd日').format(_selectedDay ?? _focusedDay)} の希望状況",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (staffList.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(40), child: Text("スタッフが登録されていません")))
        else ...staffList.map((staff) => _buildStaffCard(staff, theme, isMobile)),
      ],
    );
  }

  Widget _buildCalendarCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: TableCalendar(
          focusedDay: _focusedDay,
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
          onDaySelected: (selected, focused) => setState(() {
            _selectedDay = selected;
            _focusedDay = focused;
          }),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle),
            todayDecoration: BoxDecoration(color: theme.colorScheme.primary.withOpacity(0.3), shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }

  Widget _buildStaffCard(Staff staff, ThemeData theme, bool isMobile) {
    final prefs = _getPrefs(staff.id);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: isMobile 
        ? Column(
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(child: Text(staff.name[0])),
                title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _timeDropdown(prefs['startTime']!, (v) => setState(() => prefs['startTime'] = v), theme),
                  const Text("〜", style: TextStyle(fontWeight: FontWeight.bold)),
                  _timeDropdown(prefs['endTime']!, (v) => setState(() => prefs['endTime'] = v), theme),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(width: double.infinity, child: FilledButton.icon(icon: const Icon(Icons.save, size: 18), onPressed: () => _savePreference(staff), label: const Text("保存")))
            ],
          )
        : Row(
            children: [
              CircleAvatar(child: Text(staff.name[0])),
              const SizedBox(width: 16),
              Expanded(child: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold))),
              _timeDropdown(prefs['startTime']!, (v) => setState(() => prefs['startTime'] = v), theme),
              const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("〜", style: TextStyle(fontWeight: FontWeight.bold))),
              _timeDropdown(prefs['endTime']!, (v) => setState(() => prefs['endTime'] = v), theme),
              const SizedBox(width: 24),
              FilledButton.icon(icon: const Icon(Icons.save, size: 18), onPressed: () => _savePreference(staff), label: const Text("保存")),
            ],
          ),
      ),
    );
  }

  Widget _timeDropdown(String currentValue, Function(String) onChanged, ThemeData theme) {
    return DropdownButton<String>(
      value: currentValue,
      dropdownColor: theme.colorScheme.surface,
      underline: const SizedBox(),
      onChanged: (v) => v != null ? onChanged(v) : null,
      items: _timeOptions.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)))).toList(),
    );
  }

  // --- AUTO VIEW ---

  Widget _buildAutoView(ThemeData theme) {
    final grouped = _groupShiftsByDate();
    return Column(
      children: [
        _buildActionBanner(theme),
        const SizedBox(height: 24),
        if (_isGenerating) const LinearProgressIndicator(),
        if (!_isGenerating && grouped.isEmpty) 
          const Padding(padding: EdgeInsets.all(40), child: Text("期間を選択してAI生成ボタンを押してください")),
        ...grouped.entries.map((e) => _buildTimelineCard(e.key, e.value, theme)),
      ],
    );
  }

  Widget _buildActionBanner(ThemeData theme) {
    final df = DateFormat('yyyy/MM/dd');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: theme.colorScheme.primaryContainer.withOpacity(0.4), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          const Icon(Icons.date_range),
          const SizedBox(width: 12),
          Expanded(child: Text("${df.format(_startDate)} 〜 ${df.format(_endDate)}", style: const TextStyle(fontWeight: FontWeight.bold))),
          TextButton(onPressed: _selectDateRange, child: const Text("期間変更")),
          const SizedBox(width: 8),
          FilledButton.icon(onPressed: _isGenerating ? null : _generateAutoShifts, icon: const Icon(Icons.auto_awesome), label: const Text("AI生成")),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(String date, List<Map<String, dynamic>> shifts, ThemeData theme) {
    final actualStaff = shifts.where((s) => s['staff_id'] != -1).toList();
    final names = actualStaff.map((s) => s['name'].toString()).toSet().toList();
    const hours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];
    const double hourWidth = 45.0;
    const double labelWidth = 110.0;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Column(
        children: [
          ListTile(
            title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            tileColor: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: labelWidth + (hours.length * hourWidth),
                child: Column(
                  children: [
                    Row(
                      children: [
                        const SizedBox(width: labelWidth),
                        ...hours.map((h) => SizedBox(width: hourWidth, child: Center(child: Text("$h", style: TextStyle(fontSize: 11, color: theme.hintColor))))),
                      ],
                    ),
                    const Divider(),
                    ...names.map((name) {
                      final staffShifts = actualStaff.where((s) => s['name'] == name).toList();
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            SizedBox(width: labelWidth, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
                            ...hours.map((h) {
                              bool active = staffShifts.any((s) => s['hour'] == h);
                              return Container(
                                width: hourWidth - 4, height: 20,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: active ? theme.colorScheme.primary : theme.colorScheme.surfaceContainerHighest.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 32),
                    _buildShortageRow(hours, shifts, theme, labelWidth, hourWidth),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortageRow(List<int> hours, List<Map<String, dynamic>> shifts, ThemeData theme, double labelW, double hourW) {
    return Row(
      children: [
        SizedBox(width: labelW, child: const Text("必要人数不足", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.redAccent))),
        ...hours.map((h) {
          final bool isShort = shifts.any((s) => s['hour'] == h && s['staff_id'] == -1);
          return SizedBox(
            width: hourW,
            child: Center(
              child: isShort ? const Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 18) : const Text("-", style: TextStyle(color: Colors.grey)),
            ),
          );
        }),
      ],
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context, 
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 90)), 
      lastDate: DateTime(2030, 12, 31)
    );
    if (picked != null) setState(() { _startDate = picked.start; _endDate = picked.end; });
  }
}