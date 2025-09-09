import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../core/widgets/st_text_field.dart';
import '../../../../data/repositories/profile_repository.dart';

class OtpVerifyScreen extends StatefulWidget {
  final String email;
  final String? firstName;
  final String? lastName;
  final String? birthDate; 
  final String? password;  

  const OtpVerifyScreen({
    super.key,
    required this.email,
    this.firstName,
    this.lastName,
    this.birthDate,
    this.password,
  });

  @override
  State<OtpVerifyScreen> createState() => _OtpVerifyScreenState();
}

class _OtpVerifyScreenState extends State<OtpVerifyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _code = TextEditingController();
  bool _verifying = false;
  bool _resending = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String? _codeValidator(String? v) {
    final t = v?.trim() ?? '';
    if (t.isEmpty) return 'Enter the 6-digit code';
    if (t.length < 6) return 'Code must be 6 digits';
    return null;
  }

  Future<void> _verify() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _verifying = true);
    try {
      final auth = Supabase.instance.client.auth;

      final res = await auth.verifyOTP(
        type: OtpType.email,
        email: widget.email,
        token: _code.text.trim(),
      );

      if (!mounted) return;

      if (res.session == null) {
        _toast('Could not start a session. Try again.');
        return;
      }

      // If we collected a password at sign-up, set it now so future logins use email+password.
      final pw = widget.password?.trim() ?? '';
      if (pw.isNotEmpty) {
        await auth.updateUser(UserAttributes(password: pw));
      }

      // Seed/ensure the profile row, then decide where to go.
      final repo = ProfileRepository();
      DateTime? birth;
      if ((widget.birthDate ?? '').isNotEmpty) {
        birth = DateTime.tryParse(widget.birthDate!);
      }
      await repo.ensureRowExists(
        email: widget.email,
        first: widget.firstName,
        last: widget.lastName,
        birth: birth,
      );

      final profile = await repo.getMyProfile();
      final complete = profile?.onboardingComplete ?? false;

      if (!mounted) return;
      if (complete) {
        Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/onboarding', (_) => false);
      }
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _verifying = false);
    }
  }

  Future<void> _resend() async {
    setState(() => _resending = true);
    try {
      await Supabase.instance.client.auth.signInWithOtp(
        email: widget.email,
        shouldCreateUser: true,
      );
      _toast('Code resent to ${widget.email}');
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Could not resend: $e');
    } finally {
      if (mounted) setState(() => _resending = false);
    }
  }

  @override
  void dispose() {
    _code.dispose();
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
                  const SizedBox(height: 12),
                  Text(
                    'Enter the code we sent to\n${widget.email}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  STTextField(
                    controller: _code,
                    label: '6-digit code',
                    keyboardType: TextInputType.number,
                    validator: _codeValidator,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 48,
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _verifying ? null : _verify,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(brandPurple),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: Text(_verifying ? 'Verifying…' : 'Verify & Continue'),
                    ),
                  ),
                  TextButton(
                    onPressed: _resending ? null : _resend,
                    child: Text(_resending ? 'Resending…' : 'Resend code'),
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
