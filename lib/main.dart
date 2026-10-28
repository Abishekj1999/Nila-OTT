import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Phones browse in portrait; the player unlocks landscape while it plays.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(appOverlayStyle);
  runApp(
    // Failed requests surface a Retry button instead of retrying silently,
    // which would hammer rate-limited endpoints.
    ProviderScope(retry: (_, _) => null, child: const NilaApp()),
  );
}
