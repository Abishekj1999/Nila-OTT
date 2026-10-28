import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/catalog.dart';
import '../../../shared/models/home.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/content_row.dart';
import '../../../shared/widgets/expandable_text.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/title_card.dart';
import '../../home/presentation/home_rows.dart';
import '../../shell/main_shell.dart';
import '../application/catalog_providers.dart';
import '../data/browse_query.dart';
import 'browse_view.dart';

/// Movies / Series tab.
class CatalogTabScreen extends StatelessWidget {
  const CatalogTabScreen({super.key, required this.title, required this.query, required this.tab});

  final String title;
  final BrowseQuery query;
  final int tab;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrowseView(
        initialQuery: query,
        tab: tab,
        headerSlivers: (_) => [
          LargeTitleSliverAppBar(
            title: title,
            actions: [IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded, size: 26), onPressed: () => showComingSoon(context, 'Search'))],
          ),
        ],
      ),
    );
  }
}

/// Genre or language page: title, description and the filtered grid.
class CollectionScreen extends StatelessWidget {
  const CollectionScreen({super.key, required this.query});

  final BrowseQuery query;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BrowseView(
        initialQuery: query,
        headerSlivers: (state) {
          final c = state?.collection;
          return [
            LargeTitleSliverAppBar(title: c?.name ?? '', leading: const AppBackButton()),
            if (c != null)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 0, AppSpacing.gutter, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        [
                          if (c.moviesCount > 0) '${c.moviesCount} movie${c.moviesCount == 1 ? '' : 's'}',
                          if (c.seriesCount > 0) '${c.seriesCount} series',
                        ].join('  ·  '),
                        style: const TextStyle(color: AppColors.pinkBright, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                      if (c.description?.isNotEmpty ?? false) ...[const SizedBox(height: 6), Text(c.description!, style: AppText.subhead)],
                    ],
                  ),
                ),
              ),
          ];
        },
      ),
    );
  }
}

/// Explore tab: genres, languages and artists on one page.
class ExploreScreen extends ConsumerWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final genres = ref.watch(genresProvider);
    final languages = ref.watch(languagesProvider);
    final artists = ref.watch(artistDirectoryProvider(null));

    return Scaffold(
      body: RefreshIndicator.adaptive(
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        onRefresh: () {
          ref.invalidate(languagesProvider);
          ref.invalidate(artistDirectoryProvider(null));
          return ref.refresh(genresProvider.future);
        },
        child: TabScrollView(
          tab: 3,
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            slivers: [
              LargeTitleSliverAppBar(
                title: 'Explore',
                actions: [IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded, size: 26), onPressed: () => showComingSoon(context, 'Search'))],
              ),
              const SliverToBoxAdapter(
                child: SectionHeader(title: 'Genres', padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 4, 6, 10)),
              ),
              ...genres.when(
                skipLoadingOnRefresh: true,
                data: (items) => items.isEmpty
                    ? [const SliverToBoxAdapter(child: _SectionNote('No genres yet.'))]
                    : [
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                          sliver: SliverGrid.builder(
                            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                              maxCrossAxisExtent: 200,
                              childAspectRatio: 1.8,
                              crossAxisSpacing: 10,
                              mainAxisSpacing: 10,
                            ),
                            itemCount: items.length,
                            itemBuilder: (_, i) => TaxonomyTile(width: double.infinity, tile: _tile('genre', items[i])),
                          ),
                        ),
                      ],
                loading: () => [
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                    sliver: SliverGrid.builder(
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 200,
                        childAspectRatio: 1.8,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                      ),
                      itemCount: 6,
                      itemBuilder: (_, _) => const SkeletonBox(radius: AppSpacing.radius),
                    ),
                  ),
                ],
                error: (e, _) => [
                  SliverToBoxAdapter(
                    child: ErrorView(error: e, compact: true, onRetry: () => ref.invalidate(genresProvider)),
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: _RailSection<List<Taxonomy>>(
                  title: 'Languages',
                  value: languages,
                  onRetry: () => ref.invalidate(languagesProvider),
                  height: 76,
                  isEmpty: (l) => l.isEmpty,
                  builder: (items) => HorizontalRail(
                    height: 76,
                    itemCount: items.length,
                    itemBuilder: (_, i) => TaxonomyTile(width: 132, tile: _tile('language', items[i])),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _RailSection(
                  title: 'Artists',
                  value: artists,
                  onSeeAll: () => context.push(Routes.artists),
                  onRetry: () => ref.invalidate(artistDirectoryProvider(null)),
                  height: 118,
                  isEmpty: (d) => d.artists.isEmpty,
                  builder: (dir) => HorizontalRail(
                    height: 118,
                    spacing: 14,
                    itemCount: dir.artists.length.clamp(0, 20),
                    itemBuilder: (_, i) {
                      final a = dir.artists[i];
                      return ArtistAvatar(slug: a.slug, name: a.name, imageUrl: a.imageUrl, caption: a.roles.firstOrNull);
                    },
                  ),
                ),
              ),
              const BottomInsetSpacer(),
            ],
          ),
        ),
      ),
    );
  }

  static HomeTile _tile(String kind, Taxonomy t) => HomeTile(kind: kind, slug: t.slug, name: t.name, imageUrl: t.imageUrl, titlesCount: t.titlesCount);
}

class _RailSection<T> extends StatelessWidget {
  const _RailSection({
    required this.title,
    required this.value,
    required this.builder,
    required this.onRetry,
    required this.height,
    required this.isEmpty,
    this.onSeeAll,
  });

  final String title;
  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback onRetry;
  final double height;
  final bool Function(T data) isEmpty;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final data = value.value;
    if (data != null && isEmpty(data)) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, onSeeAll: onSeeAll),
        value.when(
          skipLoadingOnRefresh: true,
          data: builder,
          loading: () => SizedBox(
            height: height,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              itemCount: 5,
              separatorBuilder: (_, _) => const SizedBox(width: 10),
              itemBuilder: (_, _) => SkeletonBox(width: 120, height: height, radius: AppSpacing.radius),
            ),
          ),
          error: (e, _) => ErrorView(error: e, compact: true, onRetry: onRetry),
        ),
      ],
    );
  }
}

class _SectionNote extends StatelessWidget {
  const _SectionNote(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
    child: Text(text, style: AppText.subhead),
  );
}

/// Artist directory with role filter chips.
class ArtistsScreen extends ConsumerStatefulWidget {
  const ArtistsScreen({super.key});

  @override
  ConsumerState<ArtistsScreen> createState() => _ArtistsScreenState();
}

class _ArtistsScreenState extends ConsumerState<ArtistsScreen> {
  String? _role;

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(artistDirectoryProvider(_role));
    final roles = async.value?.roles ?? ref.watch(artistDirectoryProvider(null)).value?.roles ?? const [];
    return Scaffold(
      appBar: const PageAppBar(title: 'Artists'),
      body: CustomScrollView(
        slivers: [
          if (roles.isNotEmpty)
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 9),
                  children: [
                    for (final r in [null, ...roles]) ...[
                      AppChip(label: r == null ? 'All' : r.label, selected: _role == r?.key, onTap: () => setState(() => _role = r?.key)),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ),
          ...async.when(
            skipLoadingOnRefresh: true,
            data: (dir) => dir.artists.isEmpty
                ? [
                    const SliverFillRemaining(
                      hasScrollBody: false,
                      child: EmptyView(message: 'No artists found', icon: Icons.person_search_rounded),
                    ),
                  ]
                : [
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 12, AppSpacing.gutter, 16),
                      sliver: SliverGrid.builder(
                        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: 110,
                          childAspectRatio: 0.7,
                          crossAxisSpacing: 8,
                          mainAxisSpacing: 18,
                        ),
                        itemCount: dir.artists.length,
                        itemBuilder: (_, i) {
                          final a = dir.artists[i];
                          return ArtistAvatar(slug: a.slug, name: a.name, imageUrl: a.imageUrl, caption: a.roles.join(', '), size: 80);
                        },
                      ),
                    ),
                  ],
            loading: () => const [SliverFillRemaining(child: Center(child: CircularProgressIndicator.adaptive()))],
            error: (e, _) => [
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorView(error: e, onRetry: () => ref.invalidate(artistDirectoryProvider(_role))),
              ),
            ],
          ),
          const BottomInsetSpacer(),
        ],
      ),
    );
  }
}

/// Artist profile with bio and filmography.
class ArtistDetailScreen extends ConsumerWidget {
  const ArtistDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(artistDetailProvider(slug));
    return Scaffold(
      appBar: PageAppBar(title: async.value?.name),
      body: AsyncValueView(
        value: async,
        onRetry: () => ref.invalidate(artistDetailProvider(slug)),
        data: (a) => CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 0),
                child: Column(
                  children: [
                    Container(
                      width: 116,
                      height: 116,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.hairline),
                      ),
                      child: ClipOval(child: AppImage(a.imageUrl, icon: Icons.person_rounded)),
                    ),
                    const SizedBox(height: 14),
                    Text(a.name, textAlign: TextAlign.center, style: AppText.title1),
                    if (a.roles.isNotEmpty) ...[const SizedBox(height: 4), Text(a.roles.join(' · '), textAlign: TextAlign.center, style: AppText.subhead)],
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
                      child: Row(
                        children: [
                          Expanded(
                            child: _Stat(value: '${a.moviesCount}', label: 'Movies'),
                          ),
                          Container(width: 0.5, height: 28, color: AppColors.hairline),
                          Expanded(
                            child: _Stat(value: '${a.seriesCount}', label: 'Series'),
                          ),
                          if (a.country?.isNotEmpty ?? false) ...[
                            Container(width: 0.5, height: 28, color: AppColors.hairline),
                            Expanded(
                              child: _Stat(value: a.country!, label: 'Country'),
                            ),
                          ],
                        ],
                      ),
                    ),
                    if ((a.bio ?? a.shortBio)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 18),
                      Align(alignment: Alignment.centerLeft, child: ExpandableText(a.bio ?? a.shortBio!)),
                    ],
                  ],
                ),
              ),
            ),
            if (a.titles.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader(title: 'Filmography')),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                sliver: SliverGrid.builder(
                  gridDelegate: posterGridDelegate,
                  itemCount: a.titles.length,
                  itemBuilder: (_, i) => PosterCard(title: a.titles[i], showInfo: true),
                ),
              ),
            ],
            const BottomInsetSpacer(),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.headline),
        const SizedBox(height: 2),
        Text(label, style: AppText.caption),
      ],
    );
  }
}
