import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
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
  final _rollNoCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  
  String? _selectedClassId;
  String _foundStudentName = '';
  String _foundStudentId = '';
  
  // List to track multiple children
  final List<Map<String, String>> _linkedStudents = [];
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
              const SizedBox(height: 24),
              
              // --- Multiple Child Linking Section ---
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.hub_rounded, size: 16, color: Colors.green),
                        SizedBox(width: 8),
                        Text('LINK CHILDREN', style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green, fontSize: 12, letterSpacing: 1.1)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Display Linked Children
                    if (_linkedStudents.isNotEmpty) ...[
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _linkedStudents.map((student) => Chip(
                          label: Text(student['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                          avatar: const Icon(Icons.child_care_rounded, size: 16, color: Colors.green),
                          deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.red),
                          onDeleted: () => setState(() => _linkedStudents.remove(student)),
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.green[100]!),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        )).toList(),
                      ),
                      const SizedBox(height: 16),
                      const Divider(height: 1),
                      const SizedBox(height: 16),
                    ],

                    _buildLabel('Search Student by Class'),
                    StreamBuilder<List<ClassModel>>(
                      stream: ClassService().getClasses(),
                      builder: (context, snapshot) {
                        final classes = snapshot.data ?? [];
                        return DropdownButtonFormField<String>(
                          value: _selectedClassId,
                          decoration: _inputDecoration('Select Class', Icons.class_outlined),
                          items: classes.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.displayName))).toList(),
                          onChanged: (v) => setState(() {
                            _selectedClassId = v;
                            _foundStudentName = '';
                            _foundStudentId = '';
                            _rollNoCtrl.clear();
                          }),
                        );
                      }
                    ),
                    const SizedBox(height: 16),
                    _buildLabel('Search by Roll Number'),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _rollNoCtrl,
                            decoration: _inputDecoration('Enter roll number', Icons.numbers_rounded),
                            onChanged: (v) async {
                              if (v.isNotEmpty && _selectedClassId != null) {
                                final snap = await FirebaseFirestore.instance.collection('users')
                                  .where('role', isEqualTo: 'student')
                                  .where('class_id', isEqualTo: _selectedClassId)
                                  .where('roll_no', isEqualTo: v)
                                  .get();
                                
                                if (snap.docs.isNotEmpty) {
                                  setState(() {
                                    _foundStudentId = snap.docs.first.id;
                                    _foundStudentName = snap.docs.first.get('name');
                                  });
                                } else {
                                  setState(() {
                                    _foundStudentId = '';
                                    _foundStudentName = '';
                                  });
                                }
                              }
                            },
                          ),
                        ),
                        if (_foundStudentName.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          IconButton.filled(
                            onPressed: () {
                              if (!_linkedStudents.any((s) => s['id'] == _foundStudentId)) {
                                setState(() {
                                  _linkedStudents.add({'id': _foundStudentId, 'name': _foundStudentName});
                                  _foundStudentName = '';
                                  _foundStudentId = '';
                                  _rollNoCtrl.clear();
                                });
                              }
                            },
                            icon: const Icon(Icons.add_rounded),
                            style: IconButton.styleFrom(backgroundColor: Colors.green),
                          ),
                        ],
                      ],
                    ),
                    if (_foundStudentName.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Text('Found: $_foundStudentName', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 13)),
                      ).animate().fadeIn(),
                  ],
                ),
              ),
              const SizedBox(height: 24),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
      prefixIcon: Icon(icon, color: Colors.grey, size: 20),
      filled: true, fillColor: Colors.white,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[200]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.green)),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.black87)),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon, {TextInputType? keyboardType, bool isPassword = false}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: isPassword,
      decoration: _inputDecoration(hint, icon),
      validator: (v) => v!.isEmpty ? 'Field required' : null,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity, height: 56,
      child: ElevatedButton(
        onPressed: (_isLoading || _linkedStudents.isEmpty) ? null : _submit,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _isLoading 
          ? const CircularProgressIndicator(color: Colors.white) 
          : const Text('Register Parent', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_linkedStudents.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please link at least one student!'), backgroundColor: Colors.red));
      return;
    }
    
    setState(() => _isLoading = true);
    try {
      final List<String> childIds = _linkedStudents.map((s) => s['id']!).toList();
      
      await AuthService().register(
        name: _nameCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text.trim(),
        role: 'parent',
        schoolId: 'SCH001',
        parentOf: childIds,
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
