import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../shared/models/viewer.dart';

/// Signed-in viewer endpoints: continue watching, playback and progress.
class ViewerRepository {
  ViewerRepository(this._api);

  final ApiClient _api;

  /// Backend only stores progress from this position onwards.
  static const minSavedPositionSeconds = 30;

  Future<List<ContinueWatchingItem>> continueWatching() => _api.get(
        '/me/continue-watching',
        parse: (d) => asMapList(d).map(ContinueWatchingItem.fromJson).toList(),
      );

  Future<void> removeContinueWatching(int watchProgressId) => _api.delete('/me/continue-watching/$watchProgressId');

  Future<PlaybackInfo> playback(PlayableType type, int id) =>
      _api.get('/playback/${type.name}/$id', parse: (d) => PlaybackInfo.fromJson(asMap(d)));

  Future<ProgressResult> saveProgress({
    required PlayableType type,
    required int id,
    required int positionSeconds,
    int? durationSeconds,
  }) =>
      _api.put(
        '/progress',
        body: {
          'type': type.name,
          'id': id,
          'position_seconds': positionSeconds.clamp(0, 360000),
          if (durationSeconds != null && durationSeconds > 0) 'duration_seconds': durationSeconds.clamp(0, 360000),
        },
        parse: (d) => ProgressResult.fromJson(asMap(d)),
      );
}

final viewerRepositoryProvider = Provider<ViewerRepository>((ref) => ViewerRepository(ref.watch(apiClientProvider)));
