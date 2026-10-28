// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'title.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TaxonomyRef _$TaxonomyRefFromJson(Map<String, dynamic> json) => TaxonomyRef(
  slug: json['slug'] as String,
  name: json['name'] as String,
  code: json['code'] as String?,
);

CatalogTitle _$CatalogTitleFromJson(Map<String, dynamic> json) => CatalogTitle(
  type: TitleType.parse(json['type'] as String?),
  slug: json['slug'] as String,
  title: json['title'] as String,
  synopsis: json['synopsis'] as String?,
  year: (json['year'] as num?)?.toInt(),
  rating: json['rating'] as String?,
  access: json['access'] as String? ?? 'free',
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  seasonsCount: (json['seasons_count'] as num?)?.toInt(),
  episodesCount: (json['episodes_count'] as num?)?.toInt(),
  isNew: json['is_new'] as bool? ?? false,
  comingSoon: json['coming_soon'] as bool? ?? false,
  releaseDate: json['release_date'] as String?,
  daysUntilRelease: (json['days_until_release'] as num?)?.toInt(),
  trailerUrl: json['trailer_url'] as String?,
  posterUrl: json['poster_url'] as String?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => TaxonomyRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  languages:
      (json['languages'] as List<dynamic>?)
          ?.map((e) => TaxonomyRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  artists:
      (json['artists'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

CastMember _$CastMemberFromJson(Map<String, dynamic> json) => CastMember(
  name: json['name'] as String,
  slug: json['slug'] as String,
  imageUrl: json['image_url'] as String?,
);

Episode _$EpisodeFromJson(Map<String, dynamic> json) => Episode(
  id: (json['id'] as num).toInt(),
  number: (json['number'] as num).toInt(),
  title: json['title'] as String,
  synopsis: json['synopsis'] as String?,
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  thumbnailUrl: json['thumbnail_url'] as String?,
);

Season _$SeasonFromJson(Map<String, dynamic> json) => Season(
  id: (json['id'] as num).toInt(),
  number: (json['number'] as num).toInt(),
  title: json['title'] as String?,
  episodes:
      (json['episodes'] as List<dynamic>?)
          ?.map((e) => Episode.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

TitleDetail _$TitleDetailFromJson(Map<String, dynamic> json) => TitleDetail(
  id: (json['id'] as num).toInt(),
  type: TitleType.parse(json['type'] as String?),
  slug: json['slug'] as String,
  title: json['title'] as String,
  synopsis: json['synopsis'] as String?,
  description: json['description'] as String?,
  year: (json['year'] as num?)?.toInt(),
  rating: json['rating'] as String?,
  access: json['access'] as String? ?? 'free',
  durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
  seasonsCount: (json['seasons_count'] as num?)?.toInt(),
  episodesCount: (json['episodes_count'] as num?)?.toInt(),
  isNew: json['is_new'] as bool? ?? false,
  comingSoon: json['coming_soon'] as bool? ?? false,
  releaseDate: json['release_date'] as String?,
  daysUntilRelease: (json['days_until_release'] as num?)?.toInt(),
  trailerUrl: json['trailer_url'] as String?,
  posterUrl: json['poster_url'] as String?,
  thumbnailUrl: json['thumbnail_url'] as String?,
  genres:
      (json['genres'] as List<dynamic>?)
          ?.map((e) => TaxonomyRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  languages:
      (json['languages'] as List<dynamic>?)
          ?.map((e) => TaxonomyRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  artists:
      (json['artists'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  cast:
      (json['cast'] as List<dynamic>?)
          ?.map((e) => CastMember.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  seasons:
      (json['seasons'] as List<dynamic>?)
          ?.map((e) => Season.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
