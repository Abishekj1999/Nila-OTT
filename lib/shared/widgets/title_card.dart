import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../models/title.dart';
import 'app_image.dart';
import 'buttons.dart';

/// Which meta fields a card shows, mapped from the server's `card_details`.
class CardDetails {
  const CardDetails({this.rating = true, this.year = false, this.length = true, this.showNewBadge = true});

  factory CardDetails.fromServer(List<String> details, {bool showNewBadge = true}) => CardDetails(
        rating: details.contains('rating'),
        year: details.contains('year'),
        length: details.contains('length') || details.contains('duration'),
        showNewBadge: showNewBadge,
      );

  final bool rating;
  final bool year;
  final bool length;
  final bool showNewBadge;

  List<String> metaFor(CatalogTitle t) => [
        if (year && t.year != null) '${t.year}',
        if (rating && (t.rating?.isNotEmpty ?? false)) t.rating!,
        if (length) lengthLabel(t),
      ].where((s) => s.isNotEmpty).toList();

  static String lengthLabel(CatalogTitle t) {
    if (!t.isSeries) return formatDuration(t.durationSeconds);
    final seasons = t.seasonsCount ?? 0;
    return seasons > 0 ? '$seasons Season${seasons == 1 ? '' : 's'}' : '';
  }
}

/// Portrait 2:3 poster. Rails show artwork only; grids add the title below.
class PosterCard extends StatelessWidget {
  const PosterCard({super.key, required this.title, this.details = const CardDetails(), this.width, this.showInfo = false});

  final CatalogTitle title;
  final CardDetails details;
  final double? width;
  final bool showInfo;

  @override
  Widget build(BuildContext context) {
    final artwork = _Artwork(shape: ArtworkShape.portrait, title: title, details: details);
    return SizedBox(
      width: width,
      child: PressableScale(
        semanticLabel: title.title,
        onTap: () => context.push(Routes.title(title.type, title.slug)),
        child: showInfo
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: artwork),
                  const SizedBox(height: 7),
                  Text(title.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.text)),
                  const SizedBox(height: 1),
                  Text(
                    details.metaFor(title).join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.caption,
                  ),
                ],
              )
            : artwork,
      ),
    );
  }
}

/// Landscape 16:9 card with title and meta below.
class WideCard extends StatelessWidget {
  const WideCard({super.key, required this.title, this.details = const CardDetails(), this.width = 220});

  final CatalogTitle title;
  final CardDetails details;
  final double width;

  @override
  Widget build(BuildContext context) {
    final meta = details.metaFor(title);
    return SizedBox(
      width: width,
      child: PressableScale(
        semanticLabel: title.title,
        onTap: () => context.push(Routes.title(title.type, title.slug)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(aspectRatio: 16 / 9, child: _Artwork(shape: ArtworkShape.landscape, title: title, details: details)),
            const SizedBox(height: 8),
            Text(title.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text)),
            if (meta.isNotEmpty) Text(meta.join(' · '), maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
          ],
        ),
      ),
    );
  }
}

class _Artwork extends StatelessWidget {
  const _Artwork({required this.shape, required this.title, required this.details});

  final ArtworkShape shape;
  final CatalogTitle title;
  final CardDetails details;

  @override
  Widget build(BuildContext context) {
    final tag = title.comingSoon
        ? const TagBadge('COMING SOON', color: Color(0xE6231920))
        : (details.showNewBadge && title.isNew ? const TagBadge('NEW', color: AppColors.pink) : null);
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSpacing.radius),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          border: Border.all(color: AppColors.hairline, width: 0.5),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ArtworkImage(urls: [title.thumbnailUrl, title.posterUrl], shape: shape),
            if (tag != null) Positioned(left: 0, top: 0, child: tag),
            if (title.isPremium) const Positioned(right: 6, top: 6, child: PremiumBadge()),
          ],
        ),
      ),
    );
  }
}

/// Corner ribbon ("NEW", "COMING SOON") flush with the card's top-left.
class TagBadge extends StatelessWidget {
  const TagBadge(this.label, {super.key, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(color: color, borderRadius: const BorderRadius.only(bottomRight: Radius.circular(6))),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.6)),
    );
  }
}

/// Gold crown marker for premium titles; with [label], a pill.
class PremiumBadge extends StatelessWidget {
  const PremiumBadge({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    final pill = label != null;
    return Semantics(
      label: 'Premium',
      excludeSemantics: true,
      child: Container(
        height: pill ? 22 : 20,
        width: pill ? null : 20,
        padding: pill ? const EdgeInsets.symmetric(horizontal: 8) : null,
        decoration: BoxDecoration(gradient: AppColors.goldGradient, borderRadius: BorderRadius.circular(11)),
        child: Row(mainAxisSize: MainAxisSize.min, mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.workspace_premium_rounded, size: pill ? 14 : 13, color: AppColors.goldDeep),
          if (pill) ...[
            const SizedBox(width: 4),
            Text(label!, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.goldDeep)),
          ],
        ]),
      ),
    );
  }
}
