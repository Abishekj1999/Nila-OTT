import 'package:flutter_test/flutter_test.dart';
import 'package:nilaott/features/title_details/application/more_like_this.dart';
import 'package:nilaott/shared/models/title.dart';

TaxonomyRef _ref(String slug) => TaxonomyRef(slug: slug, name: slug);

CatalogTitle _title(
  String slug, {
  TitleType type = TitleType.movie,
  List<String> genres = const [],
  List<String> languages = const [],
  bool isNew = false,
  int? year,
  bool comingSoon = false,
}) =>
    CatalogTitle(
      type: type,
      slug: slug,
      title: slug,
      genres: genres.map(_ref).toList(),
      languages: languages.map(_ref).toList(),
      isNew: isNew,
      year: year,
      comingSoon: comingSoon,
    );

void main() {
  final source = TitleDetail(
    id: 1,
    type: TitleType.movie,
    slug: 'the-dark-knight',
    title: 'The Dark Knight',
    genres: [_ref('action'), _ref('crime')],
    languages: [_ref('english')],
  );

  test('drops the source title, duplicates and unrelated titles', () {
    final ranked = rankSimilar(source, [
      _title('the-dark-knight', genres: ['action']),
      _title('rampage', genres: ['action']),
      _title('rampage', genres: ['action']),
      _title('kitchen-kingdoms', genres: ['documentary'], languages: ['tamil']),
    ]);
    expect(ranked.map((t) => t.slug), ['rampage']);
  });

  test('ranks shared genres first, then same type, then newer', () {
    final ranked = rankSimilar(source, [
      _title('one-genre-series', type: TitleType.series, genres: ['action']),
      _title('one-genre-old', genres: ['action'], year: 2001),
      _title('one-genre-new', genres: ['action'], year: 2020),
      _title('two-genres', genres: ['action', 'crime']),
      _title('language-only', languages: ['english']),
    ]);
    expect(ranked.map((t) => t.slug), ['two-genres', 'one-genre-new', 'one-genre-old', 'one-genre-series', 'language-only']);
  });

  test('pushes coming-soon titles down and respects the limit', () {
    final ranked = rankSimilar(source, [
      _title('soon', genres: ['action'], comingSoon: true),
      for (var i = 0; i < 20; i++) _title('t$i', genres: ['action']),
    ]);
    expect(ranked, hasLength(moreLikeThisLimit));
    expect(ranked.map((t) => t.slug), isNot(contains('soon')));
  });
}
