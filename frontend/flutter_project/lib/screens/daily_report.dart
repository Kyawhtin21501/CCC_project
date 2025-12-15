import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
import 'package:predictor_web/widgets/responsiveCard.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/charts.dart'; // SalesPredictionChartWidget, ShiftChartWidgetが含まれる

/// --- ダミーデータ ---

/// SalesPredictionChartWidgetの期待するフォーマットに一致するダミーデータ。
const List<Map<String, dynamic>> _kDummySalesData = [
  {'date': '2025-12-01T00:00:00', 'actual_sales': 45000, 'predicted_sales': 48000},
  {'date': '2025-12-02T00:00:00', 'actual_sales': 52000, 'predicted_sales': 55000},
  {'date': '2025-12-03T00:00:00', 'actual_sales': 60000, 'predicted_sales': 58000},
  {'date': '2025-12-04T00:00:00', 'actual_sales': 58000, 'predicted_sales': 62000},
  {'date': '2025-12-05T00:00:00', 'actual_sales': 65000, 'predicted_sales': 68000},
  {'date': '2025-12-06T00:00:00', 'actual_sales': 70000, 'predicted_sales': 71000},
  {'date': '2025-12-07T00:00:00', 'actual_sales': 75000, 'predicted_sales': 75000},
];

/// ShiftChartWidgetの期待するフォーマットに一致するダミーデータ。
const List<Map<String, dynamic>> _kDummyShiftData = [
  {'date': '2025-12-15', 'shift': 'morning', 'Name': '佐藤'},
  {'date': '2025-12-15', 'shift': 'afternoon', 'Name': '田中'},
  {'date': '2025-12-16', 'shift': 'morning', 'Name': '山本'},
  {'date': '2025-12-16', 'shift': 'night', 'Name': '中村'},
  {'date': '2025-12-17', 'shift': 'afternoon', 'Name': '佐藤'},
  {'date': '2025-12-17', 'shift': 'afternoon', 'Name': '田中'},
  {'date': '2025-12-18', 'shift': 'morning', 'Name': '山本'},
  {'date': '2025-12-19', 'shift': 'night', 'Name': '中村'},
  {'date': '2025-12-20', 'shift': 'morning', 'Name': '佐藤'},
  {'date': '2025-12-21', 'shift': 'afternoon', 'Name': '田中'},
];

/// --- DashboardScreen ウィジェット ---

/// メインアプリケーションのダッシュボード画面。
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // フォーム関連
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController salesController = TextEditingController();
  final TextEditingController customerController = TextEditingController();
  final TextEditingController dateController = TextEditingController();

  // 状態変数
  DateTime? _selectedDate;
  List<String> availableStaffNames = [];
  List<String> selectedStaffNames = [];
  String? festivalStatus;
  bool _loading = false;
  String? error;
  
  // キャッシュ
  List<Map<String, dynamic>>? _shiftScheduleCache;
  List<Map<String, dynamic>>? _salesDataCache;

  /// 初期化：スタッフリストとチャートデータをロード
  @override
  void initState() {
    super.initState();
    _loadStaffList();
    _loadChartData();
  }

  /// リソースの解放
  @override
  void dispose() {
    salesController.dispose();
    customerController.dispose();
    dateController.dispose();
    super.dispose();
  }

  // --- API呼び出しとデータ処理 ---

  /// スタッフリストをAPIから取得
  Future<void> _loadStaffList() async {
    try {
      final staffList = await ApiService.fetchStaffList();
      print(staffList);
      final names = <String>[];

      for (final item in staffList) {
        print(item);
        if (item is String) {
          names.add(item as String);
        } else if (item is Map && item.containsKey('name')) {
          names.add(item['name'].toString());
        } else {
          if (item != null) {
            names.add(item.toString());
          }
        }
      }
    
      // // APIが空の場合にダミーデータを使用
      // if (names.isEmpty) {
      //   names.addAll(['佐藤 太郎', '田中 花子', '山本 健太', '中村 美咲']);
      // }

      if (mounted) setState(() => availableStaffNames = names);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('スタッフリスト取得エラー: $e')));
        // API失敗時もダミー名をロード
        if (mounted) {
          setState(() => availableStaffNames = ['佐藤 太郎', '田中 花子', '山本 健太', '中村 美咲']);
        }
      }
    }
  }

  /// チャートデータをAPIから取得し、キャッシュに保存
  Future<void> _loadChartData() async {
    try {
      final shiftData = await ApiService.fetchShiftTableDashboard();
      final salesData = await ApiService.getPredSales();

      setState(() {
        _shiftScheduleCache = (shiftData.isNotEmpty)
            ? List<Map<String, dynamic>>.from(
                shiftData.cast<Map<String, dynamic>>())
            : null;

        _salesDataCache = (salesData.isNotEmpty)
            ? List<Map<String, dynamic>>.from(
                salesData.cast<Map<String, dynamic>>())
            : null;
      });
    } catch (e) {
      if (mounted) setState(() => error = e.toString());
    }
    // キャッシュがnullの場合、ビルド時にダミーデータが使用される
  }

  /// APIリクエスト用のペイロードを構築
  Map<String, dynamic> _buildPayload() {
    final int? dayNumber = _selectedDate?.weekday;
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

  /// データの保存とチャートの更新
  Future<void> _saveDataAndRefresh() async {
    if (!_formKey.currentState!.validate()) return;

    // 日付とイベントステータスの必須チェック
    if (_selectedDate == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('日付を選択してください')));
      }
      return;
    }

    if (festivalStatus == null) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('イベントを選択してください')));
      }
      return;
    }

    final payload = _buildPayload();

    try {
      setState(() => _loading = true);
      final response = await ApiService.postUserInput(payload);

      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('保存エラー: ${response.statusCode ?? '不明'}')));
        }
        return;
      }

      _clearForm();
      await _loadChartData();

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('保存されました')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('通信エラー: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// フォームのクリア
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

  /// 日付をISOフォーマット (YYYY-MM-DD) に整形
  String _formatDateISO(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';
  }

  // --- ビルドメソッド ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.dashboard),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              // グローバルな垂直スクロールを可能にする
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                    top: 96, left: 20, right: 20, bottom: 16),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : ResponsiveBodyCard(
                        formCard: _buildCompactForm(context),
                        salesCard: _buildSalesCard(),
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



  /// 売上予測チャートとKPIカードを構築
  Widget _buildSalesCard() {
    final Color primaryColor = Theme.of(context).colorScheme.primary;

    // キャッシュがnullまたは空の場合はダミーデータを使用
    final List<Map<String, dynamic>> salesData =
        (_salesDataCache == null || _salesDataCache!.isEmpty)
            ? _kDummySalesData
            : _salesDataCache!;

    const double chartHeight = 300.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "７日間売上予測",
          style: Theme.of(context).textTheme.titleLarge!.copyWith(
              fontSize: 20, color: primaryColor),
        ),
        if (_salesDataCache == null || _salesDataCache!.isEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Text(
              '※ データが存在しないため、デモデータを表示しています。',
              style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.orange),
            ),
          ),
        const SizedBox(height: 12),
        SizedBox(
          height: chartHeight,
          child: SalesPredictionChartWidget(salesData: salesData),
        ),
      ],
    );
  }

  /// スタッフシフトチャートを構築
  Widget _buildShiftCard() {
    // キャッシュがnullまたは空の場合はダミーデータを使用
    final List<Map<String, dynamic>> shiftSchedule =
        (_shiftScheduleCache == null || _shiftScheduleCache!.isEmpty)
            ? _kDummyShiftData
            : _shiftScheduleCache!;
    
    // 実データがない場合に警告を表示するためのフラグ
    final bool isUsingDummy = _shiftScheduleCache == null || _shiftScheduleCache!.isEmpty;

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
                       if (isUsingDummy) 
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    '※ シフトデータが存在しないため、デモデータを表示しています。',
                    style: Theme.of(context).textTheme.bodySmall!.copyWith(color: Colors.orange),
                  ),
                ),
            const SizedBox(height: 12),
            ShiftChartWidget(shiftSchedule: shiftSchedule),
        ],
    );
  }

  /// 選択されたスタッフ数を表示
  Widget _buildStaffCountDisplay() {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color surfaceColor = Theme.of(context).colorScheme.surface;
    final Color borderColor =
        Theme.of(context).colorScheme.onSurface.withOpacity(0.1);

    return Container(
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

  /// 日報入力フォームを構築
  Widget _buildCompactForm(BuildContext context) {
    final Color primaryColor = Theme.of(context).colorScheme.primary;
    final Color onSurfaceColor = Theme.of(context).colorScheme.onSurface;

    return Padding(
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
            const SizedBox(height: 24), // 区切り線

            /// 入力フィールド (売上、来客数、スタッフ数)
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

            const SizedBox(height: 16),

            /// 日付とイベント入力
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(width: 200, child: _buildDatePickerInline(context)),
                SizedBox(width: 180, child: _buildEventDropdown(context)),
              ],
            ),

            const SizedBox(height: 16),

            /// スタッフ複数選択
            _buildStaffMultiSelect(context),

            const SizedBox(height: 24), // 区切り線

            /// 保存ボタン
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
    );
  }

  /// 標準のTextFormFieldを構築
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
      inputFormatters: numberOnly
          ? [FilteringTextInputFormatter.digitsOnly]
          : null,
      style: TextStyle(color: onSurfaceColor),
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: primaryColor),
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: surfaceColor,
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
        hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.3)),
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

  /// 日付選択フィールドを構築
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
        hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.3)),
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
            // DatePickerダイアログに現在のテーマを適用
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
      validator: (v) =>
          _selectedDate == null ? "日付を選択してください" : null,
    );
  }

  /// イベントステータスのドロップダウンメニューを構築
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
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        labelStyle: TextStyle(color: onSurfaceColor.withOpacity(0.6)),
        hintStyle: TextStyle(color: onSurfaceColor.withOpacity(0.3)),
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

  /// スタッフの複数選択フィールドを構築
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
      child: MultiSelectDialogField<String>(
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
                .copyWith(color: onSurfaceColor.withOpacity(0.6))),
        buttonIcon: Icon(Icons.group, color: primaryColor),
        onConfirm: (List<String> values) =>
            setState(() => selectedStaffNames = values),
        decoration: const BoxDecoration(
            // MultiSelectDialogFieldによる追加の境界線描画を防ぐ
            ),
        chipDisplay: MultiSelectChipDisplay(
          chipColor: primaryColor.withOpacity(0.1),
          textStyle: TextStyle(color: primaryColor),
        ),
      ),
    );
  }
}