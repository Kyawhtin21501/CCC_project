import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:predictor_web/services/api_services.dart';
import 'package:predictor_web/widgets/appdrawer.dart';
import 'package:predictor_web/widgets/custom_menubar.dart';

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
  String _selectedStatus = 'パートタイム'; 
  int? _editingStaffId; // null = Create Mode, not null = Edit Mode

  List<Map<String, dynamic>> availableStaff = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadStaffList();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _levelController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- Logic ---

  void _prepareEdit(Map<String, dynamic> staff) {
    setState(() {
      _editingStaffId = staff['id'] ?? staff['ID'];
      _nameController.text = staff['name']?.toString() ?? '';
      _ageController.text = staff['age']?.toString() ?? '';
      _levelController.text = staff['level']?.toString() ?? '';
      _emailController.text = staff['e_mail']?.toString() ?? '';
      _selectedGender = staff['gender'] ?? 'Male';
      _selectedStatus = staff['status'] ?? 'パートタイム';
    });
  }

  Future<void> _loadStaffList() async {
    try {
      setState(() => _isLoading = true);
      final staffList = await ApiService.fetchStaffList();
      if (mounted) setState(() => availableStaff = staffList);
    } catch (e) {
      if (mounted) _showSnackBar('取得エラー: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final staffData = {
      'name': _nameController.text,
      'age': int.tryParse(_ageController.text),
      'level': int.tryParse(_levelController.text),
      'gender': _selectedGender,
      'e_mail': _emailController.text,
      'status': _selectedStatus,
    };

    try {
      setState(() => _isLoading = true);
      
      if (_editingStaffId != null) {
        await ApiService.patchStaffProfile(_editingStaffId!, staffData);
        _showMessage('成功', '情報を更新しました');
      } else {
        await ApiService.postStaffProfile(staffData);
        _showMessage('成功', '登録しました');
      }

      _clearFields();
      _loadStaffList(); 
    } catch (e) {
      _showMessage('エラー', '保存失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProfile(int id) async {
    try {
      setState(() => _isLoading = true);
      await ApiService.deleteStaffProfile(id);
      if (!mounted) return;
      _showSnackBar('削除しました');
      if (_editingStaffId == id) _clearFields();
      _loadStaffList();
    } catch (e) {
      _showMessage('エラー', '削除失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearFields() {
    _nameController.clear();
    _ageController.clear();
    _levelController.clear();
    _emailController.clear();
    setState(() {
      _editingStaffId = null;
      _selectedGender = 'Male';
      _selectedStatus = 'パートタイム';
    });
  }

  // --- UI Builders ---

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.staffProfile),
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 96, left: 20, right: 20, bottom: 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1000),
                    child: Column(
                      children: [
                        _buildFormCard(theme),
                        const SizedBox(height: 30),
                        _buildStaffList(theme),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 28, left: 16, right: 16,
              child: CustomMenuBar(
                title: 'スタッフ管理',
                onMenuPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard(ThemeData theme) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: _editingStaffId != null ? const BorderSide(color: Colors.blue, width: 2) : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_editingStaffId != null)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("編集モード", style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                    TextButton(onPressed: _clearFields, child: const Text("キャンセル")),
                  ],
                ),
              _buildTextField(_nameController, '名前'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildNumberField(_ageController, '年齢', 15, 100)),
                  const SizedBox(width: 16),
                  Expanded(child: _buildNumberField(_levelController, 'レベル(1-5)', 1, 5)),
                ],
              ),
              const SizedBox(height: 16),
              _buildTextField(_emailController, 'メール'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildGenderDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _buildStatusDropdown()),
                ],
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _submitProfile,
                icon: Icon(_editingStaffId == null ? Icons.add : Icons.save),
                label: Text(_editingStaffId == null ? 'スタッフを登録' : '更新を保存'),
                style: ElevatedButton.styleFrom(minimumSize: const Size(200, 50)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffList(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('スタッフ一覧', style: theme.textTheme.headlineSmall),
        const SizedBox(height: 12),
        Card(
          child: ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: availableStaff.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, index) {
              final staff = availableStaff[index];
              final id = staff['id'] ?? staff['ID'];
              return ListTile(
                title: Text(staff['name'] ?? '不明'),
                subtitle: Text('Status: ${staff['status']} | Level: ${staff['level']}'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _prepareEdit(staff)),
                    IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _showDeleteConfirm(id, staff['name'])),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // --- Components ---

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(labelText: 'ステータス', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: '高校生', child: Text('高校生')),
        DropdownMenuItem(value: '留学生', child: Text('留学生')),
        DropdownMenuItem(value: 'フルタイム', child: Text('フルタイム')),
        DropdownMenuItem(value: 'パートタイム', child: Text('パートタイム')),
      ],
      onChanged: (v) => setState(() => _selectedStatus = v!),
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(labelText: '性別', border: OutlineInputBorder()),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('男性')),
        DropdownMenuItem(value: 'Female', child: Text('女性')),
      ],
      onChanged: (v) => setState(() => _selectedGender = v!),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) => (v == null || v.isEmpty) ? '入力してください' : null,
    );
  }

  Widget _buildNumberField(TextEditingController controller, String label, int min, int max) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      validator: (v) {
        final n = int.tryParse(v ?? '');
        if (n == null || n < min || n > max) return '$min-$max';
        return null;
      },
    );
  }

  void _showSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
  void _showMessage(String t, String m) => showDialog(context: context, builder: (_) => AlertDialog(title: Text(t), content: Text(m), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))]));
  void _showDeleteConfirm(dynamic id, String name) => showDialog(context: context, builder: (ctx) => AlertDialog(title: const Text('削除'), content: Text('$nameを削除しますか？'), actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')), TextButton(onPressed: () { Navigator.pop(ctx); _deleteProfile(id is int ? id : int.parse(id.toString())); }, child: const Text('削除', style: TextStyle(color: Colors.red)))]));
}