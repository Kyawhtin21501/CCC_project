import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:predictor_web/widgets/responsiveCard.dart';
import 'package:predictor_web/widgets/charts.dart';

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
      _shiftScheduleCache = await ApiService.fetchShiftTableDashboard();
    } catch (_) {}
  }

  // ✅ FIXED PAYLOAD (day added)
  Map<String, dynamic> _buildPayload() {
    return {
      "date": _formatDateISO(_selectedDate!),

      // 🔥 REQUIRED BY FLASK (KeyError FIX)
      "day": DateFormat('EEEE').format(_selectedDate!), // Monday, Tuesday...

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
        festivalStatus == null) {
      return;
    }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.dashboard),
      body: Stack(
        children: [
          Positioned.fill(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(
                top: 96,
                left: 20,
                right: 20,
                bottom: 20,
              ),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : ResponsiveBodyCard(
                      formCard: _buildForm(),
                      salesCard: SalesPredictionChartWidget(
                        salesData: _salesDataCache,
                      ),
                      dailyReportCard: _buildDailyReportCard(),
                    ),
            ),
          ),

          /// FIXED MENU BAR
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
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveDailyReport,
              child: const Text("保存"),
            ),
          )
        ],
      ),
    );
  }

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

  Widget _staffSelect() {
    return MultiSelectDialogField<String>(
      items: availableStaffNames
          .map((e) => MultiSelectItem<String>(e, e))
          .toList(),
      onConfirm: (values) {
        selectedStaffNames = values.cast<String>();
      },
      title: const Text("スタッフ"),
      buttonText: const Text("スタッフ選択"),
    );
  }
}
