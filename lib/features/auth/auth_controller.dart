import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../db/db_factory.dart';
import '../db_session/db_session_controller.dart';

class AuthState {
  final bool isLoggedIn;
  final String? username;

  const AuthState({required this.isLoggedIn, required this.username});

  static const loggedOut = AuthState(isLoggedIn: false, username: null);
}

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthState>>(
      (ref) => AuthController(ref),
    );

class AuthController extends StateNotifier<AsyncValue<AuthState>> {
  final Ref ref;
  AuthController(this.ref) : super(const AsyncValue.data(AuthState.loggedOut));

  Future<bool> login(String username, String password) async {
    state = const AsyncValue.loading();
    try {
      final sess = ref.read(dbSessionControllerProvider).valueOrNull;
      final db = sess?.db;
      if (db == null) throw Exception('No database connected');

      final ok = await DbFactory.authenticate(
        db: db,
        username: username,
        password: password,
      );

      if (!ok) {
        state = const AsyncValue.data(AuthState.loggedOut);
        return false;
      }

      state = AsyncValue.data(AuthState(isLoggedIn: true, username: username));
      return true;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      return false;
    }
  }

  void logout() {
    state = const AsyncValue.data(AuthState.loggedOut);
  }
}
