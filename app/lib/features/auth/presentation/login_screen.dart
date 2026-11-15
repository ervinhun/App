import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';
import 'package:app/l10n/app_localizations.dart';

/// Email/password sign-in and registration, plus "Continue with Google".
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  /// Google sign-in is only configured for Android so far: iOS needs its own
  /// OAuth client, and the App Store then also requires Sign in with Apple.
  static bool get googleAvailable =>
      defaultTargetPlatform == TargetPlatform.android;

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _displayName = TextEditingController();

  bool _registering = false;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _confirmPassword.dispose();
    _displayName.dispose();
    super.dispose();
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } catch (e) {
      if (e is! ApiException) debugPrint('Sign-in failed: $e');
      if (mounted) {
        setState(() => _error = ApiException.messageFor(e, context.l10n));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final auth = ref.read(authControllerProvider.notifier);
    await _run(
      () => _registering
          ? auth.register(
              email: _email.text,
              password: _password.text,
              displayName: _displayName.text,
            )
          : auth.signInWithPassword(_email.text, _password.text),
    );
  }

  Future<void> _google() =>
      _run(() => ref.read(authControllerProvider.notifier).signInWithGoogle());

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      l10n.tr('app.title'),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 32),
                    if (_registering) ...[
                      TextFormField(
                        controller: _displayName,
                        decoration: InputDecoration(
                          labelText: l10n.tr('login.name'),
                        ),
                        textInputAction: TextInputAction.next,
                        validator: (v) => (v == null || v.trim().isEmpty)
                            ? l10n.tr('login.nameRequired')
                            : null,
                      ),
                      const SizedBox(height: 12),
                    ],
                    TextFormField(
                      controller: _email,
                      decoration: InputDecoration(
                        labelText: l10n.tr('login.email'),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      textInputAction: TextInputAction.next,
                      validator: (v) => (v == null || !v.contains('@'))
                          ? l10n.tr('login.emailInvalid')
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _password,
                      decoration: InputDecoration(
                        labelText: l10n.tr('login.password'),
                      ),
                      obscureText: true,
                      autofillHints: const [AutofillHints.password],
                      textInputAction: _registering
                          ? TextInputAction.next
                          : TextInputAction.done,
                      onFieldSubmitted: _registering ? null : (_) => _submit(),
                      validator: (v) => (v == null || v.length < 8)
                          ? l10n.tr('login.passwordTooShort')
                          : null,
                    ),
                    if (_registering) ...[
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _confirmPassword,
                        decoration: InputDecoration(
                          labelText: l10n.tr('login.confirmPassword'),
                        ),
                        obscureText: true,
                        onFieldSubmitted: (_) => _submit(),
                        validator: (v) => v != _password.text
                            ? l10n.tr('login.passwordsDontMatch')
                            : null,
                      ),
                    ],
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: _busy ? null : _submit,
                      child: Text(
                        l10n.tr(
                          _registering ? 'login.createAccount' : 'login.signIn',
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _busy
                          ? null
                          : () => setState(() {
                              _registering = !_registering;
                              _error = null;
                            }),
                      child: Text(
                        l10n.tr(
                          _registering
                              ? 'login.switchToSignIn'
                              : 'login.switchToRegister',
                        ),
                      ),
                    ),
                    if (LoginScreen.googleAvailable) ...[
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Expanded(child: Divider()),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(l10n.tr('login.or')),
                          ),
                          const Expanded(child: Divider()),
                        ],
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed: _busy ? null : _google,
                        icon: const Icon(Icons.login),
                        label: Text(l10n.tr('login.continueWithGoogle')),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
