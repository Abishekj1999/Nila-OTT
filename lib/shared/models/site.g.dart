// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'site.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FooterLink _$FooterLinkFromJson(Map<String, dynamic> json) =>
    FooterLink(key: json['key'] as String, label: json['label'] as String);

SiteNavigation _$SiteNavigationFromJson(Map<String, dynamic> json) =>
    SiteNavigation(
      links:
          (SiteNavigation._readFooterLinks(json, 'links') as List<dynamic>?)
              ?.map((e) => FooterLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );

StaticPage _$StaticPageFromJson(Map<String, dynamic> json) => StaticPage(
  key: json['key'] as String,
  title: json['title'] as String,
  paragraphs:
      (json['paragraphs'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  updatedAt: json['updated_at'] as String?,
);
