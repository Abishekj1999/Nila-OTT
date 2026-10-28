import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_theme.dart';

/// Compact pill used for filters and tabs. Selected pills invert to white.
class AppChip extends StatelessWidget {
  const AppChip({super.key, required this.label, required this.selected, required this.onTap, this.leading, this.dropdown = false});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  /// Shows a chevron, for chips that open a picker.
  final bool dropdown;

  @override
  Widget build(BuildContext context) {
    final fg = selected ? Colors.black : AppColors.text;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: selected ? Colors.white : AppColors.surfaceHigh,
        shape: StadiumBorder(side: BorderSide(color: selected ? Colors.white : AppColors.hairline)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          child: Container(
            height: 34,
            padding: EdgeInsets.only(left: leading == null ? 14 : 10, right: dropdown ? 8 : 14),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (leading != null) ...[leading!, const SizedBox(width: 5)],
              Text(label, style: TextStyle(color: fg, fontSize: 13.5, fontWeight: FontWeight.w600)),
              if (dropdown) ...[const SizedBox(width: 2), Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: fg)],
            ]),
          ),
        ),
      ),
    );
  }
}
