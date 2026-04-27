import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../models/class_model.dart';
import '../../services/class_service.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddUserScreen extends StatefulWidget {
  final String? fixedRole;
  final String? fixedClassId;
  const AddUserScreen({super.key, this.fixedRole, this.fixedClassId});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _rollNoController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolIdController = TextEditingController(text: 'SCH001'); // Default
  late String _selectedRole;
  String? _selectedClassId; // for students
  List<String> _selectedAssignedClasses = []; // for teachers
  List<String> _selectedSubjects = []; // for teachers
  final _parentOfController = TextEditingController();
  String _searchQuery = ''; // For parent-child link display name

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.fixedRole ?? 'student';
    _selectedClassId = widget.fixedClassId;
  }

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
                        colors: [Color(0xFFEEF2FF), Color(0xFFE0E7FF), Color(0xFFC7D2FE)],
                      ),
                    ),
                  ),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.person_add_alt_1_rounded, color: const Color(0xFF6366F1).withOpacity(0.1), size: 220),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                      ),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(24, 0, 24, 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Member Onboarding', style: TextStyle(color: Color(0xFF0F172A), fontSize: 28, fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                        SizedBox(height: 4),
                        Text('Initialize new accounts for the school ecosystem', style: TextStyle(color: Color(0xFF475569), fontSize: 13, fontWeight: FontWeight.w500)),
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
                if (_isLoading)
                  const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator()))
                else
                  Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (widget.fixedRole == null)
                           _buildRoleSection().animate().fadeIn().slideY(begin: 0.1),
                        const SizedBox(height: 24),
                        
                        PremiumCard(
                          opacity: 1,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Row(
                                children: [
                                  Icon(Icons.badge_outlined, size: 14, color: AppTheme.textHint),
                                  SizedBox(width: 8),
                                  Text('IDENTIFICATION DETAILS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                                ],
                              ),
                              const SizedBox(height: 20),
                              _buildTextField(
                                controller: _nameController,
                                label: 'Full Official Name',
                                icon: Icons.person_rounded,
                                validator: (v) => v!.isEmpty ? 'Name required' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _emailController,
                                label: 'Corporate/Personal Email',
                                icon: Icons.alternate_email_rounded,
                                keyboardType: TextInputType.emailAddress,
                                validator: (v) => !v!.contains('@') ? 'Invalid email format' : null,
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: _passwordController,
                                label: 'Initial Access Password',
                                icon: Icons.key_rounded,
                                isPassword: true,
                                validator: (v) => v!.length < 6 ? 'Minimum 6 security digits' : null,
                              ),
                            ],
                          ),
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
                        
                        const SizedBox(height: 20),
                        
                        if (_selectedRole != 'admin')
                          PremiumCard(
                            opacity: 1,
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.link_rounded, size: 14, color: AppTheme.textHint),
                                    SizedBox(width: 8),
                                    Text('RELATIONAL MAPPING', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                                  ],
                                ),
                                const SizedBox(height: 20),
                                if (_selectedRole == 'student') ...[
                                  StreamBuilder<List<ClassModel>>(
                                    stream: ClassService().getClasses(),
                                    builder: (context, snapshot) {
                                      final classes = snapshot.data ?? [];
                                      return DropdownButtonFormField<String>(
                                        value: _selectedClassId,
                                        isExpanded: true,
                                        decoration: InputDecoration(
                                          labelText: 'Assign Primary Class',
                                          prefixIcon: const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
                                          filled: true, fillColor: AppTheme.bgLight,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                        ),
                                        items: classes.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.displayName))).toList(),
                                        onChanged: (v) => setState(() => _selectedClassId = v),
                                        validator: (v) => v == null ? 'Class assignment required' : null,
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildTextField(
                                    controller: _rollNoController,
                                    label: 'Class Roll Number',
                                    icon: Icons.numbers_rounded,
                                    keyboardType: TextInputType.text,
                                  ),
                                ],

                                if (_selectedRole == 'teacher')
                                  StreamBuilder<List<ClassModel>>(
                                    stream: ClassService().getClasses(),
                                    builder: (context, snapshot) {
                                      final classes = snapshot.data ?? [];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text('ASSIGN CLASSES', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 10)),
                                          const SizedBox(height: 12),
                                            Wrap(
                                              spacing: 8,
                                              children: classes.map((c) {
                                                final isSelected = _selectedAssignedClasses.contains(c.id);
                                                return FilterChip(
                                                  label: Text(c.displayName, style: TextStyle(
                                                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                                                    fontSize: 11,
                                                    fontWeight: FontWeight.w600
                                                  )),
                                                  selected: isSelected,
                                                  selectedColor: AppTheme.primary,
                                                  backgroundColor: const Color(0xFFF1F5F9),
                                                  checkmarkColor: Colors.white,
                                                  side: BorderSide(color: isSelected ? Colors.transparent : const Color(0xFFE2E8F0)),
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                  onSelected: (val) {
                                                    setState(() {
                                                      if (val) _selectedAssignedClasses.add(c.id);
                                                      else _selectedAssignedClasses.remove(c.id);
                                                    });
                                                  },
                                                );
                                              }).toList(),
                                            ),
                                        ],
                                      );
                                    },
                                  ),

                                if (_selectedRole == 'parent')
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('LINK CHILD ACCOUNT', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF64748B), fontSize: 10, letterSpacing: 1.2)),
                                        const SizedBox(height: 12),
                                        StreamBuilder<List<ClassModel>>(
                                          stream: ClassService().getClasses(),
                                          builder: (context, snapshot) {
                                            final classes = snapshot.data ?? [];
                                            return DropdownButtonFormField<String>(
                                              value: _selectedClassId, // Reuse or add new state
                                              decoration: InputDecoration(
                                                labelText: 'Student Class',
                                                prefixIcon: const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
                                                filled: true, fillColor: AppTheme.bgLight,
                                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                              ),
                                              items: classes.map((c) => DropdownMenuItem<String>(value: c.id, child: Text(c.displayName))).toList(),
                                              onChanged: (v) => setState(() => _selectedClassId = v),
                                            );
                                          }
                                        ),
                                        const SizedBox(height: 12),
                                        _buildTextField(
                                          controller: _rollNoController,
                                          label: "Student Roll Number",
                                          icon: Icons.numbers_rounded,
                                          keyboardType: TextInputType.text,
                                          onChanged: (v) async {
                                            if (v.length >= 1 && _selectedClassId != null) {
                                              final snap = await FirebaseFirestore.instance.collection('users')
                                                .where('role', isEqualTo: 'student')
                                                .where('class_id', isEqualTo: _selectedClassId)
                                                .where('roll_no', isEqualTo: v)
                                                .get();
                                              
                                              if (snap.docs.isNotEmpty) {
                                                setState(() {
                                                  _parentOfController.text = snap.docs.first.id;
                                                  _searchQuery = snap.docs.first.get('name'); // Reuse searchQuery for display
                                                });
                                              } else {
                                                setState(() {
                                                  _parentOfController.text = '';
                                                  _searchQuery = '';
                                                });
                                              }
                                            }
                                          },
                                        ),
                                        if (_searchQuery.isNotEmpty)
                                          Padding(
                                            padding: const EdgeInsets.only(top: 8.0, left: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                                                const SizedBox(width: 4),
                                                Text('Linked to: $_searchQuery', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                                              ],
                                            ),
                                          ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'System will automatically fetch UID using Class & Roll No.',
                                          style: TextStyle(color: AppTheme.textHint, fontSize: 10, fontStyle: FontStyle.italic),
                                        ),
                                      ],
                                    ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                        const SizedBox(height: 48),
                        SizedBox(
                          height: 60,
                          child: ElevatedButton.icon(
                            onPressed: _submitForm,
                            icon: const Icon(Icons.how_to_reg_rounded),
                            label: const Text('Initialize Account Creation', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                              elevation: 8,
                              shadowColor: AppTheme.primary.withOpacity(0.4),
                            ),
                          ),
                        ).animate().fadeIn(delay: 300.ms).scale(),
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

  Widget _buildRoleSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Designation Priority', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppTheme.textHint, letterSpacing: 1)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _RoleCard(role: 'student', title: 'Student', icon: Icons.school_rounded, isSelected: _selectedRole == 'student', onTap: () => setState(() => _selectedRole = 'student')),
              const SizedBox(width: 12),
              _RoleCard(role: 'teacher', title: 'Faculty', icon: Icons.psychology_rounded, isSelected: _selectedRole == 'teacher', onTap: () => setState(() => _selectedRole = 'teacher')),
              const SizedBox(width: 12),
              _RoleCard(role: 'parent', title: 'Guardian', icon: Icons.family_restroom_rounded, isSelected: _selectedRole == 'parent', onTap: () => setState(() => _selectedRole = 'parent')),
              const SizedBox(width: 12),
              _RoleCard(role: 'admin', title: 'Admin', icon: Icons.admin_panel_settings_rounded, isSelected: _selectedRole == 'admin', onTap: () => setState(() => _selectedRole = 'admin')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isPassword = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      keyboardType: keyboardType,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppTheme.primary, size: 20),
        filled: true,
        fillColor: AppTheme.bgLight,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      validator: validator,
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
        role: _selectedRole,
        schoolId: _schoolIdController.text.trim(),
        classId: _selectedRole == 'student' ? _selectedClassId : null,
        assignedClasses: _selectedRole == 'teacher' ? _selectedAssignedClasses : null,
        subjects: _selectedRole == 'teacher' ? _selectedSubjects : null,
        parentOf: _selectedRole == 'parent' 
            ? _parentOfController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : null,
        rollNo: _selectedRole == 'student' ? _rollNoController.text.trim() : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Deployment Successful! User account live. ⚡'),
            backgroundColor: AppTheme.secondary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deployment Error: $e'), backgroundColor: AppTheme.danger, behavior: SnackBarBehavior.floating),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}

class _RoleCard extends StatelessWidget {
  final String role;
  final String title;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleCard({required this.role, required this.title, required this.icon, required this.isSelected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppTheme.primary : const Color(0xFFE2E8F0), width: 1.5),
          boxShadow: isSelected 
              ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 6))] 
              : [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? Colors.white.withOpacity(0.2) : AppTheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : AppTheme.primary, size: 16),
            ),
            const SizedBox(width: 12),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : const Color(0xFF1E293B), fontWeight: isSelected ? FontWeight.w900 : FontWeight.w700, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
