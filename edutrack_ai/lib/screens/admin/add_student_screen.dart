import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class AddStudentScreen extends StatefulWidget {
  const AddStudentScreen({super.key});

  @override
  State<AddStudentScreen> createState() => _AddStudentScreenState();
}

class _AddStudentScreenState extends State<AddStudentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _rollNoCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'student123'); // Default password
  final _phoneCtrl = TextEditingController();
  String? _selectedClassId;
  DateTime? _selectedDOB;
  String _selectedGender = 'Male';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Student', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Stack(
                  children: [
                    Container(
                      width: 100, height: 100,
                      decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt_rounded, color: Colors.grey, size: 40),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel('Full Name'),
              _buildField(_nameCtrl, 'Enter full name', Icons.person_outline_rounded),
              const SizedBox(height: 20),
              _buildLabel('Email Address'),
              _buildField(_emailCtrl, 'Enter student email', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildLabel('Login Password'),
              _buildField(_passwordCtrl, 'Set access password', Icons.lock_outline_rounded, isPassword: true),
              const SizedBox(height: 20),
              _buildLabel('Class'),
              _buildClassDropdown(),
              const SizedBox(height: 20),
              _buildLabel('Roll Number'),
              _buildField(_rollNoCtrl, 'Enter roll number', Icons.numbers_rounded, keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              _buildLabel('Contact Number (Parent)'),
              _buildField(_phoneCtrl, 'Enter contact number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
              const SizedBox(height: 40),
              _buildSubmitButton(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        prefixIcon: Icon(icon, color: Colors.grey, size: 20),
        filled: true, fillColor: Colors.grey[50],
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F172A))),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildClassDropdown() {
    return StreamBuilder<List<ClassModel>>(
      stream: ClassService().getClasses(),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];
        return DropdownButtonFormField<String>(
          value: _selectedClassId,
          decoration: InputDecoration(
            hintText: 'Select class',
            prefixIcon: const Icon(Icons.hub_rounded, color: Colors.grey, size: 20),
            filled: true, fillColor: Colors.grey[50],
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
          ),
          items: classes.map((c) => DropdownMenuItem(value: c.id, child: Text(c.displayName))).toList(),
          onChanged: (v) => setState(() => _selectedClassId = v),
          validator: (v) => v == null ? 'Please select a class' : null,
        );
      },
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2563EB),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Save Student', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedClassId == null) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: 'student',
        schoolId: 'SCH001',
        classId: _selectedClassId,
        rollNo: _rollNoCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student registered successfully with personal email! ✅'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
