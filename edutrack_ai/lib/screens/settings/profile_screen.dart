import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/cloudinary_service.dart';
import '../../models/user_model.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _picker = ImagePicker();
  bool _isUploading = false;
  
  late TextEditingController _nameCtrl;
  late TextEditingController _rollNoCtrl;
  late TextEditingController _bioCtrl;
  late TextEditingController _phoneCtrl;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    _nameCtrl = TextEditingController(text: user?.name ?? '');
    _rollNoCtrl = TextEditingController(text: user?.rollNo ?? '');
    _bioCtrl = TextEditingController(text: user?.toMap()['bio'] ?? '');
    _phoneCtrl = TextEditingController(text: user?.toMap()['phone'] ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _rollNoCtrl.dispose();
    _bioCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 500,
    );

    if (pickedFile == null) return;

    setState(() => _isUploading = true);
    
    try {
      final result = await CloudinaryService.instance.uploadFile(
        File(pickedFile.path),
        folder: 'profiles',
      );

      if (result != null && mounted) {
        await context.read<AuthProvider>().updateProfile({
          'avatar_url': result.secureUrl,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload image: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _saveProfile() async {
    final auth = context.read<AuthProvider>();
    await auth.updateProfile({
      'name': _nameCtrl.text.trim(),
      'roll_no': _rollNoCtrl.text.trim(),
      'bio': _bioCtrl.text.trim(),
      'phone': _phoneCtrl.text.trim(),
    });

    if (mounted) {
      if (auth.error == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Personal information updated.')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${auth.error}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    final isLoading = context.watch<AuthProvider>().isLoading;

    if (user == null) return const Scaffold(body: Center(child: Text('Not logged in')));

    return Scaffold(
      backgroundColor: AppTheme.bgLight,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(user),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   _buildRoleChip(user.role.name.toUpperCase()),
                   const SizedBox(height: 24),
                   
                   _buildSectionTitle('IDENTIFICATION'),
                   const SizedBox(height: 12),
                   _buildTextField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    icon: Icons.person_outline_rounded,
                   ),
                   const SizedBox(height: 20),
                   _buildTextField(
                    label: 'Email Address',
                    initialValue: user.email,
                    icon: Icons.alternate_email_rounded,
                    enabled: false,
                   ),
                    if (user.role == UserRole.student) ...[
                      const SizedBox(height: 20),
                      _buildTextField(
                       label: 'Roll Number',
                       controller: _rollNoCtrl,
                       icon: Icons.numbers_rounded,
                       enabled: user.rollNo == null || user.rollNo!.isEmpty,
                       onChanged: (v) => setState(() {}),
                      ),
                      if (user.rollNo == null || user.rollNo!.isEmpty)
                        const Padding(
                          padding: EdgeInsets.only(left: 16, top: 4),
                          child: Text('Add your roll number for attendance.', style: TextStyle(color: AppTheme.secondary, fontSize: 11, fontWeight: FontWeight.bold)),
                        ),
                    ],
                   
                   const SizedBox(height: 32),
                   _buildSectionTitle('PERSONAL INFO'),
                   const SizedBox(height: 12),
                   _buildTextField(
                    label: 'Bio / Tagline',
                    controller: _bioCtrl,
                    icon: Icons.auto_fix_high_rounded,
                    maxLines: 3,
                   ),
                   const SizedBox(height: 20),
                   _buildTextField(
                    label: 'Phone Number',
                    controller: _phoneCtrl,
                    icon: Icons.phone_android_rounded,
                    keyboardType: TextInputType.phone,
                   ),

                   const SizedBox(height: 48),
                   SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 0,
                      ),
                      child: isLoading 
                        ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                    ),
                   ),
                   const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(user) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: AppTheme.primary,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF065F46), Color(0xFF059669), Color(0xFF10B981)],
                ),
              ),
            ),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 40),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: user.avatarUrl != null 
                          ? CachedNetworkImageProvider(user.avatarUrl!) 
                          : null,
                        child: user.avatarUrl == null 
                          ? Text(user.name[0].toUpperCase(), style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: AppTheme.primary))
                          : null,
                      ),
                    ),
                    if (_isUploading)
                       const Positioned.fill(
                         child: Center(child: CircularProgressIndicator(color: Colors.white)),
                       ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickAndUploadImage,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, color: AppTheme.primary, size: 20),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  user.name,
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                ),
                Text(
                  user.schoolId,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppTheme.secondary.withOpacity(0.1),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: AppTheme.secondary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.verified_user_rounded, color: AppTheme.secondary, size: 14),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w900, fontSize: 11, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12, letterSpacing: 1.5, color: AppTheme.textHint),
    );
  }

  Widget _buildTextField({
    required String label,
    TextEditingController? controller,
    String? initialValue,
    required IconData icon,
    bool enabled = true,
    int maxLines = 1,
    TextInputType? keyboardType,
    ValueChanged<String>? onChanged,
  }) {
    return PremiumCard(
      opacity: 1,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: TextFormField(
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        enabled: enabled,
        maxLines: maxLines,
        keyboardType: keyboardType,
        onChanged: onChanged,
        style: const TextStyle(fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
        decoration: InputDecoration(
          icon: Icon(icon, color: AppTheme.primary, size: 20),
          labelText: label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, color: AppTheme.textHint, fontSize: 14),
          border: InputBorder.none,
          focusedBorder: InputBorder.none,
        ),
      ),
    );
  }
}
