import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/state_views.dart';

/// Shared scaffold for sign-in and sign-up: logo, heading, then the form.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.title, required this.subtitle, required this.children, this.footer});

  final String title;
  final String subtitle;
  final List<Widget> children;

  /// Pinned under the form (e.g. "New here? Create an account").
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: IconButton(
          tooltip: 'Close',
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 440),
            child: ListView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              children: [
                const BrandLockup(emblemSize: 76, showTagline: false),
                const SizedBox(height: 28),
                Text(title, textAlign: TextAlign.center, style: AppText.title1),
                const SizedBox(height: 6),
                Text(subtitle, textAlign: TextAlign.center, style: AppText.subhead),
                const SizedBox(height: 28),
                ...children,
                if (footer != null) ...[const SizedBox(height: 28), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Phone, Google and Facebook sign-in have no backend support yet.
class SocialSignInOptions extends StatelessWidget {
  const SocialSignInOptions({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ProviderButton(
          leading: const Icon(Icons.smartphone_rounded, color: AppColors.text, size: 22),
          label: 'Continue with phone',
          onTap: () => showComingSoon(context, 'Phone sign-in'),
        ),
        const SizedBox(height: 10),
        _ProviderButton(
          leading: const _GoogleMark(),
          label: 'Continue with Google',
          onTap: () => showComingSoon(context, 'Google sign-in'),
        ),
        const SizedBox(height: 10),
        _ProviderButton(
          leading: const CircleAvatar(
            radius: 11,
            backgroundColor: Color(0xFF1877F2),
            child: Text('f', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w900, height: 1.15)),
          ),
          label: 'Continue with Facebook',
          onTap: () => showComingSoon(context, 'Facebook sign-in'),
        ),
      ],
    );
  }
}

class _ProviderButton extends StatelessWidget {
  const _ProviderButton({required this.leading, required this.label, required this.onTap});

  final Widget leading;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Color(0x33FFFFFF))),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 50,
          child: Row(children: [
            const SizedBox(width: 16),
            SizedBox(width: 24, child: Center(child: leading)),
            Expanded(
              child: Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.text)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(color: AppColors.surfaceHigh, borderRadius: BorderRadius.circular(6)),
              child: const Text('Soon', style: TextStyle(color: AppColors.textTertiary, fontSize: 10.5, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
          ]),
        ),
      ),
    );
  }
}

class _GoogleMark extends StatelessWidget {
  const _GoogleMark();

  @override
  Widget build(BuildContext context) {
    return ShaderMask(
      shaderCallback: (r) => const SweepGradient(
        colors: [Color(0xFF4285F4), Color(0xFF34A853), Color(0xFFFBBC05), Color(0xFFEA4335), Color(0xFF4285F4)],
      ).createShader(r),
      child: const Text('G', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
    );
  }
}

class OrDivider extends StatelessWidget {
  const OrDivider({super.key, this.label = 'or'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 22),
      child: Row(children: [
        const Expanded(child: Divider()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(label, style: AppText.caption),
        ),
        const Expanded(child: Divider()),
      ]),
    );
  }
}

class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Password',
    this.helperText,
    this.errorText,
    this.validator,
    this.textInputAction,
    this.onSubmitted,
    this.autofillHints,
  });

  final TextEditingController controller;
  final String label;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;
  final Iterable<String>? autofillHints;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _obscure = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscure,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onSubmitted,
      autofillHints: widget.autofillHints,
      autocorrect: false,
      enableSuggestions: false,
      decoration: InputDecoration(
        labelText: widget.label,
        helperText: widget.helperText,
        helperStyle: AppText.caption,
        errorText: widget.errorText,
        suffixIcon: IconButton(
          tooltip: _obscure ? 'Show password' : 'Hide password',
          icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 22),
          onPressed: () => setState(() => _obscure = !_obscure),
        ),
      ),
    );
  }
}

/// Inline banner for request-level errors (bad credentials, rate limit).
class AuthErrorBanner extends StatelessWidget {
  const AuthErrorBanner(this.message, {super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: const Color(0x26FF5A5F), borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 20),
        const SizedBox(width: 10),
        Expanded(child: Text(message, style: const TextStyle(color: AppColors.text, fontSize: 14))),
      ]),
    );
  }
}

/// "Prompt  Action" link row under the form.
class AuthSwitchLink extends StatelessWidget {
  const AuthSwitchLink({super.key, required this.prompt, required this.action, required this.onTap});

  final String prompt;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Text(prompt, style: AppText.subhead),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 6), minimumSize: const Size(0, 40)),
          child: Text(action, style: const TextStyle(fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

final _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

String? validateEmail(String? v) {
  final value = v?.trim() ?? '';
  if (value.isEmpty) return 'Enter your email';
  if (value.length > 255 || !_emailPattern.hasMatch(value)) return 'Enter a valid email';
  return null;
}
