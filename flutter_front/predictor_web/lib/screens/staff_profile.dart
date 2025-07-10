import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
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
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String _selectedGender = 'Male';
  String? _selectedStatus;

  final String baseUrl = 'http://127.0.0.1:5000/services/staff';
  late Future<List<String>> staffList;

  @override
  void initState() {
    super.initState();
    staffList = ApiService.fetchStaffList();
  }

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final staffData = {
        'name': _nameController.text,
        'age': _ageController.text,
        'level': _levelController.text,
        'gender': _selectedGender,
        'email': _emailController.text,
        'status': _selectedStatus,
      };

      try {
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(staffData),
        );

        final res = jsonDecode(response.body);
        if (!mounted) return;
        _showMessage(
          response.statusCode == 200 ? 'Success' : 'Error',
          res['message'] ?? 'Unknown response',
        );
        if (response.statusCode == 200) {
          _clearFields();
          setState(() {
            staffList = ApiService.fetchStaffList();
          });
        }
      } catch (e) {
        if (!mounted) return;
        _showMessage('Error', 'Submit failed: $e');
      }
    }
  }

  void _clearFields() {
    setState(() {
      _nameController.clear();
      _ageController.clear();
      _levelController.clear();
      _emailController.clear();
      _selectedGender = 'Male';
      _selectedStatus = null;
    });
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

  Future<void> _deleteProfileById(String id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/$id'));
      final res = jsonDecode(response.body);
      _showMessage(
        response.statusCode == 200 ? 'Deleted' : 'Error',
        res['message'] ?? 'No message',
      );
      if (response.statusCode == 200) {
        setState(() {
          staffList = ApiService.fetchStaffList();
        });
      }
    } catch (e) {
      _showMessage('Error', 'Delete failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Profile')),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value!.isEmpty ? 'Please enter name' : null,
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _ageController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Age',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter age';
                      final age = int.tryParse(value);
                      if (age == null || age < 18 || age > 100) return 'Age must be between 18 and 100';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _levelController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Level (1-5)',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Please enter level';
                      final level = int.tryParse(value);
                      if (level == null || level < 1 || level > 5) return 'Level must be 1 to 5';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedGender,
                    decoration: const InputDecoration(
                      labelText: 'Gender',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'Male', child: Text('Male')),
                      DropdownMenuItem(value: 'Female', child: Text('Female')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedGender = value!;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Status',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: '高校生', child: Text('高校生')),
                      DropdownMenuItem(value: '外国人労働者', child: Text('外国人労働者')),
                      DropdownMenuItem(value: 'フルタイム', child: Text('フルタイム')),
                      DropdownMenuItem(value: 'パートタイム', child: Text('パートタイム')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectedStatus = value;
                      });
                    },
                    validator: (value) => value == null ? 'Please select staff status' : null,
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _submitProfile,
                    child: const Text('Submit'),
                  ),
                  const Divider(height: 30, thickness: 1),
                ],
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
                future: staffList,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No staff found.'));
                  }

                  final staffList = snapshot.data!;
                  return ListView.builder(
                    itemCount: staffList.length,
                    itemBuilder: (context, index) {
                      return ListTile(
                        leading: const Icon(Icons.person),
                        title: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Expanded(child: Text(staffList[index])),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text("Edit"),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {},
                                  child: const Text("Delete"),
                                ),
                              ),
                            ],
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
    );
  }
}
