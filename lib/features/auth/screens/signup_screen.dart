// lib/features/auth/screens/sign_up_screen.dart
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants.dart';
import '../../../../core/widgets/st_text_field.dart';
import 'otp_verify_screen.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _formKey = GlobalKey<FormState>();
  final _first = TextEditingController();
  final _last  = TextEditingController();
  final _birth = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm  = TextEditingController();

  bool _loading = false;
  bool _obscure = true;
  bool _obscure2 = true;
  bool _acceptedTerms = false;

  void _toast(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String? _notEmpty(String? v, String field) {
    if (v == null || v.trim().isEmpty) return '$field is required';
    return null;
  }

  String? _birthValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Birth date is required';
    final parsed = DateTime.tryParse(v.trim());
    if (parsed == null) return 'Use format YYYY-MM-DD';
    if (parsed.isAfter(DateTime.now())) return 'Birth date can’t be in the future';
    return null;
  }

  String? _emailValidator(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final ok = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v.trim());
    return ok ? null : 'Enter a valid email';
  }

  /// Strong password rules:
  /// - at least 8 chars
  /// - at least 1 letter, 1 number, 1 special char
  /// - must NOT contain first or last name
  String? _passwordValidator(String? v) {
    if (v == null || v.isEmpty) return 'Password is required';
    final password = v.trim();
    if (password.length < 8) return 'Password must be at least 8 characters';
    final regex = RegExp(r'^(?=.*[A-Za-z])(?=.*\d)(?=.*[^A-Za-z0-9]).+$');
    if (!regex.hasMatch(password)) {
      return 'Include letters, numbers & special characters';
    }
    final firstName = _first.text.trim().toLowerCase();
    final lastName  = _last.text.trim().toLowerCase();
    final lowerPwd  = password.toLowerCase();
    if (firstName.isNotEmpty && lowerPwd.contains(firstName)) {
      return 'Password should not contain your first name';
    }
    if (lastName.isNotEmpty && lowerPwd.contains(lastName)) {
      return 'Password should not contain your last name';
    }
    return null;
  }

  String? _confirmValidator(String? v) {
    if (v == null || v.isEmpty) return 'Confirm your password';
    if (v != _password.text) return 'Passwords do not match';
    return null;
  }

  int _ageInYears(DateTime birth) {
    final now = DateTime.now();
    int years = now.year - birth.year;
    final hadBirthdayThisYear =
        (now.month > birth.month) ||
        (now.month == birth.month && now.day >= birth.day);
    if (!hadBirthdayThisYear) years -= 1;
    return years;
  }

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();
    final initial = DateTime(now.year - 7, 1, 1);
    final first   = DateTime(now.year - 18, 1, 1);
    final last    = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) {
      _birth.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      setState(() {});
    }
  }

  Future<bool> _confirmProceedOlder(int age) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirm to proceed'),
        content: Text('Your child is $age years old. Do you still wish to proceed?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Proceed')),
        ],
      ),
    );
    return ok ?? false;
  }

  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) return;

    // Names must be different
    if (_first.text.trim().toLowerCase() == _last.text.trim().toLowerCase()) {
      _toast("First name and last name can't be the same");
      return;
    }

    // Terms must be accepted (cannot be checked without opening the sheet)
    if (!_acceptedTerms) {
      _toast('Please review and accept the Terms & Conditions first.');
      return;
    }

    // Age rules
    final birth = DateTime.tryParse(_birth.text.trim());
    if (birth == null) {
      _toast('Enter a valid birth date (YYYY-MM-DD).');
      return;
    }
    final age = _ageInYears(birth);
    if (age < 2) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => const AlertDialog(
          title: Text('Too young'),
          content: Text(
            'Your child is at 1 year old. It would be better not to expose your child this early.',
          ),
        ),
      );
      return;
    }
    if (age >= 10) {
      final proceed = await _confirmProceedOlder(age);
      if (!proceed) return;
    }

    setState(() => _loading = true);
    try {
      // Send OTP; set password after verification.
      await Supabase.instance.client.auth.signInWithOtp(
        email: _email.text.trim(),
        shouldCreateUser: true,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OtpVerifyScreen(
            email: _email.text.trim(),
            firstName: _first.text.trim(),
            lastName:  _last.text.trim(),
            birthDate: _birth.text.trim(),
            password:  _password.text,
          ),
        ),
      );
    } on AuthException catch (e) {
      _toast(e.message);
    } catch (e) {
      _toast('Unexpected error: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  // --- TERMS: force user to open + scroll to accept ---
  Future<void> _showTermsSheet() async {
    final controller = ScrollController();
    bool atBottom = false;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            controller.addListener(() {
              final reachedEnd =
                  controller.offset >= controller.position.maxScrollExtent &&
                  !controller.position.outOfRange;
              if (reachedEnd != atBottom) {
                atBottom = reachedEnd;
                setSheetState(() {});
              }
            });

            return SafeArea(
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  top: 12,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.black26,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const Text(
                      'Terms & Conditions and Privacy Policy',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: MediaQuery.of(ctx).size.height * 0.65,
                      child: Scrollbar(
                        controller: controller,
                        child: SingleChildScrollView(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(horizontal: 2),
                          child: Text(_termsAndPrivacyText,
                              style: const TextStyle(height: 1.4)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: atBottom
                                ? () {
                                    setState(() => _acceptedTerms = true);
                                    Navigator.pop(ctx);
                                  }
                                : null,
                            child: const Text('I Agree'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _birth.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purple = const Color(brandPurple);

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
                    controller: _first,
                    label: "Child's First Name",
                    validator: (v) => _notEmpty(v, 'First name'),
                  ),
                  const SizedBox(height: 12),
                  STTextField(
                    controller: _last,
                    label: 'Last Name',
                    validator: (v) => _notEmpty(v, 'Last name'),
                  ),
                  const SizedBox(height: 12),
                  STTextField(
                    controller: _birth,
                    label: 'Birth Date (YYYY-MM-DD)',
                    keyboardType: TextInputType.datetime,
                    validator: _birthValidator,
                    readOnly: true,
                    onTap: _pickBirthDate,
                  ),
                  const SizedBox(height: 12),
                  STTextField(
                    controller: _email,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    validator: _emailValidator,
                  ),
                  const SizedBox(height: 12),
                  STTextField(
                    controller: _password,
                    label: 'Password',
                    obscured: _obscure,
                    validator: _passwordValidator,
                    suffix: IconButton(
                      icon: Icon(_obscure ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 12),
                  STTextField(
                    controller: _confirm,
                    label: 'Confirm Password',
                    obscured: _obscure2,
                    validator: _confirmValidator,
                    suffix: IconButton(
                      icon: Icon(_obscure2 ? Icons.visibility : Icons.visibility_off),
                      onPressed: () => setState(() => _obscure2 = !_obscure2),
                    ),
                  ),

                  const SizedBox(height: 8),
                  // Terms row: user must click to open; cannot toggle directly
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _acceptedTerms,
                        onChanged: (_) => _showTermsSheet(),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: GestureDetector(
                          onTap: _showTermsSheet,
                          child: Text.rich(
                            TextSpan(
                              children: [
                                const TextSpan(text: 'I agree to the '),
                                TextSpan(
                                  text: 'Terms & Conditions',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: ' and '),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const TextSpan(text: '.'),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: (_loading || !_acceptedTerms) ? null : _signup,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        elevation: 8,
                      ),
                      child: Text(_loading ? 'Sending code…' : 'Continue'),
                    ),
                  ),
                  TextButton(
                    onPressed: _loading ? null : () => Navigator.pushReplacementNamed(context, '/login'),
                    child: const Text('Have an account? Log in'),
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

/// Plain-text Terms & Conditions + Privacy Policy content.
/// (General template, not legal advice. Customize with your company details.)
const String _termsAndPrivacyText = '''
STORYTOTS — TERMS & CONDITIONS

Last updated: August 26, 2025

1. Introduction
These Terms & Conditions (“Terms”) govern your use of the StoryTots app and services (“Services”). By creating an account or using the Services, you agree to these Terms.

2. Eligibility & Accounts
Parents/Guardians create and manage child profiles. You are responsible for maintaining the confidentiality of login credentials and for all activities under your account.

3. Acceptable Use
You agree not to misuse the Services, including: (a) attempting to access accounts without permission; (b) uploading harmful or illegal content; (c) violating intellectual property rights.

4. Content & Intellectual Property
All app content (including stories, illustrations, and UI elements) is owned by StoryTots or its licensors. You receive a limited, non-exclusive, non-transferable license to use the Services for personal, non-commercial purposes.

5. Safety & Child Use
StoryTots is designed for child learning with parental supervision. You agree to supervise use and set appropriate limits.

6. Purchases & Subscriptions (if applicable)
Fees, billing cycles, and renewal rules will be presented at checkout. Taxes may apply. You may cancel according to platform policies; partial refunds are not guaranteed.

7. Termination
We may suspend or terminate access for violations of these Terms or for security concerns. You may stop using the Services at any time.

8. Disclaimers
The Services are provided “as is.” We do not guarantee uninterrupted or error-free operation, nor that content will meet your specific needs.

9. Limitation of Liability
To the maximum extent permitted by law, StoryTots will not be liable for indirect, incidental, special, or consequential damages. Our aggregate liability shall not exceed amounts paid by you in the 12 months prior to the claim.

10. Changes to the Terms
We may update these Terms from time to time. Continued use of the Services indicates acceptance of the updated Terms.

11. Contact
For questions: support@storytots.example

— — — — — — — — — — — — — — — — — —

PRIVACY POLICY

1. Data We Collect
We collect account information (parent name, email), child profile details (first name, birth year/month/day), and usage analytics. If you contact support, we may collect the messages you send.

2. How We Use Data
We use data to: (a) create and manage accounts; (b) personalize stories and recommendations; (c) improve safety and app performance; (d) communicate with you about updates and support.

3. Legal Bases
We process personal data based on your consent, to perform the contract (provide Services), and to comply with legal obligations.

4. Sharing
We do not sell personal data. We may share data with service providers (e.g., hosting, analytics) under confidentiality and data-protection agreements, and when required by law.

5. Children’s Privacy
Child data is managed by the parent/guardian account holder. We do not knowingly collect personal data from children without parental consent.

6. Data Retention
We retain data for as long as necessary to provide the Services and for legitimate business/legal purposes. You may request deletion of your account and profiles.

7. Your Rights
Subject to law, you may request access, correction, or deletion of your personal data. Contact: privacy@storytots.example

8. Security
We implement technical and organizational measures to protect data; however, no method is 100% secure.

9. International Transfers
If data is processed outside your country, we use safeguards consistent with applicable law.

10. Changes
We may update this Privacy Policy to reflect changes to our practices. Continued use indicates acceptance of the updated policy.

11. Contact
For privacy requests: privacy@storytots.example
''';
