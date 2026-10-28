// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'viewer.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Viewer _$ViewerFromJson(Map<String, dynamic> json) => Viewer(
  id: (json['id'] as num).toInt(),
  name: json['name'] as String,
  email: json['email'] as String,
  premium: json['premium'] as bool? ?? false,
);

AuthSession _$AuthSessionFromJson(Map<String, dynamic> json) => AuthSession(
  token: json['token'] as String,
  user: Viewer.fromJson(json['user'] as Map<String, dynamic>),
);

ContinueWatchingItem _$ContinueWatchingItemFromJson(
  Map<String, dynamic> json,
) => ContinueWatchingItem(
  id: (json['id'] as num).toInt(),
  type: PlayableType.parse(json['type'] as String?),
  itemId: (json['item_id'] as num).toInt(),
  title: json['title'] as String,
  slug: json['slug'] as String,
  subtitle: json['subtitle'] as String?,
  episodeTitle: json['episode_title'] as String?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  positionSeconds: (json['position_seconds'] as num?)?.toInt() ?? 0,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  progress: (json['progress'] as num?)?.toDouble() ?? 0,
  remainingLabel: json['remaining_label'] as String?,
  lastWatchedAt: json['last_watched_at'] as String?,
);

PlaybackInfo _$PlaybackInfoFromJson(Map<String, dynamic> json) => PlaybackInfo(
  type: PlayableType.parse(json['type'] as String?),
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  streamUrl: json['stream_url'] as String,
  streamFormat: json['stream_format'] as String,
  subtitle: json['subtitle'] as String?,
  posterUrl: json['poster_url'] as String?,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  resumeSeconds: (json['resume_seconds'] as num?)?.toInt() ?? 0,
);

ProgressResult _$ProgressResultFromJson(Map<String, dynamic> json) =>
    ProgressResult(
      saved: json['saved'] as bool? ?? false,
      positionSeconds: (json['position_seconds'] as num?)?.toInt(),
      completed: json['completed'] as bool? ?? false,
    );
