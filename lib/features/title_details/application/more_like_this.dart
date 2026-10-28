import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/title.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../catalog/data/browse_query.dart';
import '../../catalog/data/catalog_repository.dart';

/// How many titles the "More Like This" rail shows.
const moreLikeThisLimit = 12;

/// Ranks [candidates] by similarity to [source], best first.
///
/// The API has no recommendations endpoint, so similarity is scored from
/// what listings carry: shared genres weigh most, then same type (movie
/// or series), shared languages and shared cast. The source title,
/// duplicates and titles sharing nothing are dropped; ties favour new,
/// then more recent titles.
List<CatalogTitle> rankSimilar(TitleDetail source, Iterable<CatalogTitle> candidates, {int limit = moreLikeThisLimit}) {
  final genres = source.genres.map((g) => g.slug).toSet();
  final languages = source.languages.map((l) => l.slug).toSet();
  final artists = source.cast.map((c) => c.name.toLowerCase()).toSet()..addAll(source.artists.map((a) => a.toLowerCase()));

  final seen = <String>{'${source.type.name}:${source.slug}'};
  final scored = <(CatalogTitle, int)>[];
  for (final t in candidates) {
    if (!seen.add('${t.type.name}:${t.slug}')) continue;
    final sharedGenres = t.genres.where((g) => genres.contains(g.slug)).length;
    final sharedLanguages = t.languages.where((l) => languages.contains(l.slug)).length;
    final sharedArtists = t.artists.where((a) => artists.contains(a.toLowerCase())).length;
    if (sharedGenres + sharedLanguages + sharedArtists == 0) continue;
    final score = sharedGenres * 4 + (t.type == source.type ? 2 : 0) + sharedLanguages + sharedArtists * 2 - (t.comingSoon ? 3 : 0);
    scored.add((t, score));
  }

  scored.sort((a, b) {
    final byScore = b.$2.compareTo(a.$2);
    if (byScore != 0) return byScore;
    if (a.$1.isNew != b.$1.isNew) return a.$1.isNew ? -1 : 1;
    return (b.$1.year ?? 0).compareTo(a.$1.year ?? 0);
  });
  return scored.take(limit).map((e) => e.$1).toList();
}

/// Titles similar to the movie or series identified by [key], built from
/// the genre (and, as a fallback, language) browse endpoints.
final moreLikeThisProvider = FutureProvider.autoDispose.family<List<CatalogTitle>, (TitleType, String)>((ref, key) async {
  final (type, slug) = key;
  final source = await ref.watch((type == TitleType.series ? seriesDetailProvider(slug) : movieDetailProvider(slug)).future);
  final repo = ref.read(catalogRepositoryProvider);

  // Up to three genres, fetched in parallel; one failing genre shouldn't
  // hide the rest.
  Future<List<CatalogTitle>> fetch(BrowseQuery q) => repo.browse(q).then((p) => p.titles, onError: (_) => <CatalogTitle>[]);
  final pools = await Future.wait(source.genres.take(3).map((g) => fetch(BrowseQuery.genre(g.slug))));
  var ranked = rankSimilar(source, pools.expand((p) => p));

  if (ranked.length < 4 && source.languages.isNotEmpty) {
    final byLanguage = await fetch(BrowseQuery.language(source.languages.first.slug));
    ranked = rankSimilar(source, [...ranked, ...byLanguage]);
  }
  return ranked;
});
