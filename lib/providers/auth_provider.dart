import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import '../models/user_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(supabaseClientProvider).auth.onAuthStateChange;
});

final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final client = ref.watch(supabaseClientProvider);
  // Re-emit whenever auth state changes
  ref.watch(authStateChangesProvider);
  final session = client.auth.currentSession;

  if (session == null) {
    return Stream.value(null);
  }

  return client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('id', session.user.id)
      .map((list) {
        if (list.isEmpty) return null;
        return UserModel.fromJson(list.first);
      });
});

class AuthController {
  final Ref ref;
  AuthController(this.ref);

  Future<void> login(String email, String password) async {
    final response = await ref
        .read(supabaseClientProvider)
        .auth
        .signInWithPassword(email: email, password: password);

    if (response.user != null) {
      OneSignal.login(response.user!.id);
    }
  }

  Future<void> signup(
    String email,
    String password,
    String name,
    String role,
  ) async {
    final response = await ref
        .read(supabaseClientProvider)
        .auth
        .signUp(
          email: email,
          password: password,
          data: {'name': name, 'role': role},
        );

    if (response.user != null) {
      OneSignal.login(response.user!.id);
    }
  }

  Future<void> logout() async {
    await ref.read(supabaseClientProvider).auth.signOut();
    OneSignal.logout();
  }
}

final authControllerProvider = Provider((ref) => AuthController(ref));
