import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/utils/formatters.dart';

/// Full-screen video surface with streaming-app controls: auto-hiding
/// top bar, ±10 s skip, double-tap seek and a scrubber.
class VideoStage extends StatefulWidget {
  const VideoStage({super.key, required this.video, required this.title, required this.onClose, this.subtitle});

  final VideoPlayerController video;
  final String title;
  final String? subtitle;
  final VoidCallback onClose;

  @override
  State<VideoStage> createState() => _VideoStageState();
}

class _VideoStageState extends State<VideoStage> {
  static const _skip = Duration(seconds: 10);

  bool _visible = true;
  Timer? _hideTimer;

  /// Position under the finger while scrubbing; null otherwise.
  double? _dragMs;

  /// Brief "+10s" / "-10s" feedback after a double tap.
  String? _seekHint;
  Alignment _seekHintSide = Alignment.center;
  Timer? _seekHintTimer;

  VideoPlayerController get v => widget.video;

  @override
  void initState() {
    super.initState();
    _scheduleHide();
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _seekHintTimer?.cancel();
    super.dispose();
  }

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && v.value.isPlaying && _dragMs == null) setState(() => _visible = false);
    });
  }

  void _toggle() {
    setState(() => _visible = !_visible);
    if (_visible) _scheduleHide();
  }

  void _poke() {
    if (!_visible) setState(() => _visible = true);
    _scheduleHide();
  }

  void _playPause() {
    HapticFeedback.selectionClick();
    final value = v.value;
    if (value.isPlaying) {
      v.pause();
    } else {
      if (value.duration > Duration.zero && value.position >= value.duration) v.seekTo(Duration.zero);
      v.play();
    }
    _poke();
  }

  void _seekBy(Duration delta, {bool showHint = false}) {
    final value = v.value;
    var target = value.position + delta;
    if (target < Duration.zero) target = Duration.zero;
    if (value.duration > Duration.zero && target > value.duration) target = value.duration;
    v.seekTo(target);
    HapticFeedback.lightImpact();
    if (showHint) {
      _seekHintTimer?.cancel();
      setState(() {
        _seekHint = '${delta.isNegative ? '−' : '+'}${delta.inSeconds.abs()}s';
        _seekHintSide = delta.isNegative ? const Alignment(-0.6, 0) : const Alignment(0.6, 0);
      });
      _seekHintTimer = Timer(const Duration(milliseconds: 650), () {
        if (mounted) setState(() => _seekHint = null);
      });
    } else {
      _poke();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: Colors.black),
        Center(
          child: ValueListenableBuilder<VideoPlayerValue>(
            valueListenable: v,
            builder: (_, value, _) => AspectRatio(
              aspectRatio: value.aspectRatio > 0 ? value.aspectRatio : 16 / 9,
              child: VideoPlayer(v),
            ),
          ),
        ),
        // Tap toggles controls; double tap on either half seeks.
        Row(children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              onDoubleTap: () => _seekBy(-_skip, showHint: true),
            ),
          ),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _toggle,
              onDoubleTap: () => _seekBy(_skip, showHint: true),
            ),
          ),
        ]),
        if (_seekHint != null)
          IgnorePointer(
            child: Align(
              alignment: _seekHintSide,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(color: const Color(0x99000000), borderRadius: BorderRadius.circular(24)),
                child: Text(_seekHint!, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ValueListenableBuilder<VideoPlayerValue>(
          valueListenable: v,
          builder: (context, value, _) {
            final showBuffering = value.isBuffering && !_visible;
            return Stack(fit: StackFit.expand, children: [
              if (showBuffering) const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)),
              IgnorePointer(
                ignoring: !_visible,
                child: AnimatedOpacity(
                  opacity: _visible ? 1 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: _controls(context, value),
                ),
              ),
            ]);
          },
        ),
      ],
    );
  }

  Widget _controls(BuildContext context, VideoPlayerValue value) {
    final duration = value.duration;
    final totalMs = duration.inMilliseconds.toDouble();
    final positionMs = (_dragMs ?? value.position.inMilliseconds.toDouble()).clamp(0.0, totalMs > 0 ? totalMs : 0.0);
    final buffered = value.buffered.isEmpty || totalMs <= 0 ? 0.0 : value.buffered.last.end.inMilliseconds / totalMs;
    final ended = duration > Duration.zero && value.position >= duration && !value.isPlaying;

    return DecoratedBox(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xB3000000), Color(0x33000000), Color(0x33000000), Color(0xCC000000)],
          stops: [0, 0.3, 0.65, 1],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              Row(children: [
                IconButton(
                  tooltip: 'Close',
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  onPressed: widget.onClose,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                    Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                    if (widget.subtitle?.isNotEmpty ?? false)
                      Text(widget.subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Color(0xB3FFFFFF), fontSize: 12.5)),
                  ]),
                ),
              ]),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RoundControl(icon: Icons.replay_10_rounded, label: 'Back 10 seconds', size: 34, onTap: () => _seekBy(-_skip)),
                  const SizedBox(width: 44),
                  value.isBuffering && value.isPlaying
                      ? const SizedBox(width: 64, height: 64, child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)))
                      : _RoundControl(
                          icon: ended ? Icons.replay_rounded : (value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                          label: ended ? 'Replay' : (value.isPlaying ? 'Pause' : 'Play'),
                          size: 56,
                          onTap: _playPause,
                        ),
                  const SizedBox(width: 44),
                  _RoundControl(icon: Icons.forward_10_rounded, label: 'Forward 10 seconds', size: 34, onTap: () => _seekBy(_skip)),
                ],
              ),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                child: Row(children: [
                  Text(formatClock(Duration(milliseconds: positionMs.round())), style: _timeStyle),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        trackHeight: 3,
                        activeTrackColor: AppColors.pink,
                        inactiveTrackColor: const Color(0x40FFFFFF),
                        secondaryActiveTrackColor: const Color(0x80FFFFFF),
                        thumbColor: AppColors.pink,
                        overlayColor: AppColors.pinkTint,
                        thumbShape: RoundSliderThumbShape(enabledThumbRadius: _dragMs != null ? 8 : 6),
                        trackShape: const RoundedRectSliderTrackShape(),
                      ),
                      child: Slider(
                        value: positionMs,
                        max: totalMs > 0 ? totalMs : 1,
                        secondaryTrackValue: (buffered * (totalMs > 0 ? totalMs : 1)).clamp(0.0, totalMs > 0 ? totalMs : 1),
                        onChangeStart: totalMs > 0
                            ? (x) {
                                _hideTimer?.cancel();
                                setState(() => _dragMs = x);
                              }
                            : null,
                        onChanged: totalMs > 0 ? (x) => setState(() => _dragMs = x) : null,
                        onChangeEnd: totalMs > 0
                            ? (x) async {
                                await v.seekTo(Duration(milliseconds: x.round()));
                                if (mounted) setState(() => _dragMs = null);
                                _scheduleHide();
                              }
                            : null,
                      ),
                    ),
                  ),
                  Text(
                    totalMs > 0 ? '-${formatClock(duration - Duration(milliseconds: positionMs.round()))}' : '--:--',
                    style: _timeStyle,
                  ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static const _timeStyle = TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w600, fontFeatures: [FontFeature.tabularFigures()]);
}

class _RoundControl extends StatelessWidget {
  const _RoundControl({required this.icon, required this.label, required this.size, required this.onTap});

  final IconData icon;
  final String label;
  final double size;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: size * 0.9,
        child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, color: Colors.white, size: size)),
      ),
    );
  }
}
