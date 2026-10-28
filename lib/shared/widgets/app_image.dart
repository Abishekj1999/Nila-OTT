import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/providers.dart';
import '../../core/theme/app_theme.dart';
import 'skeleton.dart';

/// Cached network image with a branded placeholder for missing/broken URLs.
class AppImage extends StatelessWidget {
  const AppImage(this.url, {super.key, this.fit = BoxFit.cover, this.icon = Icons.movie_outlined, this.alignment = Alignment.center});

  final String? url;
  final BoxFit fit;
  final IconData icon;
  final Alignment alignment;

  @override
  Widget build(BuildContext context) => ArtworkImage(urls: [url], icon: icon, alignment: alignment, fit: fit);
}

enum ArtworkShape { portrait, landscape }

/// Shows the first of [urls] whose real shape matches [shape].
///
/// The API's `poster_url` / `thumbnail_url` are not reliably portrait or
/// landscape (seeded titles and admin uploads disagree), so the choice is
/// made from each image's decoded size, remembered per URL for the session.
class ArtworkImage extends ConsumerStatefulWidget {
  const ArtworkImage({
    super.key,
    required this.urls,
    this.shape,
    this.fit = BoxFit.cover,
    this.icon = Icons.movie_outlined,
    this.alignment = Alignment.center,
  });

  final List<String?> urls;

  /// Null shows the first available URL as-is.
  final ArtworkShape? shape;
  final BoxFit fit;
  final IconData icon;
  final Alignment alignment;

  @override
  ConsumerState<ArtworkImage> createState() => _ArtworkImageState();
}

class _ArtworkImageState extends ConsumerState<ArtworkImage> {
  /// width / height of every image decoded so far, by URL.
  static final _aspects = <String, double>{};

  /// Candidates already found to have the wrong shape.
  final _rejected = <String>{};

  bool _matches(double aspect) => widget.shape == ArtworkShape.portrait ? aspect < 1 : aspect >= 1;

  String? _choose(List<String> candidates) {
    final shape = widget.shape;
    if (shape == null || candidates.length < 2) return candidates.firstOrNull;
    for (final c in candidates) {
      final a = _aspects[c];
      if (a != null && _matches(a)) return c;
    }
    for (final c in candidates) {
      if (!_aspects.containsKey(c) && !_rejected.contains(c)) return c;
    }
    return candidates.first;
  }

  void _measure(String url, ImageProvider provider, List<String> candidates) {
    if (widget.shape == null || candidates.length < 2 || _aspects.containsKey(url)) return;
    final stream = provider.resolve(createLocalImageConfiguration(context));
    late final ImageStreamListener listener;
    listener = ImageStreamListener((info, _) {
      stream.removeListener(listener);
      final aspect = info.image.width / info.image.height;
      _aspects[url] = aspect;
      if (!_matches(aspect) && mounted) setState(() => _rejected.add(url));
    }, onError: (_, _) => stream.removeListener(listener));
    stream.addListener(listener);
  }

  @override
  Widget build(BuildContext context) {
    final resolve = ref.watch(mediaUrlProvider);
    final candidates = widget.urls.map(resolve).whereType<String>().where((u) => u.isNotEmpty).toSet().toList();
    final chosen = _choose(candidates);
    if (chosen == null) return _Fallback(icon: widget.icon);

    return LayoutBuilder(builder: (context, constraints) {
      final dpr = MediaQuery.devicePixelRatioOf(context);
      // Decode wide enough that a 16:9 image covering a tall box stays sharp.
      final boxW = constraints.maxWidth.isFinite ? constraints.maxWidth : null;
      final boxH = constraints.maxHeight.isFinite ? constraints.maxHeight : null;
      final needed = boxW == null ? null : math.max(boxW, (boxH ?? 0) * 16 / 9);
      return CachedNetworkImage(
        key: ValueKey(chosen),
        imageUrl: chosen,
        fit: widget.fit,
        alignment: widget.alignment,
        memCacheWidth: needed == null ? null : (needed * dpr).round(),
        fadeInDuration: const Duration(milliseconds: 220),
        placeholder: (_, _) => const SkeletonBox(),
        imageBuilder: (context, provider) {
          _measure(chosen, provider, candidates);
          return Image(image: provider, fit: widget.fit, alignment: widget.alignment, gaplessPlayback: true);
        },
        errorWidget: (_, _, _) => _Fallback(icon: widget.icon),
      );
    });
  }
}

class _Fallback extends StatelessWidget {
  const _Fallback({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.surfaceHighest, AppColors.surface],
        ),
      ),
      child: Center(child: Icon(icon, color: AppColors.textTertiary, size: 28)),
    );
  }
}
