import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddParentScreen extends StatefulWidget {
  const AddParentScreen({super.key});

  @override
  State<AddParentScreen> createState() => _AddParentScreenState();
}

class _AddParentScreenState extends State<AddParentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'parent123'); // Default
  final _childIdCtrl = TextEditingController(); // Link to student UID
  final _phoneCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Parent/Guardian', style: TextStyle(fontWeight: FontWeight.w900)),
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
                child: Container(
                  width: 100, height: 100,
                  decoration: BoxDecoration(color: Colors.green[50], shape: BoxShape.circle),
                  child: const Icon(Icons.family_restroom_rounded, color: Colors.green, size: 40),
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel('Guardian Full Name'),
              _buildField(_nameCtrl, 'Enter full name', Icons.person_outline_rounded),
              const SizedBox(height: 20),
              _buildLabel('Email Address (Login ID)'),
              _buildField(_emailCtrl, 'Enter guardian email', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildLabel('Login Password'),
              _buildField(_passwordCtrl, 'Set access password', Icons.lock_outline_rounded, isPassword: true),
              const SizedBox(height: 20),
              _buildLabel('Link to Student (Roll No/UID)'),
              _buildField(_childIdCtrl, 'Enter student roll number or UID', Icons.child_care_rounded),
              const SizedBox(height: 20),
              _buildLabel('Contact Number'),
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
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register Parent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: 'parent',
        schoolId: 'SCH001',
        parentOf: [_childIdCtrl.text.trim()],
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Parent account registered successfully! 👨‍👩‍👧‍👦'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
