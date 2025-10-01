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
    // Give a brief moment to show the splash screen
    await Future.delayed(const Duration(seconds: 1));

    if (!mounted) return;

    try {
      // Check if we have a valid cached session
      final hasValidSession = await _authCache.hasValidCachedSession();
      final currentUser = Supabase.instance.client.auth.currentUser;

      if (hasValidSession && currentUser != null) {
        // User is authenticated, check onboarding status
        await _routeToAppropriateScreen();
      } else {
        // No valid session, go to login
        _navigateToLogin();
      }
    } catch (e) {
      print('[AuthSplash] Error checking auth status: $e');
      // On error, go to login screen
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
