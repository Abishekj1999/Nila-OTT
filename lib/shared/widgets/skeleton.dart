import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';

/// Shimmering placeholder block.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, this.width, this.height, this.radius = 0});

  final double? width;
  final double? height;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final t = _controller.value * 3 - 1;
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.radius),
            gradient: LinearGradient(
              begin: Alignment(t - 1, 0),
              end: Alignment(t + 1, 0),
              colors: const [AppColors.surface, AppColors.surfaceHigh, AppColors.surface],
            ),
          ),
        );
      },
    );
  }
}

/// Placeholder for a horizontal content row.
class RowSkeleton extends StatelessWidget {
  const RowSkeleton({super.key, this.wide = false});

  final bool wide;

  @override
  Widget build(BuildContext context) {
    final w = wide ? 220.0 : 112.0;
    final h = wide ? 124.0 : 168.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(AppSpacing.gutter, 28, AppSpacing.gutter, 12),
          child: SkeletonBox(width: 140, height: 16, radius: 4),
        ),
        SizedBox(
          height: h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (_, _) => SkeletonBox(width: w, height: h, radius: AppSpacing.radius),
          ),
        ),
      ],
    );
  }
}

class GridSkeleton extends StatelessWidget {
  const GridSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppSpacing.gutter, 8, AppSpacing.gutter, 16),
      gridDelegate: posterGridDelegate,
      itemCount: 12,
      itemBuilder: (_, _) => const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Expanded(child: SkeletonBox(radius: AppSpacing.radius)),
        SizedBox(height: 8),
        SkeletonBox(width: 80, height: 10, radius: 3),
      ]),
    );
  }
}

/// Shared poster grid sizing: 3 columns on phones, more on tablets.
const posterGridDelegate = SliverGridDelegateWithMaxCrossAxisExtent(
  maxCrossAxisExtent: 140,
  childAspectRatio: 0.58,
  crossAxisSpacing: 10,
  mainAxisSpacing: 14,
);
