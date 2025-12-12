import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/theme_provider/them.dart';

import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:provider/provider.dart';

class StaffProfileScreen extends StatelessWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const StaffProfileForm();
  }
}

class StaffProfileForm extends StatefulWidget {
  const StaffProfileForm({super.key});

  @override
  State<StaffProfileForm> createState() => _StaffProfileFormState();
}

class _StaffProfileFormState extends State<StaffProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _levelController = TextEditingController();
  final _emailController = TextEditingController();

  String _selectedGender = 'Male';
  String? _selectedStatus;
  late Future<List<String>> _staffList;

  @override
  void initState() {
    super.initState();
    _loadStaffList();
  }

  void _loadStaffList() {
    setState(() {
      _staffList = ApiService.fetchStaffList().then((data) => data.map((s) => s['Name'] as String).toList());
    });
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final staffData = {
        'ID': null, // 新規登録の場合はnullやサーバーで自動採番かもしれません
        'Name': _nameController.text,
        'Age': int.parse(_ageController.text),
        'Level': int.parse(_levelController.text),
        'Gender': _selectedGender,
        'Email': _emailController.text,
        'status': _convertStatusToEnglish(_selectedStatus), // 日本語→英語変換関数を作る
      };

      try {
        final response = await ApiService.postStaffProfile(staffData);
        final res = jsonDecode(response.body);

        if (!mounted) return;
        _showMessage(
          response.statusCode == 200 ? 'Success' : 'Error',
          res['message'] ?? 'Unknown response',
        );

        if (response.statusCode == 200) {
          _clearFields();
          _loadStaffList();
        }
      } catch (e) {
        if (!mounted) return;
        _showMessage('Error', 'Submit failed: $e');
      }
    }
  }

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

  void _showMessage(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
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

  Future<void> _deleteProfileById(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) {
      _showMessage('Error', 'IDが無効です');
      return;
    }

    try {
      final response = await ApiService.deleteStaffProfile(intId);
      final res = jsonDecode(response.body);

      _showMessage(
        response.statusCode == 200 ? '削除しました。' : 'Error',
        res['message'] ?? 'No message',
      );

      if (response.statusCode == 200) {
        _loadStaffList();
      }
    } catch (e) {
      _showMessage('Error', 'Delete failed: $e');
    }
  }

  void _showEditDialog() {
    String enteredId = '';
    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text('スタフ更新'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('スタフIDを入力してください:'),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) => enteredId = value,
                  decoration: const InputDecoration(
                    hintText: 'スタフID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (enteredId.isEmpty) {
                    _showMessage('Error', 'ID が必要です');
                    return;
                  }

                  final id = int.tryParse(enteredId);
                  if (id == null) {
                    _showMessage('Error', 'ID が無効です');
                    return;
                  }

                  try {
                    final staff = await ApiService.fetchStaffById(id);
                    _openEditFormDialog(id, staff);
                  } catch (e) {
                    _showMessage('Error', 'Fetch failed: $e');
                  }
                },
                child: const Text('確認'),
              ),
            ],
          ),
    );
  }

  void _confirmDeleteWithIdPrompt(String name) {
    String enteredId = '';

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(' $name を削除しますか？'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('IDを入力して削除を確認してください:'),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) => enteredId = value,
                  decoration: const InputDecoration(
                    hintText: 'スタフID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('キャンセル'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (enteredId.isNotEmpty) {
                    _deleteProfileById(enteredId);
                  } else {
                    _showMessage('Error', 'ＩＤ が必要です');
                  }
                },
                child: const Text('確認'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text("新人スタッフ登録"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.themeMode == ThemeMode.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: () {
              final isDark = themeProvider.themeMode == ThemeMode.dark;
              themeProvider.toggleTheme(!isDark);
            },
          ),
        ],
      ),
      drawer: AppDrawer(currentScreen: DrawerScreen.staffProfile),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// --- FORM SECTION ---
       Card(
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
  elevation: 2,
  child: Padding(
    padding: const EdgeInsets.all(16.0),
    child: Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '新規スタッフ',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          LayoutBuilder(
            builder: (context, constraints) {
              // If width is less than 600, use single column
              bool useSingleColumn = constraints.maxWidth < 600;

              if (useSingleColumn) {
                return Column(
                  children: [
                    _buildTextField(_nameController, '名前'),
                    const SizedBox(height: 10),
                    _buildNumberField(_ageController, '年齢', 18, 100),
                    const SizedBox(height: 10),
                    _buildNumberField(_levelController, 'レベル(1-5)', 1, 5),
                    const SizedBox(height: 10),
                    _buildEditEmailField(_emailController, 'メール'),
                    const SizedBox(height: 10),
                    _buildGenderDropdown(),
                    const SizedBox(height: 10),
                    _buildStatusDropdown(),
                  ],
                );
              } else {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          _buildTextField(_nameController, '名前'),
                          const SizedBox(height: 10),
                          _buildNumberField(_ageController, '年齢', 18, 100),
                          const SizedBox(height: 10),
                          _buildNumberField(_levelController, 'レベル(1-5)', 1, 5),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        children: [
                          _buildEditEmailField(_emailController, 'メール'),
                          const SizedBox(height: 10),
                          _buildGenderDropdown(),
                          const SizedBox(height: 10),
                          _buildStatusDropdown(),
                        ],
                      ),
                    ),
                  ],
                );
              }
            },
          ),

          const SizedBox(height: 20),
          Center(
            child: ElevatedButton(
              onPressed: _submitProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              child: const Text('登録'),
            ),
          ),
        ],
      ),
    ),
  ),
)
,

            const SizedBox(height: 30),
            const Text(
              'スタッフ一覧',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            /// --- LIST SECTION ---
            FutureBuilder<List<String>>(
              future: _staffList,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text('スタフが見つかりません'));
                }

                final staffNames = snapshot.data!;
                return ListView.builder(
                  shrinkWrap: true, // lets it work inside SingleChildScrollView
                  physics: const NeverScrollableScrollPhysics(), //  avoid nested scrolling
                  itemCount: staffNames.length,
                  itemBuilder: (context, index) {
                    final name = staffNames[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                        child: ListTile(
                          leading: const Icon(Icons.person, color: Colors.blue),
                          title: Text(name),
                          
                          trailing: Wrap(
                            spacing: 8,
                            children: [
                              ElevatedButton(
                                onPressed: () => _showEditDialog(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('編集'),
                              ),
                              ElevatedButton(
                                onPressed: () => _confirmDeleteWithIdPrompt(name),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('削除'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }


  void _openEditFormDialog(int staffId, Map<String, dynamic> staff) {
    final editName = TextEditingController(text: staff['Name']);
    final editAge = TextEditingController(text: staff['Age'].toString());
    final editLevel = TextEditingController(text: staff['Level'].toString());
    final editEmail = TextEditingController(text: staff['Email']);
    String gender = staff['Gender'];
    String? status = _convertStatusToJapanese(staff['status']);

    showDialog(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text('スタフId Id : $staffId'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditField(editName, '名前'),
                  const SizedBox(height: 10),
                  _buildEditNumberField(editAge, '年齢', 18, 100),
                  const SizedBox(height: 10),
                  _buildEditNumberField(editLevel, 'レベル (1-5)', 1, 5),
                  const SizedBox(height: 10),
                  _buildEditField(editEmail, 'メール'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(
                      labelText: '性別',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                    DropdownMenuItem(value: 'Male', child: Text('男性')),
  DropdownMenuItem(value: 'Female', child: Text('女性')),
                    ],
                    onChanged: (val) => gender = val!,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'ステータス',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '高校生', child: Text('高校生')),
                      DropdownMenuItem(value: '留学生', child: Text('留学生')),
                      DropdownMenuItem(value: 'フルタイム', child: Text('フルタイム')),
                      DropdownMenuItem(value: 'パートタイム', child: Text('パートタイム')),
                    ],
                    onChanged: (val) => status = val,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('閉じる'),
              ),
              TextButton(
                onPressed: () async {
                  final updated = {
                    'Name': editName.text,
                    'Age': int.tryParse(editAge.text),
                    'Level': int.tryParse(editLevel.text),
                    'Gender': gender,
                    'Email': editEmail.text,
                    'status': _convertStatusToEnglish(status),
                  };

                  try {
                    final res = await ApiService.updateStaffProfile(
                      staffId,
                      updated,
                    );
                    final decoded = jsonDecode(res.body);
                    _showMessage(
                      res.statusCode == 200 ? 'Updated' : 'Error',
                      decoded['message'] ?? 'Unknown error',
                    );
                    if (!mounted) return;

                    if (res.statusCode == 200) {
                      _loadStaffList();
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    _showMessage('Error', 'Update failed: $e');
                  }
                },
                child: const Text('保存'),
              ),
            ],
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isEmail = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator:
          (value) =>
              value == null || value.isEmpty ? ' $label が必要です' : null,
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
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

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(
        labelText: '性別',
        border: OutlineInputBorder(),
      ),
   items: const [
  DropdownMenuItem(value: 'Male', child: Text('男性')),
  DropdownMenuItem(value: 'Female', child: Text('女性')),
],

      onChanged: (value) => setState(() => _selectedGender = value!),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'ステータス',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: '高校生', child: Text('高校生')),
        DropdownMenuItem(value: '留学生', child: Text('留学生')),
        DropdownMenuItem(value: 'フルタイム', child: Text('フルタイム')),
        DropdownMenuItem(value: 'パートタイム', child: Text('パートタイム')),
      ],
      onChanged: (value) => setState(() => _selectedStatus = value),
      validator: (value) => value == null ? 'スタフのステータスが必要です' : null,
    );
  }

  Widget _buildEditField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }

  Widget _buildEditNumberField(
    TextEditingController controller,
    String label,
    int min,
    int max,
  ) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      validator: (value) {
        final number = int.tryParse(value ?? '');
        if (number == null || number < min || number > max) {
          return '$label は $min と$max の間でなければなりません';
        }
        return null;
      },
    );
  }
Widget _buildEditEmailField(TextEditingController controller, String label) {
  return TextFormField(
    controller: controller,
    keyboardType: TextInputType.emailAddress,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    validator: (value) {
      if (value == null || value.isEmpty) {
        return ' $label が必要です。';
      }
      // Simple email regex
      final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
      if (!emailRegex.hasMatch(value)) {
        return '正しいメールアドレスを入力してください。';
      }
      return null;
    },
  );
}

  String _convertStatusToJapanese(String? status) {
    switch (status) {
      case 'high_school_student':
        return '高校生';
      case 'international_student':
        return '留学生';
      case 'Full Time':
        return 'フルタイム';
      case 'Part Time':
        return 'パートタイム';
      default:
        return 'unknown';
    }
  }
}