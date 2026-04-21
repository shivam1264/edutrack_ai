import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../utils/app_theme.dart';
import '../../models/user_model.dart';
import '../../services/class_service.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AddUserScreen extends StatefulWidget {
  const AddUserScreen({super.key});

  @override
  State<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends State<AddUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _authService = AuthService();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _schoolIdController = TextEditingController(text: 'SCH001'); // Default
  String _selectedRole = 'student';
  String? _selectedClassId; // for students
  List<String> _selectedAssignedClasses = []; // for teachers
  final _parentOfController = TextEditingController();

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
            backgroundColor: AppTheme.danger,
            foregroundColor: Colors.white,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
                  Positioned(
                    top: -20, right: -20,
                    child: Icon(Icons.person_add_alt_1_rounded, color: Colors.white.withOpacity(0.1), size: 200),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Register Hub Member', style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w900)),
                        Text('Onboard new students, teachers, or parents', style: TextStyle(color: Colors.white70, fontSize: 13)),
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
                                if (_selectedRole == 'student' || _selectedRole == 'teacher')
                                if (_selectedRole == 'student')
                                  StreamBuilder<List<ClassModel>>(
                                    stream: ClassService().getClasses(),
                                    builder: (context, snapshot) {
                                      final classes = snapshot.data ?? [];
                                      return DropdownButtonFormField<String>(
                                        value: _selectedClassId,
                                        decoration: InputDecoration(
                                          labelText: 'Assign Primary Hub',
                                          prefixIcon: const Icon(Icons.hub_rounded, color: AppTheme.primary, size: 20),
                                          filled: true,
                                          fillColor: AppTheme.bgLight,
                                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                                        ),
                                        items: classes.map((c) => DropdownMenuItem(
                                          value: c.displayName, 
                                          child: Text(c.displayName)
                                        )).toList(),
                                        hint: const Text('Select a standardized hub'),
                                        onChanged: (v) => setState(() => _selectedClassId = v),
                                        validator: (v) => v == null ? 'Hub assignment required' : null,
                                      );
                                    },
                                  ),
                                if (_selectedRole == 'teacher')
                                  StreamBuilder<List<ClassModel>>(
                                    stream: ClassService().getClasses(),
                                    builder: (context, snapshot) {
                                      final classes = snapshot.data ?? [];
                                      return Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('ASSIGN MULTIPLE HUBS', style: TextStyle(fontWeight: FontWeight.w900, color: AppTheme.textHint, fontSize: 10, letterSpacing: 1.2)),
                                          const SizedBox(height: 12),
                                          Wrap(
                                            spacing: 8,
                                            runSpacing: 8,
                                            children: classes.map((c) {
                                              final isSelected = _selectedAssignedClasses.contains(c.displayName);
                                              return FilterChip(
                                                label: Text(c.displayName, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontSize: 12, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w500)),
                                                selected: isSelected,
                                                onSelected: (selected) {
                                                  setState(() {
                                                    if (selected) {
                                                      _selectedAssignedClasses.add(c.displayName);
                                                    } else {
                                                      _selectedAssignedClasses.remove(c.displayName);
                                                    }
                                                  });
                                                },
                                                selectedColor: AppTheme.primary,
                                                checkmarkColor: Colors.white,
                                                backgroundColor: AppTheme.bgLight,
                                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppTheme.primary : AppTheme.borderLight)),
                                              );
                                            }).toList(),
                                          ),
                                          if (_selectedAssignedClasses.isEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 8.0),
                                              child: Text('At least one hub must be assigned to faculty.', style: TextStyle(color: AppTheme.danger, fontSize: 11)),
                                            ),
                                        ],
                                      );
                                    },
                                  ),
                                  if (_selectedRole == 'parent')
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        _buildTextField(
                                          controller: _parentOfController,
                                          label: "Children's Educational UIDs",
                                          icon: Icons.child_care_rounded,
                                          validator: (v) => v!.isEmpty ? 'At least one child link ID required' : null,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Separate multiple UIDs with commas (e.g., UID1, UID2)',
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
        parentOf: _selectedRole == 'parent' 
            ? _parentOfController.text.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
            : null,
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
          border: Border.all(color: isSelected ? AppTheme.primary : AppTheme.borderLight),
          boxShadow: isSelected ? [BoxShadow(color: AppTheme.primary.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))] : [],
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.white : AppTheme.textSecondary, size: 18),
            const SizedBox(width: 10),
            Text(title, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textPrimary, fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600, fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
