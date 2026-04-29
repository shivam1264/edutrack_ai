import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../utils/app_theme.dart';
import '../../widgets/premium_card.dart';
import '../../widgets/glass_button.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  bool _isSubmitting = false;

  late AnimationController _animCtrl;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _slideAnim =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut),
    );
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);

    final authProvider = context.read<AuthProvider>();
    await authProvider.login(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (mounted) {
      setState(() => _isSubmitting = false);
      final error = authProvider.error;
      if (error != null) {
        _showError(error);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: AppTheme.danger,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── Mesh Gradient Background ──
          Container(
            decoration: const BoxDecoration(gradient: AppTheme.meshGradient),
          ),
          
          // Subtle Overlay dots/patterns
          Opacity(
            opacity: 0.1,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://www.transparenttextures.com/patterns/carbon-fibre.png'),
                  repeat: ImageRepeat.repeat,
                ),
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // ── Header/Logo ──
                    Column(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                          ),
                          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 50),
                        ).animate().scale(duration: 600.ms, curve: Curves.easeOutBack).rotate(begin: 0.5, end: 0, duration: 600.ms),
                        const SizedBox(height: 20),
                        const Text(
                          'EduTrack AI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -1,
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 200.ms).slideY(begin: 0.2, end: 0),
                        Text(
                          'Your AI-Powered Academic Companion',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                            letterSpacing: 0.2,
                          ),
                        ).animate().fadeIn(duration: 600.ms, delay: 400.ms),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // ── Login Glass Card ──
                    PremiumCard(
                      padding: const EdgeInsets.all(32),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Enter your credentials to access your class portal',
                              style: TextStyle(
                                fontSize: 14,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 32),

                            // Email
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: const InputDecoration(
                                labelText: 'Email Address',
                                prefixIcon: Icon(Icons.alternate_email_rounded, color: AppTheme.primary),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Email is required';
                                if (!val.contains('@')) return 'Enter a valid email';
                                return null;
                              },
                            ),
                            const SizedBox(height: 20),

                            // Password
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscurePass,
                              style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600),
                              decoration: InputDecoration(
                                labelText: 'Password',
                                prefixIcon: const Icon(Icons.fingerprint_rounded, color: AppTheme.primary),
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _obscurePass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                    color: AppTheme.textSecondary,
                                  ),
                                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                                ),
                              ),
                              validator: (val) {
                                if (val == null || val.isEmpty) return 'Password is required';
                                return null;
                              },
                              onFieldSubmitted: (_) => _handleLogin(),
                            ),

                            const SizedBox(height: 8),

                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                                child: Text(
                                  'Forgot Key?',
                                  style: TextStyle(color: AppTheme.primary, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ),

                            const SizedBox(height: 24),

                            // Login Button
                            GlassButton(
                              text: 'Launch Dashboard',
                              onPressed: _handleLogin,
                              isLoading: _isSubmitting,
                              icon: Icons.rocket_launch_rounded,
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(duration: 800.ms, delay: 600.ms).slideY(begin: 0.1, end: 0),

                    const SizedBox(height: 48),

                    // Role indicator
                    Column(
                      children: [
                        Text(
                          'Select your access point',
                          style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 16),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _RoleChip(label: 'Admin', color: Colors.amber),
                              const SizedBox(width: 8),
                              _RoleChip(label: 'Teacher', color: Colors.cyan),
                              const SizedBox(width: 8),
                              _RoleChip(label: 'Student', color: Colors.lightGreenAccent),
                              const SizedBox(width: 8),
                              _RoleChip(label: 'Parent', color: Colors.orangeAccent),
                            ],
                          ),
                        ),
                      ],
                    ).animate().fadeIn(duration: 800.ms, delay: 1000.ms),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final Color color;

  const _RoleChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
