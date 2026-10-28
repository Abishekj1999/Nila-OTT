// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ArtistRole _$ArtistRoleFromJson(Map<String, dynamic> json) => ArtistRole(
  key: json['key'] as String,
  label: json['label'] as String,
  count: (json['count'] as num?)?.toInt() ?? 0,
);

ArtistSummary _$ArtistSummaryFromJson(Map<String, dynamic> json) =>
    ArtistSummary(
      slug: json['slug'] as String,
      name: json['name'] as String,
      roles:
          (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ??
          [],
      imageUrl: json['image_url'] as String?,
      titlesCount: (json['titles_count'] as num?)?.toInt() ?? 0,
    );

ArtistDirectory _$ArtistDirectoryFromJson(Map<String, dynamic> json) =>
    ArtistDirectory(
      total: (json['total'] as num?)?.toInt() ?? 0,
      role: json['role'] as String?,
      roles:
          (json['roles'] as List<dynamic>?)
              ?.map((e) => ArtistRole.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      artists:
          (json['artists'] as List<dynamic>?)
              ?.map((e) => ArtistSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

ArtistDetail _$ArtistDetailFromJson(Map<String, dynamic> json) => ArtistDetail(
  slug: json['slug'] as String,
  name: json['name'] as String,
  roles:
      (json['roles'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
  shortBio: json['short_bio'] as String?,
  bio: json['bio'] as String?,
  imageUrl: json['image_url'] as String?,
  country: json['country'] as String?,
  languages:
      (json['languages'] as List<dynamic>?)
          ?.map((e) => TaxonomyRef.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  moviesCount: (json['movies_count'] as num?)?.toInt() ?? 0,
  seriesCount: (json['series_count'] as num?)?.toInt() ?? 0,
  titles:
      (json['titles'] as List<dynamic>?)
          ?.map((e) => CatalogTitle.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
