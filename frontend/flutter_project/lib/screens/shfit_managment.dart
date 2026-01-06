import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:omakase_shift/services/api_services.dart';
import 'package:omakase_shift/widgets/appdrawer.dart';
import 'package:omakase_shift/widgets/custom_menubar.dart';

/// Defines the view modes for the screen.
/// [manual] is for staff to enter their availability.
/// [auto] is for admins to generate and view AI-predicted shifts.
enum ShiftMode { manual, auto }

/// Data model representing a staff member.
/// Supports flexible mapping from various API response formats (staff_id vs id).
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
  // UI State management
  ShiftMode _selectedMode = ShiftMode.manual;
  List<Staff> staffList = [];
  bool _loading = false;      // Main data loading
  bool _isSaving = false;     // Blocking overlay for API writes
  bool _isGenerating = false; // Progress indicator for AI generation

  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay = DateTime.now();

  /// Local state for shift preferences.
  /// Structure: { "YYYY-MM-DD": { "staffId": { "startTime": "HH:mm", "endTime": "HH:mm" } } }
  Map<String, Map<String, Map<String, String>>> preferences = {};
  
  /// Stores raw data from the AI generation API
  List<Map<String, dynamic>> _predictedShifts = [];

  // Range for AI Generation
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  /// Generates a list of strings from 00:00 to 23:30 in 30-minute increments.
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

  /// Initial load: Fetches the list of active staff members.
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

  /// Sends a specific staff member's preference for the selected date to the backend.
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

  /// Triggers the AI logic to calculate the optimal shift table based on 
  /// predicted sales, required labor, and staff preferences.
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

  /// Safe accessor for the preference map. 
  /// Initializes nested maps if they don't exist to prevent Null Pointer Exceptions.
  Map<String, String> _getPrefs(String staffId) {
    final dKey = _dateKey(_selectedDay ?? _focusedDay);
    preferences[dKey] ??= {};
    return preferences[dKey]![staffId] ??= {'startTime': '09:00', 'endTime': '18:00'};
  }

  /// Reorganizes the flat list of shift objects into a Map grouped by Date.
  /// Essential for rendering the timeline view cards.
  Map<String, List<Map<String, dynamic>>> _groupShiftsByDate() {
    final Map<String, List<Map<String, dynamic>>> map = {};
    for (var s in _predictedShifts) {
      if (s['date'] == null) continue;
      final d = s['date'].toString().split(' ')[0]; // Extract YYYY-MM-DD
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
          
          /// Fixed Menu Bar (Header)
          Positioned(
            top: 28, left: 16, right: 16,
            child: Builder(
              builder: (scaffoldContext) => CustomMenuBar(
                title: 'シフト作成・管理',
                onMenuPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
              ),
            ),
          ),

          /// Global Loading Overlay for Save operations
          if (_isSaving) Container(color: Colors.black12, child: const Center(child: CircularProgressIndicator())),
        ],
      ),
    );
  }

  /// Toggle button to switch between Manual Preference entry and AI Generation view.
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

  // --- MANUAL VIEW WIDGETS ---

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

  /// Wraps the [TableCalendar]. This serves as the primary date selector for manual entry.
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

  /// Individual card for each staff member to select start/end times.
  /// Adjusts layout (Column vs Row) based on screen width.
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

  /// Custom styling for the time selector dropdown.
  Widget _timeDropdown(String currentValue, Function(String) onChanged, ThemeData theme) {
    return DropdownButton<String>(
      value: currentValue,
      dropdownColor: theme.colorScheme.surface,
      underline: const SizedBox(),
      onChanged: (v) => v != null ? onChanged(v) : null,
      items: _timeOptions.map((v) => DropdownMenuItem(value: v, child: Text(v, style: const TextStyle(fontSize: 14)))).toList(),
    );
  }

  // --- AUTO VIEW WIDGETS (Timeline) ---

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

  /// Controls for setting the date range for AI shift prediction.
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

  /// Complex UI: Creates a Gantt-chart style timeline for a specific day.
  /// [shifts] is the list of hours and staff assigned for that day.
  Widget _buildTimelineCard(String date, List<Map<String, dynamic>> shifts, ThemeData theme) {
    // Filter out 'Shortage' entries (staff_id: -1) from the staff names list
    final actualStaff = shifts.where((s) => s['staff_id'] != -1).toList();
    final names = actualStaff.map((s) => s['name'].toString()).toSet().toList();
    
    // Config for the chart horizontal scroll
    const hours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];
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
                    // Header: Hours 9 - 24
                    Row(
                      children: [
                        const SizedBox(width: labelWidth),
                        ...hours.map((h) => SizedBox(width: hourWidth, child: Center(child: Text("$h", style: TextStyle(fontSize: 11, color: theme.hintColor))))),
                      ],
                    ),
                    const Divider(),
                    // Body: One row per staff member
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
                    // Footer: Alert row if AI predicts a labor shortage
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

  /// Renders a "Warning" row at the bottom of the chart.
  /// Triggered if the API returns a 'shortage' flag (staff_id: -1) for specific hours.
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

  /// Opens the standard Material Date Range Picker.
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