import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:predictor_web/widgets/responsiveCard.dart';
import 'package:provider/provider.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/theme_provider/them.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/charts.dart';

/// A stateful widget representing the main application dashboard.
/// It displays data input forms, sales prediction charts, and staff shift schedules.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];
  String? festivalStatus;
  bool _loading = false;
  String? error;
  List<Map<String, dynamic>>? _shiftScheduleCache;
  List<Map<String, dynamic>>? _salesDataCache;

  /// Initializes the state by loading the staff list and chart data.
  @override
  void initState() {
    super.initState();
    _loadStaffList();
    _loadChartData();
  }

  /// Disposes of the TextEditingControllers to prevent memory leaks.
  @override
  void dispose() {
    salesController.dispose();
    customerController.dispose();
    dateController.dispose();
    super.dispose();
  }

  /// Fetches the list of available staff names from the API.
  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      final names = <String>[];

      if (staffList is List) {
        for (final item in staffList) {
          if (item is String) {
            names.add(item as String);
          } else if (item is Map && item.containsKey('name')) {
            names.add(item['name'].toString());
          } else {
            names.add(item.toString());
          }
        }
      }

      if (mounted) setState(() => availableStaffNames = names);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('スタッフリスト取得エラー: $e')));
      }
    }
  }

  /// Fetches sales prediction and shift schedule data for the dashboard charts.
  Future<void> _loadChartData() async {
    try {
      final shiftData = await ApiService.fetchShiftTableDashboard();
      final salesData = await ApiService.getPredSales();

      setState(() {
        _shiftScheduleCache = (shiftData is List)
            ? List<Map<String, dynamic>>.from(
                shiftData.cast<Map<String, dynamic>>())
            : null;

        _salesDataCache = (salesData is List)
            ? List<Map<String, dynamic>>.from(
                salesData.cast<Map<String, dynamic>>())
            : null;
      });
    } catch (e) {
      setState(() => error = e.toString());
    }
  }

  /// Constructs the payload map for the API request using current form state.
  /// Staff count is automatically derived from the `selectedStaffNames` list length.
  Map<String, dynamic> _buildPayload() {
    final dayNumber = _selectedDate?.weekday;
    return {
      "date": _selectedDate != null ? _formatDateISO(_selectedDate!) : '',
      "day": dayNumber?.toString() ?? '',
      "event": festivalStatus == '1' ? "True" : "False",
      "customer_count": int.tryParse(customerController.text) ?? 0,
      "sales": int.tryParse(salesController.text) ?? 0,
      "staff_names": selectedStaffNames,
      "staff_count": selectedStaffNames.length,
    };
  }

  /// Validates the form, posts the data to the API, and refreshes the charts.
  Future<void> _saveDataAndRefresh() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('日付を選択してください')));
      return;
    }

    if (festivalStatus == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('イベントを選択してください')));
      return;
    }

    final payload = _buildPayload();

    try {
      setState(() => _loading = true);
      final response = await ApiService.postUserInput(payload);
      setState(() => _loading = false);

      if (response == null ||
          response.statusCode! < 200 ||
          response.statusCode! >= 300) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('保存エラー: ${response?.statusCode ?? '不明'}')));
        return;
      }

      _clearForm();
      await _loadChartData();

      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('保存されました')));
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('通信エラー: $e')));
    }
  }

  /// Clears all input fields and resets the form state.
  void _clearForm() {
    setState(() {
      _selectedDate = null;
      salesController.clear();
      customerController.clear();
      selectedStaffNames = [];
      festivalStatus = null;
      dateController.clear();
    });
  }

  /// Formats a DateTime object into a standard ISO date string (YYYY-MM-DD).
  String _formatDateISO(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider?>(context);

    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.dashboard),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.only(
                    top: 96, left: 20, right: 20, bottom: 16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ResponsiveBodyCard(
                        formCard: _buildCompactForm(context),
                        salesCard: _buildSalesCard(
                          availableHeight:
                              MediaQuery.of(context).size.height * 0.5,
                        ),
                        shiftCard: _buildShiftCard(),
                      ),
              ),
            ),
            Positioned(
              top: 28,
              left: 16,
              right: 16,
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

  /// Builds KPI cards displaying key metrics (sales, prediction, customer count).
  /// Uses Theme colors for background and accents.
  Widget _buildKPIs() {
    final Color accentColor = Theme.of(context).colorScheme.primary;

    final List<Map<String, dynamic>> kpis = [
      {
        'label': '本日の売上',
        'value': '¥55,000',
        'icon': Icons.trending_up,
        'color': Colors.green.shade700,
      },
      {
        'label': '明日予測',
        'value': '¥62,000',
        'icon': Icons.lightbulb_outline,
        'color': accentColor,
      },
      {
        'label': '来客数(本日)',
        'value': '125',
        'icon': Icons.person,
        'color': Colors.red.shade700,
      },
    ];

    return Wrap(
      spacing: 16.0,
      runSpacing: 16.0,
      children: kpis.map((kpi) {
        return Card(
          margin: EdgeInsets.zero,
          elevation: 0.5,
          color: Theme.of(context).cardColor,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(kpi['icon'] as IconData,
                        color: kpi['color'] as Color, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      kpi['label'] as String,
                      style: Theme.of(context).textTheme.labelLarge!.copyWith(
                            fontSize: 13,
                            color: kpi['color'] as Color,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  kpi['value'] as String,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontSize: 24,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Builds the card containing the KPI display and the sales prediction chart.
  Widget _buildSalesCard({required double availableHeight}) {
    if (_salesDataCache == null || _salesDataCache!.isEmpty) {
      return const SizedBox(
        height: 240,
        child: Center(child: Text('売上予測データがありません')),
      );
    }

    final perChart = math.max(220.0, (availableHeight - 40));
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildKPIs(),
        const SizedBox(height: 24),
        Text(
          "７日間売上予測",
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 20,
              color: primaryColor),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: perChart,
          child: SalesPredictionChartWidget(salesData: _salesDataCache!),
        ),
      ],
    );
  }

  /// Builds the card displaying the shift schedule or an empty state message.
  Widget _buildShiftCard() {
    if (_shiftScheduleCache == null || _shiftScheduleCache!.isEmpty) {
      return SizedBox(
        height: 240,
        child: Center(
            child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_today_outlined,
                size: 40,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3)),
            const SizedBox(height: 10),
            Text('シフトデータがありません',
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 5),
            Text('シフト管理画面でデータを入力してください',
                style: Theme.of(context).textTheme.bodySmall),
          ],
        )),
      );
    }
    return ShiftChartWidget(shiftSchedule: _shiftScheduleCache!);
  }

  /// Displays the current number of selected staff, automatically calculated.
  Widget _buildStaffCountDisplay() {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color borderColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.1);

    return Container(
      height: 65,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'スタッフ数 (自動計算)',
            style: Theme.of(context).textTheme.labelSmall!.copyWith(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withOpacity(0.6),
                ),
          ),
          
          Text(
            '${selectedStaffNames.length} 名',
            style: Theme.of(context).textTheme.titleMedium!.copyWith(
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
          ),
        ],
      ),
    );
  }

  /// Builds the compact, responsive data input form.
  Widget _buildCompactForm(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.assignment_outlined, color: primaryColor),
                  const SizedBox(width: 8),
                  Text(
                    "日報入力フォーム",
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: onSurfaceColor,
                        ),
                  ),
                  const Spacer(),
                ],
              ),
              const SizedBox(height: 24),

              /// Input Fields (Sales, Customer Count, Staff Count)
              LayoutBuilder(
                builder: (context, constraints) {
                  final isWide = constraints.maxWidth > 420;

                  return isWide
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: _buildIconField(
                                context: context,
                                controller: salesController,
                                label: '売上 (¥)',
                                hint: '0',
                                icon: Icons.attach_money,
                                validatorMsg: '売上を入力してください',
                                numberOnly: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildIconField(
                                context: context,
                                controller: customerController,
                                label: '来客数',
                                hint: '0',
                                icon: Icons.person,
                                validatorMsg: '来客数を入力してください',
                                numberOnly: true,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildStaffCountDisplay(),
                            ),
                          ],
                        )
                      : Column(
                          children: [
                            _buildIconField(
                              context: context,
                              controller: salesController,
                              label: '売上 (¥)',
                              hint: '0',
                              icon: Icons.attach_money,
                              validatorMsg: '売上を入力してください',
                              numberOnly: true,
                            ),
                            const SizedBox(height: 16),
                            _buildIconField(
                              context: context,
                              controller: customerController,
                              label: '来客数',
                              hint: '0',
                              icon: Icons.person,
                              validatorMsg: '来客数を入力してください',
                              numberOnly: true,
                            ),
                            const SizedBox(height: 16),
                            _buildStaffCountDisplay(),
                          ],
                        );
                },
              ),

              const SizedBox(height: 24),

              /// Date and Event inputs (Grouped)
              Wrap(
                spacing: 16,
                runSpacing: 16,
                children: [
                  SizedBox(width: 200, child: _buildDatePickerInline(context)),
                  SizedBox(width: 180, child: _buildEventDropdown(context)),
                ],
              ),

              const SizedBox(height: 24),

              /// Staff Multi-Select
              _buildStaffMultiSelect(context),

              const SizedBox(height: 32),

              /// Save Button
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: _saveDataAndRefresh,
                    child: Container(
                      height: 48,
                      padding: const EdgeInsets.symmetric(horizontal: 28),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.save, color: Colors.white),
                          const SizedBox(width: 12),
                          Text(
                            '保存',
                            style: Theme.of(context)
                                .textTheme
                                .labelLarge!
                                .copyWith(color: Colors.white, fontSize: 16),
                          ),
                        ],
                      ),
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

  /// Builds a standard TextFormField, styled using Theme colors for consistency.
  Widget _buildIconField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required String validatorMsg,
    bool numberOnly = false,
  }) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color borderColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.1);

    return TextFormField(
      controller: controller,
      keyboardType: numberOnly ? TextInputType.number : TextInputType.text,
      style: TextStyle(color: onSurfaceColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryColor),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.red, width: 1.0),
        ),
      ),
      validator: (v) {
        if (v == null || v.isEmpty) return validatorMsg;
        if (numberOnly && int.tryParse(v) == null) {
          return '数値を入力してください';
        }
        return null;
      },
    );
  }

  /// Builds a date picker input field, styled using Theme colors.
  Widget _buildDatePickerInline(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color borderColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.1);

    return TextFormField(
      controller: dateController,
      readOnly: true,
      style: TextStyle(color: onSurfaceColor),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.calendar_today, color: primaryColor),
        labelText: '日付',
        hintText: 'yyyy/mm/dd',
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
      ),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          firstDate: DateTime(2020),
          lastDate: DateTime(2030),
          initialDate: _selectedDate ?? DateTime.now(),
          builder: (context, child) {
            return Theme(
              data: Theme.of(context),
              child: child!,
            );
          },
        );

        if (date != null) {
          setState(() {
            _selectedDate = date;
            dateController.text = '${date.year}/${date.month}/${date.day}';
          });
        }
      },
      validator: (_) =>
          _selectedDate == null ? "日付を選択してください" : null,
    );
  }

  /// Builds the event status dropdown menu, styled using Theme colors.
  Widget _buildEventDropdown(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;
    final Color borderColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.1);

    return DropdownButtonFormField<String>(
      value: festivalStatus,
      style: TextStyle(color: onSurfaceColor),
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.event, color: primaryColor),
        labelText: 'イベント（祭り）',
        filled: true,
        fillColor: surfaceColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 2.0),
        ),
      ),
      items: [
        DropdownMenuItem(
            value: "1",
            child: Text("あり", style: TextStyle(color: onSurfaceColor))),
        DropdownMenuItem(
            value: "0",
            child: Text("なし", style: TextStyle(color: onSurfaceColor))),
      ],
      onChanged: (v) => setState(() => festivalStatus = v),
      validator: (v) => v == null ? "選択してください" : null,
    );
  }

  /// Builds the staff multi-select field, styled using Theme colors.
  Widget _buildStaffMultiSelect(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color borderColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.1);
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Container(
      decoration: BoxDecoration(
        color: surfaceColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: MultiSelectDialogField(
        items: availableStaffNames
            .map((name) => MultiSelectItem(name, name))
            .toList(),
        initialValue: selectedStaffNames,
        title: Text('スタッフ選択',
            style: TextStyle(
                fontWeight: FontWeight.bold, color: onSurfaceColor)),
        buttonText: Text('スタッフ',
            style: Theme.of(context)
                .textTheme
                .bodyMedium!
                .copyWith(color: onSurfaceColor)),
        buttonIcon: Icon(Icons.group, color: primaryColor),
        onConfirm: (values) =>
            setState(() => selectedStaffNames = values.cast<String>()),
        decoration: const BoxDecoration(),
        chipDisplay: MultiSelectChipDisplay(
          chipColor: primaryColor.withOpacity(0.1),
          textStyle: TextStyle(color: primaryColor),
        ),
      ),
    );
  }
}