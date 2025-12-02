import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/data/repositories/auth_repository_impl.dart';
import 'package:truth_protocol_app/presentation/auth/auth_state.dart';

part 'auth_provider.g.dart';

@Riverpod(keepAlive: true)
class AuthNotifier extends _$AuthNotifier {
  @override
  Future<AuthState> build() async {
    return _checkSession();
  }

  Future<AuthState> _checkSession() async {
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.getCurrentUser();
      if (user != null) {
        return AuthState.authenticated(user);
      } else {
        return const AuthState.unauthenticated();
      }
    } catch (e) {
      return const AuthState.unauthenticated();
    }
  }

  Future<void> login(String email, String password) async {
    state = const AsyncValue.data(AuthState.loading());
    
    try {
      final repository = ref.read(authRepositoryProvider);
      final user = await repository.login(email, password);
      state = AsyncValue.data(AuthState.authenticated(user));
    } catch (e) {
      state = AsyncValue.data(AuthState.error(e.toString()));
    }
  }

  Future<void> logout() async {
    final repository = ref.read(authRepositoryProvider);
    await repository.logout();
    state = const AsyncValue.data(AuthState.unauthenticated());
  }
}
