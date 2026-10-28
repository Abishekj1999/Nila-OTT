import 'package:json_annotation/json_annotation.dart';

part 'site.g.dart';

const _json = JsonSerializable(fieldRename: FieldRename.snake, createToJson: false);

@_json
class FooterLink {
  const FooterLink({required this.key, required this.label});

  final String key;
  final String label;

  factory FooterLink.fromJson(Map<String, dynamic> json) => _$FooterLinkFromJson(json);
}

/// Subset of `/navigation` the app uses: the footer page links.
@_json
class SiteNavigation {
  const SiteNavigation({this.links = const []});

  @JsonKey(readValue: _readFooterLinks, defaultValue: <FooterLink>[])
  final List<FooterLink> links;

  static Object? _readFooterLinks(Map<dynamic, dynamic> json, String _) => (json['footer'] as Map?)?['links'];

  factory SiteNavigation.fromJson(Map<String, dynamic> json) => _$SiteNavigationFromJson(json);
}

@_json
class StaticPage {
  const StaticPage({required this.key, required this.title, this.paragraphs = const [], this.updatedAt});

  final String key;
  final String title;
  @JsonKey(defaultValue: <String>[])
  final List<String> paragraphs;
  final String? updatedAt;

  factory StaticPage.fromJson(Map<String, dynamic> json) => _$StaticPageFromJson(json);
}
