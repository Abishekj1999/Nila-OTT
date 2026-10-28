import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'config/app_config.dart';
import 'network/api_client.dart';
import 'storage/token_storage.dart';

final appConfigProvider = Provider<AppConfig>((ref) => AppConfig.fromEnvironment());

final tokenStorageProvider = Provider<TokenStorage>((ref) => SecureTokenStorage());

final sessionTokenProvider = Provider<SessionToken>((ref) => SessionToken());

/// Set by the auth layer; invoked when an authenticated request returns 401.
final unauthorizedHandlerProvider = Provider<UnauthorizedHandler>((ref) => UnauthorizedHandler());

class UnauthorizedHandler {
  void Function()? callback;
  void call() => callback?.call();
}

final apiClientProvider = Provider<ApiClient>((ref) {
  final handler = ref.watch(unauthorizedHandlerProvider);
  return ApiClient.create(
    baseUrl: ref.watch(appConfigProvider).apiBaseUrl,
    token: ref.watch(sessionTokenProvider),
    onUnauthorized: handler.call,
  );
});

/// Shorthand for resolving media URLs from API payloads.
final mediaUrlProvider = Provider<String? Function(String?)>((ref) => ref.watch(appConfigProvider).mediaUrl);
