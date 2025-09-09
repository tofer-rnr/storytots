import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../core/widgets/st_text_field.dart';
import 'otp_verify_screen.dart';

class OtpEmailScreen extends StatefulWidget {
  const OtpEmailScreen({super.key});
  @override
  State<OtpEmailScreen> createState() => _OtpEmailScreenState();
}

class _OtpEmailScreenState extends State<OtpEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _sendCode() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: _email.text.trim(),
        shouldCreateUser: true, // creates account on first OTP sign-in
      );
      if (!mounted) return;
      Navigator.of(context).push(MaterialPageRoute(
        builder: (_) => OtpVerifyScreen(email: _email.text.trim()),
      ));
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
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(fit: StackFit.expand, children: [
        Image.asset('assets/images/storytots_background.png', fit: BoxFit.cover),
        Container(color: Colors.white.withOpacity(0.90)),
        Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Image.asset('assets/images/storytots_logo_front.png', height: 72),
                  const SizedBox(height: 18),
                  STTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48, width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(brandPurple),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 8,
                      ),
                      child: Text(_loading ? 'Sending…' : 'Get Code'),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Use password login instead'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
