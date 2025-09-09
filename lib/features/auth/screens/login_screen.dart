// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../data/repositories/profile_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _loading = false;
  bool _obscure = true;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    return null;
  }

  Future<void> _routeAfterAuth() async {
    final repo = ProfileRepository();
    await repo.ensureRowExists(email: _email.text.trim());
    final profile = await repo.getMyProfile();
    final complete = profile?.onboardingComplete ?? false;

    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      complete ? '/home' : '/onboarding',
      (_) => false,
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _email.text.trim(),
        password: _password.text,
      );
      await _routeAfterAuth();
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _loginWithGoogle() {
    _toast('Google sign-in coming soon');
  }

  void _loginWithFacebook() {
    _toast('Facebook sign-in coming soon');
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = Color(brandPurple);

    final inputTheme = const InputDecorationTheme(
      isDense: true,
      contentPadding: EdgeInsets.symmetric(vertical: 10),
      labelStyle: TextStyle(
        color: Colors.white,
        fontSize: 14,
        letterSpacing: 0.2,
      ),
      floatingLabelBehavior: FloatingLabelBehavior.never,
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(width: 1.2, color: Colors.white70),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(width: 1.4, color: Colors.white),
      ),
      errorBorder: UnderlineInputBorder(
        borderSide: BorderSide(width: 1.2, color: Colors.redAccent),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderSide: BorderSide(width: 1.4, color: Colors.redAccent),
      ),
    );

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // base tint color (#EDF2FA)
          Container(color: const Color(0xFFEDF2FA)),
          // minimal background graphic with low opacity
          Opacity(
            opacity: 0.08,
            child: Image.asset(
              'assets/images/storytots_background.png',
              fit: BoxFit.cover,
            ),
          ),

          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Logo at top
                    Image.asset(
                      'assets/images/storytots_logo_front.png',
                      height: 72,
                    ),
                    const SizedBox(height: 24),

                    // Inputs Card (violet)
                    Card(
                      color: purple,
                      elevation: 10,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 28),
                        child: Form(
                          key: _formKey,
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              inputDecorationTheme: inputTheme,
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Email
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  cursorColor: Colors.white,
                                  decoration: const InputDecoration(
                                    labelText: 'Email',
                                  ),
                                ),
                                const SizedBox(height: 14),

                                // Password
                                TextFormField(
                                  controller: _password,
                                  validator: _passwordValidator,
                                  obscureText: _obscure,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16),
                                  cursorColor: Colors.white,
                                  decoration: InputDecoration(
                                    labelText: 'Password',
                                    suffixIcon: IconButton(
                                      onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      icon: Icon(
                                        _obscure
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ),
                                ),

                                // Forgot Password
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: _loading
                                        ? null
                                        : () => Navigator.pushNamed(
                                            context, '/forgot-password'),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.only(top: 8),
                                    ),
                                    child: const Text(
                                      'Forgot Password',
                                      style: TextStyle(color: Colors.white),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Divider "or login with"
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.black26,
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12.0),
                          child: Text(
                            'or login with',
                            style: TextStyle(color: Colors.black54),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 1,
                            color: Colors.black26,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 14),

                    // Social buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _SocialCircleButton(
                          color: const Color(0xFF1877F2),
                          icon: Icons.facebook,
                          onPressed: _loading ? null : _loginWithFacebook,
                        ),
                        const SizedBox(width: 24),
                        _SocialCircleButton(
                          color: Colors.white,
                          borderColor: Colors.black26,
                          child: const Text(
                            'G',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                              color: Colors.redAccent,
                            ),
                          ),
                          onPressed: _loading ? null : _loginWithGoogle,
                        ),
                      ],
                    ),

                    const SizedBox(height: 22),

                    // Main Login button (purple pill with shadow)
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: purple,
                          foregroundColor: Colors.white,
                          elevation: 8,
                          shadowColor: purple.withOpacity(0.6),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.2,
                          ),
                        ),
                        child: Text(_loading ? 'Logging in…' : 'Login'),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Create Account
                    TextButton(
                      onPressed: _loading
                          ? null
                          : () => Navigator.pushReplacementNamed(
                              context, '/signup'),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: Colors.black87,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

class _SocialCircleButton extends StatelessWidget {
  const _SocialCircleButton({
    this.icon,
    this.child,
    this.color = Colors.white,
    this.borderColor,
    required this.onPressed,
  });

  final IconData? icon;
  final Widget? child;
  final Color color;
  final Color? borderColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      shape: const CircleBorder(),
      color: color,
      elevation: 4,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onPressed,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor!, width: 1)
                : null,
          ),
          alignment: Alignment.center,
          child: icon != null
              ? Icon(icon, color: Colors.white)
              : child,
        ),
      ),
    );
  }
}
