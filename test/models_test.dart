import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:nilaott/shared/models/artist.dart';
import 'package:nilaott/shared/models/catalog.dart';
import 'package:nilaott/shared/models/home.dart';
import 'package:nilaott/shared/models/title.dart';
import 'package:nilaott/shared/models/viewer.dart';

import 'helpers/fake_api.dart';

Map<String, dynamic> _data(String name) => (jsonDecode(fixture(name)) as Map<String, dynamic>)['data'] as Map<String, dynamic>;

void main() {
  group('real API fixtures', () {
    test('home feed parses banners, title rows and tile rows', () {
      final feed = HomeFeed.fromJson(_data('home.json'));
      expect(feed.banners, isNotEmpty);
      expect(feed.banners.first.title, isNotNull);
      expect(feed.rows.any((r) => r.items.isNotEmpty), isTrue);
      expect(feed.rows.any((r) => r.tiles.isNotEmpty), isTrue);
      expect(feed.rows.firstWhere((r) => r.layout == 'wide').isWide, isTrue);
      expect(feed.continueWatching, isEmpty);
    });

    test('browse page parses titles, pagination and both filter option shapes', () {
      final page = BrowsePage.fromJson(_data('movies.json'));
      expect(page.titles, isNotEmpty);
      expect(page.titles.every((t) => t.type == TitleType.movie), isTrue);
      expect(page.pagination.perPage, 24);
      expect(page.options.sorts.map((o) => o.value), contains('newest'));
      expect(page.options.genres.first.value, isNotEmpty); // {slug, name}
      expect(page.options.access.map((o) => o.value), containsAll(['free', 'premium'])); // {value, label}
      expect(page.collection, isNull);
    });

    test('genre browse page carries its collection', () {
      final page = BrowsePage.fromJson(_data('genre_drama.json'));
      expect(page.collection?.slug, 'drama');
      expect(page.collection?.kind, 'genre');
    });

    test('series detail parses seasons and episodes', () {
      final detail = TitleDetail.fromJson(_data('series_detail.json'));
      expect(detail.isSeries, isTrue);
      expect(detail.seasons, isNotEmpty);
      expect(detail.seasons.first.episodes.first.id, greaterThan(0));
      expect(detail.cast, isNotEmpty);
    });

    test('artist directory parses roles and artists', () {
      final dir = ArtistDirectory.fromJson(_data('artists.json'));
      expect(dir.roles, isNotEmpty);
      expect(dir.artists.first.roles, isNotEmpty);
    });
  });

  group('null tolerance', () {
    test('title with nulls and missing lists falls back to defaults', () {
      final t = CatalogTitle.fromJson({'type': 'series', 'slug': 's', 'title': 'S', 'genres': null, 'is_new': null});
      expect(t.isSeries, isTrue);
      expect(t.genres, isEmpty);
      expect(t.isNew, isFalse);
      expect(t.access, 'free');
    });

    test('movie detail with null seasons yields an empty list', () {
      final d = TitleDetail.fromJson({'id': 1, 'type': 'movie', 'slug': 'm', 'title': 'M', 'seasons': null, 'access': 'premium'});
      expect(d.seasons, isEmpty);
      expect(d.isPremium, isTrue);
    });

    test('continue watching item accepts integer progress', () {
      final item = ContinueWatchingItem.fromJson({
        'id': 42,
        'type': 'episode',
        'item_id': 105,
        'title': 'Stranger Things',
        'slug': 'stranger-things',
        'progress': 1,
      });
      expect(item.type, PlayableType.episode);
      expect(item.progress, 1.0);
    });

    test('playback info parses documented fields', () {
      final p = PlaybackInfo.fromJson({
        'type': 'movie',
        'id': 1,
        'title': 'Interstellar',
        'subtitle': null,
        'poster_url': null,
        'duration_seconds': 10140,
        'stream_url': 'https://video.bunnycdn.com/play/12345/playlist.m3u8',
        'stream_format': 'hls',
        'resume_seconds': 1540,
      });
      expect(p.resumeSeconds, 1540);
      expect(p.isYoutube, isFalse);
    });
  });
}
