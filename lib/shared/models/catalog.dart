import 'package:json_annotation/json_annotation.dart';

import 'title.dart';

part 'catalog.g.dart';

const _json = JsonSerializable(fieldRename: FieldRename.snake, createToJson: false);

/// Genre or language directory entry; also the `collection` of a browse page.
@_json
class Taxonomy {
  const Taxonomy({
    required this.kind,
    required this.slug,
    required this.name,
    this.description,
    this.imageUrl,
    this.moviesCount = 0,
    this.seriesCount = 0,
    this.titlesCount = 0,
  });

  @JsonKey(defaultValue: 'genre')
  final String kind;
  final String slug;
  final String name;
  final String? description;
  final String? imageUrl;
  @JsonKey(defaultValue: 0)
  final int moviesCount;
  @JsonKey(defaultValue: 0)
  final int seriesCount;
  @JsonKey(defaultValue: 0)
  final int titlesCount;

  factory Taxonomy.fromJson(Map<String, dynamic> json) => _$TaxonomyFromJson(json);
}

@_json
class Pagination {
  const Pagination({this.total = 0, this.page = 1, this.perPage = 24, this.hasMore = false});

  @JsonKey(defaultValue: 0)
  final int total;
  @JsonKey(defaultValue: 1)
  final int page;
  @JsonKey(defaultValue: 24)
  final int perPage;
  @JsonKey(defaultValue: false)
  final bool hasMore;

  factory Pagination.fromJson(Map<String, dynamic> json) => _$PaginationFromJson(json);
}

/// Filter options come in two shapes: `{value, label}` and `{slug, name}`.
class FilterOption {
  const FilterOption({required this.value, required this.label});

  final String value;
  final String label;

  factory FilterOption.fromJson(Map<String, dynamic> json) => FilterOption(
        value: '${json['value'] ?? json['slug'] ?? ''}',
        label: '${json['label'] ?? json['name'] ?? ''}',
      );

  static List<FilterOption> listFrom(Object? raw) => raw is List
      ? raw.whereType<Map>().map((e) => FilterOption.fromJson(e.cast<String, dynamic>())).where((o) => o.value.isNotEmpty).toList()
      : const [];
}

class BrowseFilterOptions {
  const BrowseFilterOptions({
    this.types = const [],
    this.genres = const [],
    this.languages = const [],
    this.access = const [],
    this.sorts = const [],
  });

  final List<FilterOption> types;
  final List<FilterOption> genres;
  final List<FilterOption> languages;
  final List<FilterOption> access;
  final List<FilterOption> sorts;

  factory BrowseFilterOptions.fromJson(Map<String, dynamic>? json) => BrowseFilterOptions(
        types: FilterOption.listFrom(json?['types']),
        genres: FilterOption.listFrom(json?['genres']),
        languages: FilterOption.listFrom(json?['languages']),
        access: FilterOption.listFrom(json?['access']),
        sorts: FilterOption.listFrom(json?['sorts']),
      );
}

/// BrowsePageResource returned by movies, series, genres/{slug} and languages/{slug}.
class BrowsePage {
  const BrowsePage({this.collection, required this.titles, required this.pagination, required this.options});

  final Taxonomy? collection;
  final List<CatalogTitle> titles;
  final Pagination pagination;
  final BrowseFilterOptions options;

  factory BrowsePage.fromJson(Map<String, dynamic> json) {
    final collection = json['collection'];
    final filters = json['filters'];
    final pagination = json['pagination'];
    return BrowsePage(
      collection: collection is Map ? Taxonomy.fromJson(collection.cast<String, dynamic>()) : null,
      titles: (json['titles'] as List? ?? const [])
          .whereType<Map>()
          .map((e) => CatalogTitle.fromJson(e.cast<String, dynamic>()))
          .toList(),
      pagination: pagination is Map ? Pagination.fromJson(pagination.cast<String, dynamic>()) : const Pagination(),
      options: BrowseFilterOptions.fromJson(filters is Map ? (filters['options'] as Map?)?.cast<String, dynamic>() : null),
    );
  }
}
