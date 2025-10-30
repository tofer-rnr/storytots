import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'core/services/background_music_service.dart';
import 'core/services/sound_service.dart';
import 'features/auth/screens/auth_splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/otp_email_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/auth/screens/forgot_password_request_screen.dart';
import 'features/auth/screens/forgot_password_update_screen.dart';
import 'features/interests/screens/onboarding_flow.dart';
import 'features/shell/main_tabs.dart';
import 'features/games/games_screen.dart';
import 'features/settings/screens/profile_screen.dart';
import 'core/widgets/global_click_sound.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class StoryTotsApp extends StatelessWidget {
  const StoryTotsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GlobalClickSound(
      child: MaterialApp(
        title: 'StoryTots',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(brandPurple),
          ),
          scaffoldBackgroundColor: const Color(appBg),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const AuthSplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/otp': (_) => const OtpEmailScreen(),
          '/forgot-password': (_) => const ForgotPasswordRequestScreen(),
          '/reset-password': (_) => const ForgotPasswordUpdateScreen(),
          '/onboarding': (_) => const OnboardingFlow(),
          '/profile': (_) => const ProfileScreen(),
          // Use onGenerateRoute for '/home' to support arguments
          '/games': (_) => const GamesScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verify-email') {
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: email),
            );
          }
          if (settings.name == '/home') {
            final args = settings.arguments;
            int? initialIndex;
            if (args is Map && args['initialIndex'] is int) {
              initialIndex = args['initialIndex'] as int;
            } else if (args is int) {
              initialIndex = args;
            }
            return MaterialPageRoute(
              builder: (_) => MainTabs(initialIndex: initialIndex),
            );
          }
          return null;
        },
        navigatorObservers: [_PasswordRecoveryNavigatorObserver()],
      ),
    );
  }
}

class _PasswordRecoveryNavigatorObserver extends NavigatorObserver {
  _PasswordRecoveryNavigatorObserver() {
    Supabase.instance.client.auth.onAuthStateChange.listen((event) {
      if (event.event == AuthChangeEvent.passwordRecovery) {
        navigator?.pushNamed('/reset-password');
      }
    });
  }
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    SoundService.instance.init();
    BackgroundMusicService.instance.init();
  }

  @override
  Widget build(BuildContext context) {
    BackgroundMusicService.instance.start();

    return GlobalClickSound(
      child: MaterialApp(
        title: 'StoryTots',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(brandPurple),
          ),
          scaffoldBackgroundColor: const Color(appBg),
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const AuthSplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/otp': (_) => const OtpEmailScreen(),
          '/forgot-password': (_) => const ForgotPasswordRequestScreen(),
          '/reset-password': (_) => const ForgotPasswordUpdateScreen(),
          '/onboarding': (_) => const OnboardingFlow(),
          // Use onGenerateRoute for '/home' to support arguments
          '/games': (_) => const GamesScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verify-email') {
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: email),
            );
          }
          if (settings.name == '/home') {
            final args = settings.arguments;
            int? initialIndex;
            if (args is Map && args['initialIndex'] is int) {
              initialIndex = args['initialIndex'] as int;
            } else if (args is int) {
              initialIndex = args;
            }
            return MaterialPageRoute(
              builder: (_) => MainTabs(initialIndex: initialIndex),
            );
          }
          return null;
        },
        navigatorObservers: [_PasswordRecoveryNavigatorObserver()],
      ),
    );
  }
}
