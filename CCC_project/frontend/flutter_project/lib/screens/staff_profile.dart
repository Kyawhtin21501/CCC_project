import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/theme_provider/them.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';
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
      _staffList = ApiService.fetchStaffList()
          .then((data) => data.map((s) => s['Name'] as String).toList());
    });
  }

  // ------------------------- SUBMIT / DELETE -------------------------
  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final staffData = {
        'ID': null,
        'Name': _nameController.text,
        'Age': int.parse(_ageController.text),
        'Level': int.parse(_levelController.text),
        'Gender': _selectedGender,
        'Email': _emailController.text,
        'status': _convertStatusToEnglish(_selectedStatus),
      };

      try {
        final response = await ApiService.postStaffProfile(staffData);
        final res = jsonDecode(response.body);

        if (!mounted) return;
        _showMessage(
          response.statusCode == 200 ? '成功' : 'エラー',
          res['message'] ?? '不明なレスポンス',
        );

        if (response.statusCode == 200) {
          _clearFields();
          _loadStaffList();
        }
      } catch (e) {
        if (!mounted) return;
        _showMessage('エラー', '登録失敗: $e');
      }
    }
  }

  Future<void> _deleteProfileById(String id) async {
    final intId = int.tryParse(id);
    if (intId == null) {
      _showMessage('エラー', 'IDが無効です');
      return;
    }

    try {
      final response = await ApiService.deleteStaffProfile(intId);
      final res = jsonDecode(response.body);

      _showMessage(
        response.statusCode == 200 ? '削除成功' : 'エラー',
        res['message'] ?? 'No message',
      );

      if (response.statusCode == 200) {
        _loadStaffList();
      }
    } catch (e) {
      _showMessage('エラー', '削除失敗: $e');
    }
  }

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

  // ------------------------- BUILD -------------------------
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
       drawer: const AppDrawer(currentScreen: DrawerScreen.staffProfile),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Builder(

        builder: (context) {
          return SafeArea(
            child: Column(
              children: [
                // --- CUSTOM MENU BAR ---
                CustomMenuBar(
                  title: '新人スタッフ登録',
                   onMenuPressed: () => Scaffold.of(context).openDrawer(),
                ),
            
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// --- FORM CARD ---
                        Card(
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
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
                                    style: TextStyle(
                                        fontSize: 24, fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 20),
            
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      bool singleColumn = constraints.maxWidth < 600;
            
                                      if (singleColumn) {
                                        return Column(
                                          children: [
                                            _buildTextField(_nameController, '名前'),
                                            const SizedBox(height: 10),
                                            _buildNumberField(
                                                _ageController, '年齢', 18, 100),
                                            const SizedBox(height: 10),
                                            _buildNumberField(
                                                _levelController, 'レベル(1-5)', 1, 5),
                                            const SizedBox(height: 10),
                                            _buildEditEmailField(
                                                _emailController, 'メール'),
                                            const SizedBox(height: 10),
                                            _buildGenderDropdown(),
                                            const SizedBox(height: 10),
                                            _buildStatusDropdown(),
                                          ],
                                        );
                                      } else {
                                        return Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildTextField(
                                                      _nameController, '名前'),
                                                  const SizedBox(height: 10),
                                                  _buildNumberField(
                                                      _ageController, '年齢', 18, 100),
                                                  const SizedBox(height: 10),
                                                  _buildNumberField(
                                                      _levelController, 'レベル(1-5)', 1, 5),
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                children: [
                                                  _buildEditEmailField(
                                                      _emailController, 'メール'),
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
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 24, vertical: 12),
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
                        ),
            
                        const SizedBox(height: 30),
                        const Text(
                          'スタッフ一覧',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
            
                        /// --- STAFF LIST ---
                        FutureBuilder<List<String>>(
                          future: _staffList,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            } else if (snapshot.hasError) {
                              return Center(
                                  child: Text('Error: ${snapshot.error}'));
                            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(child: Text('スタフが見つかりません'));
                            }
            
                            final staffNames = snapshot.data!;
                            return ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: staffNames.length,
                              itemBuilder: (context, index) {
                                final name = staffNames[index];
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(14)),
                                    elevation: 2,
                                    child: ListTile(
                                      leading: const Icon(Icons.person,
                                          color: Colors.blue),
                                      title: Text(name),
                                      trailing: Wrap(
                                        spacing: 8,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () {
                                              // TODO: Implement edit dialog logic here
                                              _showMessage('未実装', '編集機能はまだ実装されていません');
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.green,
                                              foregroundColor: Colors.white,
                                            ),
                                            child: const Text('編集'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                _confirmDeleteWithIdPrompt(name),
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
                ),
              ],
            ),
          );
        }
      ),
    );
  }

  // ------------------------- WIDGET HELPERS -------------------------
  Widget _buildTextField(TextEditingController controller, String label,
          {bool isEmail = false}) =>
      TextFormField(
        controller: controller,
        keyboardType:
            isEmail ? TextInputType.emailAddress : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        validator: (value) =>
            value == null || value.isEmpty ? ' $label が必要です' : null,
      );

  Widget _buildNumberField(
          TextEditingController controller, String label, int min, int max) =>
      TextFormField(
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

  Widget _buildGenderDropdown() => DropdownButtonFormField<String>(
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

  Widget _buildStatusDropdown() => DropdownButtonFormField<String>(
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

  Widget _buildEditEmailField(TextEditingController controller, String label) =>
      TextFormField(
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
          final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
          if (!emailRegex.hasMatch(value)) {
            return '正しいメールアドレスを入力してください。';
          }
          return null;
        },
      );
      
        void _confirmDeleteWithIdPrompt(String name) {}}
      