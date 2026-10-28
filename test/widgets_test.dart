import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:nilaott/core/network/api_exception.dart';
import 'package:nilaott/core/providers.dart';
import 'package:nilaott/core/theme/app_theme.dart';
import 'package:nilaott/features/auth/presentation/auth_screens.dart';
import 'package:nilaott/features/catalog/application/catalog_providers.dart';
import 'package:nilaott/features/home/presentation/home_screen.dart';
import 'package:nilaott/features/premium/premium_screen.dart';
import 'package:nilaott/shared/models/home.dart';

import 'helpers/fake_api.dart';

/// Pumps [child] inside a router and theme; network images are disabled.
Future<void> _pump(WidgetTester tester, Widget child, {List overrides = const []}) async {
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final router = GoRouter(routes: [
    GoRoute(path: '/', builder: (_, _) => child),
    GoRoute(path: '/:rest(.*)', builder: (_, _) => const Scaffold()),
  ]);
  await tester.pumpWidget(ProviderScope(
    retry: (_, _) => null,
    overrides: [mediaUrlProvider.overrideWithValue((_) => null), ...overrides],
    child: MaterialApp.router(theme: buildAppTheme(), routerConfig: router),
  ));
}

void main() {
  testWidgets('home renders banners and server-defined rows', (tester) async {
    final feed = HomeFeed.fromJson((jsonDecode(fixture('home.json')) as Map)['data'] as Map<String, dynamic>);
    await _pump(tester, const HomeScreen(), overrides: [homeFeedProvider.overrideWith((ref) async => feed)]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text(feed.banners.first.heading!), findsOneWidget);
    expect(find.text(feed.rows.first.title), findsOneWidget);
  });

  testWidgets('home shows a retry action on network failure', (tester) async {
    await _pump(tester, const HomeScreen(), overrides: [
      homeFeedProvider.overrideWith((ref) async => throw const ApiException(ApiErrorKind.network)),
    ]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('No connection. Check your internet and try again.'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('login validates input before calling the API', (tester) async {
    await _pump(tester, const LoginScreen());
    await tester.pump();

    await tester.tap(find.text('Sign in').last);
    await tester.pump();
    expect(find.text('Enter your email'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);

    await tester.enterText(find.byType(TextFormField).first, 'not-an-email');
    await tester.tap(find.text('Sign in').last);
    await tester.pump();
    expect(find.text('Enter a valid email'), findsOneWidget);
  });

  testWidgets('register shows unsupported sign-in methods as coming soon', (tester) async {
    await _pump(tester, const RegisterScreen());
    await tester.pump();

    final google = find.text('Continue with Google');
    await tester.scrollUntilVisible(google, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(google);
    await tester.pumpAndSettle();
    await tester.tap(google);
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
  });

  testWidgets('premium shows design plans and checkout is coming soon', (tester) async {
    await _pump(tester, const PremiumScreen());
    await tester.pump();

    expect(find.text('About ₹16.63/day'), findsOneWidget);
    expect(find.textContaining('₹499', findRichText: true), findsOneWidget);

    final cta = find.text('Continue');
    await tester.scrollUntilVisible(cta, 300, scrollable: find.byType(Scrollable).first);
    await tester.ensureVisible(cta);
    await tester.pumpAndSettle();
    await tester.tap(cta);
    await tester.pumpAndSettle();
    expect(find.text('Coming soon'), findsOneWidget);
  });
}
