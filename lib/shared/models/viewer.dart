import 'package:json_annotation/json_annotation.dart';

part 'viewer.g.dart';

const _json = JsonSerializable(fieldRename: FieldRename.snake, createToJson: false);

@_json
class Viewer {
  const Viewer({required this.id, required this.name, required this.email, this.premium = false});

  final int id;
  final String name;
  final String email;
  @JsonKey(defaultValue: false)
  final bool premium;

  factory Viewer.fromJson(Map<String, dynamic> json) => _$ViewerFromJson(json);
}

@_json
class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final Viewer user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => _$AuthSessionFromJson(json);
}

/// Playable kinds accepted by `/playback/{type}/{id}` and `PUT /progress`.
enum PlayableType {
  movie,
  episode;

  static PlayableType parse(String? value) => value == 'episode' ? PlayableType.episode : PlayableType.movie;
}

@_json
class ContinueWatchingItem {
  const ContinueWatchingItem({
    required this.id,
    required this.type,
    required this.itemId,
    required this.title,
    required this.slug,
    this.subtitle,
    this.episodeTitle,
    this.thumbnailUrl,
    this.positionSeconds = 0,
    this.durationSeconds,
    this.progress = 0,
    this.remainingLabel,
    this.lastWatchedAt,
  });

  /// WatchProgress record id, used for removal.
  final int id;
  @JsonKey(fromJson: PlayableType.parse)
  final PlayableType type;
  final int itemId;
  final String title;
  final String slug;
  final String? subtitle;
  final String? episodeTitle;
  final String? thumbnailUrl;
  @JsonKey(defaultValue: 0)
  final int positionSeconds;
  final int? durationSeconds;
  @JsonKey(defaultValue: 0)
  final double progress;
  final String? remainingLabel;
  final String? lastWatchedAt;

  factory ContinueWatchingItem.fromJson(Map<String, dynamic> json) => _$ContinueWatchingItemFromJson(json);
}

@_json
class PlaybackInfo {
  const PlaybackInfo({
    required this.type,
    required this.id,
    required this.title,
    required this.streamUrl,
    required this.streamFormat,
    this.subtitle,
    this.posterUrl,
    this.durationSeconds,
    this.resumeSeconds = 0,
  });

  @JsonKey(fromJson: PlayableType.parse)
  final PlayableType type;
  final int id;
  final String title;
  final String? subtitle;
  final String? posterUrl;
  final int? durationSeconds;
  final String streamUrl;

  /// `hls`, `file` or `youtube`.
  final String streamFormat;
  @JsonKey(defaultValue: 0)
  final int resumeSeconds;

  bool get isYoutube => streamFormat == 'youtube';

  factory PlaybackInfo.fromJson(Map<String, dynamic> json) => _$PlaybackInfoFromJson(json);
}

@_json
class ProgressResult {
  const ProgressResult({this.saved = false, this.positionSeconds, this.completed = false});

  @JsonKey(defaultValue: false)
  final bool saved;
  final int? positionSeconds;
  @JsonKey(defaultValue: false)
  final bool completed;

  factory ProgressResult.fromJson(Map<String, dynamic> json) => _$ProgressResultFromJson(json);
}
