import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../models/title.dart';
import 'title_card.dart';

/// Rail heading: bold title with an optional chevron link.
class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, this.onSeeAll, this.padding = const EdgeInsets.fromLTRB(AppSpacing.gutter, 26, 6, 10)});

  final String title;
  final VoidCallback? onSeeAll;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final heading = Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.headline);
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 32,
        child: onSeeAll == null
            ? Align(alignment: Alignment.centerLeft, child: heading)
            : Align(
                alignment: Alignment.centerLeft,
                child: Semantics(
                  button: true,
                  label: '$title, see all',
                  excludeSemantics: true,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: onSeeAll,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(child: heading),
                        const SizedBox(width: 2),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary, size: 24),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// Horizontal list of items under a section header.
class HorizontalRail extends StatelessWidget {
  const HorizontalRail({super.key, required this.height, required this.itemCount, required this.itemBuilder, this.spacing = 10});

  final double height;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
        itemCount: itemCount,
        separatorBuilder: (_, _) => SizedBox(width: spacing),
        itemBuilder: itemBuilder,
      ),
    );
  }
}

/// Title rail in poster (2:3) or wide (16:9) layout.
class TitleRail extends StatelessWidget {
  const TitleRail({super.key, required this.titles, this.wide = false, this.details = const CardDetails()});

  static const posterWidth = 112.0;
  static const wideWidth = 220.0;

  final List<CatalogTitle> titles;
  final bool wide;
  final CardDetails details;

  @override
  Widget build(BuildContext context) {
    return HorizontalRail(
      height: wide ? wideWidth * 9 / 16 + 44 : posterWidth * 1.5,
      itemCount: titles.length,
      itemBuilder: (_, i) =>
          wide ? WideCard(title: titles[i], details: details, width: wideWidth) : PosterCard(title: titles[i], details: details, width: posterWidth),
    );
  }
}
