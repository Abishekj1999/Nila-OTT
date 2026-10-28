import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/home.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/state_views.dart';
import '../../../shared/widgets/title_card.dart';
import '../../playback/application/play_title.dart';

/// Full-bleed, auto-advancing billboard driven by `home.banners`. It sits
/// under the status bar and fades into the page.
class HeroCarousel extends StatefulWidget {
  const HeroCarousel({super.key, required this.banners});

  final List<HomeBanner> banners;

  static double heightFor(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return math.min(size.width * 1.3, size.height * 0.68);
  }

  @override
  State<HeroCarousel> createState() => _HeroCarouselState();
}

class _HeroCarouselState extends State<HeroCarousel> {
  final _controller = PageController();
  Timer? _timer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _restartTimer();
  }

  void _restartTimer() {
    _timer?.cancel();
    if (widget.banners.length < 2) return;
    _timer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (!_controller.hasClients) return;
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(next, duration: const Duration(milliseconds: 700), curve: Curves.easeInOutCubic);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: HeroCarousel.heightFor(context),
      child: Stack(
        children: [
          NotificationListener<ScrollStartNotification>(
            onNotification: (n) {
              if (n.dragDetails != null) _restartTimer();
              return false;
            },
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.banners.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (context, i) => _BannerPage(banner: widget.banners[i]),
            ),
          ),
          if (widget.banners.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 4,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.banners.length; i++)
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: i == _index ? 16 : 5,
                      height: 5,
                      decoration: BoxDecoration(
                        color: i == _index ? AppColors.text : const Color(0x55FFFFFF),
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _BannerPage extends ConsumerWidget {
  const _BannerPage({required this.banner});

  final HomeBanner banner;

  void _openDetails(BuildContext context) {
    final title = banner.title;
    if (title != null) {
      context.push(Routes.title(title.type, title.slug));
    } else if (banner.link != null) {
      final uri = Uri.tryParse(banner.link!);
      if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = banner.title;
    final genres = title?.genres.take(3).map((g) => g.name).toList() ?? const <String>[];
    final meta = [
      if (title?.year != null) '${title!.year}',
      if (title?.rating?.isNotEmpty ?? false) title!.rating!,
      if (title != null) CardDetails.lengthLabel(title),
    ].where((s) => s.isNotEmpty).toList();

    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Stack(
        fit: StackFit.expand,
        children: [
          ArtworkImage(
            urls: [banner.mobileImageUrl, title?.thumbnailUrl, title?.posterUrl, banner.imageUrl],
            shape: ArtworkShape.portrait,
            alignment: Alignment.topCenter,
          ),
          const DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimBottom)),
          const Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: 140,
            child: DecoratedBox(decoration: BoxDecoration(gradient: AppColors.scrimTop)),
          ),
          Positioned(
            left: 24,
            right: 24,
            bottom: 26,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title?.isPremium ?? false) ...[const PremiumBadge(label: 'Premium'), const SizedBox(height: 10)],
                Text(
                  banner.heading ?? title?.title ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppText.largeTitle.copyWith(shadows: const [Shadow(color: Color(0x99000000), blurRadius: 16)]),
                ),
                const SizedBox(height: 8),
                if (genres.isNotEmpty || meta.isNotEmpty)
                  Text(
                    [...genres, ...meta].join('  ·  '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: StackedAction(icon: Icons.add_rounded, label: 'My List', onTap: () => showComingSoon(context, 'My List')),
                    ),
                    SizedBox(
                      width: 132,
                      child: title != null
                          ? AppButton(
                              label: 'Play',
                              icon: Icons.play_arrow_rounded,
                              variant: ButtonVariant.light,
                              small: true,
                              onPressed: () => playTitle(context, ref, title),
                            )
                          : AppButton(
                              label: banner.buttonLabel?.isNotEmpty == true ? banner.buttonLabel! : 'Learn more',
                              variant: ButtonVariant.light,
                              small: true,
                              onPressed: () => _openDetails(context),
                            ),
                    ),
                    Expanded(
                      child: StackedAction(icon: Icons.info_outline_rounded, label: 'Info', onTap: () => _openDetails(context)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
