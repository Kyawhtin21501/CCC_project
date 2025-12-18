
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shimmer/shimmer.dart';
class Staff {
  final String id;
  final String name;
  final String gender;

  Staff({required this.id, required this.name, required this.gender});

  // Factory to handle API mapping and null safety in one place
  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '不明',
      gender: map['gender']?.toString() ?? '不明',
    );
  }

  // Helper for UI display
  String get displayName => "$name ($gender)";
}


enum ShiftMode { manual, auto }

class ShiftManagementScreen extends StatelessWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShiftManagementForm();
  }
}

class _ShiftManagementForm extends StatefulWidget {
  const _ShiftManagementForm();

  @override
  State<_ShiftManagementForm> createState() => _ShiftManagementFormState();
}

class _ShiftManagementFormState extends State<_ShiftManagementForm> {
  ShiftMode _selectedMode = ShiftMode.manual;

  // --- MANUAL MODE STATE ---
  List<Staff> staffList = []; // Clean typed list
  DateTime _manualFocusedDay = DateTime.now();
  DateTime? _manualSelectedDay;

  /// preferences[date][staffId] = { "startTime": "...", "endTime": "..." }
  Map<String, Map<String, Map<String, String>>> preferences = {};

  bool _manualLoading = true;
  String? _manualError;

  // --- AUTO MODE STATE ---
  DateTime _autoStart = DateTime.now();
  DateTime _autoEnd = DateTime.now().add(const Duration(days: 7));
  bool _autoLoading = false;
  String? _autoError;
  List<Map<String, dynamic>> _shiftTable = [];

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  // --- LOGIC METHODS ---

  Future<void> _fetchStaff() async {
    try {
      final data = await ApiService.fetchStaffList();
      setState(() {
        staffList = data.map<Staff>((s) => Staff.fromMap(s)).toList();
        _manualLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _manualError = 'スタッフ一覧の取得に失敗しました';
          _manualLoading = false;
        });
      }
    }
  }

  String _fmt(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  Map<String, String> _getOrInitPrefs(String dateKey, String staffId) {
    preferences[dateKey] ??= {};
    return preferences[dateKey]![staffId] ??= {
      'startTime': '09:00',
      'endTime': '18:00',
    };
  }

  Future<void> _saveShift(Staff staff) async {
    final dateKey = _fmt(_manualSelectedDay ?? _manualFocusedDay);
    final pref = _getOrInitPrefs(dateKey, staff.id);

    try {
      // Logic for time validation
      final start = TimeOfDay(
        hour: int.parse(pref['startTime']!.split(":")[0]),
        minute: int.parse(pref['startTime']!.split(":")[1]),
      );
      final end = TimeOfDay(
        hour: int.parse(pref['endTime']!.split(":")[0]),
        minute: int.parse(pref['endTime']!.split(":")[1]),
      );

      if (end.hour < start.hour || (end.hour == start.hour && end.minute <= start.minute)) {
        throw '終了時間は開始時間より後にしてください';
      }

      await ApiService.saveShiftPreferences({
        'date': dateKey,
        'staff_id': staff.id,
        'start_time': pref['startTime'],
        'end_time': pref['endTime'],
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${staff.name}さんの希望を保存しました"), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // --- UI COMPONENTS ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: AppDrawer(
        currentScreen: _selectedMode == ShiftMode.manual ? DrawerScreen.shiftRequest : DrawerScreen.shiftCreate,
      ),
      body: Stack(
        children: [
          _buildMainScrollArea(theme),
          _buildTopMenuBar(),
        ],
      ),
    );
  }

  Widget _buildTopMenuBar() {
    return Positioned(
      top: 28, left: 16, right: 16,
      child: CustomMenuBar(
        title: _selectedMode == ShiftMode.manual ? '希望登録' : 'AIシフト作成',
        onMenuPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  Widget _buildMainScrollArea(ThemeData theme) {
    return Positioned.fill(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 900),
            child: Column(
              children: [
                _buildToggleSwitch(theme),
                const SizedBox(height: 32),
                _selectedMode == ShiftMode.manual 
                    ? _buildManualView(theme) 
                    : _buildAutoView(theme),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleSwitch(ThemeData theme) {
    return SegmentedButton<ShiftMode>(
      segments: const [
        ButtonSegment(value: ShiftMode.manual, label: Text('手動登録'), icon: Icon(Icons.edit)),
        ButtonSegment(value: ShiftMode.auto, label: Text('AI作成'), icon: Icon(Icons.psychology)),
      ],
      selected: {_selectedMode},
      onSelectionChanged: (set) => setState(() => _selectedMode = set.first),
    );
  }

  // --- MANUAL VIEW COMPONENTS ---

  Widget _buildManualView(ThemeData theme) {
    if (_manualLoading) return const Center(child: CircularProgressIndicator());
    final dateKey = _fmt(_manualSelectedDay ?? _manualFocusedDay);

    return Column(
      children: [
        _buildCalendarCard(theme),
        const SizedBox(height: 20),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: staffList.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, index) => _buildStaffTile(theme, staffList[index], dateKey),
        ),
      ],
    );
  }

  Widget _buildCalendarCard(ThemeData theme) {
    return Card(
      child: TableCalendar(
        firstDay: DateTime(2024),
        lastDay: DateTime(2026),
        focusedDay: _manualFocusedDay,
        selectedDayPredicate: (day) => isSameDay(_manualSelectedDay, day),
        onDaySelected: (sel, foc) => setState(() { _manualSelectedDay = sel; _manualFocusedDay = foc; }),
        calendarStyle: CalendarStyle(selectedDecoration: BoxDecoration(color: theme.colorScheme.primary, shape: BoxShape.circle)),
        headerStyle: const HeaderStyle(formatButtonVisible: false, titleCentered: true),
      ),
    );
  }

  Widget _buildStaffTile(ThemeData theme, Staff staff, String dateKey) {
    final pref = _getOrInitPrefs(dateKey, staff.id);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(child: Text(staff.name[0])),
                const SizedBox(width: 12),
                Text(staff.displayName, style: theme.textTheme.titleMedium),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => _saveShift(staff),
                  icon: const Icon(Icons.save_alt),
                  label: const Text("保存"),
                )
              ],
            ),
            const Divider(),
            Row(
              children: [
                Expanded(child: _timeButton(theme, "開始", pref['startTime']!, (v) => setState(() => pref['startTime'] = v))),
                const Padding(padding: EdgeInsets.symmetric(horizontal: 10), child: Text("~")),
                Expanded(child: _timeButton(theme, "終了", pref['endTime']!, (v) => setState(() => pref['endTime'] = v))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeButton(ThemeData theme, String label, String time, Function(String) onPick) {
    return OutlinedButton(
      onPressed: () async {
        final t = await showTimePicker(
          context: context, 
          initialTime: TimeOfDay(hour: int.parse(time.split(":")[0]), minute: int.parse(time.split(":")[1]))
        );
        if (t != null) onPick("${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}");
      },
      child: Text("$label: $time"),
    );
  }

  // --- AUTO VIEW COMPONENTS (OMITTED FOR BREVITY, SAME LOGIC AS ABOVE) ---
  Widget _buildAutoView(ThemeData theme) {
     return const Center(child: Text("AI自動生成コンテンツはここに表示されます"));
  }
}