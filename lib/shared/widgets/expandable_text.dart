import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Body text clamped to a few lines with a "more" toggle.
class ExpandableText extends StatefulWidget {
  const ExpandableText(this.text, {super.key, this.maxLines = 3, this.style = AppText.body});

  final String text;
  final int maxLines;
  final TextStyle style;

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final painter = TextPainter(
        text: TextSpan(text: widget.text, style: widget.style),
        maxLines: widget.maxLines,
        textDirection: Directionality.of(context),
        textScaler: MediaQuery.textScalerOf(context),
      )..layout(maxWidth: constraints.maxWidth);
      final overflows = painter.didExceedMaxLines;
      painter.dispose();
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: overflows ? () => setState(() => _expanded = !_expanded) : null,
        child: AnimatedSize(
          duration: const Duration(milliseconds: 200),
          alignment: Alignment.topCenter,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.text, style: widget.style, maxLines: _expanded ? null : widget.maxLines, overflow: _expanded ? null : TextOverflow.ellipsis),
              if (overflows)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(_expanded ? 'Less' : 'More', style: const TextStyle(color: AppColors.text, fontSize: 14, fontWeight: FontWeight.w700)),
                ),
            ],
          ),
        ),
      );
    });
  }
}
