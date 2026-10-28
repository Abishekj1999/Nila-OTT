import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/models/title.dart';
import '../data/browse_query.dart';
import '../data/catalog_repository.dart';

class BrowseState {
  const BrowseState({
    required this.titles,
    required this.pagination,
    required this.options,
    this.collection,
    this.loadingMore = false,
    this.loadMoreError,
  });

  final List<CatalogTitle> titles;
  final Pagination pagination;
  final BrowseFilterOptions options;
  final Taxonomy? collection;
  final bool loadingMore;
  final ApiException? loadMoreError;

  bool get hasMore => pagination.hasMore;

  BrowseState copyWith({
    List<CatalogTitle>? titles,
    Pagination? pagination,
    bool? loadingMore,
    ApiException? Function()? loadMoreError,
  }) =>
      BrowseState(
        titles: titles ?? this.titles,
        pagination: pagination ?? this.pagination,
        options: options,
        collection: collection,
        loadingMore: loadingMore ?? this.loadingMore,
        loadMoreError: loadMoreError != null ? loadMoreError() : this.loadMoreError,
      );
}

/// Paginated, filterable title grid. One instance per [BrowseQuery].
class BrowseController extends AsyncNotifier<BrowseState> {
  BrowseController(this.query);

  final BrowseQuery query;

  @override
  Future<BrowseState> build() async {
    final page = await ref.read(catalogRepositoryProvider).browse(query);
    return BrowseState(
      titles: page.titles,
      pagination: page.pagination,
      options: page.options,
      collection: page.collection,
    );
  }

  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(current.copyWith(loadingMore: true, loadMoreError: () => null));
    try {
      final next = await ref.read(catalogRepositoryProvider).browse(query, page: current.pagination.page + 1);
      if (!ref.mounted) return;
      // De-duplicate in case the catalog shifted between pages.
      final seen = current.titles.map((t) => '${t.type.name}:${t.slug}').toSet();
      final fresh = next.titles.where((t) => seen.add('${t.type.name}:${t.slug}'));
      state = AsyncData(current.copyWith(
        titles: [...current.titles, ...fresh],
        pagination: next.pagination,
        loadingMore: false,
      ));
    } catch (e) {
      if (!ref.mounted) return;
      state = AsyncData(current.copyWith(loadingMore: false, loadMoreError: () => ApiException.from(e)));
    }
  }
}

final browseProvider =
    AsyncNotifierProvider.autoDispose.family<BrowseController, BrowseState, BrowseQuery>(BrowseController.new);
