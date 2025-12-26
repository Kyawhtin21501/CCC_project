import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:table_calendar/table_calendar.dart';

enum ShiftMode { manual, auto }

class Staff {
  final String id, name;
  Staff({required this.id, required this.name});
  factory Staff.fromMap(Map<String, dynamic> m) =>
      Staff(id: m['id'].toString(), name: m['name'] ?? '');
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

  DateTime _manualFocusedDay = DateTime.now();
  DateTime? _manualSelectedDay = DateTime.now();
  
  Map<String, Map<String, Map<String, String>>> preferences = {};
  List<Map<String, dynamic>> _predictedShifts = [];
  
  final DateTime _startDate = DateTime.now();
  final DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  // --- API LOGIC ---

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    try {
      final data = await ApiService.fetchStaffList();
      if (mounted) {
        setState(() {
          staffList = data.map<Staff>((s) => Staff.fromMap(s)).toList();
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        _showSnackBar("スタッフリストの取得に失敗しました", isError: true);
      }
    }
  }

  Future<void> _savePreference(Staff staff) async {
    setState(() => _isSaving = true);
    try {
      final p = _getPrefs(staff.id);
      await ApiService.saveShiftPreferences({
        'date': _dateKey(_manualSelectedDay ?? _manualFocusedDay),
        'staff_id': int.parse(staff.id),
        'start_time': p['startTime'],
        'end_time': p['endTime'],
      });
      if (mounted) _showSnackBar("${staff.name}さんの希望を保存しました");
    } catch (e) {
      if (mounted) _showSnackBar("保存に失敗しました", isError: true);
    }
    setState(() => _isSaving = false);
  }

  Future<void> _generateAutoShifts() async {
    setState(() => _isGenerating = true);
    try {
      final data = await ApiService.fetchAutoShiftTable(_startDate, _endDate);
      setState(() => _predictedShifts = data);
      if (mounted) _showSnackBar("AIシフトを生成しました");
    } catch (e) {
      if (mounted) _showSnackBar("生成に失敗しました", isError: true);
    }
    setState(() => _isGenerating = false);
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red.shade800 : Colors.green.shade800,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.shiftManagement),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 96, left: 20, right: 20, bottom: 40),
              child: _loading
                  ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                  : Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000), // Adjusted for vertical layout
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDashboardHeader(theme),
                            const SizedBox(height: 24),
                            _buildModeToggle(theme.colorScheme),
                            const SizedBox(height: 32),
                            _selectedMode == ShiftMode.manual
                                ? _buildManualView(theme)
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
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(ThemeData theme) {
    return Text(
      _selectedMode == ShiftMode.manual ? "スタッフの出勤希望入力" : "AIシフト自動生成・分析",
      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900),
    );
  }

  Widget _buildModeToggle(ColorScheme colorScheme) {
    return SegmentedButton<ShiftMode>(
      segments: const [
        ButtonSegment(value: ShiftMode.manual, label: Text('希望入力'), icon: Icon(Icons.edit_calendar)),
        ButtonSegment(value: ShiftMode.auto, label: Text('AI予測'), icon: Icon(Icons.auto_awesome)),
      ],
      selected: {_selectedMode},
      onSelectionChanged: (set) => setState(() => _selectedMode = set.first),
    );
  }

  // --- MANUAL VIEW (Staff under Calendar) ---

  Widget _buildManualView(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Calendar at the top
        _buildCalendarCard(theme),
        const SizedBox(height: 32),
        
        // 2. Staff List Header
        Row(
          children: [
            const Icon(Icons.people_outline, size: 20),
            const SizedBox(width: 8),
            Text(
              "${DateFormat('MM月dd日').format(_manualSelectedDay ?? _manualFocusedDay)} のスタッフ希望",
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // 3. Staff Cards
        ...staffList.map((staff) => _buildStaffCard(staff, theme)),
      ],
    );
  }

  Widget _buildCalendarCard(ThemeData theme) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: TableCalendar(
          calendarFormat: CalendarFormat.month, // Keep it monthly
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _manualFocusedDay,
          selectedDayPredicate: (day) => isSameDay(_manualSelectedDay, day),
          onDaySelected: (selected, focused) => setState(() {
            _manualSelectedDay = selected;
            _manualFocusedDay = focused;
          }),
          headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
        ),
      ),
    );
  }

  Widget _buildStaffCard(Staff staff, ThemeData theme) {
    final prefs = _getPrefs(staff.id);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Text(staff.name[0], style: TextStyle(color: theme.colorScheme.onPrimaryContainer)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    _timeChip(prefs['startTime']!, () => _pickTime(staff.id, 'startTime'), theme),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("〜", style: TextStyle(color: Colors.grey)),
                    ),
                    _timeChip(prefs['endTime']!, () => _pickTime(staff.id, 'endTime'), theme),
                  ],
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            icon: _isSaving ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.save, size: 16),
            onPressed: _isSaving ? null : () => _savePreference(staff),
            label: const Text("保存"),
            style: ElevatedButton.styleFrom(
              backgroundColor: theme.colorScheme.primary,
              foregroundColor: theme.colorScheme.onPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // --- AUTO VIEW ---

  Widget _buildAutoView(ThemeData theme) {
    return Column(
      children: [
        _buildActionBanner(theme),
        const SizedBox(height: 24),
        if (_isGenerating) const LinearProgressIndicator(),
        ..._groupShiftsByDate().entries.map((e) => _buildTimelineCard(e.key, e.value, theme)),
      ],
    );
  }

  Widget _buildTimelineCard(String date, List<Map<String, dynamic>> shifts, ThemeData theme) {
    final actualStaff = shifts.where((s) => s['staff_id'] != -1).toList();
    final names = actualStaff.map((s) => s['name'].toString()).toSet().toList();
    const hours = [10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22];

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: theme.colorScheme.outlineVariant)),
      child: Column(
        children: [
          ListTile(
            title: Text(date, style: const TextStyle(fontWeight: FontWeight.bold)),
            tileColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const SizedBox(width: 120),
                      ...hours.map((h) => SizedBox(width: 50, child: Center(child: Text("$h", style: TextStyle(fontSize: 11, color: theme.hintColor))))),
                    ],
                  ),
                  const Divider(height: 30),
                  ...names.map((name) {
                    final staffShifts = actualStaff.where((s) => s['name'] == name).toList();
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 120, child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                          ...hours.map((h) {
                            bool active = staffShifts.any((s) => s['hour'] == h);
                            return Container(
                              width: 50, height: 28,
                              margin: const EdgeInsets.symmetric(horizontal: 1),
                              decoration: BoxDecoration(
                                color: active ? theme.colorScheme.primary : theme.colorScheme.surfaceVariant.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 40),
                  _buildShortageRow(hours, shifts, theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShortageRow(List<int> hours, List<Map<String, dynamic>> shifts, ThemeData theme) {
    return Row(
      children: [
        const SizedBox(width: 120, child: Text("配置スタッフ数", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13))),
        ...hours.map((h) {
          final count = shifts.where((s) => s['hour'] == h && s['staff_id'] != -1).length;
          final bool isShort = count < 2 || shifts.any((s) => s['hour'] == h && s['staff_id'] == -1);
          return SizedBox(
            width: 50,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isShort ? theme.colorScheme.error.withOpacity(0.1) : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  "$count",
                  style: TextStyle(
                    color: isShort ? theme.colorScheme.error : theme.colorScheme.onSurface,
                    fontWeight: isShort ? FontWeight.w900 : FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildActionBanner(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: theme.colorScheme.primary, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.white),
          const SizedBox(width: 12),
          const Text("不足箇所は赤字で表示されます", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const Spacer(),
          ElevatedButton(
            onPressed: _isGenerating ? null : _generateAutoShifts, 
            child: _isGenerating 
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text("再生成"),
          ),
        ],
      ),
    );
  }

  // --- HELPERS ---

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Map<String, String> _getPrefs(String id) {
    final k = _dateKey(_manualSelectedDay ?? _manualFocusedDay);
    preferences[k] ??= {};
    return preferences[k]![id] ??= {'startTime': '09:00', 'endTime': '18:00'};
  }

  Future<void> _pickTime(String id, String key) async {
    final t = await showTimePicker(context: context, initialTime: const TimeOfDay(hour: 9, minute: 0));
    if (t != null) {
      setState(() => _getPrefs(id)[key] = "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}");
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupShiftsByDate() {
    final map = <String, List<Map<String, dynamic>>>{};
    for (var s in _predictedShifts) {
      final d = s['date'].toString().split(' ')[0];
      map.putIfAbsent(d, () => []).add(s);
    }
    return map;
  }

  Widget _timeChip(String label, VoidCallback onTap, ThemeData theme) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: theme.colorScheme.outlineVariant),
        ),
        child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      ),
    );
  }
}