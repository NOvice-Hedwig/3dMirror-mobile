import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api/auth_api.dart';

// ── Auth state ────────────────────────────────────────────────────────────────

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthState {
  final AuthStatus status;
  final String?    userId;
  const AuthState({required this.status, this.userId});

  bool get isAuthenticated => status == AuthStatus.authenticated;
}

final authProvider =
    AsyncNotifierProvider<AuthNotifier, AuthState>(AuthNotifier.new);

class AuthNotifier extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final token  = await AuthApi.instance.getToken();
    final userId = await AuthApi.instance.getUserId();
    if (token != null && userId != null) {
      return AuthState(status: AuthStatus.authenticated, userId: userId);
    }
    return const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> onLogin(String token, String userId) async {
    await AuthApi.instance.persistToken(token, userId);
    state = AsyncData(AuthState(
      status: AuthStatus.authenticated, userId: userId));
  }

  Future<void> signOut() async {
    await AuthApi.instance.signOut();
    state = const AsyncData(AuthState(status: AuthStatus.unauthenticated));
  }
}

// ── Current user ID shortcut ──────────────────────────────────────────────────

final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).value?.userId;
});
