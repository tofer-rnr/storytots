import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/auth_cache_repository.dart';
import '../../../data/repositories/profile_repository.dart';

class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  final _authCache = AuthCacheRepository();

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    // brief splash
    await Future.delayed(const Duration(milliseconds: 600));

    if (!mounted) return;

    try {
      // 1) Enforce daily login: if cache not for today, sign out and go to login
      final validToday = await _authCache.hasValidCachedSession();
      if (!validToday) {
        await Supabase.instance.client.auth.signOut();
        _navigateToLogin();
        return;
      }

      // 2) Check current session/user
      final auth = Supabase.instance.client.auth;
      var user = auth.currentUser;

      // 3) If user still null, attempt restore from our cached refresh_token
      if (user == null) {
        final restored = await _authCache.restoreSession();
        if (restored) {
          user = auth.currentUser;
        }
      }

      if (user != null) {
        await _routeToAppropriateScreen();
      } else {
        _navigateToLogin();
      }
    } catch (e) {
      // ignore: avoid_print
      print('[AuthSplash] Error checking auth status: $e');
      _navigateToLogin();
    }
  }

  Future<void> _routeToAppropriateScreen() async {
    try {
      final repo = ProfileRepository();
      final profile = await repo.getMyProfile();
      final complete = profile?.onboardingComplete ?? false;

      if (!mounted) return;

      Navigator.pushNamedAndRemoveUntil(
        context,
        complete ? '/home' : '/onboarding',
        (_) => false,
      );
    } catch (e) {
      // ignore: avoid_print
      print('[AuthSplash] Error checking profile: $e');
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(brandPurple), Color(0xFF5A4080)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/images/storytots_logo_front.png',
                  height: 80,
                ),
              ),

              const SizedBox(height: 40),

              // Loading indicator
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),

              const SizedBox(height: 20),

              // Loading text
              const Text(
                'Starting your reading adventure...',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
