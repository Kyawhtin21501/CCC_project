import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:omakase_shift/services/api_services.dart';
import 'package:omakase_shift/widgets/appdrawer.dart';
import 'package:omakase_shift/widgets/custom_menubar.dart';

/// [ShiftMode] toggles the UI between staff input and admin AI generation.
enum ShiftMode { manual, auto }

/// [Staff] model handles data mapping from backend JSON.
class Staff {
  final String id;
  final String name;
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
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 6));

  final Map<String, Map<String, Map<String, String>>> _preferences = {};
  List<Map<String, dynamic>> _predictedShifts = [];

 final List<String> _timeOptions = List.generate(24, (hour) {
  return "${hour.toString().padLeft(2, '0')}:00";
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
        _showSnackBar(
          "スタッフデータの取得に失敗しました。通信環境を確認してください。",
          isError: true,
        );
      }
    }
  }

  Future<void> _savePreference(Staff staff) async {
    final selectedDate = _selectedDay;
    if (selectedDate == null) {
      _showSnackBar("日付を選択してください", isError: true); 
      return;
    }

    final p = _getPrefs(staff.id);

    
    if (p['startTime']!.compareTo(p['endTime']!) >= 0) {
      _showSnackBar(
        "開始時間は終了時間より前に設定してください",
        isError: true,
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      await ApiService.saveShiftPreferences({
        'date': _dateKey(selectedDate),
        'staff_id': int.parse(staff.id),
        'start_time': p['startTime'],
        'end_time': p['endTime'],
      });
      if (mounted) {
        _showSnackBar("${staff.name}さんの希望を保存しました");
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar(
          "保存に失敗しました。ネットワークをご確認ください。",
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

Future<void> _generateAutoShifts() async {
  if (_endDate.isBefore(_startDate)) {
    _showSnackBar(
      "終了日は開始日以降を選択してください",
      isError: true,
    );
    return;
  }

  setState(() {
    _isGenerating = true;
    _predictedShifts = [];
  });

  try {
    debugPrint("AutoShift Request Start");
    debugPrint("Start: $_startDate, End: $_endDate");

    final data =
        await ApiService.fetchAutoShiftTable(_startDate, _endDate);

    debugPrint("API Response: $data");

    if (mounted) {
      setState(() {
        _predictedShifts = List<Map<String, dynamic>>.from(data);
      });
      _showSnackBar("AIシフトを生成しました");
    }
  }
  // ここが重要
  catch (e, stackTrace) {
    debugPrint(" AutoShift Error: $e");
    debugPrint("tackTrace:\n$stackTrace");

    if (mounted) {
      _showSnackBar(
        "AIシフト生成に失敗しました。\n${e.toString()}",
        isError: true,
      );
    }
  } finally {
    if (mounted) {
      setState(() => _isGenerating = false);
    }
  }
}


  // --- HELPERS ---

  String _dateKey(DateTime d) => DateFormat('yyyy-MM-dd').format(d);

  Map<String, String> _getPrefs(String staffId) {
    final dKey = _dateKey(_selectedDay ?? _focusedDay);
    _preferences[dKey] ??= {};
    return _preferences[dKey]![staffId] ??= {
      'startTime': '09:00',
      'endTime': '18:00',
    };
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
        backgroundColor: isError
            ? Theme.of(context).colorScheme.error
            : Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // --- UI ---

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
                    padding: EdgeInsets.fromLTRB(
                      isMobile ? 12 : 24,
                      110,
                      isMobile ? 12 : 24,
                      40,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1100),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _selectedMode == ShiftMode.manual
                                  ? "スタッフの出勤希望入力"
                                  : "AIシフト自動生成・分析",
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.w900),
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
            top: 28,
            left: 16,
            right: 16,
            child: Builder(
              builder: (scaffoldContext) => CustomMenuBar(
                title: 'シフト作成・管理',
                onMenuPressed: () =>
                    Scaffold.of(scaffoldContext).openDrawer(),
              ),
            ),
          ),
          if (_isSaving)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildModeToggle(ThemeData theme) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<ShiftMode>(
        segments: const [
          ButtonSegment(
            value: ShiftMode.manual,
            label: Text('希望入力'),
            icon: Icon(Icons.edit_calendar),
          ),
          ButtonSegment(
            value: ShiftMode.auto,
            label: Text('AI予測'),
            icon: Icon(Icons.auto_awesome),
          ),
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
            Icon(Icons.people_outline, size: 20, color: theme.colorScheme.primary),
            const SizedBox(width: 8),
            Text(
              "${DateFormat('MM月dd日').format(_selectedDay ?? _focusedDay)} の希望状況",
              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),
        if (staffList.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: Text("スタッフが登録されていません"),
            ),
          )
        else
          ...staffList.map((staff) => _buildStaffCard(staff, theme, isMobile)),
      ],
    );
  }

  Widget _buildCalendarCard(ThemeData theme) {
    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerLow,
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
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: TextStyle(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarStyle: CalendarStyle(
            selectedDecoration: BoxDecoration(
              color: theme.colorScheme.primary,
              shape: BoxShape.circle,
            ),
            todayDecoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            todayTextStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
            weekendTextStyle: TextStyle(color: theme.colorScheme.error),
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
      color: theme.colorScheme.surface,
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
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.secondaryContainer,
                      child: Text(
                        staff.name[0],
                        style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                      ),
                    ),
                    title: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _timeDropdown(prefs['startTime']!, (v) => setState(() => prefs['startTime'] = v), theme),
                      const Text("〜"),
                      _timeDropdown(prefs['endTime']!, (v) => setState(() => prefs['endTime'] = v), theme),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.save, size: 18),
                      onPressed: () => _savePreference(staff),
                      label: const Text("保存"),
                    ),
                  )
                ],
              )
            : Row(
                children: [
                  CircleAvatar(
                    backgroundColor: theme.colorScheme.secondaryContainer,
                    child: Text(
                      staff.name[0],
                      style: TextStyle(color: theme.colorScheme.onSecondaryContainer),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(staff.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  _timeDropdown(prefs['startTime']!, (v) => setState(() => prefs['startTime'] = v), theme),
                  const Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: Text("〜")),
                  _timeDropdown(prefs['endTime']!, (v) => setState(() => prefs['endTime'] = v), theme),
                  const SizedBox(width: 24),
                  FilledButton.icon(
                    icon: const Icon(Icons.save, size: 18),
                    onPressed: () => _savePreference(staff),
                    label: const Text("保存"),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _timeDropdown(String currentValue, Function(String) onChanged, ThemeData theme) {
    return DropdownButton<String>(
      value: currentValue,
      dropdownColor: theme.colorScheme.surfaceContainerHighest,
      underline: const SizedBox(),
      onChanged: (v) => v != null ? onChanged(v) : null,
      items: _timeOptions
          .map((v) => DropdownMenuItem(
                value: v,
                child: Text(v, style: theme.textTheme.bodyMedium),
              ))
          .toList(),
    );
  }

  // --- AI VIEW ---

  Widget _buildAutoView(ThemeData theme) {
    final grouped = _groupShiftsByDate();
    return Column(
      children: [
        _buildActionBanner(theme),
        const SizedBox(height: 24),
        if (_isGenerating) const LinearProgressIndicator(),
        if (!_isGenerating && grouped.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Text("期間を選択してAI生成ボタンを押してください"),
          ),
        ...grouped.entries.map((e) => _buildTimelineCard(e.key, e.value, theme)),
      ],
    );
  }

  Widget _buildActionBanner(ThemeData theme) {
    final df = DateFormat('yyyy/MM/dd');
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.date_range, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              "${df.format(_startDate)} 〜 ${df.format(_endDate)}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          TextButton(onPressed: _selectDateRange, child: const Text("期間変更")),
          const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _isGenerating ? null : _generateAutoShifts,
            icon: const Icon(Icons.auto_awesome),
            label: const Text("AI生成"),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(String date, List<Map<String, dynamic>> shifts, ThemeData theme) {
    final actualStaff = shifts
        .where((s) => s['staff_id'] != -1 && s['name'] != 'not_enough')
        .toList();
    final names = actualStaff.map((s) => s['name'].toString()).toSet().toList();

    const hours = [9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24];
    const double hourWidth = 45.0;
    const double nameWidth = 100.0;
    const double totalHoursWidth = 70.0;
    final double totalTableWidth = nameWidth + totalHoursWidth + (hours.length * hourWidth);

    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 24),
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            color: theme.colorScheme.secondaryContainer.withOpacity(0.4),
            child: Text(
              date,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSecondaryContainer,
              ),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: totalTableWidth,
              child: Column(
                children: [
                  _buildHeaderRow(hours, nameWidth, totalHoursWidth, hourWidth, theme),
                  Stack(
                    children: [
                      _buildShortageBackground(hours, nameWidth, totalHoursWidth, hourWidth, shifts, theme),
                      Column(
                        children: [
                          ...names.map((name) {
                            final staffShifts = actualStaff.where((s) => s['name'] == name).toList();
                            return _buildDataRow(
                              name,
                              "${staffShifts.length}h",
                              hours,
                              staffShifts,
                              hourWidth,
                              nameWidth,
                              totalHoursWidth,
                              theme,
                              isShortageRow: false,
                            );
                          }),
                          _buildDataRow(
                            "欠員不足",
                            "-",
                            hours,
                            shifts.where((s) => s['staff_id'] == -1).toList(),
                            hourWidth,
                            nameWidth,
                            totalHoursWidth,
                            theme,
                            isShortageRow: true,
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderRow(List<int> hours, double nameW, double totalW, double hourW, ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHigh,
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _buildHeaderCell("名前", nameW, theme),
          _buildHeaderCell("実労働", totalW, theme),
          ...hours.map((h) => _buildHeaderCell("${h}h", hourW, theme)),
        ],
      ),
    );
  }

  Widget _buildShortageBackground(List<int> hours, double nameW, double totalW, double hourW, List<Map<String, dynamic>> shifts, ThemeData theme) {
    return Positioned.fill(
      child: Padding(
        padding: EdgeInsets.only(left: nameW + totalW),
        child: Row(
          children: hours.map((h) {
            final bool isShort = shifts.any((s) => s['hour'] == h && (s['staff_id'] == -1 || s['name'] == 'not_enough'));
            return Container(
              width: hourW,
              color: isShort ? theme.colorScheme.error.withOpacity(0.1) : Colors.transparent,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDataRow(String name, String totalTime, List<int> hours, List<Map<String, dynamic>> rowShifts, double hourW, double nameW, double totalW, ThemeData theme, {required bool isShortageRow}) {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: nameW,
            padding: const EdgeInsets.all(8),
            child: Text(
              name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isShortageRow ? FontWeight.bold : FontWeight.normal,
                color: isShortageRow ? theme.colorScheme.error : theme.colorScheme.onSurface,
              ),
            ),
          ),
          Container(
            width: totalW,
            alignment: Alignment.center,
            child: Text(
              totalTime,
              style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
          ...hours.map((h) {
            final bool hasEntry = rowShifts.any((s) => s['hour'] == h);
            return SizedBox(
              width: hourW,
              height: 38,
              child: Center(
                child: hasEntry
                    ? Container(
                        width: hourW - 12,
                        height: 16,
                        decoration: BoxDecoration(
                          color: isShortageRow ? theme.colorScheme.error : theme.colorScheme.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: isShortageRow
                            ? Icon(Icons.warning_amber_rounded, size: 10, color: theme.colorScheme.onError)
                            : null,
                      )
                    : const SizedBox.shrink(),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(String text, double width, ThemeData theme) {
    return Container(
      width: width,
      padding: const EdgeInsets.symmetric(vertical: 10),
      alignment: Alignment.center,
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime(2030, 12, 31),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
    }
  }
}