import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class NilaApp extends ConsumerWidget {
  const NilaApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: "Nila's OTT",
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.dark,
      routerConfig: ref.watch(appRouterProvider),
      // Respect accessibility text sizes, within what the layouts can hold.
      builder: (context, child) => MediaQuery.withClampedTextScaling(maxScaleFactor: 1.3, child: child!),
    );
  }
}
