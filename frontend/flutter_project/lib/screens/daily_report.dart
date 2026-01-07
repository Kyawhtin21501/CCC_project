import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';

import 'package:omakase_shift/services/api_services.dart';
import 'package:omakase_shift/widgets/appdrawer.dart';
import 'package:omakase_shift/widgets/custom_menubar.dart';
import 'package:omakase_shift/widgets/responsiveCard.dart';
import 'package:omakase_shift/widgets/charts.dart';
import 'package:omakase_shift/widgets/todayshift.dart';

/// ------------------------------------------------------------
/// RESPONSIVE HELPER
/// ------------------------------------------------------------
class Responsive {
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;
}

/// ------------------------------------------------------------
/// DASHBOARD SCREEN
/// ------------------------------------------------------------
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  DateTime? _selectedDate;
  String? festivalStatus;

  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];

  bool _loading = false;

  List<Map<String, dynamic>> _dailyReportCache = [];
  List<Map<String, dynamic>> _salesDataCache = [];
  List<Map<String, dynamic>> _shiftScheduleCache = [];

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    salesController.dispose();
    customerController.dispose();
    dateController.dispose();
    super.dispose();
  }

  /// ------------------------------------------------------------
  /// DATA LOADING
  /// ------------------------------------------------------------
  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadStaffList(),
      _loadDailyReports(),
      _loadChartData(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      availableStaffNames =
          staffList.map<String>((e) => e['name'].toString()).toList();
    } catch (_) {
      availableStaffNames = ['佐藤', '田中', '山本', '中村'];
    }
  }

  Future<void> _loadDailyReports() async {
    try {
      _dailyReportCache = await ApiService.fetchDailyReports();
    } catch (_) {}
  }

  Future<void> _loadChartData() async {
    try {
      _salesDataCache = await ApiService.fetchPredSalesOneWeek();
      _shiftScheduleCache = await ApiService.fetchTodayShiftAssignment();
    } catch (_) {}
  }

  /// ------------------------------------------------------------
  /// FORM SUBMISSION
  /// ------------------------------------------------------------
  Map<String, dynamic> _buildPayload() {
    return {
      "date": _formatDateISO(_selectedDate!),
      "day": DateFormat('EEEE').format(_selectedDate!),
      "event": festivalStatus == '1',
      "customer_count": int.parse(customerController.text),
      "sales": double.parse(salesController.text),
      "staff_names": selectedStaffNames,
      "staff_count": selectedStaffNames.length,
    };
  }

  Future<void> _saveDailyReport() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        festivalStatus == null) return;

    setState(() => _loading = true);
    await ApiService.postUserInput(_buildPayload());
    await _loadInitialData();
    _clearForm();
    setState(() => _loading = false);
  }

  void _clearForm() {
    salesController.clear();
    customerController.clear();
    dateController.clear();
    selectedStaffNames.clear();
    festivalStatus = null;
    _selectedDate = null;
  }

  String _formatDateISO(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  /// ------------------------------------------------------------
  /// UI
  /// ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.dashboard),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                top: isMobile ? 88 : 96,
                left: isMobile ? 12 : 20,
                right: isMobile ? 12 : 20,
                bottom: 20,
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ResponsiveBodyCard(
                      formCard: _buildForm(),
                      salesCard:
                          SalesPredictionChartWidget(salesData: _salesDataCache),
                      dailyReportCard: _buildDailyReportCard(),
                      shiftCard:
                          TodayShiftCard(shifts: _shiftScheduleCache),
                    ),
            ),
          ),

          /// Floating Menu Bar
          Positioned(
            top: 28,
            left: Responsive.isDesktop(context) ? 48 : 16,
            right: Responsive.isDesktop(context) ? 48 : 16,
            child: Builder(
              builder: (scaffoldContext) {
                return CustomMenuBar(
                  title: 'ダッシュボード',
                  onMenuPressed: () {
                    Scaffold.of(scaffoldContext).openDrawer();
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ------------------------------------------------------------
  /// DAILY REPORT CARD
  /// ------------------------------------------------------------
  Widget _buildDailyReportCard() {
    if (_dailyReportCache.isEmpty) {
      return const Center(child: Text("日報データなし"));
    }

    final latest = _dailyReportCache.last;
    final hasEvent = latest['event'] == true || latest['event'] == 1;
    final staffNames =
        (latest['staff_names'] as List?)?.map((e) => e.toString()).toList() ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("最新の日報", style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        _infoRow("日付", latest['date']),
        _infoRow("曜日", latest['day']),
        _infoRow("売上", "¥${latest['sales']}"),
        _infoRow("来客数", latest['customer_count']),
        _infoRow("スタッフ数", latest['staff_count']),
        _infoRow("イベント", hasEvent ? "あり" : "なし"),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: staffNames
              .map((s) => Chip(
                    label: Text(
                      s,
                      style: TextStyle(
                        fontSize:
                            Responsive.isMobile(context) ? 12 : 13,
                      ),
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }

  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }

 /// ------------------------------------------------------------
/// FORM
/// ------------------------------------------------------------
Widget _buildForm() {
  return Form(
    key: _formKey,
    child: Column(
      children: [
        _numberField(salesController, "売上", Icons.attach_money),
        const SizedBox(height: 12),
        _numberField(
          customerController,
          "来客数",
          Icons.person,
          integer: true,
        ),
        const SizedBox(height: 12),
        _datePicker(),
        const SizedBox(height: 12),
        _eventDropdown(),
        const SizedBox(height: 12),
        _staffSelect(),
        const SizedBox(height: 20),
        _submitButton(),
      ],
    ),
  );
}

/// ------------------------------------------------------------
/// SUBMIT BUTTON
/// ------------------------------------------------------------
Widget _submitButton() {
  final theme = Theme.of(context);

  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      onPressed: _saveDailyReport,
      style: ElevatedButton.styleFrom(
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Text(
        "保存",
        style: TextStyle(
          fontSize: Responsive.isMobile(context) ? 16 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}

/// ------------------------------------------------------------
/// NUMBER FIELD (Sales / Customers)
/// ------------------------------------------------------------
Widget _numberField(
  TextEditingController c,
  String label,
  IconData icon, {
  bool integer = false,
}) {
  final theme = Theme.of(context);

  return TextFormField(
    controller: c,
    keyboardType: TextInputType.numberWithOptions(decimal: !integer),
    inputFormatters: [
      FilteringTextInputFormatter.allow(
        RegExp(integer ? r'[0-9]' : r'[0-9.]'),
      ),
    ],
    validator: (v) => v == null || v.isEmpty ? "必須項目です" : null,
    style: TextStyle(color: theme.colorScheme.onSurface),
    decoration: InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: theme.colorScheme.primary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  );
}

/// ------------------------------------------------------------
/// DATE PICKER
/// ------------------------------------------------------------
Widget _datePicker() {
  final theme = Theme.of(context);

  return TextFormField(
    controller: dateController,
    readOnly: true,
    style: TextStyle(color: theme.colorScheme.onSurface),
    decoration: InputDecoration(
      labelText: "日付",
      prefixIcon: Icon(
        Icons.calendar_today,
        color: theme.colorScheme.primary,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    onTap: () async {
      final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2024),
        lastDate: DateTime(2030),
        builder: (context, child) {
          return Theme(
            data: theme,
            child: child!,
          );
        },
      );

      if (d != null) {
        setState(() {
          _selectedDate = d;
          dateController.text = _formatDateISO(d);
        });
      }
    },
  );
}

/// ------------------------------------------------------------
/// EVENT DROPDOWN
/// ------------------------------------------------------------
Widget _eventDropdown() {
  final theme = Theme.of(context);

  return DropdownButtonFormField<String>(
    value: festivalStatus,
    style: TextStyle(
      color: theme.colorScheme.onSurface, // selected value text
      fontSize: 16,
    ),
    decoration: InputDecoration(
      labelText: "イベント",
      labelStyle: TextStyle(color: theme.colorScheme.onSurface),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
    dropdownColor: theme.colorScheme.surface,
    iconEnabledColor: theme.colorScheme.primary,
    items: [
      DropdownMenuItem(
        value: "1",
        child: Text(
          "あり",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
      DropdownMenuItem(
        value: "0",
        child: Text(
          "なし",
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
      ),
    ],
    onChanged: (v) => setState(() => festivalStatus = v),
    validator: (v) => v == null ? "選択してください" : null,
  );
}


/// ------------------------------------------------------------
/// RESPONSIVE STAFF SELECT (Light & Dark Safe)
/// ------------------------------------------------------------
Widget _staffSelect() {
  final theme = Theme.of(context);
  final isMobile = Responsive.isMobile(context);

  return ConstrainedBox(
    constraints: BoxConstraints(
      maxWidth: isMobile ? double.infinity : 520,
    ),
    child: MultiSelectDialogField<String>(
      items: availableStaffNames
          .map((e) => MultiSelectItem<String>(e, e))
          .toList(),

      // Dialog title
      title: Text(
        "スタッフ選択",
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: isMobile ? 16 : 18,
          fontWeight: FontWeight.bold,
        ),
      ),

      // Button text
      buttonText: Text(
        selectedStaffNames.isEmpty
            ? (isMobile ? "スタッフ選択" : "スタッフを選択してください")
            : "選択中：${selectedStaffNames.length}名",
        style: TextStyle(color: theme.colorScheme.onSurface),
      ),

      buttonIcon: Icon(
        Icons.person_add,
        color: theme.colorScheme.primary,
      ),

      // Dialog background
      backgroundColor: theme.colorScheme.surface,

      // List item text (VERY IMPORTANT)
      itemsTextStyle: TextStyle(
        color: theme.colorScheme.onSurface,
        fontSize: 15,
      ),

      // Selected list item text
      selectedItemsTextStyle: TextStyle(
        color: theme.colorScheme.primary,
        fontWeight: FontWeight.bold,
      ),

      selectedColor: theme.colorScheme.primary,

      onConfirm: (values) {
        setState(() {
          selectedStaffNames = values.cast<String>();
        });
      },

      // Selected chips
      chipDisplay: MultiSelectChipDisplay(
        textStyle: TextStyle(
          color: theme.colorScheme.onPrimary,
        ),
        chipColor: theme.colorScheme.primary,
      ),

      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
    ),
  );
}

}