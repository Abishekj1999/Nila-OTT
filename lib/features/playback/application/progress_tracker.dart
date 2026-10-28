import 'dart:async';

import 'package:video_player/video_player.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/models/viewer.dart';
import '../../viewer/data/viewer_repository.dart';

typedef SaveProgress = Future<ProgressResult> Function(int positionSeconds, int? durationSeconds);

/// Saves watch progress every [interval] while playing, on pause, on
/// completion and on exit. Skips positions the backend ignores (< 30 s)
/// and stops for good after an auth or premium rejection.
class ProgressTracker {
  ProgressTracker({required this.video, required this.save, this.interval = const Duration(seconds: 15)});

  final VideoPlayerController video;
  final SaveProgress save;
  final Duration interval;

  Timer? _timer;
  bool _wasPlaying = false;
  bool _disabled = false;
  int? _lastSaved;
  Future<void>? _inFlight;

  void start() {
    video.addListener(_onTick);
    _timer = Timer.periodic(interval, (_) {
      if (video.value.isPlaying) flush();
    });
  }

  void _onTick() {
    final v = video.value;
    final playing = v.isPlaying;
    final ended = v.isInitialized && v.duration > Duration.zero && v.position >= v.duration;
    if ((_wasPlaying && !playing) || ended) flush();
    _wasPlaying = playing;
  }

  /// Sends the current position if it changed and is worth saving.
  Future<void> flush() {
    if (_disabled || !video.value.isInitialized) return Future.value();
    final position = video.value.position.inSeconds;
    final duration = video.value.duration.inSeconds;
    if (position < ViewerRepository.minSavedPositionSeconds || position == _lastSaved) return Future.value();
    // Serialize saves so an older position never lands after a newer one.
    final previous = _inFlight ?? Future.value();
    final next = previous.then((_) => _send(position, duration > 0 ? duration : null));
    _inFlight = next;
    return next;
  }

  Future<void> _send(int position, int? duration) async {
    if (_disabled) return;
    try {
      await save(position, duration);
      _lastSaved = position;
    } on ApiException catch (e) {
      if (e.kind == ApiErrorKind.unauthorized || e.kind == ApiErrorKind.premiumRequired || e.kind == ApiErrorKind.forbidden) {
        _disabled = true;
      }
    } catch (_) {
      // Network blips are retried on the next tick.
    }
  }

  Future<void> stop({bool flush = false}) async {
    _timer?.cancel();
    _timer = null;
    final pending = flush ? this.flush() : Future<void>.value();
    try {
      video.removeListener(_onTick);
    } catch (_) {}
    await pending;
  }
}
