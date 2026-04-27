import 'package:flutter/material.dart';
import '../../../services/auth_service.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
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
  final _passwordCtrl = TextEditingController(); // Blank by default
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
                        colors: [Color(0xFFF5F3FF), Color(0xFFEDE9FE), Color(0xFFDDD6FE)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.psychology_rounded, color: const Color(0xFF8B5CF6).withOpacity(0.1), size: 220),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Faculty Recruitment', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('Onboard specialized teachers to the faculty pool', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
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
                                Icon(Icons.school_rounded, size: 14, color: AppTheme.textHint),
                                SizedBox(width: 8),
                                Text('PROFESSIONAL PROFILE', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildField(_nameCtrl, 'Faculty Full Name', Icons.person_rounded),
                            const SizedBox(height: 16),
                            _buildField(_emailCtrl, 'Official Email Address', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildField(_passwordCtrl, 'Initial Access Password', Icons.lock_outline_rounded, isPassword: true),
                            const SizedBox(height: 16),
                            _buildField(_qualCtrl, 'Qualification', Icons.history_edu_rounded),
                            const SizedBox(height: 16),
                            _buildField(_phoneCtrl, 'Contact Number', Icons.phone_android_rounded, keyboardType: TextInputType.phone),
                          ],
                        ),
                      ).animate().fadeIn().slideY(begin: 0.1),
                      const SizedBox(height: 24),
                      
                      PremiumCard(
                        opacity: 1,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.subject_rounded, size: 14, color: Color(0xFF8B5CF6)),
                                SizedBox(width: 8),
                                Text('SUBJECT SPECIALIZATION', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6), fontSize: 10, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Wrap(
                              spacing: 8, runSpacing: 8,
                              children: _subjectsList.map((s) {
                                final isSelected = _selectedSubjects.contains(s);
                                  return FilterChip(
                                    label: Text(s, style: TextStyle(
                                      color: isSelected ? Colors.white : const Color(0xFF1E293B), 
                                      fontSize: 11, 
                                      fontWeight: FontWeight.w600
                                    )),
                                    selected: isSelected,
                                    selectedColor: const Color(0xFF8B5CF6),
                                    backgroundColor: const Color(0xFFF1F5F9),
                                    checkmarkColor: Colors.white,
                                    side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) _selectedSubjects.add(s);
                                      else _selectedSubjects.remove(s);
                                    });
                                  },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 24),
                            const Row(
                              children: [
                                Icon(Icons.hub_rounded, size: 14, color: Color(0xFF8B5CF6)),
                                SizedBox(width: 8),
                                Text('ASSIGNED ACADEMIC UNITS', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF8B5CF6), fontSize: 10, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            _buildClassSelector(),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
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
        prefixIcon: Icon(icon, color: const Color(0xFF8B5CF6), size: 20),
        filled: true, fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              label: Text(c.displayName, style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF1E293B), 
                fontSize: 11, 
                fontWeight: FontWeight.w600
              )),
              selected: isSelected,
              selectedColor: const Color(0xFF8B5CF6),
              backgroundColor: const Color(0xFFF1F5F9),
              checkmarkColor: Colors.white,
              side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
