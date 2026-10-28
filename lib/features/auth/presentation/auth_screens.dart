import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/buttons.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/auth_controller.dart';
import 'auth_widgets.dart';

/// Navigates to [from] after a successful sign-in, or home.
void _finish(BuildContext context, String? from) {
  if (from != null && from.startsWith('/')) {
    context.go(from);
  } else {
    context.go(Routes.home);
  }
}

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).login(email: _email.text, password: _password.text);
      TextInput.finishAutofillContext();
      if (mounted) _finish(context, widget.from);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final emailError = error?.firstFieldError('email');
    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to keep watching',
      footer: AuthSwitchLink(
        prompt: "New to Nila's OTT?",
        action: 'Create account',
        onTap: () => context.pushReplacement(widget.from == null ? Routes.register : '${Routes.register}?from=${Uri.encodeComponent(widget.from!)}'),
      ),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                validator: validateEmail,
                decoration: InputDecoration(labelText: 'Email', errorText: emailError),
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                validator: (v) => (v == null || v.isEmpty) ? 'Enter your password' : null,
              ),
            ]),
          ),
        ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton(onPressed: () => showComingSoon(context, 'Password reset'), child: const Text('Forgot password?')),
        ),
        if (error != null && emailError == null) ...[AuthErrorBanner(error.userMessage), const SizedBox(height: 12)],
        AppButton(label: 'Sign in', expand: true, loading: _busy, onPressed: _submit),
        const OrDivider(),
        const SocialSignInOptions(),
      ],
    );
  }
}

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.from});

  final String? from;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  late final _termsTap = TapGestureRecognizer()..onTap = () => context.push(Routes.page('terms'));
  late final _privacyTap = TapGestureRecognizer()..onTap = () => context.push(Routes.page('privacy'));
  bool _busy = false;
  ApiException? _error;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _termsTap.dispose();
    _privacyTap.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(authControllerProvider.notifier).register(name: _name.text, email: _email.text, password: _password.text);
      TextInput.finishAutofillContext();
      if (mounted) _finish(context, widget.from);
    } catch (e) {
      if (mounted) setState(() => _error = ApiException.from(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final error = _error;
    final fieldErrors = {
      'name': error?.firstFieldError('name'),
      'email': error?.firstFieldError('email'),
      'password': error?.firstFieldError('password'),
    };
    final hasFieldError = fieldErrors.values.any((e) => e != null);
    const link = TextStyle(color: AppColors.text, fontWeight: FontWeight.w600);
    return AuthScaffold(
      title: 'Create your account',
      subtitle: 'Stories for every heart, in one place',
      footer: AuthSwitchLink(
        prompt: 'Already have an account?',
        action: 'Sign in',
        onTap: () => context.pushReplacement(widget.from == null ? Routes.login : Routes.loginThen(widget.from!)),
      ),
      children: [
        Form(
          key: _form,
          child: AutofillGroup(
            child: Column(children: [
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                textCapitalization: TextCapitalization.words,
                autofillHints: const [AutofillHints.name],
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Enter your name';
                  if (value.length > 255) return 'Name is too long';
                  return null;
                },
                decoration: InputDecoration(labelText: 'Full name', errorText: fieldErrors['name']),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.email],
                autocorrect: false,
                validator: validateEmail,
                decoration: InputDecoration(labelText: 'Email', errorText: fieldErrors['email']),
              ),
              const SizedBox(height: 12),
              PasswordField(
                controller: _password,
                helperText: 'At least 8 characters',
                errorText: fieldErrors['password'],
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                onSubmitted: (_) => _submit(),
                validator: (v) => (v == null || v.length < 8) ? 'Use at least 8 characters' : null,
              ),
            ]),
          ),
        ),
        if (error != null && !hasFieldError) ...[const SizedBox(height: 12), AuthErrorBanner(error.userMessage)],
        const SizedBox(height: 20),
        AppButton(label: 'Create account', expand: true, loading: _busy, onPressed: _submit),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(children: [
            const TextSpan(text: 'By creating an account you agree to our '),
            TextSpan(text: 'Terms of Use', style: link, recognizer: _termsTap),
            const TextSpan(text: ' and '),
            TextSpan(text: 'Privacy Policy', style: link, recognizer: _privacyTap),
            const TextSpan(text: '.'),
          ]),
          textAlign: TextAlign.center,
          style: AppText.caption,
        ),
        const OrDivider(),
        const SocialSignInOptions(),
      ],
    );
  }
}
