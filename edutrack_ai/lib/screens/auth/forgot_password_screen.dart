import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/glass_button.dart';
import '../../widgets/premium_card.dart';
import 'package:flutter_animate/flutter_animate.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _isSubmitting = false;
  bool _isSent = false;

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    try {
      await context.read<AuthProvider>().sendPasswordResetEmail(_emailCtrl.text.trim());
      setState(() => _isSent = true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: AppTheme.danger),
      );
    } finally {
      setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(decoration: const BoxDecoration(gradient: AppTheme.meshGradient)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: _isSent ? _buildSuccessView() : _buildRequestView(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequestView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.key_off_rounded, size: 60, color: Colors.white),
        ).animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 24),
        const Text(
          'Recovery System',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: 12),
        Text(
          'Enter your registered email to receive a secure recovery link.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 16),
        ).animate().fadeIn(delay: 400.ms),
        const SizedBox(height: 48),
        PremiumCard(
          padding: const EdgeInsets.all(32),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.alternate_email_rounded, color: AppTheme.primary),
                    hintText: 'user@school.com',
                  ),
                  validator: (val) => (val == null || !val.contains('@')) ? 'Invalid email' : null,
                ),
                const SizedBox(height: 32),
                GlassButton(
                  text: 'Request Recovery Link',
                  onPressed: _handleReset,
                  isLoading: _isSubmitting,
                  icon: Icons.send_rounded,
                ),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildSuccessView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.mark_email_read_rounded, size: 80, color: Colors.green),
        ).animate().scale(curve: Curves.easeOutBack),
        const SizedBox(height: 32),
        const Text(
          'Transmission Sent!',
          style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 16),
        Text(
          'A secure link has been sent to:\n${_emailCtrl.text}',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 18),
        ),
        const SizedBox(height: 12),
        const Text(
          'Please check your inbox (and spam) to reset your access key.',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        const SizedBox(height: 48),
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppTheme.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            child: const Text('Back to Secure Portal', style: TextStyle(fontWeight: FontWeight.w900)),
          ),
        ),
      ],
    ).animate().fadeIn();
  }
}
