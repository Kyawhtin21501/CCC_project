import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/api_services/api_services.dart';
import 'package:predictor_web/theme_provider/them.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/charts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _formKey = GlobalKey<FormState>();

  DateTime? _selectedDate;
  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController staffCountController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

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
    _loadStaffList();
    _loadChartData();
  }

  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      setState(() {
        availableStaffNames = staffList.map((e) => e.toString()).toList() ?? [];
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('スタッフリスト取得エラー: $e')),
      );
    }
  }

  Future<void> _loadChartData() async {
    try {
      final shiftData = await ApiService.fetchShiftTableDashboard();
      final salesData = await ApiService.getPredSales();

      setState(() {
        _shiftScheduleCache = shiftData;
        _salesDataCache = salesData;
      });
    } catch (e) {
      setState(() {
        error = e.toString();
      });
    }
  }

  Map<String, dynamic> _buildPayload() {
    return {
      "date": _selectedDate?.toIso8601String().split('T').first ?? '',
      "day": _selectedDate?.weekday.toString() ?? '',
      "event": festivalStatus == '1' ? "True" : "False",
      "customer_count": int.tryParse(customerController.text) ?? 0,
      "sales": int.tryParse(salesController.text) ?? 0,
      "staff_names": selectedStaffNames,
      "staff_count": int.tryParse(staffCountController.text) ?? 0,
    };
  }

  bool _validateStaffCountMatchesNames() {
    final enteredCount = int.tryParse(staffCountController.text) ?? 0;
    return enteredCount == selectedStaffNames.length;
  }

  Future<void> _saveDataAndRefresh() async {
    if (_formKey.currentState!.validate() &&
        _selectedDate != null &&
        festivalStatus != null) {
      if (!_validateStaffCountMatchesNames()) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('スタッフ数とスタッフ名の数が一致していません')),
        );
        return;
      }

      final payloadUserInput = _buildPayload();

      try {
        setState(() => _loading = true);
        final response = await ApiService.postUserInput(payloadUserInput);
        setState(() => _loading = false);

        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存エラー (${response.statusCode})')),
          );
          return;
        }

        _clearForm();
        await _loadChartData();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('データが保存され、最新シフトが取得されました')),
        );
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('通信エラー: $e')),
        );
      }
    }
  }

  void _clearForm() {
    setState(() {
      _selectedDate = null;
      salesController.clear();
      customerController.clear();
      staffCountController.clear();
      selectedStaffNames.clear();
      festivalStatus = null;
      dateController.clear();
    });
  }

  @override
  void dispose() {
    salesController.dispose();
    customerController.dispose();
    staffCountController.dispose();
    dateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context, listen: true);
    final isDarkMode = themeProvider?.themeMode == ThemeMode.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text("ダッシュボード"),
        actions: [
          if (themeProvider != null)
            IconButton(
              icon: Icon(isDarkMode ? Icons.light_mode : Icons.dark_mode),
              onPressed: () {
                themeProvider.toggleTheme(isDarkMode ? false : true);
              },
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // === Form + Sales Chart ===
                  screenWidth >= 1024
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildDashboardForm()),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 2,
                              child: _salesChartWidget(isDarkMode),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildDashboardForm(),
                            const SizedBox(height: 16),
                            _salesChartWidget(isDarkMode),
                          ],
                        ),

                  const SizedBox(height: 24),
                  if (error != null)
                    Text('Error: $error', style: const TextStyle(color: Colors.red)),
                  if (_shiftScheduleCache != null && _shiftScheduleCache!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: ShiftChartWidget(shiftSchedule: _shiftScheduleCache!),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _salesChartWidget(bool isDarkMode) {
    if (_salesDataCache == null || _salesDataCache!.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            children: [
              Text(
                "本日の予測売上",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                NumberFormat.currency(locale: 'ja_JP', symbol: '¥')
                    .format(_salesDataCache!.first['predicted_sales']),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: isDarkMode ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: SalesPredictionChartWidget(salesData: _salesDataCache!),
        ),
      ],
    );
  }

  Widget _buildDashboardForm() {
    final themeProvider = Provider.of<ThemeProvider?>(context, listen: false);
    final isDarkMode = themeProvider?.themeMode == ThemeMode.dark;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment_outlined, color: Colors.blue.shade600),
                  const SizedBox(width: 8),
                  Text(
                    "日報入力",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              LayoutBuilder(builder: (context, constraints) {
                int crossAxisCount = 1;
                if (constraints.maxWidth >= 1024) {
                  crossAxisCount = 3;
                } else if (constraints.maxWidth >= 600) {
                  crossAxisCount = 2;
                }
                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 2.2,
                  children: [
                    _buildDatePicker(isDarkMode),
                    _buildNumberField(salesController, '売上', isDarkMode),
                    _buildNumberField(customerController, '来客数', isDarkMode),
                    _buildNumberField(staffCountController, 'スタッフ数', isDarkMode),
                    _buildStaffMultiSelect(isDarkMode),
                    _buildEventDropdown(isDarkMode),
                  ],
                );
              }),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _clearForm,
                    icon: const Icon(Icons.clear),
                    label: const Text('クリア'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: _saveDataAndRefresh,
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text('保存して更新', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade600,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDatePicker(bool isDarkMode) {
    return _formFieldWrapper(
      label: "日付",
      child: TextFormField(
        controller: dateController,
        readOnly: true,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
          hintText: 'yyyy/mm/dd',
          suffixIcon: IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
              );
              if (date != null) {
                setState(() {
                  _selectedDate = date;
                  dateController.text = '${date.year}/${date.month}/${date.day}';
                });
              }
            },
          ),
        ),
        validator: (_) => _selectedDate == null ? '日付を選択してください' : null,
      ),
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, bool isDarkMode) {
    return _formFieldWrapper(
      label: label,
      child: TextFormField(
        controller: controller,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          hintText: '数値を入力してください',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '$label を入力してください';
          if (int.tryParse(value) == null) return '有効な数値を入力してください';
          return null;
        },
      ),
    );
  }

  Widget _buildStaffMultiSelect(bool isDarkMode) {
    return _formFieldWrapper(
      label: "スタッフ",
      child: MultiSelectDialogField<String>(
        items: availableStaffNames.map((name) => MultiSelectItem<String>(name, name)).toList(),
        title: const Text("スタッフ選択"),
        selectedColor: Colors.blueAccent,
        itemsTextStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
        buttonText: const Text("選択"),
        initialValue: selectedStaffNames,
        onConfirm: (values) {
          setState(() => selectedStaffNames = values);
        },
        chipDisplay: MultiSelectChipDisplay(
          chipColor: isDarkMode ? Colors.blue.shade700 : Colors.blue.shade200,
          textStyle: TextStyle(color: isDarkMode ? Colors.white : Colors.black),
          items: selectedStaffNames.map((name) => MultiSelectItem<String>(name, name)).toList(),
          onTap: (value) => setState(() => selectedStaffNames.remove(value)),
        ),
        validator: (values) => (values == null || values.isEmpty) ? 'スタッフを1人以上選択してください' : null,
      ),
    );
  }

  Widget _buildEventDropdown(bool isDarkMode) {
    return _formFieldWrapper(
      label: "イベント",
      child: DropdownButtonFormField<String>(
        value: festivalStatus,
        items: const [
          DropdownMenuItem(value: '1', child: Text('あり')),
          DropdownMenuItem(value: '0', child: Text('なし')),
        ],
        onChanged: (value) => setState(() => festivalStatus = value),
        validator: (value) => value == null ? 'イベントの有無を選択してください' : null,
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: isDarkMode ? Colors.grey.shade800 : Colors.grey.shade50,
        ),
      ),
    );
  }

  Widget _formFieldWrapper({required String label, required Widget child}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 5),
        child,
      ],
    );
  }
}
