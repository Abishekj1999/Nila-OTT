import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_theme.dart';

/// Tab and collection header: one compact pinned row with a bold
/// left-aligned title and actions on the right.
class LargeTitleSliverAppBar extends StatelessWidget {
  const LargeTitleSliverAppBar({super.key, required this.title, this.actions = const [], this.leading});

  final String title;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      leading: leading,
      backgroundColor: AppColors.background,
      toolbarHeight: 56,
      centerTitle: false,
      titleSpacing: leading == null ? AppSpacing.gutter : 0,
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title1),
      actions: [...actions, const SizedBox(width: 4)],
    );
  }
}

/// Standard pushed-page bar with a back chevron.
class PageAppBar extends StatelessWidget implements PreferredSizeWidget {
  const PageAppBar({super.key, this.title, this.actions = const []});

  final String? title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: const AppBackButton(),
      title: title == null ? null : Text(title!),
      actions: actions,
    );
  }
}

class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key, this.color = AppColors.text});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final ios = Theme.of(context).platform == TargetPlatform.iOS;
    return IconButton(
      tooltip: 'Back',
      icon: Icon(ios ? Icons.arrow_back_ios_new_rounded : Icons.arrow_back_rounded, color: color, size: ios ? 21 : 24),
      onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
    );
  }
}

/// Space so the last item clears the floating tab bar and home indicator.
class BottomInsetSpacer extends StatelessWidget {
  const BottomInsetSpacer({super.key, this.extra = 24});

  final double extra;

  @override
  Widget build(BuildContext context) => SliverToBoxAdapter(child: SizedBox(height: MediaQuery.paddingOf(context).bottom + extra));
}
