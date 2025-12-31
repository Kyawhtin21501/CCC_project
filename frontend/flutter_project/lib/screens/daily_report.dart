import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:predictor_web/widgets/responsiveCard.dart';
import 'package:predictor_web/widgets/charts.dart';
import 'package:predictor_web/widgets/todayshift.dart';

/// [DashboardScreen] is the primary landing page of the application.
/// It serves three main purposes:
/// 1. Data Entry: Inputting daily sales and staff reports.
/// 2. Visualization: Displaying sales prediction charts.
/// 3. Information: Showing today's shift schedule and the most recent report.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // Form key for validation of sales/customer inputs
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // Controllers for text input fields
  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // State variables for form selection
  DateTime? _selectedDate;
  String? festivalStatus; // Managed as String "1" or "0" for the dropdown
  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];

  // Global loading state to trigger the CircularProgressIndicator
  bool _loading = false;

  // Local caches to prevent redundant API calls and handle UI rendering
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
    // Clean up controllers to prevent memory leaks
    salesController.dispose();
    customerController.dispose();
    dateController.dispose();
    super.dispose();
  }

  /// Orchestrates the initial data fetch for the dashboard.
  /// Uses [Future.wait] to run requests in parallel for better performance.
  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadStaffList(),
      _loadDailyReports(),
      _loadChartData(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  /// Fetches staff names for the MultiSelect dropdown.
  /// Fallback provided for development/offline mode.
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

  /// Prepares the data object for the POST request.
  /// [day] is derived from [_selectedDate] to satisfy backend requirements.
  Map<String, dynamic> _buildPayload() {
    return {
      "date": _formatDateISO(_selectedDate!),
      "day": DateFormat('EEEE').format(_selectedDate!), // e.g., "Monday"
      "event": festivalStatus == '1',
      "customer_count": int.parse(customerController.text),
      "sales": double.parse(salesController.text),
      "staff_names": selectedStaffNames,
      "staff_count": selectedStaffNames.length,
    };
  }

  /// Validates and submits the daily report form.
  /// On success, it refreshes the dashboard data and clears the form.
  Future<void> _saveDailyReport() async {
    if (!_formKey.currentState!.validate() ||
        _selectedDate == null ||
        festivalStatus == null) {
      // Logic could be added here to show a SnackBar for missing selections
      return;
    }

    setState(() => _loading = true);

    await ApiService.postUserInput(_buildPayload());
    await _loadInitialData(); // Refresh UI with new data
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

  /// Standardizes date formatting for API compatibility (YYYY-MM-DD)
  String _formatDateISO(DateTime d) =>
      "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.dashboard),
      body: Stack(
        children: [
          // Main Content Area
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(top: 96, left: 20, right: 20, bottom: 20),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ResponsiveBodyCard(
                      // Custom widget handling layout for desktop/mobile
                      formCard: _buildForm(),
                      salesCard: SalesPredictionChartWidget(
                        salesData: _salesDataCache,
                      ),
                      dailyReportCard: _buildDailyReportCard(),
                      shiftCard: TodayShiftCard(
                        shifts: _shiftScheduleCache,
                      ),
                    ),
            ),
          ),

          /// Floating Menu Bar
          /// Positioned independently to maintain visibility during scroll
          Positioned(
            top: 28,
            left: 16,
            right: 16,
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

  /// Renders a summary card showing the most recently submitted data.
  Widget _buildDailyReportCard() {
    if (_dailyReportCache.isEmpty) {
      return const Center(child: Text("日報データなし"));
    }

    final latest = _dailyReportCache.last;
    final bool hasEvent = latest['event'] == true || latest['event'] == 1;
    final List<String> staffNames =
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
          children: staffNames.map((s) => Chip(label: Text(s))).toList(),
        )
      ],
    );
  }

  /// Helper for consistent key-value pair rows
  Widget _infoRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value.toString())),
        ],
      ),
    );
  }

  /// Builds the data entry form
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

  /// Custom button using Theme colors to ensure contrast across Dark/Light modes
  Widget _submitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _saveDailyReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 2,
        ),
        child: const Text(
          "保存",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2),
        ),
      ),
    );
  }

  /// Reusable numeric input with strict formatters (integers vs decimals)
  Widget _numberField(
    TextEditingController c,
    String label,
    IconData icon, {
    bool integer = false,
  }) {
    return TextFormField(
      controller: c,
      keyboardType: TextInputType.numberWithOptions(decimal: !integer),
      inputFormatters: [
        FilteringTextInputFormatter.allow(
          RegExp(integer ? r'[0-9]' : r'[0-9.]'),
        )
      ],
      validator: (v) => v == null || v.isEmpty ? "必須項目です" : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  /// Date picker field; readOnly ensures users must use the calendar dialog
  Widget _datePicker() {
    return TextFormField(
      controller: dateController,
      readOnly: true,
      decoration: const InputDecoration(
        labelText: "日付",
        prefixIcon: Icon(Icons.calendar_today),
        border: OutlineInputBorder(),
      ),
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
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

  Widget _eventDropdown() {
    return DropdownButtonFormField<String>(
      decoration: const InputDecoration(
        labelText: "イベント",
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: "1", child: Text("あり")),
        DropdownMenuItem(value: "0", child: Text("なし")),
      ],
      onChanged: (v) => festivalStatus = v,
      validator: (v) => v == null ? "選択してください" : null,
    );
  }

  /// Multi-select logic for staff members
  /// Styled to match the app's custom color scheme (primaryContainer/surface)
  Widget _staffSelect() {
    final theme = Theme.of(context);

    return MultiSelectDialogField<String>(
      items: availableStaffNames.map((e) => MultiSelectItem<String>(e, e)).toList(),
      title: Text("スタッフ選択", style: TextStyle(color: theme.colorScheme.onSurface)),
      backgroundColor: theme.colorScheme.surface,
      selectedColor: theme.colorScheme.primary,
      checkColor: theme.colorScheme.onPrimary,
      itemsTextStyle: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
      selectedItemsTextStyle: TextStyle(color: theme.colorScheme.primary, fontWeight: FontWeight.bold),
      buttonText: Text(
        "スタッフを選択してください",
        style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.7), fontSize: 16),
      ),
      buttonIcon: Icon(Icons.person_add, color: theme.colorScheme.primary),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor, width: 1),
      ),
      onConfirm: (values) {
        setState(() {
          selectedStaffNames = values.cast<String>();
        });
      },
      chipDisplay: MultiSelectChipDisplay(
        textStyle: TextStyle(color: theme.colorScheme.onPrimaryContainer),
        chipColor: theme.colorScheme.primaryContainer,
      ),
    );
  }
}