import 'package:json_annotation/json_annotation.dart';

part 'title.g.dart';

const _json = JsonSerializable(fieldRename: FieldRename.snake, createToJson: false);

/// Genre or language reference embedded in titles and filters.
@_json
class TaxonomyRef {
  const TaxonomyRef({required this.slug, required this.name, this.code});

  final String slug;
  final String name;
  final String? code;

  factory TaxonomyRef.fromJson(Map<String, dynamic> json) => _$TaxonomyRefFromJson(json);
}

enum TitleType {
  movie,
  series;

  static TitleType parse(String? value) => value == 'series' ? TitleType.series : TitleType.movie;
}

/// TitleResource: the card-level title shape used in lists, rows and banners.
@_json
class CatalogTitle {
  const CatalogTitle({
    required this.type,
    required this.slug,
    required this.title,
    this.synopsis,
    this.year,
    this.rating,
    this.access = 'free',
    this.durationSeconds,
    this.seasonsCount,
    this.episodesCount,
    this.isNew = false,
    this.comingSoon = false,
    this.releaseDate,
    this.daysUntilRelease,
    this.trailerUrl,
    this.posterUrl,
    this.thumbnailUrl,
    this.genres = const [],
    this.languages = const [],
    this.artists = const [],
  });

  @JsonKey(fromJson: TitleType.parse)
  final TitleType type;
  final String slug;
  final String title;
  final String? synopsis;
  final int? year;
  final String? rating;
  @JsonKey(defaultValue: 'free')
  final String access;
  final int? durationSeconds;
  final int? seasonsCount;
  final int? episodesCount;
  @JsonKey(defaultValue: false)
  final bool isNew;
  @JsonKey(defaultValue: false)
  final bool comingSoon;
  final String? releaseDate;
  final int? daysUntilRelease;
  final String? trailerUrl;
  final String? posterUrl;
  final String? thumbnailUrl;
  @JsonKey(defaultValue: <TaxonomyRef>[])
  final List<TaxonomyRef> genres;
  @JsonKey(defaultValue: <TaxonomyRef>[])
  final List<TaxonomyRef> languages;
  @JsonKey(defaultValue: <String>[])
  final List<String> artists;

  bool get isPremium => access == 'premium';
  bool get isSeries => type == TitleType.series;

  factory CatalogTitle.fromJson(Map<String, dynamic> json) => _$CatalogTitleFromJson(json);
}

@_json
class CastMember {
  const CastMember({required this.name, required this.slug, this.imageUrl});

  final String name;
  final String slug;
  final String? imageUrl;

  factory CastMember.fromJson(Map<String, dynamic> json) => _$CastMemberFromJson(json);
}

@_json
class Episode {
  const Episode({required this.id, required this.number, required this.title, this.synopsis, this.durationSeconds, this.thumbnailUrl});

  final int id;
  final int number;
  final String title;
  final String? synopsis;
  final int? durationSeconds;
  final String? thumbnailUrl;

  factory Episode.fromJson(Map<String, dynamic> json) => _$EpisodeFromJson(json);
}

@_json
class Season {
  const Season({required this.id, required this.number, this.title, this.episodes = const []});

  final int id;
  final int number;
  final String? title;
  @JsonKey(defaultValue: <Episode>[])
  final List<Episode> episodes;

  String get label => (title == null || title!.isEmpty) ? 'Season $number' : 'S$number · $title';

  factory Season.fromJson(Map<String, dynamic> json) => _$SeasonFromJson(json);
}

/// Full movie or series payload from `/movies/{slug}` and `/series/{slug}`.
@_json
class TitleDetail {
  const TitleDetail({
    required this.id,
    required this.type,
    required this.slug,
    required this.title,
    this.synopsis,
    this.description,
    this.year,
    this.rating,
    this.access = 'free',
    this.durationSeconds,
    this.seasonsCount,
    this.episodesCount,
    this.isNew = false,
    this.comingSoon = false,
    this.releaseDate,
    this.daysUntilRelease,
    this.trailerUrl,
    this.posterUrl,
    this.thumbnailUrl,
    this.genres = const [],
    this.languages = const [],
    this.artists = const [],
    this.cast = const [],
    this.seasons = const [],
  });

  final int id;
  @JsonKey(fromJson: TitleType.parse)
  final TitleType type;
  final String slug;
  final String title;
  final String? synopsis;
  final String? description;
  final int? year;
  final String? rating;
  @JsonKey(defaultValue: 'free')
  final String access;
  final int? durationSeconds;
  final int? seasonsCount;
  final int? episodesCount;
  @JsonKey(defaultValue: false)
  final bool isNew;
  @JsonKey(defaultValue: false)
  final bool comingSoon;
  final String? releaseDate;
  final int? daysUntilRelease;
  final String? trailerUrl;
  final String? posterUrl;
  final String? thumbnailUrl;
  @JsonKey(defaultValue: <TaxonomyRef>[])
  final List<TaxonomyRef> genres;
  @JsonKey(defaultValue: <TaxonomyRef>[])
  final List<TaxonomyRef> languages;
  @JsonKey(defaultValue: <String>[])
  final List<String> artists;
  @JsonKey(defaultValue: <CastMember>[])
  final List<CastMember> cast;
  // `seasons` is null for movies.
  @JsonKey(defaultValue: <Season>[])
  final List<Season> seasons;

  bool get isPremium => access == 'premium';
  bool get isSeries => type == TitleType.series;

  factory TitleDetail.fromJson(Map<String, dynamic> json) => _$TitleDetailFromJson(json);
}
