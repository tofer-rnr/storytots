import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/data/repositories/auth_cache_repository.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: const Color(0xFF6366F1),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Account',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.logout, color: Color(0xFF6366F1)),
              title: const Text('Logout'),
              subtitle: const Text('Sign out of your account'),
              onTap: () => _logout(context),
            ),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'App Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF6366F1),
              ),
            ),
            const SizedBox(height: 16),
            const ListTile(
              leading: Icon(Icons.info, color: Color(0xFF6366F1)),
              title: Text('Version'),
              subtitle: Text('1.0.0'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      // Clear cached session
      final authCache = AuthCacheRepository();
      await authCache.clearCache();

      // Sign out from Supabase
      await Supabase.instance.client.auth.signOut();

      if (context.mounted) {
        // Navigate to login screen
        Navigator.of(
          context,
        ).pushNamedAndRemoveUntil('/login', (route) => false);
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error logging out: $error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
