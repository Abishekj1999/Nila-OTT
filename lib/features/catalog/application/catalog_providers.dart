import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/artist.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/models/home.dart';
import '../../../shared/models/site.dart';
import '../../../shared/models/title.dart';
import '../../auth/application/auth_controller.dart';
import '../data/catalog_repository.dart';

/// Home is refetched when the viewer signs in or out, because the
/// continue-watching row depends on the token.
final homeFeedProvider = FutureProvider<HomeFeed>((ref) {
  ref.watch(isSignedInProvider);
  return ref.watch(catalogRepositoryProvider).home();
});

final genresProvider = FutureProvider<List<Taxonomy>>((ref) => ref.watch(catalogRepositoryProvider).genres());

final languagesProvider = FutureProvider<List<Taxonomy>>((ref) => ref.watch(catalogRepositoryProvider).languages());

final movieDetailProvider =
    FutureProvider.autoDispose.family<TitleDetail, String>((ref, slug) => ref.watch(catalogRepositoryProvider).movie(slug));

final seriesDetailProvider =
    FutureProvider.autoDispose.family<TitleDetail, String>((ref, slug) => ref.watch(catalogRepositoryProvider).series(slug));

final artistDirectoryProvider =
    FutureProvider.autoDispose.family<ArtistDirectory, String?>((ref, role) => ref.watch(catalogRepositoryProvider).artists(role: role));

final artistDetailProvider =
    FutureProvider.autoDispose.family<ArtistDetail, String>((ref, slug) => ref.watch(catalogRepositoryProvider).artist(slug));

final navigationProvider = FutureProvider<SiteNavigation>((ref) => ref.watch(catalogRepositoryProvider).navigation());

final staticPageProvider =
    FutureProvider.autoDispose.family<StaticPage, String>((ref, key) => ref.watch(catalogRepositoryProvider).page(key));
