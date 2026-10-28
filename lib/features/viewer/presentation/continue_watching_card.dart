import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/title.dart';
import '../../../shared/models/viewer.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/state_views.dart';

/// Landscape card with a progress bar; tapping resumes playback, the
/// overflow menu offers details and removal.
class ContinueWatchingCard extends StatelessWidget {
  const ContinueWatchingCard({super.key, required this.item, this.onRemove, this.width = 200});

  final ContinueWatchingItem item;
  final VoidCallback? onRemove;
  final double? width;

  Future<void> _menu(BuildContext context) async {
    final picked = await showOptionSheet<String>(
      context,
      title: item.title,
      selected: '',
      options: [
        const SheetOption('play', 'Resume', icon: Icons.play_arrow_rounded),
        const SheetOption('info', 'Details', icon: Icons.info_outline_rounded),
        if (onRemove != null) const SheetOption('remove', 'Remove from row', icon: Icons.remove_circle_outline_rounded),
      ],
    );
    if (!context.mounted) return;
    switch (picked) {
      case 'play':
        context.push(Routes.watch(item.type, item.itemId));
      case 'info':
        context.push(Routes.title(item.type == PlayableType.episode ? TitleType.series : TitleType.movie, item.slug));
      case 'remove':
        onRemove?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final subtitle = [item.subtitle, item.remainingLabel].whereType<String>().where((s) => s.isNotEmpty).join(' · ');
    return SizedBox(
      width: width,
      child: PressableScale(
        semanticLabel: 'Resume ${item.title}',
        onTap: () => context.push(Routes.watch(item.type, item.itemId)),
        onLongPress: () => _menu(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppSpacing.radius),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppImage(item.thumbnailUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0x00000000), Color(0x99000000)],
                        ),
                      ),
                    ),
                    Center(
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: const Color(0x66000000),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
                      ),
                    ),
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      child: LinearProgressIndicator(
                        value: item.progress.clamp(0.0, 1.0),
                        minHeight: 3,
                        backgroundColor: const Color(0x40FFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.text)),
                    if (subtitle.isNotEmpty) Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.caption),
                  ]),
                ),
                SizedBox(
                  width: 28,
                  height: 28,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    tooltip: 'More options',
                    iconSize: 20,
                    color: AppColors.textSecondary,
                    icon: const Icon(Icons.more_vert_rounded),
                    onPressed: () => _menu(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
