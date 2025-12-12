import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:provider/provider.dart';

import 'package:predictor_web/theme_provider/them.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/charts.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
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
        availableStaffNames = staffList.map((e) => e.toString()).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('スタッフリスト取得エラー: $e')));
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
      setState(() => error = e.toString());
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
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('スタッフ数と選択されたスタッフ名の人数が一致していません')));
        return;
      }
      final payload = _buildPayload();

      try {
        setState(() => _loading = true);
        final response = await ApiService.postUserInput(payload);
        setState(() => _loading = false);
        if (response.statusCode != 200) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('保存エラー: ${response.statusCode}')));
          return;
        }
        _clearForm();
        await _loadChartData();
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('データが保存されました')));
      } catch (e) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('通信エラー: $e')));
      }
    } else {
      _formKey.currentState!.validate();
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
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);
    final isDarkMode = themeProvider?.themeMode == ThemeMode.dark;

    return Scaffold(
      drawer: AppDrawer(currentScreen: DrawerScreen.dashboard),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(
                  top: 96, left: 20, right: 20, bottom: 16),
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _buildResponsiveBody(isDarkMode),
            ),
          ),

          Positioned(
            top: 28,
            left: 16,
            right: 16,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(12),
              color: isDarkMode ? Colors.grey.shade900 : Colors.blue.shade600,
              child: Container(
                height: 60,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: [
                    Builder(
                      builder: (context) => IconButton(
                        icon: const Icon(Icons.menu, color: Colors.white),
                        onPressed: () => Scaffold.of(context).openDrawer(),
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(isDarkMode ? Icons.dark_mode : Icons.light_mode,
                          color: Colors.white),
                      onPressed: () {
                        themeProvider?.toggleTheme(isDarkMode ? false : true);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveBody(bool isDarkMode) {
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;

      if (width >= 1000) {
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Flexible(
                  flex: 45,
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: _buildCompactForm(isDarkMode),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Flexible(
                  flex: 55,
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: _buildSalesCard(
                          isDarkMode, availableHeight: constraints.maxHeight * 0.6),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: _buildShiftCard(isDarkMode),
              ),
            ),
          ],
        );
      } else if (width >= 600) {
        return SingleChildScrollView(
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              SizedBox(
                width: width / 2 - 16,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildCompactForm(isDarkMode),
                  ),
                ),
              ),
              SizedBox(
                width: width / 2 - 16,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child:
                        _buildSalesCard(isDarkMode, availableHeight: 300),
                  ),
                ),
              ),
              SizedBox(
                width: width,
                child: Card(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 3,
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: _buildShiftCard(isDarkMode),
                  ),
                ),
              ),
            ],
          ),
        );
      } else {
        return SingleChildScrollView(
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _buildCompactForm(isDarkMode),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _buildSalesCard(isDarkMode, availableHeight: 260),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                elevation: 3,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: _buildShiftCard(isDarkMode),
                ),
              ),
            ],
          ),
        );
      }
    });
  }

  Widget _buildSalesCard(bool isDarkMode, {required double availableHeight}) {
    if (_salesDataCache == null || _salesDataCache!.isEmpty) {
      return SizedBox(
          height: 240, child: Center(child: Text('売上予測データがありません')));
    }
    final perChart = math.max(220.0, (availableHeight - 40));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("７日間売上予測",
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.blue.shade700)),
        const SizedBox(height: 12),
        SizedBox(height: perChart, child: SalesPredictionChartWidget(salesData: _salesDataCache!)),
      ],
    );
  }

  Widget _buildShiftCard(bool isDarkMode) {
    if (_shiftScheduleCache == null || _shiftScheduleCache!.isEmpty) {
      return SizedBox(height: 240, child: Center(child: Text('シフトデータがありません')));
    }
    return ShiftChartWidget(shiftSchedule: _shiftScheduleCache!);
  }

  Widget _buildCompactForm(bool isDarkMode) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.assignment_outlined, color: Colors.blue.shade600),
              const SizedBox(width: 8),
              Text("日報入力フォーム",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(builder: (context, constraints) {
            final isWide = constraints.maxWidth > 420;
            return isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                          child: _buildIconField(
                              controller: salesController,
                              label: '売上',
                              hint: '¥',
                              icon: Icons.attach_money,
                              validatorMsg: '売上を入力してください')),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildIconField(
                              controller: customerController,
                              label: '来客数',
                              hint: '',
                              icon: Icons.person,
                              validatorMsg: '来客数を入力してください',
                              numberOnly: true)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: _buildIconField(
                              controller: staffCountController,
                              label: 'スタッフ数',
                              hint: '',
                              icon: Icons.people,
                              validatorMsg: 'スタッフ数を入力してください',
                              numberOnly: true)),
                    ],
                  )
                : Column(
                    children: [
                      _buildIconField(
                          controller: salesController,
                          label: '売上',
                          hint: '¥',
                          icon: Icons.attach_money,
                          validatorMsg: '売上を入力してください'),
                      const SizedBox(height: 8),
                      _buildIconField(
                          controller: customerController,
                          label: '来客数',
                          hint: '',
                          icon: Icons.person,
                          validatorMsg: '来客数を入力してください',
                          numberOnly: true),
                      const SizedBox(height: 8),
                      _buildIconField(
                          controller: staffCountController,
                          label: 'スタッフ数',
                          hint: '',
                          icon: Icons.people,
                          validatorMsg: 'スタッフ数を入力してください',
                          numberOnly: true),
                    ],
                  );
          }),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: [
              SizedBox(width: 180, child: _buildDatePickerInline()),
              SizedBox(width: 140, child: _buildEventDropdown(isDarkMode)),
            ],
          ),
          const SizedBox(height: 12),
          _buildStaffMultiSelect(isDarkMode),
          const SizedBox(height: 12),
          Row(
            children: [
              const Spacer(),
              GestureDetector(
                onTap: _saveDataAndRefresh,
                child: Container(
                  height: 44,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade600,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 4))
                    ],
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.save, color: Colors.white),
                      SizedBox(width: 8),
                      Text('保存',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIconField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String validatorMsg,
    bool numberOnly = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: numberOnly ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        prefixIcon: Icon(icon),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return validatorMsg;
        if (numberOnly && int.tryParse(v) == null) return '数値を入力してください';
        return null;
      },
    );
  }

  Widget _buildDatePickerInline() {
    return TextFormField(
      controller: dateController,
      readOnly: true,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.calendar_today),
        labelText: '日付',
        hintText: 'yyyy/mm/dd',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDate: _selectedDate ?? DateTime.now(),
        );
        if (date != null) {
          setState(() {
            _selectedDate = date;
            dateController.text = '${date.year}/${date.month}/${date.day}';
          });
        }
      },
      validator: (_) => _selectedDate == null ? "日付を選択してください" : null,
    );
  }

  Widget _buildEventDropdown(bool isDarkMode) {
    return DropdownButtonFormField<String>(
      value: festivalStatus,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.event),
        labelText: 'イベント（祭り）',
        filled: true,
        fillColor: Colors.grey.shade50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: const [
        DropdownMenuItem(value: "1", child: Text("あり")),
        DropdownMenuItem(value: "0", child: Text("なし")),
      ],
      onChanged: (v) => setState(() => festivalStatus = v),
      validator: (v) => v == null ? "選択してください" : null,
    );
  }

  Widget _buildStaffMultiSelect(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MultiSelectDialogField(
          items: availableStaffNames
              .map((name) => MultiSelectItem(name, name))
              .toList(),
          initialValue: selectedStaffNames,
          title: const Text('スタッフ選択'),
          buttonText: const Text('スタッフ'),
          onConfirm: (values) =>
              setState(() => selectedStaffNames = values.cast<String>()),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.black26),
          ),
        ),
      ],
    );
  }
}
