import 'dart:convert';
import 'package:flutter/material.dart';
// 外部依存関係: サービスのインポートはそのまま維持します
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';

// ====================================================================
// I. スクリーンコンテナ (StatelessWidget)
// ====================================================================

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // 画面全体の状態管理をStaffProfileFormに委任します。
    return const StaffProfileForm();
  }
}

// ====================================================================
// II. フォームウィジェット (StatefulWidget)
// ====================================================================

class StaffProfileForm extends StatefulWidget {
  const StaffProfileForm({super.key});

  @override
  State<StaffProfileForm> createState() => _StaffProfileFormState();
}

class _StaffProfileFormState extends State<StaffProfileForm> {
  // ------------------------- 1. 状態とコントローラー -------------------------
  
  final _formKey = GlobalKey<FormState>();
  
  // テキストフィールドコントローラー
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _levelController = TextEditingController();
  final _emailController = TextEditingController();

  // フォームのドロップダウン状態
  String _selectedGender = 'Male';
  String? _selectedStatus;

  // スタッフ名リストの状態
  List<String> availableStaffNames = [];
  
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

      if (mounted) List<String> availableStaffNames;
       setState(() => availableStaffNames = names);
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
  // ------------------------- 2. ライフサイクル -------------------------

  @override
  void initState() {
    super.initState();
    _loadStaffList(); // 画面初期化時にスタッフ一覧をロード
  }

  @override
  void dispose() {
    // コントローラーの破棄
    _nameController.dispose();
    _ageController.dispose();
    _levelController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  

  /// スタッフプロフィールをAPIに送信し、新規登録します。
  Future<void> _submitProfile() async {
    // フォームバリデーション
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final staffData = {
     // 'ID': null, // 新規登録のためIDはnull
      'name': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'level': int.tryParse(_levelController.text),
      'gender': _selectedGender,
      'e_mail': _emailController.text,
      'status': _convertStatusToEnglish(_selectedStatus), // 日本語→英語キーに変換
    };

    try {
      final response = await ApiService.postStaffProfile(staffData);
      final res = jsonDecode(response.body);

      if (!mounted) return;
      _showMessage(
        response.statusCode == 200 ? '✅ 成功' : '❌ エラー',
        res['message'] ?? '不明なレスポンス',
      );

      if (response.statusCode == 200) {
        _clearFields();   // 成功時に入力フィールドをクリア
        _loadStaffList(); // スタッフリストを再ロード
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('❌ エラー', '登録失敗: $e');
    }
  }

  /// IDを指定してスタッフプロフィールを削除します。
  Future<void> _deleteProfileById(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) {
      _showMessage('❌ エラー', 'IDが無効です');
      return;
    }

    try {
      final response = await ApiService.deleteStaffProfile(intId);
      final res = jsonDecode(response.body);

      if (!mounted) return;
      _showMessage(
        response.statusCode == 200 ? '✅ 削除成功' : '❌ エラー',
        res['message'] ?? 'メッセージなし',
      );

      if (response.statusCode == 200) {
        _loadStaffList(); // 削除後にリストを再ロード
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage('❌ エラー', '削除失敗: $e');
    }
  }

  /// 削除確認ダイアログ（現状はID要求で未実装メッセージを表示）。
  void _confirmDeleteWithIdPrompt(String name) {
    _showMessage(
        '⚠️ 未実装', 'スタッフ名 "$name" を削除するには、まずIDを取得する必要があります。');
    // TODO: 今後、名前からIDを検索するか、IDを保持するロジックを実装する必要があります。
  }

  /// フィールドをクリアし、選択をリセットします。
  void _clearFields() {
    _nameController.clear();
    _ageController.clear();
    _levelController.clear();
    _emailController.clear();
    setState(() {
      _selectedGender = 'Male';
      _selectedStatus = null;
    });
  }

  /// 日本語ステータスをAPI送信用の英語キーに変換します。
  String _convertStatusToEnglish(String? status) {
    switch (status) {
      case '高校生':
        return 'high_school_student';
      case '留学生':
        return 'international_student';
      case 'フルタイム':
        return 'Full Time';
      case 'パートタイム':
        return 'Part Time';
      default:
        return 'unknown';
    }
  }

  // ------------------------- 4. UI表示ヘルパー -------------------------

  /// メッセージ（成功/エラー）をダイアログで表示します。
  void _showMessage(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ------------------------- 5. BUILD メソッド (レイアウト) -------------------------
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 左側にドロワーを配置
      drawer: const AppDrawer(currentScreen: DrawerScreen.staffProfile),
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Builder(
        builder: (ctx) {
          return Stack(
            children: [
              // スクロール可能なコンテンツ領域
              Positioned.fill(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.only(top: 96, left: 20, right: 20, bottom: 24),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 1000), // 最大幅設定
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. 登録フォームカード
                          _buildFormCard(theme),
                          const SizedBox(height: 30),

                          // 2. スタッフ一覧ヘッダー
                          Text(
                            'スタッフ一覧',
                            style: theme.textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),

                          // 3. スタッフリスト (FutureBuilder)
                          _buildStaffList(theme),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // カスタムメニューバー (固定ヘッダー)
              Positioned(
                top: 28,
                left: 16,
                right: 16,
                child: CustomMenuBar(
                  title: '新人スタッフ登録',
                  onMenuPressed: () => Scaffold.of(ctx).openDrawer(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // ------------------------- 6. UIコンポーネント -------------------------

  /// スタッフ登録フォームを含むカードを構築します。
  Widget _buildFormCard(ThemeData theme) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '新規スタッフ情報',
                style: theme.textTheme.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              LayoutBuilder(
                builder: (context, constraints) {
                  // 幅に応じてレイアウトを切り替え（レスポンシブデザイン）
                  bool singleColumn = constraints.maxWidth < 600;
                  final spacing = singleColumn ? 10.0 : 16.0;

                  final formFields = [
                    _buildTextField(_nameController, '名前'),
                    _buildNumberField(_ageController, '年齢', 18, 100),
                    _buildNumberField(_levelController, 'レベル(1-5)', 1, 5),
                    _buildEditEmailField(_emailController, 'メール'),
                    _buildGenderDropdown(),
                    _buildStatusDropdown(),
                  ];

                  if (singleColumn) {
                    // 1カラムレイアウト
                    return Column(
                      children: formFields
                          .map((w) => [w, SizedBox(height: spacing)])
                          .expand((i) => i)
                          .toList()
                        ..removeLast(), // 最後のSizedBoxを削除
                    );
                  } else {
                    // 2カラムレイアウト
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              formFields[0],
                              SizedBox(height: spacing),
                              formFields[1],
                              SizedBox(height: spacing),
                              formFields[2],
                            ],
                          ),
                        ),
                        SizedBox(width: spacing),
                        Expanded(
                          child: Column(
                            children: [
                              formFields[3],
                              SizedBox(height: spacing),
                              formFields[4],
                              SizedBox(height: spacing),
                              formFields[5],
                            ],
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              const SizedBox(height: 30),
              // 登録ボタン
              Center(
                child: ElevatedButton.icon(
                  onPressed: _submitProfile,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(Icons.person_add),
                  label: const Text('登録'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

 _buildStaffList(ThemeData theme) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: availableStaffNames.length,
      separatorBuilder: (_, __) => const Divider(height: 1, thickness: 1),
      itemBuilder: (context, index) {
        final name = availableStaffNames[index];
        return ListTile(
          title: Text(name),
          trailing: IconButton(
            icon: const Icon(Icons.delete, color: Colors.redAccent),
            onPressed: () => _confirmDeleteWithIdPrompt(name),
          ),
        );
      },
    );
  }

  // ------------------------- 7. フォームフィールドヘルパー -------------------------

  // 標準テキストフィールド
  Widget _buildTextField(TextEditingController controller, String label) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintStyle: TextStyle(color: theme.hintColor),
      ),
      validator: (value) =>
          value == null || value.isEmpty ? ' $label が必要です' : null,
    );
  }

  // 数値入力フィールド (範囲バリデーション付き)
  Widget _buildNumberField(
      TextEditingController controller, String label, int min, int max) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintStyle: TextStyle(color: theme.hintColor),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) return ' $label が必要です';
        final number = int.tryParse(value);
        if (number == null || number < min || number > max) {
          return '$label は $min と $max の間でなければなりません';
        }
        return null;
      },
    );
  }

  // 性別ドロップダウン
  Widget _buildGenderDropdown() {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: InputDecoration(
        labelText: '性別',
        border: const OutlineInputBorder(),
        hintStyle: TextStyle(color: theme.hintColor),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('男性')),
        DropdownMenuItem(value: 'Female', child: Text('女性')),
      ],
      onChanged: (value) => setState(() => _selectedGender = value!),
    );
  }

  // ステータスドロップダウン
  Widget _buildStatusDropdown() {
    final theme = Theme.of(context);
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: InputDecoration(
        labelText: 'ステータス',
        border: const OutlineInputBorder(),
        hintStyle: TextStyle(color: theme.hintColor),
      ),
      items: const [
        DropdownMenuItem(value: '高校生', child: Text('高校生')),
        DropdownMenuItem(value: '留学生', child: Text('留学生')),
        DropdownMenuItem(value: 'フルタイム', child: Text('フルタイム')),
        DropdownMenuItem(value: 'パートタイム', child: Text('パートタイム')),
      ],
      onChanged: (value) => setState(() => _selectedStatus = value),
      validator: (value) => value == null ? 'スタッフのステータスが必要です' : null,
    );
  }

  // メールアドレスフィールド (形式バリデーション付き)
  Widget _buildEditEmailField(TextEditingController controller, String label) {
    final theme = Theme.of(context);
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.emailAddress,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        hintStyle: TextStyle(color: theme.hintColor),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return ' $label が必要です。';
        }
        final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
        if (!emailRegex.hasMatch(value)) {
          return '正しいメールアドレスを入力してください。';
        }
        return null;
      },
    );
  }
}