import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nilaott/core/providers.dart';
import 'package:nilaott/core/storage/token_storage.dart';
import 'package:nilaott/features/auth/application/auth_controller.dart';

import 'helpers/fake_api.dart';

ProviderContainer _container(FakeAdapter adapter, TokenStorage storage) {
  final container = ProviderContainer(
    retry: (_, _) => null,
    overrides: [
      tokenStorageProvider.overrideWithValue(storage),
      apiClientProvider.overrideWith((ref) => fakeClient(
            adapter,
            token: ref.watch(sessionTokenProvider),
            onUnauthorized: ref.watch(unauthorizedHandlerProvider).call,
          )),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

const _user = {'id': 14, 'name': 'Jane Viewer', 'email': 'jane@example.com', 'premium': true};

void main() {
  test('restore without a stored token signs out', () async {
    final c = _container(FakeAdapter(), InMemoryTokenStorage());
    await c.read(authControllerProvider.notifier).restore();
    expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
  });

  test('restore with a valid token loads the profile', () async {
    final adapter = FakeAdapter()..on('GET', '/me', 200, {'data': _user});
    final c = _container(adapter, InMemoryTokenStorage('tok'));

    await c.read(authControllerProvider.notifier).restore();

    final state = c.read(authControllerProvider);
    expect(state.isSignedIn, isTrue);
    expect(state.isPremium, isTrue);
    expect(adapter.requests.single.headers['Authorization'], 'Bearer tok');
  });

  test('restore with an expired token clears it', () async {
    final storage = InMemoryTokenStorage('expired');
    final adapter = FakeAdapter()..on('GET', '/me', 401, {'message': 'Unauthenticated.'});
    final c = _container(adapter, storage);

    await c.read(authControllerProvider.notifier).restore();

    expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
    expect(await storage.read(), isNull);
    expect(c.read(sessionTokenProvider).value, isNull);
  });

  test('restore while offline keeps the session', () async {
    final storage = InMemoryTokenStorage('tok');
    final c = _container(FakeAdapter()..on('GET', '/me', 503), storage);

    await c.read(authControllerProvider.notifier).restore();

    expect(c.read(authControllerProvider).isSignedIn, isTrue);
    expect(await storage.read(), 'tok');
  });

  test('login stores the token and a later 401 signs out', () async {
    final storage = InMemoryTokenStorage();
    final adapter = FakeAdapter()
      ..on('POST', '/auth/login', 200, {
        'data': {'token': 'new', 'user': _user},
      })
      ..on('GET', '/me', 401, {'message': 'Unauthenticated.'});
    final c = _container(adapter, storage);
    await c.read(authControllerProvider.notifier).restore();

    await c.read(authControllerProvider.notifier).login(email: 'jane@example.com', password: 'secret123');
    expect(await storage.read(), 'new');
    expect(c.read(authControllerProvider).isSignedIn, isTrue);

    // Any authenticated 401 ends the session.
    await expectLater(c.read(authControllerProvider.notifier).refreshProfile(), completes);
    await Future<void>.delayed(Duration.zero);
    expect(c.read(authControllerProvider).status, AuthStatus.signedOut);
    expect(await storage.read(), isNull);
  });
}
