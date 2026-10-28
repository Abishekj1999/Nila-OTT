import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/providers.dart';
import '../../../shared/models/artist.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/models/home.dart';
import '../../../shared/models/site.dart';
import '../../../shared/models/title.dart';
import 'browse_query.dart';

/// Public catalog endpoints. All work for guests; the home feed also
/// includes continue-watching when a token is attached.
class CatalogRepository {
  CatalogRepository(this._api);

  final ApiClient _api;

  Future<HomeFeed> home() => _api.get('/home', parse: (d) => HomeFeed.fromJson(asMap(d)));

  Future<SiteNavigation> navigation() => _api.get('/navigation', parse: (d) => SiteNavigation.fromJson(asMap(d)));

  Future<StaticPage> page(String key) => _api.get('/pages/$key', parse: (d) => StaticPage.fromJson(asMap(d)));

  Future<BrowsePage> browse(BrowseQuery query, {int page = 1}) =>
      _api.get(query.path, query: query.params(page), parse: (d) => BrowsePage.fromJson(asMap(d)));

  Future<List<Taxonomy>> genres() => _api.get('/genres', parse: (d) => asMapList(d).map(Taxonomy.fromJson).toList());

  Future<List<Taxonomy>> languages() => _api.get('/languages', parse: (d) => asMapList(d).map(Taxonomy.fromJson).toList());

  Future<TitleDetail> movie(String slug) => _api.get('/movies/$slug', parse: (d) => TitleDetail.fromJson(asMap(d)));

  Future<TitleDetail> series(String slug) => _api.get('/series/$slug', parse: (d) => TitleDetail.fromJson(asMap(d)));

  Future<ArtistDirectory> artists({String? role}) =>
      _api.get('/artists', query: {'role': role}, parse: (d) => ArtistDirectory.fromJson(asMap(d)));

  Future<ArtistDetail> artist(String slug) => _api.get('/artists/$slug', parse: (d) => ArtistDetail.fromJson(asMap(d)));
}

final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => CatalogRepository(ref.watch(apiClientProvider)));
