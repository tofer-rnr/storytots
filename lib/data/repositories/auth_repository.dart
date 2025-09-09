import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:storytots/data/supabase/client.dart';

class AuthRepository {
  Future<void> signUp(String email, String password) async {
    await supa.auth.signUp(email: email, password: password);
  }

  Future<void> signIn(String email, String password) async {
    await supa.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => supa.auth.signOut();
}
