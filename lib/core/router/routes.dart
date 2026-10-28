import '../../shared/models/title.dart';
import '../../shared/models/viewer.dart';

/// Route paths, kept in one place so screens never hand-build URLs.
abstract final class Routes {
  static const splash = '/splash';
  static const home = '/home';
  static const movies = '/movies';
  static const series = '/series';
  static const explore = '/explore';
  static const profile = '/profile';
  static const login = '/login';
  static const register = '/register';
  static const premium = '/premium';
  static const continueWatching = '/continue-watching';
  static const artists = '/artists';

  static String title(TitleType type, String slug) => type == TitleType.series ? '/series/$slug' : '/movie/$slug';
  static String genre(String slug) => '/genre/$slug';
  static String language(String slug) => '/language/$slug';
  static String artist(String slug) => '/artist/$slug';
  static String page(String key) => '/page/$key';

  static String watch(PlayableType type, int id, {bool restart = false}) =>
      '/watch/${type.name}/$id${restart ? '?restart=1' : ''}';

  static String loginThen(String from) => '$login?from=${Uri.encodeComponent(from)}';
}
