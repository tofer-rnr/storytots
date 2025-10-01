import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants.dart';
import 'data/repositories/auth_cache_repository.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey: supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(
      authFlowType: AuthFlowType.pkce,
    ),
  );

  // Initialize auth cache for persistent login
  final authCache = AuthCacheRepository();
  await authCache.initialize();

  await Permission.microphone.request();

  runApp(const StoryTotsApp());
}
