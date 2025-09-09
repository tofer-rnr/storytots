import 'package:flutter/material.dart';
import 'package:storytots/core/constants.dart';
import 'profile_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(brandPurple),
        foregroundColor: Colors.white,
        title: const Text('STORYTOTS'),
        elevation: 0,
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/images/storytots_background.png', fit: BoxFit.cover),
          Container(color: Colors.white.withOpacity(0.94)),
          ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
            children: [
              const SizedBox(height: 4),
              const _Heading(title: 'SETTINGS'),
              const SizedBox(height: 20),
              _BigPillButton(
                label: 'PROFILE',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
              ),
              const SizedBox(height: 14),
              _BigPillButton(
                label: 'NOTIFICATION',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Notifications coming soon')),
                  );
                },
              ),
              const SizedBox(height: 14),
              _BigPillButton(
                label: 'ABOUT',
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'StoryTots',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
              const SizedBox(height: 14),
              _BigPillButton(
                label: 'HELP',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Help center coming soon')),
                  );
                },
              ),
              const SizedBox(height: 24),
              Align(
                alignment: Alignment.centerLeft,
                child: _SmallPillButton(
                  label: 'LOGOUT',
                  onTap: () {
                    // If you’re using Supabase, you can sign out here, e.g.:
                    // await Supabase.instance.client.auth.signOut();
                    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(
        fontSize: 20,
        letterSpacing: 6,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _BigPillButton extends StatelessWidget {
  const _BigPillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(brandPurple),
      borderRadius: BorderRadius.circular(14),
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.centerLeft,
          child: Row(
            children: [
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _SmallPillButton extends StatelessWidget {
  const _SmallPillButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(brandPurple),
      borderRadius: BorderRadius.circular(10),
      elevation: 1.5,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          height: 40,
          width: 120,
          child: Center(
            child: Text(
              'LOGOUT',
              style: TextStyle(
                color: Colors.white,
                letterSpacing: 4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
