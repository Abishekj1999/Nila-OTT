import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_exception.dart';
import '../../core/theme/app_theme.dart';
import 'buttons.dart';

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.error, this.onRetry, this.compact = false});

  final Object error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final e = ApiException.from(error);
    final icon = switch (e.kind) {
      ApiErrorKind.network || ApiErrorKind.timeout => Icons.wifi_off_rounded,
      ApiErrorKind.notFound => Icons.search_off_rounded,
      ApiErrorKind.premiumRequired => Icons.workspace_premium_rounded,
      ApiErrorKind.unauthorized => Icons.lock_outline_rounded,
      _ => Icons.error_outline_rounded,
    };
    return MessageView(
      icon: icon,
      title: switch (e.kind) {
        ApiErrorKind.notFound => 'Not available',
        ApiErrorKind.network || ApiErrorKind.timeout => "You're offline",
        _ => 'Something went wrong',
      },
      message: e.userMessage,
      compact: compact,
      action: onRetry != null && e.isRetryable ? AppButton.secondary(label: 'Try again', icon: Icons.refresh_rounded, small: true, onPressed: onRetry) : null,
    );
  }
}

class MessageView extends StatelessWidget {
  const MessageView({super.key, required this.icon, required this.title, this.message, this.action, this.compact = false});

  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 40, vertical: compact ? 16 : 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: compact ? 52 : 72,
              height: compact ? 52 : 72,
              decoration: const BoxDecoration(color: AppColors.surfaceHigh, shape: BoxShape.circle),
              child: Icon(icon, size: compact ? 24 : 32, color: AppColors.pinkBright),
            ),
            const SizedBox(height: 18),
            Text(title, style: AppText.headline, textAlign: TextAlign.center),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, style: AppText.subhead, textAlign: TextAlign.center),
            ],
            if (action != null) ...[const SizedBox(height: 22), action!],
          ],
        ),
      ),
    );
  }
}

class EmptyView extends StatelessWidget {
  const EmptyView({super.key, required this.message, this.icon = Icons.movie_filter_outlined, this.detail, this.action});

  final String message;
  final String? detail;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) => MessageView(icon: icon, title: message, message: detail, action: action);
}

/// Renders loading / error / data for an [AsyncValue] with consistent states.
class AsyncValueView<T> extends StatelessWidget {
  const AsyncValueView({super.key, required this.value, required this.data, this.loading, this.onRetry});

  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final Widget? loading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return value.when(
      skipLoadingOnRefresh: true,
      data: data,
      loading: () => loading ?? const Center(child: CircularProgressIndicator.adaptive()),
      error: (e, _) => ErrorView(error: e, onRetry: onRetry),
    );
  }
}

/// Bottom sheet for features the backend doesn't support yet.
Future<void> showComingSoon(BuildContext context, String feature) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 4, 24, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(color: AppColors.pinkTint, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome_rounded, color: AppColors.pinkBright, size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Coming soon', style: AppText.title2),
            const SizedBox(height: 6),
            Text(
              "$feature isn't available yet. We're working on it and will let you know when it's ready.",
              textAlign: TextAlign.center,
              style: AppText.subhead,
            ),
            const SizedBox(height: 22),
            AppButton(label: 'Got it', expand: true, onPressed: () => Navigator.pop(context)),
          ],
        ),
      ),
    ),
  );
}

/// A pickable option for [showOptionSheet].
class SheetOption<T> {
  const SheetOption(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// Native-style single-choice list in a bottom sheet. Returns the picked value,
/// or null when dismissed.
Future<T?> showOptionSheet<T>(
  BuildContext context, {
  required String title,
  required List<SheetOption<T>> options,
  required T selected,
}) {
  HapticFeedback.selectionClick();
  return showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    builder: (context) => ConstrainedBox(
      constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(title, style: AppText.title2),
            ),
            Flexible(
              child: ListView(
                shrinkWrap: true,
                padding: const EdgeInsets.only(bottom: 8),
                children: [
                  for (final o in options)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                      leading: o.icon == null ? null : Icon(o.icon, size: 22),
                      title: Text(
                        o.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: o.value == selected ? FontWeight.w700 : FontWeight.w400,
                          color: o.value == selected ? AppColors.text : AppColors.textSecondary,
                        ),
                      ),
                      trailing: o.value == selected ? const Icon(Icons.check_rounded, color: AppColors.pinkBright) : null,
                      onTap: () => Navigator.pop(context, o.value),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

void showErrorSnack(BuildContext context, Object error) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(ApiException.from(error).userMessage)));
}
