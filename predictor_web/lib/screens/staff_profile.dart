import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _ageController = TextEditingController();
  final TextEditingController _levelController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController searchController = TextEditingController();

  String _selectedGender = 'Male';
  bool isSearching = false;
  String searchText = '';

  final String baseUrl = 'http://127.0.0.1:5000/services/staff';

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _levelController.dispose();
    _emailController.dispose();
    searchController.dispose();
    super.dispose();
  }

  void _clearFields() {
    setState(() {
      _idController.clear();
      _nameController.clear();
      _ageController.clear();
      _levelController.clear();
      _emailController.clear();
      _selectedGender = 'Male';
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

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final staffData = {
        'name': _nameController.text,
        'age': _ageController.text,
        'level': _levelController.text,
        'gender': _selectedGender,
        'email': _emailController.text,
      };

      try {
        final response = await http.post(
          Uri.parse(baseUrl),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(staffData),
        );

        final res = jsonDecode(response.body);
        if (!mounted) return;
        _showMessage(response.statusCode == 200 ? 'Success' : 'Error', res['message'] ?? 'Unknown response');
        if (response.statusCode == 200) _clearFields();
      } catch (e) {
        if (!mounted) return;
        _showMessage('Error', 'Submit failed: $e');
      }
    }
  }
//Have some logical error-> Kyipyar Hlaing
  // Future<void> _editProfile() async {
  //   if (_formKey.currentState!.validate() && _idController.text.isNotEmpty) {
  //     final updates = {
  //       'name': _nameController.text,
  //       'age': _ageController.text,
  //       'level': _levelController.text,
  //       'gender': _selectedGender,
  //       'email': _emailController.text,
  //     };

  //     try {
  //       final response = await http.put(
  //         Uri.parse('$baseUrl/${_idController.text}'),
  //         headers: {'Content-Type': 'application/json'},
  //         body: jsonEncode(updates),
  //       );

  //       final res = jsonDecode(response.body);
  //       if (!mounted) return;
  //       _showMessage(response.statusCode == 200 ? 'Updated' : 'Error', res['message'] ?? 'No message');
  //     } catch (e) {
  //       if (!mounted) return;
  //       _showMessage('Error', 'Edit failed: $e');
  //     }
  //   } else {
  //     _showMessage('Missing ID', 'Enter staff ID to edit.');
  //   }
  // }

  // Future<void> _deleteProfile() async {
  //   if (_idController.text.isEmpty) {
  //     _showMessage('Missing ID', 'Enter staff ID to delete.');
  //     return;
  //   }

  //   try {
  //     final response = await http.delete(Uri.parse('$baseUrl/${_idController.text}'));
  //     final res = jsonDecode(response.body);
  //     if (!mounted) return;
  //     _showMessage(response.statusCode == 200 ? 'Deleted' : 'Error', res['message'] ?? 'No message');
  //     if (response.statusCode == 200) _clearFields();
  //   } catch (e) {
  //     if (!mounted) return;
  //     _showMessage('Error', 'Delete failed: $e');
  //   }
  // }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !isSearching
            ? const Text('Staff Profile')
            : TextField(
                controller: searchController,
                autofocus: true,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  hintText: 'Search by Name...',
                  hintStyle: TextStyle(color: Colors.white70),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    searchText = value;
                  });
                },
              ),
        actions: [
          IconButton(
            icon: Icon(isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (isSearching) {
                  searchText = '';
                  searchController.clear();
                }
                isSearching = !isSearching;
              });
            },
          )
        ],
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              // TextFormField(
              //   controller: _idController,
              //   keyboardType: TextInputType.number,
              //   decoration: const InputDecoration(
              //     labelText: 'Staff ID (for Edit/Delete)',
              //     border: OutlineInputBorder(),
              //   ),
              // ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value!.isEmpty ? 'Please enter name' : null,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
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
              const SizedBox(height: 16),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please enter email' : null,
              ),
              const SizedBox(height: 16),
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
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(onPressed: _submitProfile, child: const Text('Submit')),
                  const SizedBox(width: 20),
                  ElevatedButton(onPressed:(){},// _editProfile, 
                  child: const Text('Edit')),
                  const SizedBox(width: 20),
                  ElevatedButton(onPressed:() {},//_deleteProfile, 
                  child: const Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
