import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:shimmer/shimmer.dart';

// --- ENUM for Mode Selection ---
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

  // --- MANUAL MODE STATE (from CreatedShiftScreen) ---
  final List<String> shifts = const ['morning', 'afternoon', 'night'];
  List<String> staffList = [];

  DateTime _manualFocusedDay = DateTime.now();
  DateTime? _manualSelectedDay;

  /// preferences[date][staff][shift] = bool
  Map<String, Map<String, Map<String, bool>>> preferences = {};

  bool _manualLoading = true;
  String? _manualError;

  // --- AUTO MODE STATE (from ShiftAutoScreen) ---
  DateTime _autoStart =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);
  DateTime _autoEnd =
      DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day + 7);

  bool _autoLoading = false;
  String? _autoError;
  List<Map<String, dynamic>> _shiftTable = [];

  @override
  void initState() {
    super.initState();
    _fetchStaff();
  }

  // --- COMMON LOGIC ---

  /// Fetch staff list from backend API (used by Manual Mode)
  Future<void> _fetchStaff() async {
    try {
      final data = await ApiService.fetchStaffList();

      final List<String> names = data.map<String>((s) {
        if (s is Map && s.containsKey('name')) {
          return s['name'].toString();
        }
        return s.toString();
      }).toList();

      setState(() {
        staffList = names;
        _manualLoading = false;
      });
        } catch (e) {
      if (mounted) {
        setState(() {
          _manualError = 'スタッフ一覧の取得に失敗しました: $e';
          _manualLoading = false;
        });
      }
    }
  }

  /// Get normalized date string (YYYY-MM-DD)
  String _fmt(DateTime date) => date.toIso8601String().split("T")[0];

  // --- MANUAL MODE LOGIC (from CreatedShiftScreen) ---

  /// Ensure preferences map exists for this date/staff
  Map<String, bool> _getOrInitStaffPrefs(String dateKey, String staff) {
    preferences[dateKey] ??= {};
    preferences[dateKey]![staff] ??= {
      for (final shift in shifts) shift: false,
    };
    return preferences[dateKey]![staff]!;
  }

  /// Save preferences
  Future<void> _saveShiftPreferences(String staff) async {
    final selected = _manualSelectedDay ?? _manualFocusedDay;
    final dateKey = _fmt(selected);
    final pref = _getOrInitStaffPrefs(dateKey, staff);

    final data = {
      'date': dateKey,
      'preferences': {
        staff: {
          'morning': pref['morning'],
          'afternoon': pref['afternoon'],
          'night': pref['night'],
        },
      },
    };

    try {
      await ApiService.saveShiftPreferences(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("$staff さんの希望を保存しました")),
        );

        // Reset shifts after saving, this state logic seems intentional for the UI
        setState(() {
          preferences[dateKey]![staff] = {
            for (var shift in shifts) shift: false,
          };
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("エラー: $e")),
        );
      }
    }
  }

  // --- AUTO MODE LOGIC (from ShiftAutoScreen) ---

  Future<void> _loadShiftTable() async {
    if (_autoStart.isAfter(_autoEnd)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('開始日は終了日より前に設定してください。')),
        );
      }
      return;
    }
    if (_autoLoading) return;

    setState(() {
      _autoLoading = true;
      _autoError = null;
    });
    try {
      final data = await ApiService.fetchAutoShiftTableDashboard(_autoStart, _autoEnd);
      if (mounted) {
        setState(() {
          _shiftTable = data;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _autoError = "Error: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _autoLoading = false;
        });
      }
    }
  }

  void _clearAutoShifts() {
    setState(() {
      _shiftTable = [];
      _autoError = null;
      _autoLoading = false;
    });
  }

  /// Groups the flat list of shift assignments by date and then by shift type.
  Map<String, Map<String, List<Map<String, dynamic>>>> _groupByDateShift(
      List<Map<String, dynamic>> data) {
    final Map<String, Map<String, List<Map<String, dynamic>>>> grouped = {};
    for (var item in data) {
      String date = item['date'].toString();
      String shift = item['shift'].toString();
      int staffId = int.tryParse(item['ID'].toString()) ?? 0;
      String staffName = item['Name']?.toString() ?? 'Unknown';

      if (staffId == 0) continue;

      grouped.putIfAbsent(date, () => {});
      grouped[date]!.putIfAbsent(shift, () => []);
      grouped[date]![shift]!.add({"ID": staffId, "Name": staffName});
    }
    return grouped;
  }

  // --- BUILD METHOD ---
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Determine the title based on the selected mode
    final screenTitle = _selectedMode == ShiftMode.manual
        ? 'シフト希望登録 (手動作成)'
        : 'シフト自動作成 (AI生成)';
    
    // Determine the correct drawer screen based on the original structure
    final drawerScreen = _selectedMode == ShiftMode.manual
        ? DrawerScreen.shiftRequest // Original CreatedShiftScreen drawer
        : DrawerScreen.shiftCreate; // Original ShiftAutoScreen drawer

    return Scaffold(
      drawer: AppDrawer(currentScreen: drawerScreen),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Builder(
        builder: (ctx) {
          return Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  // Apply top padding to clear space for the CustomMenuBar
                  padding: const EdgeInsets.only(
                      top: 96, left: 20, right: 20, bottom: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // 1. Mode Selector
                          _buildModeSelector(theme),
                          const SizedBox(height: 30),

                          // 2. Conditional Content based on Mode
                          _buildCurrentModeContent(theme),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // --- CUSTOM MENU BAR (Fixed at Top) ---
              Positioned(
                top: 28,
                left: 16,
                right: 16,
                child: CustomMenuBar(
                  title: screenTitle,
                  onMenuPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET BUILDERS ---

  Widget _buildModeSelector(ThemeData theme) {
    return Center(
      child: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? Colors.grey.shade800
              : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModeButton(
              theme,
              mode: ShiftMode.manual,
              label: '手動登録（希望）',
              icon: Icons.edit_calendar,
            ),
            const SizedBox(width: 8),
            _buildModeButton(
              theme,
              mode: ShiftMode.auto,
              label: 'AI自動生成',
              icon: Icons.auto_mode,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton(
      ThemeData theme, {
        required ShiftMode mode,
        required String label,
        required IconData icon,
      }) {
    final isSelected = _selectedMode == mode;
    return ElevatedButton.icon(
      onPressed: () {
        setState(() {
          _selectedMode = mode;
        });
      },
      icon: Icon(icon, size: 18),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected
            ? theme.colorScheme.primary
            : Colors.transparent,
        foregroundColor: isSelected
            ? theme.colorScheme.onPrimary
            : _unselectedTextColor(theme),
        elevation: isSelected ? 4 : 0,
        shadowColor: Colors.black,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  Color _unselectedTextColor(ThemeData theme) {
    return theme.brightness == Brightness.dark
        ? Colors.white70
        : Colors.black54;
  }

  Widget _buildCurrentModeContent(ThemeData theme) {
    switch (_selectedMode) {
      case ShiftMode.manual:
        return _buildManualCreationForm(theme);
      case ShiftMode.auto:
        return _buildAutoGenerationInputs(theme);
    }
  }

  // --- MANUAL SHIFT CREATION (CreatedShiftScreen UI/Logic) ---
  Widget _buildManualCreationForm(ThemeData theme) {
    final selected = _manualSelectedDay ?? _manualFocusedDay;
    final dateKey = _fmt(selected);

    if (_manualLoading) {
      // Use a simple spinner for manual loading since staff fetch is quick and simple
      return const Center(child: CircularProgressIndicator());
    }

    if (_manualError != null) {
      return Center(child: Text(_manualError!));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Calendar Card
        _buildCalendarCard(theme, dateKey),
        const SizedBox(height: 24),

        // Staff Cards
        ...staffList.map((staff) {
          return _buildStaffPreferenceCard(theme, dateKey, staff);
        }),
      ],
    );
  }

  /// Builds the calendar card using TableCalendar
  Widget _buildCalendarCard(ThemeData theme, String dateKey) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TableCalendar(
              firstDay: DateTime(2020),
              lastDay: DateTime(2030),
              focusedDay: _manualFocusedDay,
              selectedDayPredicate: (day) => isSameDay(_manualSelectedDay, day),
              onDaySelected: (selected, focused) {
                setState(() {
                  _manualSelectedDay = selected;
                  _manualFocusedDay = focused;
                });
              },
              calendarStyle: CalendarStyle(
                todayDecoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.4),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                defaultTextStyle: theme.textTheme.bodyMedium!,
                weekendTextStyle: theme.textTheme.bodyMedium!.copyWith(color: Colors.red),
                holidayTextStyle: theme.textTheme.bodyMedium!.copyWith(color: Colors.red),
              ),
              headerStyle: HeaderStyle(
                titleCentered: true,
                formatButtonVisible: false,
                titleTextStyle: theme.textTheme.titleMedium!,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "希望日: $dateKey",
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for a single staff member's shift preferences
  Widget _buildStaffPreferenceCard(
      ThemeData theme, String dateKey, String staff) {
    final pref = _getOrInitStaffPrefs(dateKey, staff);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              staff,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            // Shift Checkboxes
            Wrap(
              spacing: 16.0,
              runSpacing: 8.0,
              children: shifts.map((shift) {
                return Row(
                  mainAxisSize: MainAxisSize.min, // Keep items close together
                  children: [
                    Text(shift, style: theme.textTheme.bodyMedium),
                    Checkbox(
                      value: pref[shift] ?? false,
                      onChanged: (boolean) {
                        setState(() {
                          pref[shift] = boolean ?? false;
                        });
                      },
                      activeColor: theme.colorScheme.primary,
                    ),
                  ],
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // Save Button
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: () => _saveShiftPreferences(staff),
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text("保存"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- AUTO SHIFT GENERATION (ShiftAutoScreen UI/Logic) ---
  Widget _buildAutoGenerationInputs(ThemeData theme) {
    final df = DateFormat('MM/dd');
    final grouped = _groupByDateShift(_shiftTable);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        /// === Input Card ===
        _buildAutoInputCard(theme, df),
        const SizedBox(height: 16),

        /// === Output Card ===
        _buildAutoOutputCard(theme, grouped, df),
      ],
    );
  }

  Widget _buildAutoInputCard(ThemeData theme, DateFormat df) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AIシフト作成の期間設定",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            Text("日付範囲",
                style: theme.textTheme.bodyLarge
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 10),
            Row(
              children: [
                _DateBox(
                    text: df.format(_autoStart),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _autoStart,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: Theme.of(context),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _autoStart = picked);
                      }
                    }),
                const SizedBox(width: 12),
                const Text("~"),
                const SizedBox(width: 12),
                _DateBox(
                    text: df.format(_autoEnd),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _autoEnd,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                        builder: (context, child) => Theme(
                          data: Theme.of(context),
                          child: child!,
                        ),
                      );
                      if (picked != null) {
                        setState(() => _autoEnd = picked);
                      }
                    }),
              ],
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _autoLoading ? null : _loadShiftTable,
              style: ElevatedButton.styleFrom(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
              ),
              label: Text(_autoLoading ? '作成中...' : 'シフト作成'),
              icon: _autoLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.auto_awesome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAutoOutputCard(
      ThemeData theme, Map<String, Map<String, List<Map<String, dynamic>>>> grouped, DateFormat df) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("シフト結果",
                style: theme.textTheme.titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            if (_autoLoading)
              _buildShimmerPlaceholder(theme)
            else if (_autoError != null)
              Text(_autoError!, style: const TextStyle(color: Colors.red))
            else if (_shiftTable.isEmpty)
              Text("結果なし",
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(color: theme.hintColor))
            else
              _buildShiftTable(grouped, df),
            const SizedBox(height: 12),
            Text("注意:",
                style: theme.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
                "シフトなし:スタッフが不足しているか、そのシフトに利用可能なスタッフがいないこと、スタフが希望日まだ記入してないことを意味します。",
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.hintColor)),
            const SizedBox(height: 20),
            Row(
              children: [
                OutlinedButton(
                    onPressed: _clearAutoShifts, child: const Text('クリア')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShiftTable(
      Map<String, Map<String, List<Map<String, dynamic>>>> grouped,
      DateFormat df) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columns: const [
          DataColumn(label: Text("日付")),
          DataColumn(label: Text("朝シフト（午前）")),
          DataColumn(label: Text("昼シフト（午後）")),
          DataColumn(label: Text("夜シフト（夜間）")),
        ],
        rows: List.generate(
          _autoEnd.difference(_autoStart).inDays + 1,
          (i) {
            final currentDate = _autoStart.add(Duration(days: i));
            final dateStr = currentDate.toIso8601String().split("T").first;
            final shifts = grouped[dateStr] ?? {};
            String formatNames(List<Map<String, dynamic>>? staffList) {
              if (staffList == null || staffList.isEmpty) return "シフトなし";
              return staffList.map((s) => s["Name"]).join(", ");
            }

            return DataRow(cells: [
              DataCell(Text(df.format(currentDate))),
              DataCell(Text(formatNames(shifts["morning"]))),
              DataCell(Text(formatNames(shifts["afternoon"]))),
              DataCell(Text(formatNames(shifts["night"]))),
            ]);
          },
        ),
      ),
    );
  }

  /// ⭐ UPDATED: Builds a shimmer placeholder that mimics the table structure.
  Widget _buildShimmerPlaceholder(ThemeData theme) {
    return Shimmer.fromColors(
      baseColor: theme.brightness == Brightness.light
          ? Colors.grey.shade300
          : Colors.grey.shade700,
      highlightColor: theme.brightness == Brightness.light
          ? Colors.grey.shade100
          : Colors.grey.shade500,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Table Header Simulation (to align data correctly)
          Padding(
            padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
            child: Row(
              children: [
                _buildShimmerCell(width: 80, height: 16), // Date Header
                const SizedBox(width: 20),
                _buildShimmerCell(width: 150, height: 16), // Shift 1 Header
                const SizedBox(width: 20),
                _buildShimmerCell(width: 150, height: 16), // Shift 2 Header
                const SizedBox(width: 20),
                _buildShimmerCell(width: 150, height: 16), // Shift 3 Header
              ],
            ),
          ),
          const Divider(height: 15, thickness: 1),
          
          // Table Rows Simulation (7 days)
          ...List.generate(7, (index) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10.0),
              child: Row(
                children: [
                  // Date Column (Fixed width)
                  _buildShimmerCell(width: 80, height: 14),
                  const SizedBox(width: 20),
                  // Shift 1 Column (Variable width for realism)
                  _buildShimmerCell(width: 100 + (index % 3) * 30.0, height: 14),
                  const SizedBox(width: 20),
                  // Shift 2 Column (Variable width for realism)
                  _buildShimmerCell(width: 120 + (index % 2) * 20.0, height: 14),
                  const SizedBox(width: 20),
                  // Shift 3 Column (Variable width for realism)
                  _buildShimmerCell(width: 80 + (index % 4) * 25.0, height: 14),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  /// Helper function for creating Shimmer cells
  Widget _buildShimmerCell({required double width, required double height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// --- SHARED HELPER WIDGET ---
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
          color: theme.colorScheme.surfaceContainerHighest,
          border: Border.all(color: theme.dividerColor),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, style: theme.textTheme.bodyMedium),
            const SizedBox(width: 6),
            Icon(Icons.calendar_today,
                size: 16, color: theme.colorScheme.primary),
          ],
        ),
      ),
    );
  }
}