import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/title_card.dart';
import '../../shell/main_shell.dart';
import '../application/browse_controller.dart';
import '../data/browse_query.dart';

/// Filterable, infinitely scrolling title grid shared by the Movies, Series,
/// Genre and Language screens. Filter options come from the API response.
class BrowseView extends ConsumerStatefulWidget {
  const BrowseView({super.key, required this.initialQuery, required this.headerSlivers, this.tab});

  final BrowseQuery initialQuery;

  /// Slivers above the pinned filter bar (app bar, collection banner).
  final List<Widget> Function(BrowseState? state) headerSlivers;

  /// Bottom-tab index when this is a tab root, for scroll-to-top on reselect.
  final int? tab;

  @override
  ConsumerState<BrowseView> createState() => _BrowseViewState();
}

class _BrowseViewState extends ConsumerState<BrowseView> {
  late BrowseQuery _query = widget.initialQuery;

  // Keep the last good options so the filter bar doesn't vanish while a
  // new filter combination is loading.
  BrowseFilterOptions? _options;

  bool _onScroll(ScrollNotification n) {
    if (n.metrics.axis == Axis.vertical && n.metrics.pixels > n.metrics.maxScrollExtent - 800) {
      ref.read(browseProvider(_query).notifier).loadMore();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(browseProvider(_query));
    final state = async.value;
    if (state != null) _options = state.options;
    final top = MediaQuery.paddingOf(context).top;

    return NotificationListener<ScrollNotification>(
      onNotification: _onScroll,
      child: RefreshIndicator.adaptive(
        edgeOffset: top + kToolbarHeight,
        onRefresh: () => ref.refresh(browseProvider(_query).future),
        child: TabScrollView(
          tab: widget.tab ?? -1,
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            slivers: [
              ...widget.headerSlivers(state),
              if (_options != null)
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _FilterBarDelegate(
                    _FilterBar(query: _query, options: _options!, total: state?.pagination.total, onChanged: (q) => setState(() => _query = q)),
                  ),
                ),
              ...async.when(
                skipLoadingOnRefresh: true,
                data: _grid,
                loading: () => const [SliverFillRemaining(child: GridSkeleton())],
                error: (e, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorView(error: e, onRetry: () => ref.invalidate(browseProvider(_query))),
                  ),
                ],
              ),
              const BottomInsetSpacer(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _grid(BrowseState s) {
    if (s.titles.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(
            icon: Icons.filter_alt_off_outlined,
            message: _query.hasFilters ? 'No matches' : 'Nothing here yet',
            detail: _query.hasFilters ? 'Try removing a filter to see more titles.' : 'New titles are added regularly.',
            action: _query.hasFilters
                ? AppButton.secondary(label: 'Clear filters', small: true, onPressed: () => setState(() => _query = _query.cleared()))
                : null,
          ),
        ),
      ];
    }
    return [
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 12, AppSpacing.gutter, 8),
        sliver: SliverGrid.builder(
          gridDelegate: posterGridDelegate,
          itemCount: s.titles.length,
          itemBuilder: (_, i) => PosterCard(title: s.titles[i], showInfo: true),
        ),
      ),
      SliverToBoxAdapter(
        child: SizedBox(
          height: 56,
          child: Center(
            child: s.loadingMore
                ? const CircularProgressIndicator.adaptive()
                : s.loadMoreError != null
                ? TextButton.icon(
                    onPressed: () => ref.read(browseProvider(_query).notifier).loadMore(),
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Load more'),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ),
    ];
  }
}

class _FilterBarDelegate extends SliverPersistentHeaderDelegate {
  _FilterBarDelegate(this.child);

  final _FilterBar child;
  static const _height = 52.0;

  @override
  double get minExtent => _height;

  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(bottom: BorderSide(color: overlapsContent || shrinkOffset > 0 ? AppColors.hairline : Colors.transparent, width: 0.5)),
      ),
      child: child,
    );
  }

  @override
  bool shouldRebuild(_FilterBarDelegate old) => old.child.query != child.query || old.child.options != child.options || old.child.total != child.total;
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.query, required this.options, required this.onChanged, this.total});

  final BrowseQuery query;
  final BrowseFilterOptions options;
  final ValueChanged<BrowseQuery> onChanged;
  final int? total;

  /// Sentinel for "no filter" in pickers, since null means "dismissed".
  static const _all = '';

  Future<void> _pick(
    BuildContext context, {
    required String title,
    required String allLabel,
    required List<FilterOption> choices,
    required String? current,
    required void Function(String?) apply,
  }) async {
    final picked = await showOptionSheet<String>(
      context,
      title: title,
      selected: current ?? _all,
      options: [SheetOption(_all, allLabel), for (final o in choices) SheetOption(o.value, o.label)],
    );
    if (picked != null) apply(picked == _all ? null : picked);
  }

  @override
  Widget build(BuildContext context) {
    final isCollection = query.source == BrowseSource.genre || query.source == BrowseSource.language;
    final sort = options.sorts.where((o) => o.value == query.sort).firstOrNull ?? options.sorts.firstOrNull;
    final genre = options.genres.where((o) => o.value == query.genre).firstOrNull;
    final language = options.languages.where((o) => o.value == query.language).firstOrNull;

    final chips = <Widget>[
      if (query.hasFilters)
        AppChip(
          label: 'Clear',
          selected: false,
          leading: const Icon(Icons.close_rounded, size: 16, color: AppColors.text),
          onTap: () => onChanged(query.cleared()),
        ),
      if (isCollection)
        for (final t in options.types)
          AppChip(
            label: t.label,
            selected: (query.type ?? 'all') == t.value,
            onTap: () => onChanged(query.copyWith(type: () => t.value == 'all' ? null : t.value)),
          ),
      for (final a in options.access)
        AppChip(
          label: a.label,
          leading: a.value == 'premium' ? const Icon(Icons.workspace_premium_rounded, size: 16, color: AppColors.gold) : null,
          selected: query.access == a.value,
          onTap: () => onChanged(query.copyWith(access: () => query.access == a.value ? null : a.value)),
        ),
      if (query.source != BrowseSource.genre && options.genres.isNotEmpty)
        AppChip(
          label: genre?.label ?? 'Genre',
          selected: genre != null,
          dropdown: true,
          onTap: () => _pick(
            context,
            title: 'Genre',
            allLabel: 'All genres',
            choices: options.genres,
            current: query.genre,
            apply: (v) => onChanged(query.copyWith(genre: () => v)),
          ),
        ),
      if (query.source != BrowseSource.language && options.languages.isNotEmpty)
        AppChip(
          label: language?.label ?? 'Language',
          selected: language != null,
          dropdown: true,
          onTap: () => _pick(
            context,
            title: 'Language',
            allLabel: 'All languages',
            choices: options.languages,
            current: query.language,
            apply: (v) => onChanged(query.copyWith(language: () => v)),
          ),
        ),
      if (options.sorts.isNotEmpty)
        AppChip(
          label: sort?.label ?? 'Sort',
          selected: false,
          leading: const Icon(Icons.swap_vert_rounded, size: 16, color: AppColors.text),
          dropdown: true,
          onTap: () async {
            final picked = await showOptionSheet<String>(
              context,
              title: 'Sort by',
              selected: sort?.value ?? '',
              options: [for (final o in options.sorts) SheetOption(o.value, o.label)],
            );
            if (picked != null) onChanged(query.copyWith(sort: () => picked));
          },
        ),
    ];

    return Semantics(
      label: total == null ? 'Filters' : 'Filters, $total titles',
      container: true,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 9),
        itemCount: chips.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }
}
