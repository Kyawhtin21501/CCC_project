// Fixed & backend-safe version of StaffProfileScreen
// - Handles id/ID differences
// - Prevents Dropdown crashes
// - Safer parsing & loading state handling
// - Matches Flask CSV-style backend

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

  final List<String> _genderOptions = ['Male', 'Female'];
  final List<String> _statusOptions = ['高校生', '留学生', 'フルタイム', 'パートタイム'];

  String _selectedGender = 'Male';
  String _selectedStatus = 'パートタイム';
  int? _editingStaffId;

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

  // ---------------- LOGIC ----------------

  Future<void> _loadStaffList() async {
    try {
      setState(() => _isLoading = true);
      final data = await ApiService.fetchStaffList();
      if (!mounted) return;
      setState(() => availableStaff = List<Map<String, dynamic>>.from(data));
    } catch (e) {
      _showSnackBar('取得失敗: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prepareEdit(Map<String, dynamic> staff) {
    final rawId = staff['id'] ?? staff['ID'];

    setState(() {
      _editingStaffId = rawId is int ? rawId : int.tryParse(rawId.toString());

      _nameController.text = staff['name']?.toString() ?? '';
      _ageController.text = staff['age']?.toString() ?? '';
      _levelController.text = staff['level']?.toString() ?? '';
      _emailController.text = staff['e_mail']?.toString() ?? '';

      final g = staff['gender']?.toString() ?? 'Male';
      _selectedGender = _genderOptions.contains(g) ? g : 'Male';

      final s = staff['status']?.toString() ?? 'パートタイム';
      _selectedStatus = _statusOptions.contains(s) ? s : 'パートタイム';
    });
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    final payload = {
      'name': _nameController.text.trim(),
      'age': int.parse(_ageController.text),
      'level': int.parse(_levelController.text),
      'gender': _selectedGender,
      'e_mail': _emailController.text.trim(),
      'status': _selectedStatus,
    };

    try {
      setState(() => _isLoading = true);

      if (_editingStaffId == null) {
        await ApiService.postStaffProfile(payload);
      } else {
        await ApiService.patchStaffProfile(_editingStaffId!, payload);
      }

      _clearForm();
      await _loadStaffList();
      _showSnackBar('保存しました');
    } catch (e) {
      _showDialog('エラー', e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _clearForm() {
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

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const AppDrawer(currentScreen: DrawerScreen.staffProfile),
      body: Builder(
        builder: (ctx) => Stack(
          children: [
            Positioned.fill(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      children: [
                        _buildFormCard(),
                        const SizedBox(height: 30),
                        _buildStaffList(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: 28,
              left: 16,
              right: 16,
              child: CustomMenuBar(
                title: 'スタッフ管理',
                onMenuPressed: () => Scaffold.of(ctx).openDrawer(),
              ),
            ),
            if (_isLoading) const Center(child: CircularProgressIndicator()),
          ],
        ),
      ),
    );
  }

  Widget _buildFormCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: _editingStaffId != null
            ? const BorderSide(color: Colors.blue, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                _editingStaffId == null
                    ? '新規スタッフ登録'
                    : 'スタッフ編集 (ID: $_editingStaffId)',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              _textField(_nameController, '名前'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _numberField(_ageController, '年齢', 15, 100)),
                  const SizedBox(width: 16),
                  Expanded(child: _numberField(_levelController, 'レベル(1–5)', 1, 5)),
                ],
              ),
              const SizedBox(height: 16),
              _textField(_emailController, 'メール'),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _genderDropdown()),
                  const SizedBox(width: 16),
                  Expanded(child: _statusDropdown()),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (_editingStaffId != null)
                    OutlinedButton(onPressed: _clearForm, child: const Text('キャンセル')),
                  const SizedBox(width: 10),
                  ElevatedButton(
                    onPressed: _submitProfile,
                    child: Text(_editingStaffId == null ? '登録' : '更新'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStaffList() {
    if (availableStaff.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('スタッフが登録されていません'),
        ),
      );
    }

    return Card(
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: availableStaff.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (_, i) {
          final s = availableStaff[i];
          final id = s['id'] ?? s['ID'];

          return ListTile(
            title: Text(s['name'] ?? 'No Name'),
            subtitle: Text('${s['status']} | Lv.${s['level']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _prepareEdit(s),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _confirmDelete(id, s['name']),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------- FIELDS ----------------

  Widget _textField(TextEditingController c, String label) => TextFormField(
        controller: c,
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) => v == null || v.isEmpty ? '必須入力' : null,
      );

  Widget _numberField(TextEditingController c, String label, int min, int max) =>
      TextFormField(
        controller: c,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
        validator: (v) {
          final n = int.tryParse(v ?? '');
          if (n == null || n < min || n > max) return '$min〜$max';
          return null;
        },
      );

  Widget _genderDropdown() => DropdownButtonFormField<String>(
        initialValue: _selectedGender,
        decoration: const InputDecoration(labelText: '性別', border: OutlineInputBorder()),
        items: _genderOptions
            .map((g) => DropdownMenuItem(value: g, child: Text(g == 'Male' ? '男性' : '女性')))
            .toList(),
        onChanged: (v) => setState(() => _selectedGender = v!),
      );

  Widget _statusDropdown() => DropdownButtonFormField<String>(
        initialValue: _selectedStatus,
        decoration: const InputDecoration(labelText: 'ステータス', border: OutlineInputBorder()),
        items: _statusOptions.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
        onChanged: (v) => setState(() => _selectedStatus = v!),
      );

  // ---------------- HELPERS ----------------

  void _confirmDelete(dynamic id, String name) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('削除確認'),
        content: Text('$name を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                setState(() => _isLoading = true);
                final intId = id is int ? id : int.parse(id.toString());
                await ApiService.deleteStaffProfile(intId);
                await _loadStaffList();
              } catch (e) {
                _showSnackBar('削除失敗: $e');
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            },
            child: const Text('削除', style: TextStyle(color: Colors.red)),
          )
        ],
      ),
    );
  }

  void _showSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  void _showDialog(String t, String m) => showDialog(
        context: context,
        builder: (_) => AlertDialog(title: Text(t), content: Text(m), actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))
        ]),
      );
}
