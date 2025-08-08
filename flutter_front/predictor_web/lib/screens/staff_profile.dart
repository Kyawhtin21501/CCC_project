import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:predictor_web/api_services/api_services.dart';

import 'package:predictor_web/widgets/appdrawer.dart';

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
      _staffList = ApiService.fetchStaffList();
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
      _showMessage('Error', 'Invalid ID. Please enter a valid number.');
      return;
    }

    try {
      final response = await ApiService.deleteStaffProfile(intId);
      final res = jsonDecode(response.body);

      _showMessage(
        response.statusCode == 200 ? 'Deleted' : 'Error',
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
            title: const Text('Edit Staff'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter Staff ID to edit:'),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) => enteredId = value,
                  decoration: const InputDecoration(
                    hintText: 'Staff ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  if (enteredId.isEmpty) {
                    _showMessage('Error', 'ID is required.');
                    return;
                  }

                  final id = int.tryParse(enteredId);
                  if (id == null) {
                    _showMessage('Error', 'Invalid ID.');
                    return;
                  }

                  try {
                    final staff = await ApiService.fetchStaffById(id);
                    _openEditFormDialog(id, staff);
                  } catch (e) {
                    _showMessage('Error', 'Fetch failed: $e');
                  }
                },
                child: const Text('Edit'),
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
            title: Text('Delete $name'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Enter the staff ID to confirm deletion:'),
                const SizedBox(height: 10),
                TextField(
                  keyboardType: TextInputType.number,
                  onChanged: (value) => enteredId = value,
                  decoration: const InputDecoration(
                    hintText: 'Staff ID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  if (enteredId.isNotEmpty) {
                    _deleteProfileById(enteredId);
                  } else {
                    _showMessage('Error', 'ID is required for deletion.');
                  }
                },
                child: const Text('Delete'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Profile')),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Container(
          color: Colors.white,
          child: Column(
            children: [
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
               
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField(_nameController, 'Name'),
                        const SizedBox(height: 10),
                        _buildNumberField(_ageController, 'Age', 18, 100),
                        const SizedBox(height: 10),
                        _buildNumberField(_levelController, 'Level (1-5)', 1, 5),
                        const SizedBox(height: 10),
                        _buildTextField(_emailController, 'Email', isEmail: true),
                        const SizedBox(height: 10),
                        _buildGenderDropdown(),
                        const SizedBox(height: 10),
                        _buildStatusDropdown(),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: _submitProfile,
                           style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                          child: const Text('Submit'),
                        ),
                       
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Staff List',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: FutureBuilder<List<String>>(
                  future: _staffList,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text('No staff found.'));
                    }
          
                    final staffNames = snapshot.data!;
                    return ListView.builder(
                      itemCount: staffNames.length,
                      itemBuilder: (context, index) {
                        final name = staffNames[index];
                        return Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Card(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                elevation: 2,
                                color: Colors.white,
                            child: ListTile(
                              leading: const Icon(Icons.person),
                              title: Text(name),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                                              ),
                                    onPressed: () => _showEditDialog(),
                                    child: const Text('Edit'),
                                  ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () => _confirmDeleteWithIdPrompt(name),
                                   style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                                              ),
                                    child: const Text(
                                      'Delete',
                                      style: TextStyle(color: Colors.white),
                                    ),
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
              ),
            ],
          ),
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
            title: Text('Edit Staff ID: $staffId'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildEditField(editName, 'Name'),
                  const SizedBox(height: 10),
                  _buildEditNumberField(editAge, 'Age', 18, 100),
                  const SizedBox(height: 10),
                  _buildEditNumberField(editLevel, 'Level (1-5)', 1, 5),
                  const SizedBox(height: 10),
                  _buildEditField(editEmail, 'Email'),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: gender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (val) => gender = val!,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: status,
                    decoration: const InputDecoration(
                      labelText: 'Status',
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
                child: const Text('Leave'),
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
                child: const Text('Update'),
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
              value == null || value.isEmpty ? 'Please enter $label' : null,
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
        if (value == null || value.isEmpty) return 'Please enter $label';
        final number = int.tryParse(value);
        if (number == null || number < min || number > max) {
          return '$label must be between $min and $max';
        }
        return null;
      },
    );
  }

  Widget _buildGenderDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedGender,
      decoration: const InputDecoration(
        labelText: 'Gender',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: 'Male', child: Text('Male')),
        DropdownMenuItem(value: 'Female', child: Text('Female')),
      ],
      onChanged: (value) => setState(() => _selectedGender = value!),
    );
  }

  Widget _buildStatusDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedStatus,
      decoration: const InputDecoration(
        labelText: 'Status',
        border: OutlineInputBorder(),
      ),
      items: const [
        DropdownMenuItem(value: '高校生', child: Text('高校生')),
        DropdownMenuItem(value: '留学生', child: Text('留学生')),
        DropdownMenuItem(value: 'フルタイム', child: Text('フルタイム')),
        DropdownMenuItem(value: 'パートタイム', child: Text('パートタイム')),
      ],
      onChanged: (value) => setState(() => _selectedStatus = value),
      validator: (value) => value == null ? 'Please select staff status' : null,
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
          return '$label must be between $min and $max';
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
