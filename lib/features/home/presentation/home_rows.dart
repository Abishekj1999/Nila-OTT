import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/home.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/chips.dart';
import '../../../shared/widgets/content_row.dart';
import '../../../shared/widgets/title_card.dart';

/// Renders one server-defined home row according to the content it carries.
class HomeRowView extends StatelessWidget {
  const HomeRowView({super.key, required this.row});

  final HomeRow row;

  @override
  Widget build(BuildContext context) {
    final details = CardDetails.fromServer(row.cardDetails, showNewBadge: row.showNewBadge);
    final Widget body;
    if (row.items.isNotEmpty) {
      body = TitleRail(titles: row.items, wide: row.isWide, details: details);
    } else if (row.tiles.isNotEmpty) {
      body = HorizontalRail(
        height: 84,
        itemCount: row.tiles.length,
        itemBuilder: (_, i) => TaxonomyTile(tile: row.tiles[i], width: 150),
      );
    } else if (row.tabs.isNotEmpty) {
      body = _TabbedRail(tabs: row.tabs, details: details, wide: row.isWide);
    } else {
      body = HorizontalRail(
        height: 118,
        spacing: 14,
        itemCount: row.artists.length,
        itemBuilder: (_, i) => ArtistAvatar(
          slug: row.artists[i].slug,
          name: row.artists[i].name,
          imageUrl: row.artists[i].imageUrl,
          caption: row.artists[i].role,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: row.title, onSeeAll: _seeAll(context)),
        body,
      ],
    );
  }

  VoidCallback? _seeAll(BuildContext context) => switch (row.source) {
        'movies' => () => context.go(Routes.movies),
        'series' => () => context.go(Routes.series),
        'genre_tiles' || 'language_tiles' => () => context.go(Routes.explore),
        _ when row.artists.isNotEmpty => () => context.push(Routes.artists),
        _ => null,
      };
}

class _TabbedRail extends StatefulWidget {
  const _TabbedRail({required this.tabs, required this.details, required this.wide});

  final List<HomeTab> tabs;
  final CardDetails details;
  final bool wide;

  @override
  State<_TabbedRail> createState() => _TabbedRailState();
}

class _TabbedRailState extends State<_TabbedRail> {
  int _selected = 0;

  @override
  Widget build(BuildContext context) {
    final tab = widget.tabs[_selected.clamp(0, widget.tabs.length - 1)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 34,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            itemCount: widget.tabs.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => AppChip(
              label: widget.tabs[i].name,
              selected: i == _selected,
              onTap: () => setState(() => _selected = i),
            ),
          ),
        ),
        const SizedBox(height: 12),
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 220),
          child: tab.items.isEmpty
              ? const Padding(
                  key: ValueKey('empty'),
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 24),
                  child: Text('Nothing here yet.', style: AppText.subhead),
                )
              : TitleRail(key: ValueKey(tab.slug), titles: tab.items, wide: widget.wide, details: widget.details),
        ),
      ],
    );
  }
}

/// Genre or language tile: artwork with a tinted scrim and the name.
class TaxonomyTile extends StatelessWidget {
  const TaxonomyTile({super.key, required this.tile, this.width = 150});

  final HomeTile tile;
  final double width;

  @override
  Widget build(BuildContext context) {
    final isLanguage = tile.kind == 'language';
    return SizedBox(
      width: width,
      child: PressableScale(
        semanticLabel: tile.name,
        onTap: () => context.push(isLanguage ? Routes.language(tile.slug) : Routes.genre(tile.slug)),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppImage(tile.imageUrl, icon: isLanguage ? Icons.translate_rounded : Icons.theater_comedy_outlined),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x1A000000), Color(0xF0120810)],
                    stops: [0.2, 0.95],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(tile.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15.5)),
                    Text('${tile.titlesCount} title${tile.titlesCount == 1 ? '' : 's'}', style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 11.5, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ArtistAvatar extends StatelessWidget {
  const ArtistAvatar({super.key, required this.slug, required this.name, this.imageUrl, this.caption, this.size = 72});

  final String slug;
  final String name;
  final String? imageUrl;
  final String? caption;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size + 12,
      child: PressableScale(
        semanticLabel: name,
        onTap: () => context.push(Routes.artist(slug)),
        child: Column(
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: AppColors.hairline)),
              child: ClipOval(child: AppImage(imageUrl, icon: Icons.person_rounded)),
            ),
            const SizedBox(height: 7),
            Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.text)),
            if (caption != null && caption!.isNotEmpty)
              Text(caption!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center, style: AppText.caption.copyWith(fontSize: 11)),
          ],
        ),
      ),
    );
  }
}
