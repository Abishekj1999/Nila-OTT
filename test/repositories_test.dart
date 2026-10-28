import 'package:flutter_test/flutter_test.dart';
import 'package:nilaott/core/network/api_client.dart';
import 'package:nilaott/core/network/api_exception.dart';
import 'package:nilaott/features/auth/data/auth_repository.dart';
import 'package:nilaott/features/catalog/data/browse_query.dart';
import 'package:nilaott/features/catalog/data/catalog_repository.dart';
import 'package:nilaott/features/viewer/data/viewer_repository.dart';
import 'package:nilaott/shared/models/viewer.dart';

import 'helpers/fake_api.dart';

void main() {
  late FakeAdapter adapter;

  setUp(() => adapter = FakeAdapter());

  group('CatalogRepository', () {
    test('browse sends only documented, non-empty filters', () async {
      adapter.on('GET', '/movies', 200, fixture('movies.json'));
      final repo = CatalogRepository(fakeClient(adapter));
      final query = const BrowseQuery.movies().copyWith(access: () => 'free', sort: () => 'popular');

      final page = await repo.browse(query, page: 2);

      expect(page.titles, isNotEmpty);
      final params = adapter.requests.single.queryParameters;
      expect(params, {'access': 'free', 'sort': 'popular', 'page': 2});
    });

    test('genre browse sends type, never genre', () async {
      adapter.on('GET', '/genres/drama', 200, fixture('genre_drama.json'));
      final repo = CatalogRepository(fakeClient(adapter));

      await repo.browse(const BrowseQuery.genre('drama').copyWith(type: () => 'series', genre: () => 'x'));

      final params = adapter.requests.single.queryParameters;
      expect(params['type'], 'series');
      expect(params.containsKey('genre'), isFalse);
    });

    test('404 becomes a notFound ApiException', () async {
      final repo = CatalogRepository(fakeClient(adapter));
      await expectLater(repo.movie('nope'), throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.notFound)));
    });

    test('response without a data envelope is malformed', () async {
      adapter.on('GET', '/genres', 200, {'items': []});
      final repo = CatalogRepository(fakeClient(adapter));
      await expectLater(repo.genres(), throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.malformed)));
    });
  });

  group('AuthRepository', () {
    test('register sends password confirmation and device name', () async {
      adapter.on('POST', '/auth/register', 201, {
        'data': {
          'token': 't',
          'user': {'id': 1, 'name': 'Jane', 'email': 'jane@example.com', 'premium': false},
        },
      });
      final session = await AuthRepository(fakeClient(adapter)).register(name: 'Jane', email: 'jane@example.com', password: 'secret123');

      expect(session.user.name, 'Jane');
      final body = adapter.requests.single.data as Map;
      expect(body['password_confirmation'], body['password']);
      expect(body['device_name'], isNotEmpty);
    });

    test('422 exposes field errors for the form', () async {
      adapter.on('POST', '/auth/login', 422, {
        'message': 'Email or password is incorrect.',
        'errors': {
          'email': ['Email or password is incorrect.'],
        },
      });
      final repo = AuthRepository(fakeClient(adapter));
      await expectLater(
        repo.login(email: 'a@b.co', password: 'x'),
        throwsA(isA<ApiException>()
            .having((e) => e.kind, 'kind', ApiErrorKind.validation)
            .having((e) => e.firstFieldError('email'), 'email error', 'Email or password is incorrect.')),
      );
    });
  });

  group('ViewerRepository', () {
    test('attaches bearer token and reports 401 to the session handler', () async {
      var unauthorized = 0;
      final token = SessionToken()..value = 'abc';
      adapter.on('GET', '/me/continue-watching', 401, {'message': 'Unauthenticated.'});
      final repo = ViewerRepository(fakeClient(adapter, token: token, onUnauthorized: () => unauthorized++));

      await expectLater(repo.continueWatching(), throwsA(isA<ApiException>()));
      expect(adapter.requests.single.headers['Authorization'], 'Bearer abc');
      expect(unauthorized, 1);
    });

    test('playback 403 premium_required maps to premiumRequired', () async {
      adapter.on('GET', '/playback/episode/13', 403, {'message': 'A premium plan is needed to watch this.', 'reason': 'premium_required'});
      final repo = ViewerRepository(fakeClient(adapter));
      await expectLater(
        repo.playback(PlayableType.episode, 13),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.premiumRequired)),
      );
    });

    test('progress 403 with message premium_required maps to premiumRequired', () async {
      adapter.on('PUT', '/progress', 403, {'message': 'premium_required'});
      final repo = ViewerRepository(fakeClient(adapter));
      await expectLater(
        repo.saveProgress(type: PlayableType.episode, id: 13, positionSeconds: 120),
        throwsA(isA<ApiException>().having((e) => e.kind, 'kind', ApiErrorKind.premiumRequired)),
      );
    });

    test('saveProgress sends the documented body', () async {
      adapter.on('PUT', '/progress', 200, {
        'data': {'saved': true, 'position_seconds': 1540, 'completed': false},
      });
      final result = await ViewerRepository(fakeClient(adapter))
          .saveProgress(type: PlayableType.movie, id: 1, positionSeconds: 1540, durationSeconds: 7200);

      expect(result.saved, isTrue);
      expect(adapter.requests.single.data, {'type': 'movie', 'id': 1, 'position_seconds': 1540, 'duration_seconds': 7200});
    });

    test('remove continue watching handles 204', () async {
      adapter.on('DELETE', '/me/continue-watching/42', 204);
      await ViewerRepository(fakeClient(adapter)).removeContinueWatching(42);
      expect(adapter.requests.single.method, 'DELETE');
    });
  });

  test('429 is rate limited and retryable', () async {
    adapter.on('GET', '/home', 429, {'message': 'Too Many Attempts.'});
    try {
      await CatalogRepository(fakeClient(adapter)).home();
      fail('expected an exception');
    } on ApiException catch (e) {
      expect(e.kind, ApiErrorKind.rateLimited);
      expect(e.isRetryable, isTrue);
      expect(e.userMessage, isNot(contains('Too Many Attempts')));
    }
  });
}
