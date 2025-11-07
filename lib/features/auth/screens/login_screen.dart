// lib/features/auth/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../data/repositories/profile_repository.dart';
import '../../../../data/repositories/auth_cache_repository.dart';
import '../../../../data/repositories/role_mode_repository.dart';
import '../../../../data/repositories/reading_activity_repository.dart';
import '../../../../data/repositories/progress_repository.dart';
import '../../../../data/repositories/difficult_words_repository.dart';
import '../../../../data/repositories/assessment_repository.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _authCache = AuthCacheRepository();
  String _selectedMode = 'kid'; // 'kid' or 'parent'
  final _roleRepo = RoleModeRepository();

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

      // Cache the session for persistent login
      await _authCache.cacheCurrentSession();

      // Persist chosen role mode
      await _roleRepo.setMode(_selectedMode);

      // Best-effort: flush any locally queued data to Supabase
      try {
        await ReadingActivityRepository().flushQueue();
      } catch (_) {}
      try {
        await ProgressRepository().flushPendingProgress();
      } catch (_) {}
      try {
        final uid = Supabase.instance.client.auth.currentUser?.id ?? '';
        await DifficultWordsRepository().flushToServer(userId: uid);
      } catch (_) {}
      try {
        // Also ensure completed assessments are synced to Supabase and cache refreshed
        await AssessmentRepository().getCompletedStoryIds();
      } catch (_) {}

      await _routeAfterAuth();
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
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
                          horizontal: 20,
                          vertical: 28,
                        ),
                        child: Form(
                          key: _formKey,
                          child: Theme(
                            data: Theme.of(
                              context,
                            ).copyWith(inputDecorationTheme: inputTheme),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Role toggle (segmented)
                                _RoleSegmentedToggle(
                                  value: _selectedMode,
                                  onChanged: _loading
                                      ? null
                                      : (v) => setState(() => _selectedMode = v),
                                ),
                                const SizedBox(height: 14),
                                // Email
                                TextFormField(
                                  controller: _email,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: _emailValidator,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
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
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
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
                                            context,
                                            '/forgot-password',
                                          ),
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

                

                    const SizedBox(height: 14),

                 

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
                              context,
                              '/signup',
                            ),
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

class _RoleSegmentedToggle extends StatelessWidget {
  final String value; // 'kid' or 'parent'
  final ValueChanged<String>? onChanged;
  const _RoleSegmentedToggle({required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isKid = value == 'kid';
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white24, width: 1),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // Animated pill background
          AnimatedAlign(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOut,
            alignment: isKid ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: 40,
            child: Row(
              children: [
                _segButton(
                  context: context,
                  label: 'Kid',
                  selected: isKid,
                  icon: Icons.child_care_outlined,
                  onTap: onChanged == null ? null : () => onChanged!('kid'),
                ),
                _segButton(
                  context: context,
                  label: 'Parent',
                  selected: !isKid,
                  icon: Icons.lock_outline,
                  onTap: onChanged == null ? null : () => onChanged!('parent'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _segButton({
    required BuildContext context,
    required String label,
    required bool selected,
    required IconData icon,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: onTap,
        child: Container(
          height: 40,
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: selected ? const Color(brandPurple) : Colors.white),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(brandPurple) : Colors.white,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
