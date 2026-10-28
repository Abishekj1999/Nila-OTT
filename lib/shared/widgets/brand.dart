import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

abstract final class BrandAssets {
  static const emblem = 'assets/brand/logo_emblem.png';

  /// "NILA'S" lettering cut for dark backgrounds.
  static const wordmark = 'assets/brand/wordmark_dark.png';
}

/// Compact horizontal logo for app bars: emblem + NILA'S.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.height = 34});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: "Nila's OTT",
      image: true,
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(BrandAssets.emblem, height: height, filterQuality: FilterQuality.medium),
          const SizedBox(width: 6),
          Image.asset(BrandAssets.wordmark, height: height * 0.5, filterQuality: FilterQuality.medium),
        ],
      ),
    );
  }
}

/// Stacked logo for splash, sign-in and paywall: emblem, NILA'S, OTT, tagline.
class BrandLockup extends StatelessWidget {
  const BrandLockup({super.key, this.emblemSize = 96, this.showTagline = true});

  final double emblemSize;
  final bool showTagline;

  @override
  Widget build(BuildContext context) {
    final wordHeight = emblemSize * 0.36;
    return Semantics(
      label: "Nila's OTT. Stories for every heart",
      image: true,
      excludeSemantics: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(BrandAssets.emblem, height: emblemSize, filterQuality: FilterQuality.medium),
          SizedBox(height: emblemSize * 0.08),
          Image.asset(BrandAssets.wordmark, height: wordHeight, filterQuality: FilterQuality.medium),
          SizedBox(height: emblemSize * 0.05),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Container(width: wordHeight, height: 1, color: AppColors.pink.withValues(alpha: 0.6)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                'OTT',
                style: TextStyle(color: AppColors.text, fontSize: wordHeight * 0.42, fontWeight: FontWeight.w600, letterSpacing: wordHeight * 0.3),
              ),
            ),
            Container(width: wordHeight, height: 1, color: AppColors.pink.withValues(alpha: 0.6)),
          ]),
          if (showTagline) ...[
            SizedBox(height: emblemSize * 0.06),
            Text(
              'STORIES FOR EVERY HEART',
              style: TextStyle(color: AppColors.textTertiary, fontSize: wordHeight * 0.3, fontWeight: FontWeight.w600, letterSpacing: 2.4),
            ),
          ],
        ],
      ),
    );
  }
}
