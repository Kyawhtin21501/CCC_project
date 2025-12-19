import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:table_calendar/table_calendar.dart';


// ====================================================================
// I. DATA MODELS
// ====================================================================

/// Staff model used in the shift management screen
/// Represents a single staff member fetched from the backend
class Staff {
  final String id;
  final String name;
  final String gender;

  Staff({
    required this.id,
    required this.name,
    required this.gender,
  });

  /// Factory constructor to convert API response (Map) into Staff object
  factory Staff.fromMap(Map<String, dynamic> map) {
    return Staff(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '不明',
      gender: map['gender']?.toString() ?? '不明',
    );
  }

  /// Display name shown in UI
  /// Example: 山田 (Male)
  String get displayName => "$name ($gender)";
}

/// Shift creation mode
/// - manual : user manually inputs shift preferences
/// - auto   : AI generates shifts automatically
enum ShiftMode { manual, auto }


// ====================================================================
// II. SCREEN CONTAINER
// ====================================================================

/// Root screen widget for shift management
class ShiftManagementScreen extends StatelessWidget {
  const ShiftManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _ShiftManagementForm();
  }
}

/// Stateful widget containing all logic and UI
class _ShiftManagementForm extends StatefulWidget {
  const _ShiftManagementForm();

  @override
  State<_ShiftManagementForm> createState() => _ShiftManagementFormState();
}

class _ShiftManagementFormState extends State<_ShiftManagementForm> {

  /// Currently selected mode (manual / auto)
  ShiftMode _selectedMode = ShiftMode.manual;

  /// Staff list fetched from backend
  List<Staff> staffList = [];

  /// Loading & saving state flags
  bool _isLoadingStaff = true;
  bool _isSaving = false;

  /// Calendar state
  DateTime _manualFocusedDay = DateTime.now();
  DateTime? _manualSelectedDay;

  /// Shift preferences storage
  /// preferences[date][staffId] = { startTime, endTime }
  Map<String, Map<String, Map<String, String>>> preferences = {};

  @override
  void initState() {
    super.initState();
    _manualSelectedDay = DateTime.now();
    _fetchStaff();
  }

  // ------------------------------------------------------------------
  // III. LOGIC METHODS
  // ------------------------------------------------------------------

  /// Fetch staff list from backend API
  Future<void> _fetchStaff() async {
    try {
      final data = await ApiService.fetchStaffList();
      if (mounted) {
        setState(() {
          staffList = data.map<Staff>((s) => Staff.fromMap(s)).toList();
          _isLoadingStaff = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingStaff = false);
        _showSnackBar('スタッフ取得エラー: $e', Colors.red);
      }
    }
  }

  /// Format DateTime to yyyy-MM-dd (used as map key & API payload)
  String _fmt(DateTime date) => DateFormat('yyyy-MM-dd').format(date);

  /// Get existing preference or initialize default values
  Map<String, String> _getOrInitPrefs(String dateKey, String staffId) {
    preferences[dateKey] ??= {};
    return preferences[dateKey]![staffId] ??= {
      'startTime': '09:00',
      'endTime': '18:00',
    };
  }

  /// Save a single staff’s shift preference to backend
  Future<void> _saveShift(Staff staff) async {
    if (_isSaving) return;

    final DateTime targetDate = _manualSelectedDay ?? _manualFocusedDay;
    final String dateKey = _fmt(targetDate);
    final pref = _getOrInitPrefs(dateKey, staff.id);

    setState(() => _isSaving = true);

    try {
      /// Convert staff ID to int (required by backend)
      final int? staffIdInt = int.tryParse(staff.id);
      if (staffIdInt == null) throw "有効なスタッフIDが見つかりません";

      final payload = {
        'date': dateKey,
        'staff_id': staffIdInt,
        'start_time': pref['startTime'],
        'end_time': pref['endTime'],
      };

      await ApiService.saveShiftPreferences(payload);

      if (mounted) {
        _showSnackBar("${staff.name}さんの希望を保存しました", Colors.green);
      }
    } catch (e) {
      if (mounted) {
        _showSnackBar("エラー: $e", Colors.red);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Show snackbar messages
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ------------------------------------------------------------------
  // IV. UI BUILDING
  // ------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.shiftManagement),
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    top: 100, left: 20, right: 20, bottom: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        _buildToggleSwitch(),
                        const SizedBox(height: 24),
                        if (_selectedMode == ShiftMode.manual)
                          _buildManualView(theme)
                        else
                          _buildAutoView(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 24,
              left: 16,
              right: 16,
              child: CustomMenuBar(
                title: "シフト作成・管理",
                onMenuPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Toggle between manual and auto modes
  Widget _buildToggleSwitch() {
    return SegmentedButton<ShiftMode>(
      segments: const [
        ButtonSegment(
          value: ShiftMode.manual,
          label: Text('手動登録'),
          icon: Icon(Icons.calendar_month),
        ),
        ButtonSegment(
          value: ShiftMode.auto,
          label: Text('AI自動生成'),
          icon: Icon(Icons.auto_awesome),
        ),
      ],
      selected: {_selectedMode},
      onSelectionChanged: (set) =>
          setState(() => _selectedMode = set.first),
    );
  }

  /// Manual shift input view
  Widget _buildManualView(ThemeData theme) {
    if (_isLoadingStaff) {
      return const Center(child: CircularProgressIndicator());
    }

    final dateKey = _fmt(_manualSelectedDay ?? _manualFocusedDay);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildCalendarCard(theme),
        const SizedBox(height: 32),
        Text("個別希望入力 ($dateKey)", style: theme.textTheme.titleLarge),
        const SizedBox(height: 16),
        if (staffList.isEmpty)
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text("スタッフが登録されていません"),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: staffList.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) =>
                _buildStaffTile(theme, staffList[index], dateKey),
          ),
      ],
    );
  }

  /// Calendar UI
  Widget _buildCalendarCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: TableCalendar(
        firstDay: DateTime(2024),
        lastDay: DateTime(2026),
        focusedDay: _manualFocusedDay,
        selectedDayPredicate: (day) =>
            isSameDay(_manualSelectedDay, day),
        onDaySelected: (selected, focused) {
          setState(() {
            _manualSelectedDay = selected;
            _manualFocusedDay = focused;
          });
        },
        calendarStyle: CalendarStyle(
          todayDecoration: BoxDecoration(
            color: theme.colorScheme.primary.withOpacity(0.3),
            shape: BoxShape.circle,
          ),
          selectedDecoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
        ),
      ),
    );
  }

  /// Staff row with time pickers and save button
  Widget _buildStaffTile(
      ThemeData theme, Staff staff, String dateKey) {
    final pref = _getOrInitPrefs(dateKey, staff.id);

    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.primaryContainer,
                  child: Text(staff.name[0]),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    staff.displayName,
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed:
                      _isSaving ? null : () => _saveShift(staff),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.save_alt, size: 18),
                  label: Text(_isSaving ? "通信中..." : "保存"),
                )
              ],
            ),
            const Divider(height: 32),
            Row(
              children: [
                Expanded(
                  child: _timePickerButton(
                    theme,
                    "開始",
                    pref['startTime']!,
                    (v) => setState(() => pref['startTime'] = v),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward,
                      size: 16, color: Colors.grey),
                ),
                Expanded(
                  child: _timePickerButton(
                    theme,
                    "終了",
                    pref['endTime']!,
                    (v) => setState(() => pref['endTime'] = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Time picker button component
  Widget _timePickerButton(
    ThemeData theme,
    String label,
    String currentTime,
    Function(String) onPick,
  ) {
    return InkWell(
      onTap: () async {
        final parts = currentTime.split(":");
        final initialTime = TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );

        final picked = await showTimePicker(
          context: context,
          initialTime: initialTime,
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(alwaysUse24HourFormat: true),
            child: child!,
          ),
        );

        if (picked != null) {
          final formatted =
              "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
          onPick(formatted);
        }
      },
      child: Container(
        padding:
            const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
        decoration: BoxDecoration(
          border:
              Border.all(color: theme.colorScheme.outlineVariant),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(currentTime,
                style: theme.textTheme.titleMedium),
          ],
        ),
      ),
    );
  }

  /// Auto shift generation placeholder UI
  Widget _buildAutoView(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          children: [
            const Icon(Icons.auto_awesome,
                size: 60, color: Colors.orangeAccent),
            const SizedBox(height: 16),
            Text("AI シフト自動生成",
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 12),
            const Text(
              "登録された希望時間を分析し、売上予測に基づいた最適なシフトを作成します。",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                // TODO: Implement AI generation logic
              },
              child: const Text("生成プロセスを開始"),
            )
          ],
        ),
      ),
    );
  }
}
