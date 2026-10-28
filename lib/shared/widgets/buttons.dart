import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

enum ButtonVariant {
  /// Solid brand pink; one per screen.
  primary,

  /// Translucent white fill, for secondary actions over artwork or dark surfaces.
  secondary,

  /// Solid white, used for Play on artwork.
  light,

  /// Hairline outline.
  outline,
}

/// The app's standard button: 50pt tall, 12pt corners, light haptic on tap.
class AppButton extends StatelessWidget {
  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.variant = ButtonVariant.primary,
    this.loading = false,
    this.expand = false,
    this.small = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.loading = false,
    this.expand = false,
    this.small = false,
  }) : variant = ButtonVariant.secondary;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final ButtonVariant variant;
  final bool loading;
  final bool expand;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (Color bg, Color fg, BorderSide side) = switch (variant) {
      ButtonVariant.primary => (AppColors.pink, Colors.white, BorderSide.none),
      ButtonVariant.secondary => (const Color(0x29FFFFFF), Colors.white, BorderSide.none),
      ButtonVariant.light => (Colors.white, Colors.black, BorderSide.none),
      ButtonVariant.outline => (Colors.transparent, AppColors.text, const BorderSide(color: Color(0x40FFFFFF))),
    };
    final height = small ? 38.0 : 50.0;
    final radius = small ? 10.0 : 12.0;

    final content = Row(
      mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.2, color: fg))
        else ...[
          if (icon != null) ...[Icon(icon, color: fg, size: small ? 18 : 22), SizedBox(width: small ? 6 : 8)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg, fontSize: small ? 14 : 16, fontWeight: FontWeight.w700, letterSpacing: -0.1),
            ),
          ),
        ],
      ],
    );

    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: enabled || loading ? 1 : 0.45,
        child: Material(
          color: bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: side),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: enabled
                ? () {
                    HapticFeedback.lightImpact();
                    onPressed!();
                  }
                : null,
            child: Container(
              height: height,
              padding: EdgeInsets.symmetric(horizontal: small ? 14 : 22),
              alignment: Alignment.center,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}

/// Round translucent icon button for use over artwork (back, share, close).
class GlassIconButton extends StatelessWidget {
  const GlassIconButton({super.key, required this.icon, required this.onPressed, required this.tooltip, this.size = 38});

  final IconData icon;
  final VoidCallback onPressed;
  final String tooltip;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0x66000000),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(width: size, height: size, child: Icon(icon, color: Colors.white, size: size * 0.55)),
        ),
      ),
    );
  }
}

/// Icon-over-label action (My List, Share, Download) as on streaming detail pages.
class StackedAction extends StatelessWidget {
  const StackedAction({super.key, required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        radius: 36,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: AppColors.text, size: 24),
            const SizedBox(height: 6),
            Text(label, maxLines: 1, style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textSecondary)),
          ]),
        ),
      ),
    );
  }
}

/// Wraps a tappable card with a subtle press-down scale.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, required this.onTap, this.onLongPress, this.semanticLabel});

  final Widget child;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final String? semanticLabel;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTapDown: (_) => _set(true),
        onTapUp: (_) => _set(false),
        onTapCancel: () => _set(false),
        onTap: widget.onTap,
        onLongPress: widget.onLongPress == null
            ? null
            : () {
                HapticFeedback.mediumImpact();
                widget.onLongPress!();
              },
        child: AnimatedScale(
          scale: _down ? 0.96 : 1,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}
