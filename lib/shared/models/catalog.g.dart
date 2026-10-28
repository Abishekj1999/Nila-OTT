// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Taxonomy _$TaxonomyFromJson(Map<String, dynamic> json) => Taxonomy(
  kind: json['kind'] as String? ?? 'genre',
  slug: json['slug'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  imageUrl: json['image_url'] as String?,
  moviesCount: (json['movies_count'] as num?)?.toInt() ?? 0,
  seriesCount: (json['series_count'] as num?)?.toInt() ?? 0,
  titlesCount: (json['titles_count'] as num?)?.toInt() ?? 0,
);

Pagination _$PaginationFromJson(Map<String, dynamic> json) => Pagination(
  total: (json['total'] as num?)?.toInt() ?? 0,
  page: (json['page'] as num?)?.toInt() ?? 1,
  perPage: (json['per_page'] as num?)?.toInt() ?? 24,
  hasMore: json['has_more'] as bool? ?? false,
);
