import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';

class ForgotPasswordUpdateScreen extends StatefulWidget {
  const ForgotPasswordUpdateScreen({super.key});

  @override
  State<ForgotPasswordUpdateScreen> createState() => _ForgotPasswordUpdateScreenState();
}

class _ForgotPasswordUpdateScreenState extends State<ForgotPasswordUpdateScreen> {
  final _pwd = TextEditingController();
  final _pwd2 = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _pwd.dispose();
    _pwd2.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final a = _pwd.text;
    final b = _pwd2.text;
    if (a.isEmpty || a != b) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      await Supabase.instance.client.auth.updateUser(UserAttributes(password: a));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated. Please sign in.')),
      );
      Navigator.popUntil(context, (r) => r.isFirst);
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: const Text('Set New Password'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Create a new password for your account.'),
            const SizedBox(height: 16),
            TextField(
              controller: _pwd,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'New password'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _pwd2,
              obscureText: true,
              decoration: const InputDecoration(labelText: 'Confirm new password'),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _saving ? null : _update,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(brandPurple),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _saving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Update password'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
