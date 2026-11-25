import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'package:app/core/api/api_client.dart';
import 'package:app/core/theme/app_colors.dart';
import 'package:app/core/theme/app_text.dart';
import 'package:app/features/auth/data/apple_auth.dart';
import 'package:app/features/auth/data/guest_mode.dart';
import 'package:app/features/auth/presentation/auth_controller.dart';

/// "Continue with Google", "Continue with email" and "Continue as guest", as
/// in the Figma Login screen, plus "Continue with Apple" on iOS. Email opens
/// the sign-in and registration form.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _displayName = TextEditingController();

  /// Whether the email form is shown instead of the ways to sign in.
  bool _withEmail = false;
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
      if (mounted) setState(() => _error = ApiException.messageFor(e));
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

  Future<void> _apple() =>
      _run(() => ref.read(authControllerProvider.notifier).signInWithApple());

  void _showEmail(bool show) => setState(() {
    _withEmail = show;
    _error = null;
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle.dark,
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, viewport) => SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: viewport.maxHeight),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // As tall as the footer, so the content sits centred.
                    const SizedBox(height: _footerHeight),
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: _buildContent(),
                      ),
                    ),
                    SizedBox(
                      height: _footerHeight,
                      child: Text(
                        'Terms · Privacy',
                        style: AppText.nunito(
                          10,
                          FontWeight.w400,
                          AppColors.brandPrimary,
                          height: 14 / 10,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  static const _footerHeight = 22.0;

  Widget _buildContent() {
    final error = _error;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _Welcome(),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 14,
            children: [
              if (_withEmail)
                _buildEmailForm()
              else ...[
                _OutlinedButton(
                  onPressed: _busy ? null : _google,
                  icon: SvgPicture.asset(
                    'assets/images/google_logo.svg',
                    width: 20,
                    height: 20,
                  ),
                  label: 'Continue with Google',
                ),
                if (AppleAuth.available)
                  _OutlinedButton(
                    onPressed: _busy ? null : _apple,
                    icon: const Icon(
                      Icons.apple,
                      size: 20,
                      color: AppColors.textPrimary,
                    ),
                    label: 'Continue with Apple',
                  ),
                _FilledButton(
                  label: 'Continue with email',
                  onPressed: _busy ? null : () => _showEmail(true),
                ),
              ],
              if (error != null)
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: AppText.nunito(
                    12,
                    FontWeight.w600,
                    AppColors.statusSoon,
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _TextButton(
            label: 'Continue as guest',
            onPressed: _busy
                ? null
                : () => ref.read(guestModeProvider.notifier).enter(),
          ),
        ),
      ],
    );
  }

  Widget _buildEmailForm() => Form(
    key: _formKey,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 14,
      children: [
        _BackLink(
          label: 'Other ways to sign in',
          onTap: _busy ? null : () => _showEmail(false),
        ),
        if (_registering)
          _Input(
            label: 'Name',
            controller: _displayName,
            textCapitalization: TextCapitalization.words,
            autofillHints: const [AutofillHints.name],
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
          ),
        _Input(
          label: 'Email',
          controller: _email,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          validator: (v) =>
              (v == null || !v.contains('@')) ? 'Enter a valid email' : null,
        ),
        _Input(
          label: 'Password',
          controller: _password,
          obscureText: true,
          autofillHints: const [AutofillHints.password],
          textInputAction: _registering
              ? TextInputAction.next
              : TextInputAction.done,
          onFieldSubmitted: _registering ? null : (_) => _submit(),
          validator: (v) =>
              (v == null || v.length < 8) ? 'At least 8 characters' : null,
        ),
        if (_registering)
          _Input(
            label: 'Confirm password',
            controller: _confirmPassword,
            obscureText: true,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => _submit(),
            validator: (v) =>
                v != _password.text ? "Passwords don't match" : null,
          ),
        _FilledButton(
          label: _registering ? 'Create account' : 'Sign in',
          onPressed: _busy ? null : _submit,
        ),
        _TextButton(
          label: _registering
              ? 'Have an account? Sign in'
              : 'New here? Create an account',
          onPressed: _busy
              ? null
              : () => setState(() {
                  _registering = !_registering;
                  _error = null;
                }),
        ),
      ],
    ),
  );
}

/// The fridge mark, the wordmark and the tagline.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 24),
    child: Column(
      children: [
        SizedBox.square(
          dimension: 108.8,
          child: Padding(
            padding: const EdgeInsets.only(left: 11.74, top: 11.74),
            child: Align(
              alignment: Alignment.topLeft,
              child: SvgPicture.asset(
                'assets/images/logo_mark.svg',
                width: 85.31,
                height: 86.77,
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Fridge',
                style: AppText.brand(Colors.black, size: 32),
              ),
              TextSpan(
                text: 'Friend',
                style: AppText.brand(AppColors.brandPrimary, size: 32),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 18),
        Text(
          'Less waste. More ease.',
          textAlign: TextAlign.center,
          style: AppText.nunito(
            22,
            FontWeight.w900,
            AppColors.textPrimary,
            height: 30 / 22,
          ).copyWith(letterSpacing: -0.4),
        ),
      ],
    ),
  );
}

/// A 52-high rounded button: [color] filled, with an optional [border].
class _Button extends StatelessWidget {
  const _Button({
    required this.onPressed,
    required this.color,
    required this.child,
    this.border,
  });

  final VoidCallback? onPressed;
  final Color color;
  final BorderSide? border;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final border = this.border;
    return Opacity(
      opacity: onPressed == null ? 0.6 : 1,
      child: Material(
        color: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: border ?? BorderSide.none,
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            height: 52,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle _buttonText(Color color) =>
    AppText.nunito(14, FontWeight.w800, color, height: 20 / 14);

class _OutlinedButton extends StatelessWidget {
  const _OutlinedButton({
    required this.onPressed,
    required this.icon,
    required this.label,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final String label;

  @override
  Widget build(BuildContext context) => _Button(
    onPressed: onPressed,
    color: AppColors.surface,
    border: const BorderSide(color: AppColors.textSecondary),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 10,
      children: [
        icon,
        Text(label, style: _buttonText(AppColors.textPrimary)),
      ],
    ),
  );
}

class _FilledButton extends StatelessWidget {
  const _FilledButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => _Button(
    onPressed: onPressed,
    color: AppColors.brandPrimary,
    child: Center(
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: _buttonText(AppColors.surface),
      ),
    ),
  );
}

/// A borderless 48-high button, as "Continue as guest".
class _TextButton extends StatelessWidget {
  const _TextButton({required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Opacity(
    opacity: onPressed == null ? 0.6 : 1,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 48,
        child: Center(
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: _buttonText(AppColors.textPrimary),
          ),
        ),
      ),
    ),
  );
}

/// As "Back to my food" on the Add food screen.
class _BackLink extends StatelessWidget {
  const _BackLink({required this.label, required this.onTap});

  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.centerLeft,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          spacing: 5,
          children: [
            const Icon(
              LucideIcons.arrowLeft,
              size: 14,
              color: AppColors.brandPrimary,
            ),
            Text(
              label,
              style: AppText.nunito(
                12,
                FontWeight.w800,
                AppColors.brandPrimary,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

/// A text field with its label above, styled as on the Add food screen.
class _Input extends StatelessWidget {
  const _Input({
    required this.label,
    required this.controller,
    this.validator,
    this.keyboardType,
    this.autofillHints,
    this.obscureText = false,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
    this.textCapitalization = TextCapitalization.none,
  });

  final String label;
  final TextEditingController controller;
  final FormFieldValidator<String>? validator;
  final TextInputType? keyboardType;
  final Iterable<String>? autofillHints;
  final bool obscureText;
  final TextInputAction textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      borderSide: BorderSide(color: color),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: AppText.nunito(11, FontWeight.w800, AppColors.textPrimary),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          validator: validator,
          keyboardType: keyboardType,
          autofillHints: autofillHints,
          obscureText: obscureText,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          textCapitalization: textCapitalization,
          cursorColor: AppColors.brandAccent,
          style: AppText.nunito(15, FontWeight.w700, AppColors.textPrimary),
          decoration: InputDecoration(
            errorStyle: AppText.nunito(
              11,
              FontWeight.w600,
              AppColors.statusSoon,
            ),
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            border: border(AppColors.textSecondary),
            enabledBorder: border(AppColors.textSecondary),
            focusedBorder: border(AppColors.brandAccent),
            errorBorder: border(AppColors.statusSoon),
            focusedErrorBorder: border(AppColors.statusSoon),
          ),
        ),
      ],
    );
  }
}
