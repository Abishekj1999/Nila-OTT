// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HomeBanner _$HomeBannerFromJson(Map<String, dynamic> json) => HomeBanner(
  kind: json['kind'] as String?,
  heading: json['heading'] as String?,
  tagline: json['tagline'] as String?,
  imageUrl: json['image_url'] as String?,
  mobileImageUrl: json['mobile_image_url'] as String?,
  buttonLabel: json['button_label'] as String?,
  link: json['link'] as String?,
  title: json['title'] == null
      ? null
      : CatalogTitle.fromJson(json['title'] as Map<String, dynamic>),
);

HomeTile _$HomeTileFromJson(Map<String, dynamic> json) => HomeTile(
  kind: json['kind'] as String,
  slug: json['slug'] as String,
  name: json['name'] as String,
  imageUrl: json['image_url'] as String?,
  titlesCount: (json['titles_count'] as num?)?.toInt() ?? 0,
);

HomeTab _$HomeTabFromJson(Map<String, dynamic> json) => HomeTab(
  slug: json['slug'] as String,
  name: json['name'] as String,
  code: json['code'] as String?,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CatalogTitle.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

HomeArtist _$HomeArtistFromJson(Map<String, dynamic> json) => HomeArtist(
  slug: json['slug'] as String,
  name: json['name'] as String,
  role: json['role'] as String?,
  imageUrl: json['image_url'] as String?,
  titlesCount: (json['titles_count'] as num?)?.toInt() ?? 0,
);

HomeRow _$HomeRowFromJson(Map<String, dynamic> json) => HomeRow(
  id: (json['id'] as num).toInt(),
  title: json['title'] as String,
  source: json['source'] as String?,
  layout: json['layout'] as String?,
  cardDetails:
      (json['card_details'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  showNewBadge: json['show_new_badge'] as bool? ?? false,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => CatalogTitle.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  tiles:
      (json['tiles'] as List<dynamic>?)
          ?.map((e) => HomeTile.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  tabs:
      (json['tabs'] as List<dynamic>?)
          ?.map((e) => HomeTab.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  artists:
      (json['artists'] as List<dynamic>?)
          ?.map((e) => HomeArtist.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

HomeFeed _$HomeFeedFromJson(Map<String, dynamic> json) => HomeFeed(
  banners:
      (json['banners'] as List<dynamic>?)
          ?.map((e) => HomeBanner.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  rows:
      (json['rows'] as List<dynamic>?)
          ?.map((e) => HomeRow.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  continueWatching:
      (json['continue_watching'] as List<dynamic>?)
          ?.map((e) => ContinueWatchingItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);
