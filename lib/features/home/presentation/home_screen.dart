import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/home.dart';
import '../../../shared/models/viewer.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/content_row.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../shell/main_shell.dart';
import '../../viewer/application/viewer_providers.dart';
import '../../viewer/data/viewer_repository.dart';
import '../../viewer/presentation/continue_watching_card.dart';
import 'hero_carousel.dart';
import 'home_rows.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _scroll = ScrollController();

  /// 0 over the hero, 1 once content scrolls under the top bar.
  final _barOpacity = ValueNotifier<double>(0);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_updateBar);
  }

  void _updateBar() {
    final fadeEnd = HeroCarousel.heightFor(context) * 0.55;
    _barOpacity.value = (_scroll.offset / fadeEnd).clamp(0.0, 1.0);
  }

  @override
  void dispose() {
    _scroll.dispose();
    _barOpacity.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final feed = ref.watch(homeFeedProvider);
    final hasHero = feed.value?.banners.isNotEmpty ?? false;
    final top = MediaQuery.paddingOf(context).top;

    return Scaffold(
      body: Stack(
        children: [
          RefreshIndicator.adaptive(
            edgeOffset: top + 56,
            onRefresh: () => ref.refresh(homeFeedProvider.future),
            child: TabScrollView(
              tab: 0,
              controller: _scroll,
              builder: (context, controller) => CustomScrollView(
                controller: controller,
                slivers: [
                  if (!hasHero) SliverToBoxAdapter(child: SizedBox(height: top + 56)),
                  ...feed.when(
                    skipLoadingOnRefresh: true,
                    data: (data) => _content(context, data),
                    loading: () => const [
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
                          child: AspectRatio(aspectRatio: 0.85, child: SkeletonBox(radius: AppSpacing.radiusLg)),
                        ),
                      ),
                      SliverToBoxAdapter(child: RowSkeleton(wide: true)),
                      SliverToBoxAdapter(child: RowSkeleton()),
                    ],
                    error: (e, _) => [
                      SliverFillRemaining(
                        hasScrollBody: false,
                        child: ErrorView(error: e, onRetry: () => ref.invalidate(homeFeedProvider)),
                      ),
                    ],
                  ),
                  const BottomInsetSpacer(),
                ],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            child: ValueListenableBuilder<double>(
              valueListenable: _barOpacity,
              builder: (context, t, _) => _HomeTopBar(opacity: hasHero ? t : 1),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _content(BuildContext context, HomeFeed data) {
    final rows = data.rows.where((r) => !r.isEmpty).toList();
    if (data.banners.isEmpty && rows.isEmpty && data.continueWatching.isEmpty) {
      return const [
        SliverFillRemaining(
          hasScrollBody: false,
          child: EmptyView(message: 'New stories are on their way', detail: 'Check back soon for fresh movies and series.'),
        ),
      ];
    }
    return [
      if (data.banners.isNotEmpty) SliverToBoxAdapter(child: HeroCarousel(banners: data.banners)),
      if (data.continueWatching.isNotEmpty)
        SliverToBoxAdapter(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'Continue Watching', onSeeAll: () => context.push(Routes.continueWatching)),
              HorizontalRail(
                height: 200 * 9 / 16 + 44,
                itemCount: data.continueWatching.length,
                itemBuilder: (_, i) => ContinueWatchingCard(item: data.continueWatching[i], onRemove: () => _remove(data.continueWatching[i])),
              ),
            ],
          ),
        ),
      SliverList.builder(
        itemCount: rows.length,
        itemBuilder: (_, i) => HomeRowView(row: rows[i]),
      ),
    ];
  }

  Future<void> _remove(ContinueWatchingItem item) async {
    try {
      await ref.read(viewerRepositoryProvider).removeContinueWatching(item.id);
      ref.invalidate(homeFeedProvider);
      ref.invalidate(continueWatchingProvider);
    } catch (e) {
      if (mounted) showErrorSnack(context, e);
    }
  }
}

/// Logo bar floating over the hero; frosts in as the page scrolls.
class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.opacity});

  final double opacity;

  @override
  Widget build(BuildContext context) {
    final bar = SafeArea(
      bottom: false,
      child: SizedBox(
        height: 56,
        child: Row(
          children: [
            const SizedBox(width: AppSpacing.gutter),
            const BrandMark(height: 32),
            const Spacer(),
            IconButton(tooltip: 'Search', icon: const Icon(Icons.search_rounded, size: 26), onPressed: () => showComingSoon(context, 'Search')),
            IconButton(
              tooltip: 'Go Premium',
              icon: const Icon(Icons.workspace_premium_rounded, color: AppColors.gold, size: 26),
              onPressed: () => context.push(Routes.premium),
            ),
            const SizedBox(width: 6),
          ],
        ),
      ),
    );
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24 * opacity, sigmaY: 24 * opacity),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.background.withValues(alpha: 0.85 * opacity),
            border: Border(
              bottom: BorderSide(color: AppColors.hairline.withValues(alpha: 0.1 * opacity), width: 0.5),
            ),
          ),
          child: bar,
        ),
      ),
    );
  }
}
