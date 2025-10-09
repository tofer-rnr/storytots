import 'package:flutter/material.dart';
import 'core/constants.dart';
import 'features/auth/screens/auth_splash_screen.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/signup_screen.dart';
import 'features/auth/screens/otp_email_screen.dart';
import 'features/auth/screens/verify_email_screen.dart';
import 'features/interests/screens/onboarding_flow.dart';
import 'features/shell/main_tabs.dart';
import 'features/games/games_screen.dart';
import 'core/widgets/global_click_sound.dart';

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
          // Keep default font family. We will apply custom fonts to specific widgets.
        ),
        initialRoute: '/',
        routes: {
          '/': (_) => const AuthSplashScreen(),
          '/login': (_) => const LoginScreen(),
          '/signup': (_) => const SignUpScreen(),
          '/otp': (_) => const OtpEmailScreen(),
          '/onboarding': (_) => const OnboardingFlow(),
          '/home': (_) => const MainTabs(),
          '/games': (_) => const GamesScreen(),
        },
        onGenerateRoute: (settings) {
          if (settings.name == '/verify-email') {
            final email = settings.arguments as String? ?? '';
            return MaterialPageRoute(
              builder: (_) => VerifyEmailScreen(email: email),
            );
          }
          return null;
        },
      ),
    );
  }
}
