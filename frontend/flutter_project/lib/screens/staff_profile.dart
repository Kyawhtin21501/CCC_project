import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:omakase_shift/services/api_services.dart';
import 'package:omakase_shift/widgets/appdrawer.dart';
import 'package:omakase_shift/widgets/custom_menubar.dart';

/// Screen for managing staff records. 
/// Features: List view, Search/Filter, Create (Dialog), Edit (Side Sheet), and Delete.
class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  // Data State
  List<Map<String, dynamic>> _allStaff = [];      // Source of truth from API
  List<Map<String, dynamic>> _filteredStaff = []; // Data currently displayed in the table
  bool _isLoading = false;

  // Search Controller
  final TextEditingController _searchController = TextEditingController();

  /// Utility for debug logging that only prints in development mode.
  void _trace(String message) {
    if (kDebugMode) {
      print('[StaffProfileScreen] $message');
    }
  }

  @override
  void initState() {
    super.initState();
    _loadStaffList();
  }

  /// Fetches the staff list and applies current filters.
  Future<void> _loadStaffList() async {
    _trace('Starting loadStaffList...');
    try {
      setState(() => _isLoading = true);
      final data = await ApiService.fetchStaffList();

      if (!mounted) return;

      setState(() {
        _allStaff = List<Map<String, dynamic>>.from(data);
        _applyFilter(_searchController.text);
      });
      _trace('Successfully loaded ${_allStaff.length} staff members.');
    } catch (e) {
      _trace('Error loading staff list: $e');
      _showSnackBar('データの取得に失敗しました');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Client-side filtering logic for the search bar.
  void _applyFilter(String query) {
    _trace('Applying filter for query: "$query"');
    setState(() {
      if (query.isEmpty) {
        _filteredStaff = List.from(_allStaff);
      } else {
        _filteredStaff = _allStaff
            .where((s) => s['name']
                .toString()
                .toLowerCase()
                .contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  /// Orchestrates how the form is opened.
  /// If [staff] is null, opens a center Dialog (Create mode).
  /// If [staff] is provided, opens a sliding Side Sheet (Edit mode).
  void _openStaffForm([Map<String, dynamic>? staff]) {
    if (staff == null) {
      // Create Mode: Simple Modal
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => _StaffAddDialog(onSave: _loadStaffList),
      );
    } else {
      // Edit Mode: Right-side Sliding Sheet using a custom transition
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Close',
        barrierColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
        transitionDuration: const Duration(milliseconds: 300),
        pageBuilder: (context, anim1, anim2) => Align(
          alignment: Alignment.centerRight,
          child: _StaffEditSideSheet(staff: staff, onSave: _loadStaffList),
        ),
        transitionBuilder: (context, anim1, anim2, child) {
          return SlideTransition(
            position: Tween(begin: const Offset(1, 0), end: const Offset(0, 0))
                .animate(CurvedAnimation(parent: anim1, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      drawer: const AppDrawer(currentScreen: DrawerScreen.staffProfile),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 90), // Offset for the custom menu bar
              _buildHeader(theme),
              Expanded(child: _buildMainContent(theme)),
            ],
          ),
          // Floating Top Menu Bar
          Positioned(
            top: 28, left: 16, right: 16,
            child: Builder(
              builder: (scaffoldContext) => CustomMenuBar(
                title: 'スタッフ管理',
                onMenuPressed: () => Scaffold.of(scaffoldContext).openDrawer(),
              ),
            ),
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }

  /// Search Bar and Add Button section.
  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            child: SearchBar(
              controller: _searchController,
              onChanged: _applyFilter,
              hintText: "名前で検索...",
              leading: const Icon(Icons.search),
            ),
          ),
          const SizedBox(width: 16),
          IconButton.filledTonal(
              onPressed: _loadStaffList, 
              icon: const Icon(Icons.refresh)
          ),
          const SizedBox(width: 16),
          FilledButton.icon(
              onPressed: () => _openStaffForm(),
              icon: const Icon(Icons.add),
              label: const Text('追加')
          ),
        ],
      ),
    );
  }

  /// The main data table container with horizontal and vertical scrolling.
  Widget _buildMainContent(ThemeData theme) {
    if (_filteredStaff.isEmpty && !_isLoading) {
      return const Center(child: Text("見つかりません"));
    }

    return Container(
      margin: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant.withOpacity(0.5))
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.vertical,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              // Ensures the DataTable fills at least the available screen width
              constraints: BoxConstraints(minWidth: MediaQuery.of(context).size.width - 48),
              child: DataTable(
                
                headingRowColor: WidgetStateProperty.all(theme.colorScheme.surfaceContainerHighest.withOpacity(0.3)),
                horizontalMargin: 24,
                columnSpacing: 24,
                columns: [
                  DataColumn(label: Text('No.', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                  DataColumn(label: Text('氏名', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                  DataColumn(label: Text('種別', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                  DataColumn(label: Text('性別', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                  DataColumn(label: Text('年齢', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                  DataColumn(label: Text('メール', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                  DataColumn(label: Text('Lv', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                  DataColumn(label: Text('操作', style: TextStyle(fontWeight: FontWeight.bold,color: Theme.of(context).colorScheme.onSurface))),
                ],
                rows: _filteredStaff.asMap().entries.map((entry) {
                  final index = entry.key;
                  final s = entry.value;
                  final id = s['id'] ?? s['ID'];
                  
                  return DataRow(
                    key: ValueKey('staff_$id'),
                    cells: [
                      DataCell(Text('${index + 1}')),
                      DataCell(Text(s['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w500))),
                      DataCell(_buildStatusChip(s['status'] ?? '', theme)),
                      DataCell(Text(s['gender'] == 'Male' ? '男性' : '女性')),
                      DataCell(Text(s['age']?.toString() ?? '-')),
                      DataCell(Text(s['e_mail'] ?? '-')),
                      DataCell(Text(s['level']?.toString() ?? '')),
                      DataCell(Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit_outlined, size: 20),
                            onPressed: () => _openStaffForm(s)
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                            onPressed: () => _confirmDelete(s)
                          ),
                        ],
                      )),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Returns a styled Chip based on the staff employment status.
  Widget _buildStatusChip(String status, ThemeData theme) {
    Color color = status == 'フルタイム' ? Colors.blue : (status == '留学生' ? Colors.orange : Colors.green);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color)
      ),
      child: Text(status, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold)),
    );
  }

  /// Deletion confirmation dialog.
  void _confirmDelete(Map<String, dynamic> staff) {
    final staffId = staff['id'] ?? staff['ID'];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('削除', style: TextStyle(color: Colors.red)),
        content: Text('${staff['name']}を削除しますか？'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('キャンセル')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.deleteStaffProfile(staffId);
              _loadStaffList();
            },
            child: const Text('削除', style: TextStyle(color: Colors.red))
          ),
        ],
      ),
    );
  }

  void _showSnackBar(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));
}

// ============================================================
// SHARED COMPONENTS: StaffFormBody
// ============================================================

/// Reusable form body shared between the Add Dialog and Edit Side Sheet.
class StaffFormBody extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name, email, age, level;
  final String status, gender;
  final Function(String?) onStatusChanged, onGenderChanged;

  const StaffFormBody({
    super.key, required this.formKey, required this.name, required this.email,
    required this.age, required this.level, required this.status, required this.gender,
    required this.onStatusChanged, required this.onGenderChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      key: formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextFormField(controller: name, decoration: const InputDecoration(labelText: '氏名', border: OutlineInputBorder()), validator: (v) => v!.isEmpty ? '必須' : null),
          const SizedBox(height: 16),
          TextFormField(controller: email, decoration: const InputDecoration(labelText: 'メール', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: TextFormField(controller: age, decoration: const InputDecoration(labelText: '年齢', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
              const SizedBox(width: 12),
              Expanded(child: TextFormField(controller: level, decoration: const InputDecoration(labelText: 'Lv (1-5)', border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            ],
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: status,
            decoration: const InputDecoration(labelText: '雇用形態', border: OutlineInputBorder()),
            items: ['高校生', '留学生', 'フルタイム', 'パートタイム'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: onStatusChanged,
          ),
          const SizedBox(height: 24),
          const Text("性別", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Male', label: Text('男性'), icon: Icon(Icons.male)),
                ButtonSegment(value: 'Female', label: Text('女性'), icon: Icon(Icons.female))
              ],
              selected: {gender},
              onSelectionChanged: (set) => onGenderChanged(set.first),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// CREATE MODE: Staff Add Dialog
// ============================================================

class _StaffAddDialog extends StatefulWidget {
  final VoidCallback onSave;
  const _StaffAddDialog({required this.onSave});
  @override
  State<_StaffAddDialog> createState() => _StaffAddDialogState();
}

class _StaffAddDialogState extends State<_StaffAddDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController(), _email = TextEditingController(), 
        _age = TextEditingController(), _level = TextEditingController();
  String _status = 'パートタイム', _gender = 'Male';

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('新規登録'),
      content: SizedBox(width: 450, child: SingleChildScrollView(child: StaffFormBody(
        formKey: _formKey, name: _name, email: _email, age: _age, level: _level, status: _status, gender: _gender,
        onStatusChanged: (v) => setState(() => _status = v!), 
        onGenderChanged: (v) => setState(() => _gender = v!),
      ))),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('キャンセル')),
        FilledButton(onPressed: () async {
          if (!_formKey.currentState!.validate()) return;
          await ApiService.postStaffProfile({
            'name': _name.text, 'e_mail': _email.text, 'age': int.tryParse(_age.text) ?? 0,
            'level': int.tryParse(_level.text) ?? 1, 'gender': _gender, 'status': _status
          });
          widget.onSave();
          Navigator.pop(context);
        }, child: const Text('保存')),
      ],
    );
  }
}

// ============================================================
// EDIT MODE: Staff Edit Side Sheet
// ============================================================

class _StaffEditSideSheet extends StatefulWidget {
  final Map<String, dynamic> staff;
  final VoidCallback onSave;
  const _StaffEditSideSheet({required this.staff, required this.onSave});
  @override
  State<_StaffEditSideSheet> createState() => _StaffEditSideSheetState();
}


class _StaffEditSideSheetState extends State<_StaffEditSideSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _name, _email, _age, _level;
  late String _status, _gender;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.staff['name']?.toString());
    _email = TextEditingController(text: widget.staff['e_mail']?.toString());
    _age = TextEditingController(text: widget.staff['age']?.toString());
    _level = TextEditingController(text: widget.staff['level']?.toString());
    _status = widget.staff['status'] ?? 'パートタイム';
    _gender = widget.staff['gender'] ?? 'Male';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Material(
      // surface automatically switches between white (light) and dark gray (dark)
      color: theme.colorScheme.surface,
      child: Container(
        width: 450,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          // Uses the theme's standard divider/outline color
          border: Border(left: BorderSide(color: theme.colorScheme.outlineVariant)),
          boxShadow: [
            BoxShadow(
              // Adaptive shadow: softer in dark mode
              color: theme.brightness == Brightness.light 
                  ? Colors.black.withOpacity(0.1) 
                  : Colors.black.withOpacity(0.4), 
              blurRadius: 10,
            )
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween, 
              children: [
                Text(
                  '編集', 
                  style: theme.textTheme.headlineSmall?.copyWith(
                    // Forces the text to be black in light mode and white in dark mode
                    color: theme.colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context), 
                  icon: const Icon(Icons.close),
                  // Secondary text/icon color for the close button
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: StaffFormBody(
                  formKey: _formKey, 
                  name: _name, 
                  email: _email, 
                  age: _age, 
                  level: _level, 
                  status: _status, 
                  gender: _gender,
                  onStatusChanged: (v) => setState(() => _status = v!), 
                  onGenderChanged: (v) => setState(() => _gender = v!),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity, 
              height: 50, 
              child: FilledButton(
                onPressed: _isSaving ? null : _handleSave,
                child: _isSaving 
                  ? const SizedBox(
                      width: 20, 
                      height: 20, 
                      child: CircularProgressIndicator(
                        strokeWidth: 2, 
                        // Automatically uses the theme's "onPrimary" color
                        color: Colors.white, 
                      ),
                    ) 
                  : const Text('保存'),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await ApiService.patchStaffProfile(widget.staff['id'] ?? widget.staff['ID'], {
        'name': _name.text, 
        'e_mail': _email.text, 
        'age': int.tryParse(_age.text) ?? 0,
        'level': int.tryParse(_level.text) ?? 1, 
        'gender': _gender, 
        'status': _status
      });
      widget.onSave();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('保存に失敗しました')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }
}