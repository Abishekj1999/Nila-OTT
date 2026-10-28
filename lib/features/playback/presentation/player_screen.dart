import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/viewer.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/state_views.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../viewer/application/viewer_providers.dart';
import '../../viewer/data/viewer_repository.dart';
import '../application/progress_tracker.dart';
import 'player_controls.dart';

/// Fetches playback info, offers Resume/Restart, plays the stream full
/// screen in landscape and reports progress. Requires a signed-in viewer
/// (enforced by the router).
class PlayerScreen extends ConsumerStatefulWidget {
  const PlayerScreen({super.key, required this.type, required this.id, this.restart = false});

  final PlayableType type;
  final int id;
  final bool restart;

  @override
  ConsumerState<PlayerScreen> createState() => _PlayerScreenState();
}

enum _Phase { loading, choose, playing, external, error }

class _PlayerScreenState extends ConsumerState<PlayerScreen> {
  _Phase _phase = _Phase.loading;
  PlaybackInfo? _info;
  Object? _error;
  VideoPlayerController? _video;
  ProgressTracker? _tracker;
  late final ViewerRepository _repo = ref.read(viewerRepositoryProvider);
  late final ProviderContainer _container;

  @override
  void initState() {
    super.initState();
    _container = ProviderScope.containerOf(context, listen: false);
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _phase = _Phase.loading;
      _error = null;
    });
    try {
      final info = await _repo.playback(widget.type, widget.id);
      if (!mounted) return;
      _info = info;
      if (info.isYoutube) {
        setState(() => _phase = _Phase.external);
      } else if (!widget.restart && _canResume(info)) {
        setState(() => _phase = _Phase.choose);
      } else {
        await _start(Duration.zero);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e;
          _phase = _Phase.error;
        });
      }
    }
  }

  bool _canResume(PlaybackInfo info) {
    final resume = info.resumeSeconds;
    final duration = info.durationSeconds;
    if (resume < ViewerRepository.minSavedPositionSeconds) return false;
    return duration == null || resume < duration - 60;
  }

  Future<void> _start(Duration at) async {
    final info = _info!;
    setState(() => _phase = _Phase.loading);
    final url = ref.read(mediaUrlProvider)(info.streamUrl) ?? info.streamUrl;
    await _disposePlayer();
    final video = VideoPlayerController.networkUrl(
      Uri.parse(url),
      formatHint: info.streamFormat == 'hls' ? VideoFormat.hls : null,
    );
    _video = video;
    try {
      await video.initialize();
      if (at > Duration.zero) await video.seekTo(at);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = const _StreamFailed();
        _phase = _Phase.error;
      });
      return;
    }
    if (!mounted) return;

    _tracker = ProgressTracker(
      video: video,
      save: (position, duration) => _repo.saveProgress(
        type: info.type,
        id: info.id,
        positionSeconds: position,
        durationSeconds: duration ?? info.durationSeconds,
      ),
    )..start();

    await _enterFullscreen();
    if (!mounted) return;
    video.play();
    setState(() => _phase = _Phase.playing);
  }

  Future<void> _enterFullscreen() async {
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
  }

  static Future<void> _exitFullscreen() async {
    WakelockPlus.disable();
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  }

  Future<void> _disposePlayer() async {
    final video = _video, tracker = _tracker;
    _video = null;
    _tracker = null;
    await tracker?.stop(flush: true);
    await video?.dispose();
  }

  void _close() => context.canPop() ? context.pop() : context.go(Routes.home);

  @override
  void dispose() {
    // Final save on exit, then refresh lists that show progress.
    final tracker = _tracker;
    final video = _video;
    final container = _container;
    _tracker = null;
    _video = null;
    (tracker?.stop(flush: true) ?? Future<void>.value()).whenComplete(() {
      video?.dispose();
      container.invalidate(continueWatchingProvider);
      container.invalidate(homeFeedProvider);
    });
    _exitFullscreen();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (_phase == _Phase.playing && _video != null) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: VideoStage(video: _video!, title: info?.title ?? '', subtitle: info?.subtitle, onClose: _close),
      );
    }
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: appOverlayStyle,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (info?.posterUrl != null) Opacity(opacity: 0.28, child: AppImage(info!.posterUrl)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x99000000), Color(0x66000000), Colors.black],
                ),
              ),
            ),
            SafeArea(child: _body(info)),
            SafeArea(
              child: Align(
                alignment: Alignment.topLeft,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton(
                    tooltip: 'Close',
                    icon: const Icon(Icons.close_rounded, color: Colors.white, size: 26),
                    onPressed: _close,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(PlaybackInfo? info) {
    switch (_phase) {
      case _Phase.loading:
      case _Phase.playing:
        return const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5));
      case _Phase.error:
        return _PlaybackError(error: _error!, onRetry: _load);
      case _Phase.external:
        return _ExternalPlayback(info: info!);
      case _Phase.choose:
        return _ResumeChoice(
          info: info!,
          onResume: () => _start(Duration(seconds: info.resumeSeconds)),
          onRestart: () => _start(Duration.zero),
        );
    }
  }
}

class _ResumeChoice extends StatelessWidget {
  const _ResumeChoice({required this.info, required this.onResume, required this.onRestart});

  final PlaybackInfo info;
  final VoidCallback onResume;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final progress = info.durationSeconds == null || info.durationSeconds == 0 ? null : info.resumeSeconds / info.durationSeconds!;
    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Text(info.title, textAlign: TextAlign.center, style: AppText.title1),
          if (info.subtitle?.isNotEmpty ?? false) ...[
            const SizedBox(height: 4),
            Text(info.subtitle!, textAlign: TextAlign.center, style: AppText.subhead),
          ],
          const SizedBox(height: 20),
          if (progress != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(value: progress.clamp(0.0, 1.0), minHeight: 3),
            ),
            const SizedBox(height: 8),
            Text(
              'Stopped at ${formatClock(Duration(seconds: info.resumeSeconds))} of ${formatClock(Duration(seconds: info.durationSeconds!))}',
              textAlign: TextAlign.center,
              style: AppText.caption,
            ),
            const SizedBox(height: 20),
          ],
          AppButton(
            label: 'Resume from ${formatClock(Duration(seconds: info.resumeSeconds))}',
            icon: Icons.play_arrow_rounded,
            variant: ButtonVariant.light,
            onPressed: onResume,
          ),
          const SizedBox(height: 10),
          AppButton.secondary(label: 'Start over', icon: Icons.replay_rounded, onPressed: onRestart),
        ]),
      ),
    );
  }
}

class _ExternalPlayback extends StatelessWidget {
  const _ExternalPlayback({required this.info});

  final PlaybackInfo info;

  @override
  Widget build(BuildContext context) {
    return MessageView(
      icon: Icons.smart_display_rounded,
      title: info.title,
      message: 'This title plays on YouTube.',
      action: AppButton(
        label: 'Open video',
        icon: Icons.open_in_new_rounded,
        onPressed: () {
          final uri = Uri.tryParse(info.streamUrl);
          if (uri != null) launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

class _PlaybackError extends StatelessWidget {
  const _PlaybackError({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    if (error is _StreamFailed) {
      return MessageView(
        icon: Icons.videocam_off_rounded,
        title: 'Video unavailable',
        message: "This video couldn't be played right now. Please try again later.",
        action: AppButton.secondary(label: 'Try again', icon: Icons.refresh_rounded, small: true, onPressed: onRetry),
      );
    }
    final e = ApiException.from(error);
    if (e.kind == ApiErrorKind.premiumRequired) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.goldDeep, size: 38),
            ),
            const SizedBox(height: 18),
            const Text('Included with Premium', textAlign: TextAlign.center, style: AppText.title2),
            const SizedBox(height: 6),
            Text(e.userMessage, textAlign: TextAlign.center, style: AppText.subhead),
            const SizedBox(height: 24),
            AppButton(
              label: 'See plans',
              icon: Icons.workspace_premium_rounded,
              expand: true,
              onPressed: () => context.pushReplacement(Routes.premium),
            ),
          ]),
        ),
      );
    }
    return ErrorView(error: e, onRetry: onRetry);
  }
}

/// The stream URL loaded but the player could not open it.
class _StreamFailed {
  const _StreamFailed();
}
