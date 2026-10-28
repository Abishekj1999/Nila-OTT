import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/widgets/brand.dart';
import '../auth/application/auth_controller.dart';

/// Restores the session, then the router redirect leaves this screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _intro = AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..forward();

  @override
  void initState() {
    super.initState();
    ref.read(authControllerProvider.notifier).restore(minDuration: const Duration(milliseconds: 1200));
  }

  @override
  void dispose() {
    _intro.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(parent: _intro, curve: Curves.easeOutCubic);
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          Center(
            child: FadeTransition(
              opacity: curve,
              child: ScaleTransition(
                scale: Tween(begin: 0.92, end: 1.0).animate(curve),
                child: const BrandLockup(emblemSize: 120),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: MediaQuery.paddingOf(context).bottom + 48,
            child: const Center(
              child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.2, color: AppColors.pink)),
            ),
          ),
        ],
      ),
    );
  }
}
