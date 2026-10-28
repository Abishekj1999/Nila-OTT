import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/application/auth_controller.dart';
import '../../features/auth/presentation/auth_screens.dart';
import '../../features/catalog/data/browse_query.dart';
import '../../features/catalog/presentation/catalog_screens.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/playback/presentation/player_screen.dart';
import '../../features/premium/premium_screen.dart';
import '../../features/shell/main_shell.dart';
import '../../features/shell/splash_screen.dart';
import '../../features/title_details/presentation/title_detail_screen.dart';
import '../../features/viewer/presentation/viewer_screens.dart';
import '../../shared/models/title.dart';
import '../../shared/models/viewer.dart';
import 'routes.dart';

/// Bridges auth state changes to GoRouter's refreshListenable.
class _AuthListenable extends ChangeNotifier {
  _AuthListenable(Ref ref) {
    ref.listen(authControllerProvider.select((s) => s.status), (_, _) => notifyListeners());
  }
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final refresh = _AuthListenable(ref);
  ref.onDispose(refresh.dispose);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) {
      final status = ref.read(authControllerProvider).status;
      final path = state.uri.path;
      if (status == AuthStatus.unknown) return path == Routes.splash ? null : Routes.splash;
      if (path == Routes.splash) return Routes.home;

      final signedIn = status == AuthStatus.signedIn;
      // Playback and viewer pages need a session; catalog browsing doesn't.
      final needsAuth = path.startsWith('/watch/') || path == Routes.continueWatching;
      if (needsAuth && !signedIn) return Routes.loginThen(state.uri.toString());
      if (signedIn && (path == Routes.login || path == Routes.register)) {
        return state.uri.queryParameters['from'] ?? Routes.home;
      }
      return null;
    },
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      StatefulShellRoute.indexedStack(
        builder: (_, _, shell) => MainShell(shell: shell),
        branches: [
          StatefulShellBranch(routes: [GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen())]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.movies, builder: (_, _) => const CatalogTabScreen(title: 'Movies', query: BrowseQuery.movies(), tab: 1)),
          ]),
          StatefulShellBranch(routes: [
            GoRoute(path: Routes.series, builder: (_, _) => const CatalogTabScreen(title: 'Series', query: BrowseQuery.series(), tab: 2)),
          ]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.explore, builder: (_, _) => const ExploreScreen())]),
          StatefulShellBranch(routes: [GoRoute(path: Routes.profile, builder: (_, _) => const ProfileScreen())]),
        ],
      ),
      GoRoute(path: '/movie/:slug', builder: (_, s) => TitleDetailScreen(type: TitleType.movie, slug: s.pathParameters['slug']!)),
      GoRoute(path: '/series/:slug', builder: (_, s) => TitleDetailScreen(type: TitleType.series, slug: s.pathParameters['slug']!)),
      GoRoute(path: '/genre/:slug', builder: (_, s) => CollectionScreen(query: BrowseQuery.genre(s.pathParameters['slug']!))),
      GoRoute(path: '/language/:slug', builder: (_, s) => CollectionScreen(query: BrowseQuery.language(s.pathParameters['slug']!))),
      GoRoute(path: Routes.artists, builder: (_, _) => const ArtistsScreen()),
      GoRoute(path: '/artist/:slug', builder: (_, s) => ArtistDetailScreen(slug: s.pathParameters['slug']!)),
      GoRoute(path: '/page/:key', builder: (_, s) => StaticPageScreen(pageKey: s.pathParameters['key']!)),
      GoRoute(path: Routes.login, builder: (_, s) => LoginScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: Routes.register, builder: (_, s) => RegisterScreen(from: s.uri.queryParameters['from'])),
      GoRoute(path: Routes.premium, builder: (_, _) => const PremiumScreen()),
      GoRoute(path: Routes.continueWatching, builder: (_, _) => const ContinueWatchingScreen()),
      GoRoute(
        path: '/watch/:type/:id',
        builder: (_, s) {
          final id = int.tryParse(s.pathParameters['id'] ?? '');
          final type = s.pathParameters['type'];
          if (id == null || (type != 'movie' && type != 'episode')) return const _NotFound();
          return PlayerScreen(type: PlayableType.parse(type), id: id, restart: s.uri.queryParameters['restart'] == '1');
        },
      ),
    ],
    errorBuilder: (_, _) => const _NotFound(),
  );
  ref.onDispose(router.dispose);
  return router;
});

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Center(
        child: TextButton(onPressed: () => context.go(Routes.home), child: const Text('Page not found. Go home')),
      ),
    );
  }
}
