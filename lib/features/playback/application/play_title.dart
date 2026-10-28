import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../shared/models/title.dart';
import '../../../shared/models/viewer.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/auth_controller.dart';
import '../../catalog/data/catalog_repository.dart';
import '../../viewer/application/viewer_providers.dart';

/// The viewer's in-progress item for [t], if any.
ContinueWatchingItem? resumeItemFor(TitleDetail t, List<ContinueWatchingItem> items) {
  final episodeIds = {for (final s in t.seasons) ...s.episodes.map((e) => e.id)};
  for (final i in items) {
    if (t.isSeries && i.type == PlayableType.episode && episodeIds.contains(i.itemId)) return i;
    if (!t.isSeries && i.type == PlayableType.movie && i.itemId == t.id) return i;
  }
  return null;
}

/// What Play starts: the resume point, else the movie or the first episode.
/// Null when nothing is playable yet.
(PlayableType, int)? playTargetFor(TitleDetail t, ContinueWatchingItem? resume) {
  if (t.comingSoon) return null;
  if (resume != null) return (resume.type, resume.itemId);
  if (!t.isSeries) return (PlayableType.movie, t.id);
  final first = t.seasons.expand((s) => s.episodes).firstOrNull;
  return first == null ? null : (PlayableType.episode, first.id);
}

/// Starts playback straight from a card or banner. Listing payloads carry no
/// playable ids, so the title detail is fetched first; titles that can't
/// play yet open their detail page instead.
Future<void> playTitle(BuildContext context, WidgetRef ref, CatalogTitle title) async {
  HapticFeedback.lightImpact();
  try {
    final repo = ref.read(catalogRepositoryProvider);
    final detail = await (title.isSeries ? repo.series(title.slug) : repo.movie(title.slug));
    final history = ref.read(isSignedInProvider) ? await ref.read(continueWatchingProvider.future) : const <ContinueWatchingItem>[];
    if (!context.mounted) return;
    final target = playTargetFor(detail, resumeItemFor(detail, history));
    if (target == null) {
      context.push(Routes.title(title.type, title.slug));
    } else {
      context.push(Routes.watch(target.$1, target.$2));
    }
  } catch (e) {
    if (context.mounted) showErrorSnack(context, e);
  }
}
