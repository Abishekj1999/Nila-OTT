import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../shared/models/viewer.dart';
import '../data/auth_repository.dart';

enum AuthStatus { unknown, signedOut, signedIn }

class AuthState {
  const AuthState._(this.status, [this.viewer]);

  const AuthState.unknown() : this._(AuthStatus.unknown);
  const AuthState.signedOut() : this._(AuthStatus.signedOut);
  const AuthState.signedIn(Viewer? viewer) : this._(AuthStatus.signedIn, viewer);

  final AuthStatus status;

  /// Null while signed in only if the profile could not be loaded yet
  /// (e.g. offline at launch); the token is kept so the session survives.
  final Viewer? viewer;

  bool get isSignedIn => status == AuthStatus.signedIn;
  bool get isPremium => viewer?.premium ?? false;
}

class AuthController extends Notifier<AuthState> {
  @override
  AuthState build() {
    ref.read(unauthorizedHandlerProvider).callback = _onUnauthorized;
    return const AuthState.unknown();
  }

  AuthRepository get _repo => ref.read(authRepositoryProvider);

  /// Restores a stored session at launch and refreshes the profile.
  /// [minDuration] keeps the splash on screen for a short brand moment.
  Future<void> restore({Duration minDuration = Duration.zero}) async {
    final delay = Future<void>.delayed(minDuration);
    final next = await _restoredState();
    await delay;
    if (state.status == AuthStatus.unknown) state = next;
  }

  Future<AuthState> _restoredState() async {
    final storage = ref.read(tokenStorageProvider);
    String? token;
    try {
      token = await storage.read();
    } catch (_) {
      token = null;
    }
    if (token == null || token.isEmpty) return const AuthState.signedOut();
    ref.read(sessionTokenProvider).value = token;
    try {
      return AuthState.signedIn(await _repo.me());
    } on ApiException catch (e) {
      if (e.kind != ApiErrorKind.unauthorized) return const AuthState.signedIn(null);
      ref.read(sessionTokenProvider).value = null;
      try {
        await storage.clear();
      } catch (_) {}
      return const AuthState.signedOut();
    }
  }

  Future<void> refreshProfile() async {
    if (!state.isSignedIn) return;
    try {
      state = AuthState.signedIn(await _repo.me());
    } on ApiException catch (e) {
      if (e.kind != ApiErrorKind.unauthorized) rethrow;
    }
  }

  Future<void> login({required String email, required String password}) async {
    await _start(await _repo.login(email: email.trim(), password: password));
  }

  Future<void> register({required String name, required String email, required String password}) async {
    await _start(await _repo.register(name: name.trim(), email: email.trim(), password: password));
  }

  Future<void> logout() async {
    try {
      await _repo.logout();
    } catch (_) {
      // The token is discarded locally even if revoking it fails.
    }
    await _clearLocal();
  }

  Future<void> _start(AuthSession session) async {
    ref.read(sessionTokenProvider).value = session.token;
    await ref.read(tokenStorageProvider).write(session.token);
    state = AuthState.signedIn(session.user);
  }

  void _onUnauthorized() {
    if (state.isSignedIn) _clearLocal();
  }

  Future<void> _clearLocal() async {
    ref.read(sessionTokenProvider).value = null;
    try {
      await ref.read(tokenStorageProvider).clear();
    } catch (_) {}
    state = const AuthState.signedOut();
  }
}

final authControllerProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

/// True when signed in; providers watch this to refetch on sign-in/out.
final isSignedInProvider = Provider<bool>((ref) => ref.watch(authControllerProvider.select((s) => s.isSignedIn)));
