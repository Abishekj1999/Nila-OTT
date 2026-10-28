import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

/// Bottom tab shell: Home, Movies, Series, Explore, Account. Pages scroll
/// beneath a frosted tab bar, as in native streaming apps.
class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  static const _tabs = [
    (Icons.home_outlined, Icons.home_rounded, 'Home'),
    (Icons.movie_outlined, Icons.movie_rounded, 'Movies'),
    (Icons.live_tv_outlined, Icons.live_tv_rounded, 'Series'),
    (Icons.explore_outlined, Icons.explore_rounded, 'Explore'),
    (Icons.account_circle_outlined, Icons.account_circle_rounded, 'Account'),
  ];

  void _select(int i) {
    final reselect = i == shell.currentIndex;
    if (!reselect) HapticFeedback.selectionClick();
    shell.goBranch(i, initialLocation: reselect);
    // Scroll after the branch pops to its root, so the navigation frame
    // doesn't cut the animation short.
    if (reselect) WidgetsBinding.instance.addPostFrameCallback((_) => _tabReselectBus.fire(i));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: appOverlayStyle,
      child: Scaffold(
        extendBody: true,
        body: shell,
        bottomNavigationBar: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: DecoratedBox(
              decoration: const BoxDecoration(
                color: Color(0xE00E090D),
                border: Border(top: BorderSide(color: AppColors.hairline, width: 0.5)),
              ),
              child: SafeArea(
                top: false,
                child: SizedBox(
                  height: 56,
                  child: Row(children: [
                    for (var i = 0; i < _tabs.length; i++)
                      Expanded(child: _TabItem(tab: _tabs[i], selected: i == shell.currentIndex, onTap: () => _select(i))),
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem extends StatelessWidget {
  const _TabItem({required this.tab, required this.selected, required this.onTap});

  final (IconData, IconData, String) tab;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, selectedIcon, label) = tab;
    final color = selected ? AppColors.text : AppColors.textTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: InkResponse(
        onTap: onTap,
        radius: 32,
        highlightColor: Colors.transparent,
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Icon(selected ? selectedIcon : icon, key: ValueKey(selected), color: selected ? AppColors.pinkBright : color, size: 25),
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(color: color, fontSize: 10.5, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
        ]),
      ),
    );
  }
}

/// Broadcasts taps on the tab that is already selected.
class _TabReselectBus extends ChangeNotifier {
  int? index;

  void fire(int i) {
    index = i;
    notifyListeners();
  }
}

final _tabReselectBus = _TabReselectBus();

/// Owns a scroll controller for a tab's root list and scrolls it to the top
/// when that tab is tapped again, as native tab bars do.
class TabScrollView extends StatefulWidget {
  const TabScrollView({super.key, required this.tab, required this.builder, this.controller});

  final int tab;
  final Widget Function(BuildContext context, ScrollController controller) builder;

  /// Supply one when the screen also listens to scrolling.
  final ScrollController? controller;

  @override
  State<TabScrollView> createState() => _TabScrollViewState();
}

class _TabScrollViewState extends State<TabScrollView> {
  late final ScrollController _own = ScrollController();

  ScrollController get _controller => widget.controller ?? _own;

  @override
  void initState() {
    super.initState();
    _tabReselectBus.addListener(_onReselect);
  }

  void _onReselect() {
    if (_tabReselectBus.index == widget.tab && _controller.hasClients) {
      _controller.animateTo(0, duration: const Duration(milliseconds: 450), curve: Curves.easeOutCubic);
    }
  }

  @override
  void dispose() {
    _tabReselectBus.removeListener(_onReselect);
    _own.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}
