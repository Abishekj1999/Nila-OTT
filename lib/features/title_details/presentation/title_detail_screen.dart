import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/title.dart';
import '../../../shared/models/viewer.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/content_row.dart';
import '../../../shared/widgets/expandable_text.dart';
import '../../../shared/widgets/skeleton.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/title_card.dart';
import '../../auth/application/auth_controller.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../home/presentation/home_rows.dart';
import '../../playback/application/play_title.dart';
import '../../viewer/application/viewer_providers.dart';
import '../application/more_like_this.dart';

/// Movie or series detail. Series add a season picker and episode list.
class TitleDetailScreen extends ConsumerWidget {
  const TitleDetailScreen({super.key, required this.type, required this.slug});

  final TitleType type;
  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = type == TitleType.series ? seriesDetailProvider(slug) : movieDetailProvider(slug);
    final async = ref.watch(provider);
    return Scaffold(
      body: async.when(
        skipLoadingOnRefresh: true,
        data: (t) => _DetailBody(detail: t),
        loading: () => const _DetailSkeleton(),
        error: (e, _) => Scaffold(
          appBar: const PageAppBar(),
          body: ErrorView(error: e, onRetry: () => ref.invalidate(provider)),
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerStatefulWidget {
  const _DetailBody({required this.detail});

  final TitleDetail detail;

  @override
  ConsumerState<_DetailBody> createState() => _DetailBodyState();
}

class _DetailBodyState extends ConsumerState<_DetailBody> {
  final _scroll = ScrollController();
  final _barOpacity = ValueNotifier<double>(0);
  int _season = 0;

  TitleDetail get t => widget.detail;

  double _backdropHeight(BuildContext context) => MediaQuery.sizeOf(context).width * 0.68 + MediaQuery.paddingOf(context).top;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      final start = _backdropHeight(context) - 140;
      _barOpacity.value = ((_scroll.offset - start) / 60).clamp(0.0, 1.0);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _barOpacity.dispose();
    super.dispose();
  }

  void _play(PlayableType type, int id) => context.push(Routes.watch(type, id));

  @override
  Widget build(BuildContext context) {
    final signedIn = ref.watch(isSignedInProvider);
    final resume = signedIn ? resumeItemFor(t, ref.watch(continueWatchingProvider).value ?? const []) : null;
    final target = playTargetFor(t, resume);

    final meta = [
      if (t.year != null) '${t.year}',
      if (!t.isSeries) formatDuration(t.durationSeconds),
      if (t.isSeries && (t.seasonsCount ?? 0) > 0) '${t.seasonsCount} Season${t.seasonsCount == 1 ? '' : 's'}',
      if (t.isSeries && (t.episodesCount ?? 0) > 0) '${t.episodesCount} Episodes',
    ].where((s) => s.isNotEmpty).toList();

    return Stack(
      children: [
        CustomScrollView(
          controller: _scroll,
          slivers: [
            SliverToBoxAdapter(child: _Backdrop(detail: t, height: _backdropHeight(context))),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
              sliver: SliverList.list(children: [
                Text(t.title, style: AppText.title1.copyWith(fontSize: 26)),
                const SizedBox(height: 8),
                Wrap(
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    if (t.isNew && !t.comingSoon) const Text('NEW', style: TextStyle(color: AppColors.pinkBright, fontSize: 13, fontWeight: FontWeight.w800)),
                    for (final m in meta) Text(m, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13.5, fontWeight: FontWeight.w500)),
                    if (t.rating?.isNotEmpty ?? false) _RatingBox(t.rating!),
                    if (t.isPremium) const PremiumBadge(label: 'Premium'),
                  ],
                ),
                const SizedBox(height: 16),
                if (t.comingSoon || target == null)
                  _ComingSoonNotice(detail: t.comingSoon ? t : null)
                else ...[
                  AppButton(
                    expand: true,
                    icon: Icons.play_arrow_rounded,
                    variant: ButtonVariant.light,
                    label: resume != null
                        ? 'Resume${resume.subtitle != null ? ' ${resume.subtitle}' : ''}'
                        : (t.isSeries ? 'Play S1 E1' : 'Play'),
                    onPressed: () => _play(target.$1, target.$2),
                  ),
                  if (resume != null) ...[
                    const SizedBox(height: 10),
                    Row(children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(value: resume.progress.clamp(0.0, 1.0), minHeight: 3),
                        ),
                      ),
                      if (resume.remainingLabel != null) ...[
                        const SizedBox(width: 10),
                        Text(resume.remainingLabel!, style: AppText.caption),
                      ],
                    ]),
                  ],
                  if (!signedIn) ...[
                    const SizedBox(height: 8),
                    const Text('Sign in to start watching', textAlign: TextAlign.center, style: AppText.caption),
                  ],
                ],
                const SizedBox(height: 14),
                if ((t.description ?? t.synopsis)?.isNotEmpty ?? false) ExpandableText(t.description ?? t.synopsis!),
                if (t.cast.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text.rich(
                    TextSpan(children: [
                      const TextSpan(text: 'Starring: ', style: TextStyle(color: AppColors.textTertiary)),
                      TextSpan(text: t.cast.take(4).map((c) => c.name).join(', ')),
                    ]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 14),
                Row(children: [
                  Expanded(child: StackedAction(icon: Icons.add_rounded, label: 'My List', onTap: () => showComingSoon(context, 'My List'))),
                  if (t.trailerUrl?.isNotEmpty ?? false)
                    Expanded(
                      child: StackedAction(
                        icon: Icons.movie_creation_outlined,
                        label: 'Trailer',
                        onTap: () {
                          final uri = Uri.tryParse(t.trailerUrl!);
                          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
                        },
                      ),
                    ),
                  Expanded(child: StackedAction(icon: Icons.ios_share_rounded, label: 'Share', onTap: () => showComingSoon(context, 'Sharing'))),
                  Expanded(child: StackedAction(icon: Icons.download_rounded, label: 'Download', onTap: () => showComingSoon(context, 'Downloads'))),
                ]),
              ]),
            ),
            if (t.isSeries && t.seasons.isNotEmpty) ..._episodes(context, resume),
            SliverToBoxAdapter(child: _MoreLikeThis(type: t.type, slug: t.slug)),
            if (t.genres.isNotEmpty || t.languages.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader(title: 'Genres & Languages')),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                  child: Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final g in t.genres) AppChip(label: g.name, selected: false, onTap: () => context.push(Routes.genre(g.slug))),
                    for (final l in t.languages)
                      AppChip(
                        label: l.name,
                        selected: false,
                        leading: const Icon(Icons.translate_rounded, size: 15, color: AppColors.textSecondary),
                        onTap: () => context.push(Routes.language(l.slug)),
                      ),
                  ]),
                ),
              ),
            ],
            if (t.cast.isNotEmpty) ...[
              const SliverToBoxAdapter(child: SectionHeader(title: 'Cast & Crew')),
              SliverToBoxAdapter(
                child: HorizontalRail(
                  height: 104,
                  spacing: 14,
                  itemCount: t.cast.length,
                  itemBuilder: (_, i) => ArtistAvatar(slug: t.cast[i].slug, name: t.cast[i].name, imageUrl: t.cast[i].imageUrl, size: 64),
                ),
              ),
            ],
            const BottomInsetSpacer(extra: 32),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          top: 0,
          child: ValueListenableBuilder<double>(
            valueListenable: _barOpacity,
            builder: (context, o, _) => _DetailTopBar(title: t.title, opacity: o),
          ),
        ),
      ],
    );
  }

  List<Widget> _episodes(BuildContext context, ContinueWatchingItem? resume) {
    final season = t.seasons[_season.clamp(0, t.seasons.length - 1)];
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 28, AppSpacing.gutter, 12),
          child: Row(children: [
            const Expanded(child: Text('Episodes', style: AppText.headline)),
            if (t.seasons.length > 1)
              AppChip(
                label: season.label,
                selected: false,
                dropdown: true,
                onTap: () async {
                  final picked = await showOptionSheet<int>(
                    context,
                    title: 'Seasons',
                    selected: _season,
                    options: [
                      for (var i = 0; i < t.seasons.length; i++)
                        SheetOption(i, '${t.seasons[i].label}  ·  ${t.seasons[i].episodes.length} episodes'),
                    ],
                  );
                  if (picked != null) setState(() => _season = picked);
                },
              )
            else
              Text(season.label, style: AppText.subhead),
          ]),
        ),
      ),
      if (season.episodes.isEmpty)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
            child: Text('Episodes coming soon.', style: AppText.subhead),
          ),
        )
      else
        SliverList.separated(
          itemCount: season.episodes.length,
          separatorBuilder: (_, _) => const SizedBox(height: 18),
          itemBuilder: (_, i) {
            final e = season.episodes[i];
            final inProgress = resume?.type == PlayableType.episode && resume?.itemId == e.id ? resume : null;
            return _EpisodeTile(
              episode: e,
              progress: inProgress?.progress,
              fallbackImages: [t.thumbnailUrl, t.posterUrl],
              onTap: () => _play(PlayableType.episode, e.id),
            );
          },
        ),
    ];
  }
}

/// Similar titles rail. Hidden when there's nothing to suggest or the
/// lookup fails, since it's secondary to the page.
class _MoreLikeThis extends ConsumerWidget {
  const _MoreLikeThis({required this.type, required this.slug});

  final TitleType type;
  final String slug;

  static const _cardWidth = 112.0;
  static const _railHeight = _cardWidth * 1.5 + 44;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final similar = ref.watch(moreLikeThisProvider((type, slug)));
    return similar.when(
      skipLoadingOnRefresh: true,
      data: (titles) => titles.isEmpty
          ? const SizedBox.shrink()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionHeader(title: 'More Like This'),
                HorizontalRail(
                  height: _railHeight,
                  itemCount: titles.length,
                  itemBuilder: (_, i) => PosterCard(title: titles[i], width: _cardWidth, showInfo: true, details: const CardDetails(year: true, rating: false)),
                ),
              ],
            ),
      loading: () => const RowSkeleton(),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.detail, required this.height});

  final TitleDetail detail;
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: Stack(fit: StackFit.expand, children: [
        ArtworkImage(urls: [detail.thumbnailUrl, detail.posterUrl], shape: ArtworkShape.landscape, alignment: Alignment.topCenter),
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x00000000), Color(0x660E090D), AppColors.background],
              stops: [0.5, 0.8, 1],
            ),
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          top: 0,
          height: 120,
          child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimTop)),
        ),
      ]),
    );
  }
}

/// Floating back/share buttons that become a frosted title bar on scroll.
class _DetailTopBar extends StatelessWidget {
  const _DetailTopBar({required this.title, required this.opacity});

  final String title;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    final solid = opacity > 0.5;
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24 * opacity, sigmaY: 24 * opacity),
        child: ColoredBox(
          color: AppColors.background.withValues(alpha: 0.88 * opacity),
          child: SafeArea(
            bottom: false,
            child: SizedBox(
              height: 52,
              child: Row(children: [
                const SizedBox(width: 10),
                solid
                    ? const AppBackButton()
                    : GlassIconButton(
                        icon: Theme.of(context).platform == TargetPlatform.iOS ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded,
                        tooltip: 'Back',
                        onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
                      ),
                Expanded(
                  child: Opacity(
                    opacity: opacity,
                    child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.headline),
                  ),
                ),
                solid
                    ? IconButton(tooltip: 'Share', icon: const Icon(Icons.ios_share_rounded), onPressed: () => showComingSoon(context, 'Sharing'))
                    : GlassIconButton(icon: Icons.ios_share_rounded, tooltip: 'Share', onPressed: () => showComingSoon(context, 'Sharing')),
                const SizedBox(width: 10),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}

class _RatingBox extends StatelessWidget {
  const _RatingBox(this.rating);

  final String rating;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(border: Border.all(color: AppColors.textTertiary), borderRadius: BorderRadius.circular(3)),
      child: Text(rating, style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, fontWeight: FontWeight.w600)),
    );
  }
}

class _EpisodeTile extends StatelessWidget {
  const _EpisodeTile({required this.episode, required this.onTap, this.fallbackImages = const [], this.progress});

  final Episode episode;
  final VoidCallback onTap;
  final List<String?> fallbackImages;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      semanticLabel: 'Episode ${episode.number}, ${episode.title}',
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 136,
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: Stack(fit: StackFit.expand, children: [
                        episode.thumbnailUrl != null
                            ? AppImage(episode.thumbnailUrl)
                            : ArtworkImage(urls: fallbackImages, shape: ArtworkShape.landscape),
                        const ColoredBox(color: Color(0x33000000)),
                        Center(
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: const Color(0x66000000),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 1.4),
                            ),
                            child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 20),
                          ),
                        ),
                        if (progress != null)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: LinearProgressIndicator(value: progress!.clamp(0.0, 1.0), minHeight: 3),
                          ),
                      ]),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${episode.number}. ${episode.title}', maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong.copyWith(fontSize: 14.5)),
                      if (episode.durationSeconds != null) ...[
                        const SizedBox(height: 3),
                        Text(formatDuration(episode.durationSeconds), style: AppText.caption),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (episode.synopsis?.isNotEmpty ?? false) ...[
              const SizedBox(height: 8),
              Text(episode.synopsis!, maxLines: 3, overflow: TextOverflow.ellipsis, style: AppText.subhead),
            ],
          ],
        ),
      ),
    );
  }
}

class _ComingSoonNotice extends StatelessWidget {
  const _ComingSoonNotice({this.detail});

  final TitleDetail? detail;

  @override
  Widget build(BuildContext context) {
    final days = detail?.daysUntilRelease;
    final release = detail?.releaseDate;
    final when = days != null && days > 0
        ? 'Arrives in $days day${days == 1 ? '' : 's'}'
        : (release != null ? 'Releasing $release' : 'Coming soon');
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.event_available_rounded, color: AppColors.pinkBright),
        const SizedBox(width: 12),
        Expanded(child: Text(when, style: AppText.bodyStrong)),
      ]),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Stack(children: [
      ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: [
          SkeletonBox(height: width * 0.68 + MediaQuery.paddingOf(context).top),
          const Padding(
            padding: EdgeInsets.all(AppSpacing.gutter),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SkeletonBox(width: 220, height: 26, radius: 6),
              SizedBox(height: 10),
              SkeletonBox(width: 160, height: 14, radius: 4),
              SizedBox(height: 18),
              SkeletonBox(height: 50, radius: 12),
              SizedBox(height: 18),
              SkeletonBox(height: 12, radius: 4),
              SizedBox(height: 8),
              SkeletonBox(height: 12, radius: 4),
              SizedBox(height: 8),
              SkeletonBox(width: 200, height: 12, radius: 4),
            ]),
          ),
        ],
      ),
      const Positioned(left: 0, right: 0, top: 0, child: _DetailTopBar(title: '', opacity: 0)),
    ]);
  }
}
