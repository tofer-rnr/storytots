import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';

class ForgotPasswordUpdateScreen extends StatefulWidget {
  const ForgotPasswordUpdateScreen({super.key});

  @override
  State<ForgotPasswordUpdateScreen> createState() =>
      _ForgotPasswordUpdateScreenState();
}

class _ForgotPasswordUpdateScreenState
    extends State<ForgotPasswordUpdateScreen> {
  final _token = TextEditingController();
  final _email = TextEditingController();
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Prefill email from navigation args if provided
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is String && _email.text.isEmpty) {
      _email.text = args;
    }
  }

  @override
  void dispose() {
    _token.dispose();
    _email.dispose();
    _pwd.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  String? _notEmpty(String? v, String label) {
    if (v == null || v.trim().isEmpty) return '$label is required';
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  String? _passwordRules(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    if (v.length < 8) return 'Use at least 8 characters';
    return null;
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pwd.text != _pwd2.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = Supabase.instance.client.auth;

      // Step 1: verify recovery token to obtain a session
      final res = await auth.verifyOTP(
        type: OtpType.recovery,
        email: _email.text.trim(),
        token: _token.text.trim(),
      );

      if (res.session == null) {
        throw AuthException('Invalid or expired token');
      }

      // Step 2: update password while recovery session is active
      await auth.updateUser(UserAttributes(password: _pwd.text));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to reset: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(brandPurple);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: purple,
        foregroundColor: Colors.white,
        title: const Text('Reset Password'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Create new password',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                SizedBox(height: 8),
                Text(
                  'Enter the token from your email, then set a new password.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _token,
                  keyboardType: TextInputType.number,
                  validator: (v) => _notEmpty(v, 'Reset token'),
                  decoration: const InputDecoration(
                    labelText: 'Reset Token',
                    prefixIcon: Icon(Icons.vpn_key_rounded),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  validator: _emailValidator,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwd,
                  obscureText: true,
                  validator: _passwordRules,
                  decoration: const InputDecoration(
                    labelText: 'New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _pwd2,
                  obscureText: true,
                  validator: _passwordRules,
                  decoration: const InputDecoration(
                    labelText: 'Confirm New Password',
                    prefixIcon: Icon(Icons.lock_outline),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 48,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _reset,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: purple,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Reset Password'),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFE3B3)),
            ),
            child: const Text(
              'Password tips:\n• Use at least 8 characters\n• Mix letters, numbers, and symbols\n• Avoid common words',
              style: TextStyle(color: Color(0xFF664D03)),
            ),
          ),
        ],
      ),
    );
  }
}
