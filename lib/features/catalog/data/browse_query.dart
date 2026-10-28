/// Which browse endpoint a [BrowseQuery] targets.
enum BrowseSource { movies, series, genre, language }

/// Immutable filter set for the paginated browse endpoints.
/// Used as a provider family key, so it implements value equality.
class BrowseQuery {
  const BrowseQuery({
    required this.source,
    this.slug,
    this.type,
    this.genre,
    this.language,
    this.access,
    this.sort,
  });

  const BrowseQuery.movies() : this(source: BrowseSource.movies);
  const BrowseQuery.series() : this(source: BrowseSource.series);
  const BrowseQuery.genre(String slug) : this(source: BrowseSource.genre, slug: slug);
  const BrowseQuery.language(String slug) : this(source: BrowseSource.language, slug: slug);

  final BrowseSource source;
  final String? slug;

  /// `all` | `movie` | `series` (genre/language pages only).
  final String? type;
  final String? genre;
  final String? language;
  final String? access;
  final String? sort;

  String get path => switch (source) {
        BrowseSource.movies => '/movies',
        BrowseSource.series => '/series',
        BrowseSource.genre => '/genres/$slug',
        BrowseSource.language => '/languages/$slug',
      };

  /// Only parameters the endpoint documents are sent.
  Map<String, dynamic> params(int page) => {
        if (source == BrowseSource.genre || source == BrowseSource.language) 'type': type,
        if (source != BrowseSource.genre) 'genre': genre,
        if (source != BrowseSource.language) 'language': language,
        'access': access,
        'sort': sort,
        'page': page,
      };

  bool get hasFilters => [type, genre, language, access].any((v) => v != null && v != 'all') || sort != null;

  BrowseQuery copyWith({
    String? Function()? type,
    String? Function()? genre,
    String? Function()? language,
    String? Function()? access,
    String? Function()? sort,
  }) =>
      BrowseQuery(
        source: source,
        slug: slug,
        type: type != null ? type() : this.type,
        genre: genre != null ? genre() : this.genre,
        language: language != null ? language() : this.language,
        access: access != null ? access() : this.access,
        sort: sort != null ? sort() : this.sort,
      );

  BrowseQuery cleared() => BrowseQuery(source: source, slug: slug);

  @override
  bool operator ==(Object other) =>
      other is BrowseQuery &&
      other.source == source &&
      other.slug == slug &&
      other.type == type &&
      other.genre == genre &&
      other.language == language &&
      other.access == access &&
      other.sort == sort;

  @override
  int get hashCode => Object.hash(source, slug, type, genre, language, access, sort);
}
