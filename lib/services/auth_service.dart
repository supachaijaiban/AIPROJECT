import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/app_user.dart';

class AuthService {
  final SupabaseClient _client = Supabase.instance.client;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  User? get currentUser => _client.auth.currentUser;

  Future<void> signIn(String email, String password) {
    return _client.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() => _client.auth.signOut();

  Future<AppUser?> loadCurrentAppUser() async {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) return null;
    final row = await _client.from('profiles').select().eq('id', uid).maybeSingle();
    if (row == null) return null;
    return AppUser.fromMap(row);
  }
}
