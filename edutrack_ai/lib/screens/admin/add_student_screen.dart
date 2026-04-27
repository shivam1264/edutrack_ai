import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../utils/app_theme.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
import '../../../widgets/premium_card.dart';
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
  final _passwordCtrl = TextEditingController(); // Blank by default
  final _phoneCtrl = TextEditingController();
  String? _selectedClassId;
  DateTime? _selectedDOB;
  String _selectedGender = 'Male';
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Colors.white,
            foregroundColor: const Color(0xFF0F172A),
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF0F9FF), Color(0xFFE0F2FE), Color(0xFFBAE6FD)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.school_rounded, color: const Color(0xFF3B82F6).withOpacity(0.1), size: 220),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Student Admission', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('Onboard a new student to the academic system', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      PremiumCard(
                        opacity: 1,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.badge_rounded, size: 14, color: AppTheme.textHint),
                                SizedBox(width: 8),
                                Text('ACADEMIC PROFILE', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildField(_nameCtrl, 'Full Name', Icons.person_rounded),
                            const SizedBox(height: 16),
                            _buildField(_emailCtrl, 'Personal Email Address', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildField(_passwordCtrl, 'Initial Access Password', Icons.lock_outline_rounded, isPassword: true),
                            const SizedBox(height: 16),
                            _buildClassDropdown(),
                            const SizedBox(height: 16),
                            _buildField(_rollNoCtrl, 'Class Roll Number', Icons.numbers_rounded, keyboardType: TextInputType.text),
                            const SizedBox(height: 16),
                            _buildField(_phoneCtrl, 'Parent Contact Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 40),
                      _buildSubmitButton(),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
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
        labelText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF2563EB), size: 20),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
          isExpanded: true,
          decoration: InputDecoration(
            labelText: 'Assigned Academic Unit',
            prefixIcon: const Icon(Icons.hub_rounded, color: Color(0xFF2563EB), size: 20),
            filled: true, fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.5)),
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
