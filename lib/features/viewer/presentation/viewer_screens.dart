import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/models/site.dart';
import '../../../shared/models/viewer.dart';
import '../../../shared/widgets/app_bars.dart';
import '../../../shared/widgets/app_image.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/state_views.dart';
import '../../auth/application/auth_controller.dart';
import '../../catalog/application/catalog_providers.dart';
import '../../shell/main_shell.dart';
import '../application/viewer_providers.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await showAdaptiveDialog<bool>(
      context: context,
      builder: (c) => AlertDialog.adaptive(
        title: const Text('Sign out?'),
        content: const Text('You can sign back in any time to pick up where you left off.'),
        actions: [
          adaptiveAction(c, label: 'Cancel', onPressed: () => Navigator.pop(c, false)),
          adaptiveAction(c, label: 'Sign out', destructive: true, onPressed: () => Navigator.pop(c, true)),
        ],
      ),
    );
    if (ok == true) {
      HapticFeedback.mediumImpact();
      await ref.read(authControllerProvider.notifier).logout();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authControllerProvider);
    final viewer = auth.viewer;

    return Scaffold(
      body: RefreshIndicator.adaptive(
        edgeOffset: MediaQuery.paddingOf(context).top + kToolbarHeight,
        onRefresh: () async {
          if (!auth.isSignedIn) return;
          await ref.read(authControllerProvider.notifier).refreshProfile().catchError((Object e) {
            if (context.mounted) showErrorSnack(context, e);
          });
        },
        child: TabScrollView(
          tab: 4,
          builder: (context, controller) => CustomScrollView(
            controller: controller,
            slivers: [
              const LargeTitleSliverAppBar(title: 'Account'),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter),
                sliver: SliverList.list(
                  children: [
                    const SizedBox(height: 8),
                    if (viewer != null) _ProfileHeader(viewer: viewer, premium: auth.isPremium) else const _GuestCard(),
                    const SizedBox(height: 16),
                    if (!auth.isPremium) const _PremiumUpsell(),
                    SettingsGroup(
                      title: 'Library',
                      children: [
                        if (auth.isSignedIn)
                          SettingsRow(icon: Icons.history_rounded, label: 'Continue Watching', onTap: () => context.push(Routes.continueWatching)),
                        SettingsRow(icon: Icons.bookmark_border_rounded, label: 'My List', soon: true, onTap: () => showComingSoon(context, 'My List')),
                        SettingsRow(icon: Icons.download_outlined, label: 'Downloads', soon: true, onTap: () => showComingSoon(context, 'Downloads')),
                      ],
                    ),
                    SettingsGroup(
                      title: 'Preferences',
                      children: [
                        if (auth.isSignedIn)
                          SettingsRow(
                            icon: Icons.person_outline_rounded,
                            label: 'Edit profile',
                            soon: true,
                            onTap: () => showComingSoon(context, 'Profile editing'),
                          ),
                        SettingsRow(
                          icon: Icons.notifications_none_rounded,
                          label: 'Notifications',
                          soon: true,
                          onTap: () => showComingSoon(context, 'Notifications'),
                        ),
                        SettingsRow(icon: Icons.hd_outlined, label: 'Playback & data', soon: true, onTap: () => showComingSoon(context, 'Playback settings')),
                      ],
                    ),
                    const _HelpGroup(),
                    if (auth.isSignedIn)
                      SettingsGroup(
                        children: [
                          SettingsRow(icon: Icons.logout_rounded, label: 'Sign out', destructive: true, chevron: false, onTap: () => _logout(context, ref)),
                        ],
                      ),
                    const SizedBox(height: 28),
                    const Center(child: Opacity(opacity: 0.6, child: BrandMark(height: 26))),
                    const SizedBox(height: 8),
                    const Text('Stories for every heart', textAlign: TextAlign.center, style: AppText.caption),
                  ],
                ),
              ),
              const BottomInsetSpacer(extra: 32),
            ],
          ),
        ),
      ),
    );
  }
}

/// Platform-appropriate dialog action (Cupertino on iOS, text button elsewhere).
Widget adaptiveAction(BuildContext context, {required String label, required VoidCallback onPressed, bool destructive = false}) {
  if (Theme.of(context).platform == TargetPlatform.iOS) {
    return CupertinoDialogAction(onPressed: onPressed, isDestructiveAction: destructive, isDefaultAction: !destructive, child: Text(label));
  }
  return TextButton(
    onPressed: onPressed,
    style: destructive ? TextButton.styleFrom(foregroundColor: AppColors.danger) : null,
    child: Text(label),
  );
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.viewer, required this.premium});

  final Viewer viewer;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    final initial = viewer.name.trim().isNotEmpty ? viewer.name.trim()[0].toUpperCase() : '?';
    return Row(
      children: [
        Container(
          width: 60,
          height: 60,
          alignment: Alignment.center,
          decoration: const BoxDecoration(shape: BoxShape.circle, gradient: AppColors.pinkGradient),
          child: Text(
            initial,
            style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(viewer.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.title2),
              const SizedBox(height: 2),
              Text(viewer.email, maxLines: 1, overflow: TextOverflow.ellipsis, style: AppText.subhead),
              const SizedBox(height: 8),
              premium ? const _PlanPill(label: 'Premium member', premium: true) : const _PlanPill(label: 'Free plan', premium: false),
            ],
          ),
        ),
      ],
    );
  }
}

class _PlanPill extends StatelessWidget {
  const _PlanPill({required this.label, required this.premium});

  final String label;
  final bool premium;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(
        gradient: premium ? AppColors.goldGradient : null,
        color: premium ? null : AppColors.surfaceHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (premium) ...[const Icon(Icons.workspace_premium_rounded, size: 13, color: AppColors.goldDeep), const SizedBox(width: 4)],
          Text(
            label,
            style: TextStyle(color: premium ? AppColors.goldDeep : AppColors.textSecondary, fontWeight: FontWeight.w700, fontSize: 11.5),
          ),
        ],
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  const _GuestCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
      child: Column(
        children: [
          const BrandLockup(emblemSize: 64, showTagline: false),
          const SizedBox(height: 18),
          const Text('Sign in for the full experience', textAlign: TextAlign.center, style: AppText.headline),
          const SizedBox(height: 6),
          const Text('Watch every story, save your progress and continue on any device.', textAlign: TextAlign.center, style: AppText.subhead),
          const SizedBox(height: 20),
          AppButton(label: 'Sign in', expand: true, onPressed: () => context.push(Routes.login)),
          const SizedBox(height: 10),
          AppButton.secondary(label: 'Create account', expand: true, onPressed: () => context.push(Routes.register)),
        ],
      ),
    );
  }
}

class _PremiumUpsell extends StatelessWidget {
  const _PremiumUpsell();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PressableScale(
        semanticLabel: 'Go Premium',
        onTap: () => context.push(Routes.premium),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            gradient: const LinearGradient(colors: [Color(0xFF3A2A10), Color(0xFF241A0E)]),
            border: Border.all(color: const Color(0x66F6C34A)),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(gradient: AppColors.goldGradient, shape: BoxShape.circle),
                child: const Icon(Icons.workspace_premium_rounded, color: AppColors.goldDeep, size: 24),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Go Premium',
                      style: TextStyle(color: AppColors.gold, fontSize: 16, fontWeight: FontWeight.w800),
                    ),
                    SizedBox(height: 2),
                    Text('Unlimited stories, exclusive content and no ads.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.gold),
            ],
          ),
        ),
      ),
    );
  }
}

/// Inset-grouped list section, as in iOS Settings.
class SettingsGroup extends StatelessWidget {
  const SettingsGroup({super.key, this.title, required this.children});

  final String? title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
              child: Text(title!.toUpperCase(), style: AppText.label.copyWith(color: AppColors.textTertiary)),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            child: ColoredBox(
              color: AppColors.surface,
              child: Column(
                children: [
                  for (var i = 0; i < children.length; i++) ...[if (i > 0) const Divider(indent: 52), children[i]],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.soon = false,
    this.destructive = false,
    this.chevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool soon;
  final bool destructive;
  final bool chevron;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? AppColors.danger : AppColors.text;
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 52,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(icon, size: 22, color: destructive ? AppColors.danger : AppColors.textSecondary),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(fontSize: 15.5, color: color, fontWeight: FontWeight.w500),
                ),
              ),
              if (soon)
                const Text(
                  'Soon',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              if (chevron) ...[const SizedBox(width: 4), const Icon(Icons.chevron_right_rounded, color: AppColors.textTertiary, size: 22)],
              const SizedBox(width: 10),
            ],
          ),
        ),
      ),
    );
  }
}

/// Help/Terms/Privacy/Contact, labelled from `/navigation` when available.
class _HelpGroup extends ConsumerWidget {
  const _HelpGroup();

  static const _fallback = [
    FooterLink(key: 'help', label: 'Help & support'),
    FooterLink(key: 'terms', label: 'Terms of use'),
    FooterLink(key: 'privacy', label: 'Privacy policy'),
    FooterLink(key: 'contact', label: 'Contact us'),
  ];

  static const _icons = {
    'help': Icons.help_outline_rounded,
    'terms': Icons.description_outlined,
    'privacy': Icons.privacy_tip_outlined,
    'contact': Icons.mail_outline_rounded,
  };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final links = ref.watch(navigationProvider).value?.links.where((l) => _icons.containsKey(l.key)).toList();
    return SettingsGroup(
      title: 'Help & legal',
      children: [
        for (final l in (links == null || links.isEmpty) ? _fallback : links)
          SettingsRow(icon: _icons[l.key]!, label: l.label, onTap: () => context.push(Routes.page(l.key))),
      ],
    );
  }
}

class ContinueWatchingScreen extends ConsumerWidget {
  const ContinueWatchingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(continueWatchingProvider);
    return Scaffold(
      appBar: const PageAppBar(title: 'Continue Watching'),
      body: AsyncValueView(
        value: async,
        onRetry: () => ref.invalidate(continueWatchingProvider),
        data: (items) {
          if (items.isEmpty) {
            return EmptyView(
              message: 'Nothing in progress',
              detail: 'Titles you start watching will appear here.',
              icon: Icons.history_rounded,
              action: AppButton.secondary(label: 'Browse titles', small: true, onPressed: () => context.go(Routes.home)),
            );
          }
          return RefreshIndicator.adaptive(
            onRefresh: () => ref.refresh(continueWatchingProvider.future),
            child: ListView.separated(
              padding: EdgeInsets.fromLTRB(0, 8, 0, MediaQuery.paddingOf(context).bottom + 24),
              itemCount: items.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                if (i == items.length) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Swipe left on a title to remove it.', textAlign: TextAlign.center, style: AppText.caption),
                  );
                }
                final item = items[i];
                return Dismissible(
                  key: ValueKey(item.id),
                  direction: DismissDirection.endToStart,
                  background: Container(
                    color: AppColors.danger,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 24),
                    child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                  ),
                  onDismissed: (_) => ref.read(continueWatchingProvider.notifier).remove(item).catchError((Object e) {
                    if (context.mounted) showErrorSnack(context, e);
                  }),
                  child: _ProgressRow(item: item),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({required this.item});

  final ContinueWatchingItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(Routes.watch(item.type, item.itemId)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.gutter, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 148,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppImage(item.thumbnailUrl),
                      const Center(child: Icon(Icons.play_circle_outline_rounded, color: Colors.white, size: 34)),
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(value: item.progress.clamp(0.0, 1.0), minHeight: 3, backgroundColor: const Color(0x40FFFFFF)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: AppText.bodyStrong),
                  if ([item.subtitle, item.episodeTitle].any((s) => s?.isNotEmpty ?? false)) ...[
                    const SizedBox(height: 2),
                    Text(
                      [item.subtitle, item.episodeTitle].whereType<String>().where((s) => s.isNotEmpty).join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppText.subhead,
                    ),
                  ],
                  if (item.remainingLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(item.remainingLabel!, style: AppText.caption.copyWith(color: AppColors.pinkBright)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class StaticPageScreen extends ConsumerWidget {
  const StaticPageScreen({super.key, required this.pageKey});

  final String pageKey;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staticPageProvider(pageKey));
    return Scaffold(
      appBar: PageAppBar(title: async.value?.title),
      body: async.when(
        data: (page) => ListView(
          padding: EdgeInsets.fromLTRB(20, 8, 20, MediaQuery.paddingOf(context).bottom + 32),
          children: [
            Text(page.title, style: AppText.title1),
            if (page.updatedAt != null)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text('Last updated ${page.updatedAt!.split('T').first}', style: AppText.caption),
              ),
            const SizedBox(height: 20),
            for (final p in page.paragraphs)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(p, style: AppText.body.copyWith(fontSize: 15.5, height: 1.6)),
              ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator.adaptive()),
        // The API returns 404 when a page has no content yet.
        error: (e, _) => ErrorView(error: e, onRetry: () => ref.invalidate(staticPageProvider(pageKey))),
      ),
    );
  }
}
