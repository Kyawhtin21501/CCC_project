import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:predictor_web/widgets/responsiveCard.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/charts.dart';

/// --- ダミーデータ ---
const List<Map<String, dynamic>> _kDummySalesData = [
  {'date': '2025-12-01T00:00:00', 'actual_sales': 45000, 'predicted_sales': 48000},
  {'date': '2025-12-02T00:00:00', 'actual_sales': 52000, 'predicted_sales': 55000},
  {'date': '2025-12-03T00:00:00', 'actual_sales': 60000, 'predicted_sales': 58000},
  {'date': '2025-12-07T00:00:00', 'actual_sales': 75000, 'predicted_sales': 75000},
];

const List<Map<String, dynamic>> _kDummyShiftData = [
  {'date': '2025-12-15', 'shift': 'morning', 'Name': '佐藤'},
  {'date': '2025-12-15', 'shift': 'afternoon', 'Name': '田中'},
  {'date': '2025-12-21', 'shift': 'afternoon', 'Name': '田中'},
];

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
  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];
  String? festivalStatus;
  bool _loading = false;
  String? error;
  
  List<Map<String, dynamic>>? _shiftScheduleCache;
  List<Map<String, dynamic>>? _salesDataCache;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    setState(() => _loading = true);
    await Future.wait([
      _loadStaffList(),
      _loadChartData(),
    ]);
    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    salesController.dispose();
    customerController.dispose();
    dateController.dispose();
    super.dispose();
  }

  // --- API 連携ロジック ---

  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      final names = <String>[];

      for (final item in staffList) {
        if (item.containsKey('name')) {
          names.add(item['name'].toString());
        } else {
          names.add(item.toString());
        }
      }

      if (mounted) setState(() => availableStaffNames = names);
    } catch (e) {
      debugPrint("Staff load error: $e");
      if (mounted) {
        setState(() => availableStaffNames = ['佐藤 太郎', '田中 花子', '山本 健太', '中村 美咲']);
      }
    }
  }

  Future<void> _loadChartData() async {
    try {
      final shiftData = await ApiService.fetchShiftTableDashboard();
      final salesData = await ApiService.getPredSales();

      if (mounted) {
        setState(() {
          _shiftScheduleCache = shiftData.isNotEmpty ? shiftData : null;
          _salesDataCache = salesData.isNotEmpty ? salesData : null;
        });
      }
    } catch (e) {
      debugPrint("Chart load error: $e");
      if (mounted) setState(() => error = e.toString());
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      "date": _selectedDate != null ? _formatDateISO(_selectedDate!) : '',
      "day": _selectedDate?.weekday.toString() ?? '',
      "event": festivalStatus == '1' ? "True" : "False",
      "customer_count": int.tryParse(customerController.text) ?? 0,
      "sales": int.tryParse(salesController.text) ?? 0,
      "staff_names": selectedStaffNames,
      "staff_count": selectedStaffNames.length,
    };
  }

  Future<void> _saveDataAndRefresh() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || festivalStatus == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('日付とイベントを入力してください')));
      return;
    }

    try {
      setState(() => _loading = true);
      
      // ApiService internally checks for 200/201 and throws if fails
      await ApiService.postUserInput(_buildPayload());

      _clearForm();
      await _loadChartData(); // Refresh graphs after save

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('正常に保存されました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _clearForm() {
    setState(() {
      _selectedDate = null;
      salesController.clear();
      customerController.clear();
      dateController.clear();
      selectedStaffNames = [];
      festivalStatus = null;
    });
  }

  String _formatDateISO(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.dashboard),
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 96, left: 20, right: 20, bottom: 16),
                child: _loading 
                    ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
                    : ResponsiveBodyCard(
                        formCard: _buildCompactForm(context),
                        salesCard: _buildSalesCard(),
                        shiftCard: _buildShiftCard(),
                      ),
              ),
            ),
            Positioned(
              top: 28, left: 16, right: 16,
              child: CustomMenuBar(
                title: 'ダッシュボード',
                onMenuPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI Components ---

  Widget _buildSalesCard() {
    final List<Map<String, dynamic>> data = _salesDataCache ?? _kDummySalesData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("７日間売上予測", style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Theme.of(context).primaryColor)),
        if (_salesDataCache == null) const Text('※ デモデータを表示中', style: TextStyle(color: Colors.orange, fontSize: 10)),
        const SizedBox(height: 12),
        SizedBox(height: 300, child: SalesPredictionChartWidget(salesData: data)),
      ],
    );
  }

  Widget _buildShiftCard() {
    final List<Map<String, dynamic>> data = _shiftScheduleCache ?? _kDummyShiftData;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("最新のシフト状況", style: Theme.of(context).textTheme.titleLarge),
        if (_shiftScheduleCache == null) const Text('※ デモデータを表示中', style: TextStyle(color: Colors.orange, fontSize: 10)),
        const SizedBox(height: 12),
        ShiftChartWidget(shiftSchedule: data),
      ],
    );
  }

  Widget _buildCompactForm(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: Theme.of(context).primaryColor),
              const SizedBox(width: 8),
              const Text("日報入力フォーム", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          _buildIconField(context, salesController, '売上 (¥)', Icons.attach_money, true),
          const SizedBox(height: 16),
          _buildIconField(context, customerController, '来客数', Icons.person, true),
          const SizedBox(height: 16),
          _buildDatePickerInline(context),
          const SizedBox(height: 16),
          _buildEventDropdown(context),
          const SizedBox(height: 16),
          _buildStaffMultiSelect(context),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveDataAndRefresh,
              icon: const Icon(Icons.save),
              label: const Text("データを保存する"),
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconField(BuildContext context, TextEditingController ctrl, String label, IconData icon, bool isNum) {
    return TextFormField(
      controller: ctrl,
      keyboardType: isNum ? TextInputType.number : TextInputType.text,
      inputFormatters: isNum ? [FilteringTextInputFormatter.digitsOnly] : null,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (v) => (v == null || v.isEmpty) ? '$labelを入力してください' : null,
    );
  }

  Widget _buildDatePickerInline(BuildContext context) {
    return TextFormField(
      controller: dateController,
      readOnly: true,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.calendar_today), labelText: '日付', border: OutlineInputBorder()),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: DateTime.now(),
          firstDate: DateTime(2024),
          lastDate: DateTime(2030),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            dateController.text = _formatDateISO(date);
          });
        }
      },
    );
  }

  Widget _buildEventDropdown(BuildContext context) {
    return DropdownButtonFormField<String>(
      value: festivalStatus,
      decoration: const InputDecoration(prefixIcon: Icon(Icons.event), labelText: 'イベント', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: "1", child: Text("あり")),
        DropdownMenuItem(value: "0", child: Text("なし")),
      ],
      onChanged: (v) => setState(() => festivalStatus = v),
    );
  }

  Widget _buildStaffMultiSelect(BuildContext context) {
    return MultiSelectDialogField<String>(
      items: availableStaffNames.map((name) => MultiSelectItem(name, name)).toList(),
      initialValue: selectedStaffNames,
      buttonIcon: const Icon(Icons.group),
      buttonText: const Text("スタッフを選択"),
      onConfirm: (values) => setState(() => selectedStaffNames = values),
      decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
    );
  }
}