import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddTeacherScreen extends StatefulWidget {
  const AddTeacherScreen({super.key});

  @override
  State<AddTeacherScreen> createState() => _AddTeacherScreenState();
}

class _AddTeacherScreenState extends State<AddTeacherScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _qualCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController(text: 'teacher123'); // Default password
  List<String> _selectedSubjects = [];
  List<String> _selectedClasses = [];
  bool _isLoading = false;

  final List<String> _subjectsList = [
    'Mathematics', 'Science', 'English', 'Hindi', 'History', 'Physics', 
    'Chemistry', 'Biology', 'Social Studies', 'Computer Science', 'Economics', 'Geography'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Add Teacher', style: TextStyle(fontWeight: FontWeight.w900)),
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
                  decoration: BoxDecoration(color: Colors.blue[50], shape: BoxShape.circle),
                  child: const Icon(Icons.psychology_rounded, color: Colors.blue, size: 40),
                ),
              ),
              const SizedBox(height: 32),
              _buildLabel('Full Name'),
              _buildField(_nameCtrl, 'Enter full name', Icons.person_outline_rounded),
              const SizedBox(height: 20),
              _buildLabel('Email Address (Login ID)'),
              _buildField(_emailCtrl, 'Enter official email', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 20),
              _buildLabel('Login Password'),
              _buildField(_passwordCtrl, 'Set access password', Icons.lock_outline_rounded, isPassword: true),
              const SizedBox(height: 20),
              
              _buildLabel('Assign Subjects (Select Multiple)'),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: _subjectsList.map((s) {
                  final isSelected = _selectedSubjects.contains(s);
                  return FilterChip(
                    label: Text(s, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12)),
                    selected: isSelected,
                    selectedColor: Colors.blueAccent,
                    checkmarkColor: Colors.white,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) _selectedSubjects.add(s);
                        else _selectedSubjects.remove(s);
                      });
                    },
                  );
                }).toList(),
              ),
              if (_selectedSubjects.isEmpty) 
                const Padding(
                  padding: EdgeInsets.only(top: 8, left: 4),
                  child: Text('Please select at least one subject', style: TextStyle(color: Colors.red, fontSize: 11)),
                ),
                
              const SizedBox(height: 20),
              _buildLabel('Assign Classes'),
              _buildClassSelector(),
              const SizedBox(height: 20),
              _buildLabel('Qualification'),
              _buildField(_qualCtrl, 'Enter qualification', Icons.school_outlined),
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
      ),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildClassSelector() {
    return StreamBuilder<List<ClassModel>>(
      stream: ClassService().getClasses(),
      builder: (context, snapshot) {
        final classes = snapshot.data ?? [];
        return Wrap(
          spacing: 8, runSpacing: 8,
          children: classes.map((c) {
            final isSelected = _selectedClasses.contains(c.id);
            return FilterChip(
              label: Text(c.displayName, style: TextStyle(color: isSelected ? Colors.white : Colors.black, fontSize: 12)),
              selected: isSelected,
              selectedColor: const Color(0xFF0F172A),
              checkmarkColor: Colors.white,
              onSelected: (selected) {
                setState(() {
                  if (selected) _selectedClasses.add(c.id);
                  else _selectedClasses.remove(c.id);
                });
              },
            );
          }).toList(),
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
        ),
        child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text('Register Faculty Member', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedSubjects.isEmpty || _selectedClasses.isEmpty) return;
    setState(() => _isLoading = true);
    try {
      await AuthService().register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: 'teacher',
        schoolId: 'SCH001',
        assignedClasses: _selectedClasses,
        subjects: _selectedSubjects,
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Faculty account created with multiple subjects! ⚡'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
