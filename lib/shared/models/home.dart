import 'package:json_annotation/json_annotation.dart';

import 'title.dart';
import 'viewer.dart';

part 'home.g.dart';

const _json = JsonSerializable(fieldRename: FieldRename.snake, createToJson: false);

@_json
class HomeBanner {
  const HomeBanner({this.kind, this.heading, this.tagline, this.imageUrl, this.mobileImageUrl, this.buttonLabel, this.link, this.title});

  final String? kind;
  final String? heading;
  final String? tagline;
  final String? imageUrl;
  final String? mobileImageUrl;
  final String? buttonLabel;
  final String? link;
  final CatalogTitle? title;

  factory HomeBanner.fromJson(Map<String, dynamic> json) => _$HomeBannerFromJson(json);
}

/// Genre/language tile in a home row.
@_json
class HomeTile {
  const HomeTile({required this.kind, required this.slug, required this.name, this.imageUrl, this.titlesCount = 0});

  final String kind;
  final String slug;
  final String name;
  final String? imageUrl;
  @JsonKey(defaultValue: 0)
  final int titlesCount;

  factory HomeTile.fromJson(Map<String, dynamic> json) => _$HomeTileFromJson(json);
}

@_json
class HomeTab {
  const HomeTab({required this.slug, required this.name, this.code, this.items = const []});

  final String slug;
  final String name;
  final String? code;
  @JsonKey(defaultValue: <CatalogTitle>[])
  final List<CatalogTitle> items;

  factory HomeTab.fromJson(Map<String, dynamic> json) => _$HomeTabFromJson(json);
}

@_json
class HomeArtist {
  const HomeArtist({required this.slug, required this.name, this.role, this.imageUrl, this.titlesCount = 0});

  final String slug;
  final String name;
  final String? role;
  final String? imageUrl;
  @JsonKey(defaultValue: 0)
  final int titlesCount;

  factory HomeArtist.fromJson(Map<String, dynamic> json) => _$HomeArtistFromJson(json);
}

/// A server-defined home row. Exactly one of items/tiles/tabs/artists is
/// expected to carry content; the UI renders whichever is non-empty.
@_json
class HomeRow {
  const HomeRow({
    required this.id,
    required this.title,
    this.source,
    this.layout,
    this.cardDetails = const [],
    this.showNewBadge = false,
    this.items = const [],
    this.tiles = const [],
    this.tabs = const [],
    this.artists = const [],
  });

  final int id;
  final String title;
  final String? source;
  final String? layout;
  @JsonKey(defaultValue: <String>[])
  final List<String> cardDetails;
  @JsonKey(defaultValue: false)
  final bool showNewBadge;
  @JsonKey(defaultValue: <CatalogTitle>[])
  final List<CatalogTitle> items;
  @JsonKey(defaultValue: <HomeTile>[])
  final List<HomeTile> tiles;
  @JsonKey(defaultValue: <HomeTab>[])
  final List<HomeTab> tabs;
  @JsonKey(defaultValue: <HomeArtist>[])
  final List<HomeArtist> artists;

  /// `wide` rows use landscape thumbnails; anything else uses posters.
  bool get isWide => layout == 'wide' || layout == 'landscape';

  bool get isEmpty => items.isEmpty && tiles.isEmpty && tabs.every((t) => t.items.isEmpty) && artists.isEmpty;

  factory HomeRow.fromJson(Map<String, dynamic> json) => _$HomeRowFromJson(json);
}

@_json
class HomeFeed {
  const HomeFeed({this.banners = const [], this.rows = const [], this.continueWatching = const []});

  @JsonKey(defaultValue: <HomeBanner>[])
  final List<HomeBanner> banners;
  @JsonKey(defaultValue: <HomeRow>[])
  final List<HomeRow> rows;
  @JsonKey(defaultValue: <ContinueWatchingItem>[])
  final List<ContinueWatchingItem> continueWatching;

  factory HomeFeed.fromJson(Map<String, dynamic> json) => _$HomeFeedFromJson(json);
}
