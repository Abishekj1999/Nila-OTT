import 'package:json_annotation/json_annotation.dart';

import 'title.dart';

part 'artist.g.dart';

const _json = JsonSerializable(fieldRename: FieldRename.snake, createToJson: false);

@_json
class ArtistRole {
  const ArtistRole({required this.key, required this.label, this.count = 0});

  final String key;
  final String label;
  @JsonKey(defaultValue: 0)
  final int count;

  factory ArtistRole.fromJson(Map<String, dynamic> json) => _$ArtistRoleFromJson(json);
}

@_json
class ArtistSummary {
  const ArtistSummary({required this.slug, required this.name, this.roles = const [], this.imageUrl, this.titlesCount = 0});

  final String slug;
  final String name;
  @JsonKey(defaultValue: <String>[])
  final List<String> roles;
  final String? imageUrl;
  @JsonKey(defaultValue: 0)
  final int titlesCount;

  factory ArtistSummary.fromJson(Map<String, dynamic> json) => _$ArtistSummaryFromJson(json);
}

@_json
class ArtistDirectory {
  const ArtistDirectory({this.total = 0, this.role, this.roles = const [], this.artists = const []});

  @JsonKey(defaultValue: 0)
  final int total;
  final String? role;
  @JsonKey(defaultValue: <ArtistRole>[])
  final List<ArtistRole> roles;
  @JsonKey(defaultValue: <ArtistSummary>[])
  final List<ArtistSummary> artists;

  factory ArtistDirectory.fromJson(Map<String, dynamic> json) => _$ArtistDirectoryFromJson(json);
}

@_json
class ArtistDetail {
  const ArtistDetail({
    required this.slug,
    required this.name,
    this.roles = const [],
    this.shortBio,
    this.bio,
    this.imageUrl,
    this.country,
    this.languages = const [],
    this.moviesCount = 0,
    this.seriesCount = 0,
    this.titles = const [],
  });

  final String slug;
  final String name;
  @JsonKey(defaultValue: <String>[])
  final List<String> roles;
  final String? shortBio;
  final String? bio;
  final String? imageUrl;
  final String? country;
  @JsonKey(defaultValue: <TaxonomyRef>[])
  final List<TaxonomyRef> languages;
  @JsonKey(defaultValue: 0)
  final int moviesCount;
  @JsonKey(defaultValue: 0)
  final int seriesCount;
  @JsonKey(defaultValue: <CatalogTitle>[])
  final List<CatalogTitle> titles;

  factory ArtistDetail.fromJson(Map<String, dynamic> json) => _$ArtistDetailFromJson(json);
}
