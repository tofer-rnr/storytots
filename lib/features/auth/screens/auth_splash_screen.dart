import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants.dart';
import '../../../data/repositories/auth_cache_repository.dart';
import '../../../data/repositories/profile_repository.dart';
import '../../../core/widgets/animated_brand_art.dart';

class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  final _authCache = AuthCacheRepository();
  Timer? _frameTimer; // kept if we later need delays

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  @override
  void dispose() {
    _frameTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkAuthStatus() async {
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    try {
      final validToday = await _authCache.hasValidCachedSession();
      if (!validToday) {
        await Supabase.instance.client.auth.signOut();
        _navigateToLogin();
        return;
      }
      final auth = Supabase.instance.client.auth;
      var user = auth.currentUser;
      if (user == null) {
        final restored = await _authCache.restoreSession();
        if (restored) user = auth.currentUser;
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
    // Responsive size for the splash art
    final size = MediaQuery.of(context).size;
    final double artSize = (size.shortestSide * 0.45)
        .clamp(140.0, 360.0)
        .toDouble();

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
              // Animated brand art without white card
              AnimatedBrandArt(size: artSize, withCard: false),
              const SizedBox(height: 40),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              const SizedBox(height: 20),
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
