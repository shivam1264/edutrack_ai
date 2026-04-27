import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/auth_service.dart';
import '../../../services/class_service.dart';
import '../../../models/class_model.dart';
import '../../../utils/app_theme.dart';
import '../../../widgets/premium_card.dart';
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
  final _passwordCtrl = TextEditingController(); // Blank by default
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
                        colors: [Color(0xFFECFDF5), Color(0xFFD1FAE5), Color(0xFFA7F3D0)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.family_restroom_rounded, color: const Color(0xFF10B981).withOpacity(0.1), size: 220),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Parental Onboarding', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('Onboard parents and guardians to the ecosystem', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
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
                                Icon(Icons.person_pin_rounded, size: 14, color: AppTheme.textHint),
                                SizedBox(width: 8),
                                Text('PERSONAL INFORMATION', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            _buildField(_nameCtrl, 'Guardian Full Name', Icons.person_rounded),
                            const SizedBox(height: 16),
                            _buildField(_emailCtrl, 'Email Address (Login ID)', Icons.alternate_email_rounded, keyboardType: TextInputType.emailAddress),
                            const SizedBox(height: 16),
                            _buildField(_passwordCtrl, 'Login Password', Icons.lock_outline_rounded, isPassword: true),
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
                                Icon(Icons.hub_rounded, size: 14, color: Color(0xFF10B981)),
                                SizedBox(width: 8),
                                Text('LINK CHILDREN', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF10B981), fontSize: 10, letterSpacing: 1.2)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Display Linked Children
                            if (_linkedStudents.isNotEmpty) ...[
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: _linkedStudents.map((student) => Chip(
                                  label: Text(student['name']!, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white)),
                                  avatar: const Icon(Icons.child_care_rounded, size: 16, color: Colors.white),
                                  deleteIcon: const Icon(Icons.cancel, size: 16, color: Colors.white70),
                                  onDeleted: () => setState(() => _linkedStudents.remove(student)),
                                  backgroundColor: const Color(0xFF10B981),
                                  side: BorderSide.none,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                )).toList(),
                              ),
                              const SizedBox(height: 20),
                              const Divider(height: 1, color: Color(0xFFF1F5F9)),
                              const SizedBox(height: 20),
                            ],

                            StreamBuilder<List<ClassModel>>(
                              stream: ClassService().getClasses(),
                              builder: (context, snapshot) {
                                final classes = snapshot.data ?? [];
                                return DropdownButtonFormField<String>(
                                  value: _selectedClassId,
                                  isExpanded: true,
                                  decoration: _inputDecoration('Search Student by Class', Icons.class_outlined),
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
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _rollNoCtrl,
                                    decoration: _inputDecoration('Search by Roll Number', Icons.numbers_rounded),
                                    keyboardType: TextInputType.text,
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
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF10B981),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            if (_foundStudentName.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, left: 4),
                                child: Text('Found: $_foundStudentName', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold, fontSize: 13)),
                              ).animate().fadeIn(),
                          ],
                        ),
                      ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      const SizedBox(height: 48),
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

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      labelText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFF10B981), size: 20),
      filled: true, fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFF10B981), width: 1.5)),
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
