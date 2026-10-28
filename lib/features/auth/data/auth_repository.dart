import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../shared/models/viewer.dart';

class AuthRepository {
  AuthRepository(this._api);

  final ApiClient _api;

  static String get deviceName {
    if (kIsWeb) return 'Nila OTT Web';
    return switch (defaultTargetPlatform) {
      TargetPlatform.iOS => 'Nila OTT iOS',
      TargetPlatform.android => 'Nila OTT Android',
      _ => 'Nila OTT',
    };
  }

  Future<AuthSession> login({required String email, required String password}) => _api.post(
        '/auth/login',
        body: {'email': email, 'password': password, 'device_name': deviceName},
        parse: (d) => AuthSession.fromJson(asMap(d)),
      );

  Future<AuthSession> register({required String name, required String email, required String password}) => _api.post(
        '/auth/register',
        body: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': password,
          'device_name': deviceName,
        },
        parse: (d) => AuthSession.fromJson(asMap(d)),
      );

  Future<void> logout() => _api.postEmpty('/auth/logout');

  Future<Viewer> me() => _api.get('/me', parse: (d) => Viewer.fromJson(asMap(d)));
}

final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository(ref.watch(apiClientProvider)));
