import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StaffProfileApp extends StatelessWidget {
  const StaffProfileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Staff Profile',
      home: StaffProfileForm(),
    );
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

  String _selectedGender = 'Male';
  bool _morningShift = false;
  bool _lunchShift = false;
  bool _nightShift = false;

  Future<void> _submitProfile() async {
    if (_formKey.currentState!.validate()) {
      final staffData = {
        'id': _idController.text,
        'name': _nameController.text,
        'age': _ageController.text,
        'level': _levelController.text,
        'gender': _selectedGender,
        'shifts': {
          'morning': _morningShift,
          'lunch': _lunchShift,
          'night': _nightShift,
        }
      };

      // Replace with your actual API URL
      final url = Uri.parse('http://127.0.0.1:5000/testing');

      try {
        final response = await http.post(
          url,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(staffData),
        );

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Success'),
              content: Text(responseData['message'] ?? 'Staff profile submitted!'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          throw Exception('Failed to submit data');
        }
      } catch (e) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Error: $e'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    _ageController.dispose();
    _levelController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Staff Profile Input')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(
                  labelText: 'Staff ID',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter staff ID' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (value) =>
                    value!.isEmpty ? 'Please enter name' : null,
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter age';
                  }
                  final age = int.tryParse(value);
                  if (age == null || age < 18 || age > 100) {
                    return 'Age must be between 18 and 100';
                  }
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
                  if (value == null || value.isEmpty) {
                    return 'Please enter level';
                  }
                  final level = int.tryParse(value);
                  if (level == null || level < 1 || level > 5) {
                    return 'Level must be a number between 1 and 5';
                  }
                  return null;
                },
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
                  DropdownMenuItem(value: 'Other', child: Text('Other')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedGender = value!;
                  });
                },
              ),
              const SizedBox(height: 20),
              const Text('Available Shifts',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              CheckboxListTile(
                title: const Text('Morning Shift'),
                value: _morningShift,
                onChanged: (val) => setState(() => _morningShift = val!),
              ),
              CheckboxListTile(
                title: const Text('Lunch Shift'),
                value: _lunchShift,
                onChanged: (val) => setState(() => _lunchShift = val!),
              ),
              CheckboxListTile(
                title: const Text('Night Shift'),
                value: _nightShift,
                onChanged: (val) => setState(() => _nightShift = val!),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submitProfile,
                child: const Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
