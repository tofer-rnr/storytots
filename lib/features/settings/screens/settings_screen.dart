import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/data/repositories/auth_cache_repository.dart';
import 'package:storytots/core/constants.dart';
import 'package:storytots/features/settings/screens/profile_screen.dart';
import 'about_screen.dart';
import 'help_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(appBg),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              // Top branded pill header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(brandPurple),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(brandPurple).withOpacity(0.25),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      'storytots',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontFamily: 'Growback',
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'SETTINGS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(brandPurple),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 3,
                    fontFamily: 'RustyHooks',
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Background subtle pattern (optional)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _SettingsActionCard(
                      label: 'PROFILE',
                      onTap: () => _openProfile(context),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionCard(
                      label: 'NOTIFICATION',
                      onTap: () => _comingSoon(context, 'Notifications'),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionCard(
                      label: 'ABOUT',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AboutScreen()),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _SettingsActionCard(
                      label: 'HELP',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpScreen()),
                      ),
                    ),
                    const SizedBox(height: 22),

                    // Logout Button styled to match design
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: const Color(brandPurple),
                            width: 2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          foregroundColor: const Color(brandPurple),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            letterSpacing: 2,
                            fontFamily: 'RustyHooks',
                          ),
                        ),
                        onPressed: () => _logout(context),
                        child: const Text('LOGOUT'),
                      ),
                    ),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openProfile(BuildContext context) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
  }

  void _comingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature is coming soon'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _logout(BuildContext context) async {
    try {
      final authCache = AuthCacheRepository();
      await authCache.clearCache();
      await Supabase.instance.client.auth.signOut();

      if (context.mounted) {
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

class _SettingsActionCard extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SettingsActionCard({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Ink(
          decoration: BoxDecoration(
            color: const Color(brandPurple),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(brandPurple).withOpacity(0.2),
                blurRadius: 10,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                      fontFamily: 'RustyHooks',
                    ),
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
