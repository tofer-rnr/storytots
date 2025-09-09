import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String email;
  const VerifyEmailScreen({super.key, required this.email});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  bool _resending = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,   // resend the verification email
        email: widget.email,
      );
      _toast('Verification email sent again.');
    } catch (e) {
      _toast('Could not resend: $e');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // (Keep just your logo; no extra "STORYTOTS" text)
                Image.asset('assets/images/storytots_logo_front.png', height: 72),
                const SizedBox(height: 16),
                Text(
                  'Check your email',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'We sent a verification link to:\n${widget.email}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _resending ? null : _resend,
                  child: Text(_resending ? 'Resending…' : 'Resend email'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: () => Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false),
                  child: const Text('I verified — Log in'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
