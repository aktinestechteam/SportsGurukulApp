import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/app_button.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/password_field.dart';
import '../widgets/validators.dart';

class ResetPasswordPage extends StatefulWidget {
  const ResetPasswordPage({super.key});

  @override
  State<ResetPasswordPage> createState() => _ResetPasswordPageState();
}

class _ResetPasswordPageState extends State<ResetPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;
  bool _completed = false;

  String? get _token => GoRouterState.of(context).uri.queryParameters['token'];

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.resetPassword(
      token: _token ?? '',
      newPassword: _passwordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _completed = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (_token == null || _token!.isEmpty) {
      return AuthScaffold(
        title: 'Reset Password',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const ErrorBanner(
              message: 'This password reset link is invalid or expired.',
            ),
            AppButton(
              label: 'Back to Sign In',
              onPressed: () => context.go('/sign-in'),
            ),
          ],
        ),
      );
    }

    if (_completed) {
      return AuthScaffold(
        title: 'Password Reset',
        child: _SuccessView(onDone: () => context.go('/sign-in')),
      );
    }

    return AuthScaffold(
      title: 'Reset Password',
      subtitle: 'Choose a new password for your account.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorBanner(message: auth.errorMessage ?? ''),
            PasswordField(
              controller: _passwordController,
              label: 'New Password',
              validator: validatePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),
            PasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              validator: confirmWith(
                () => _passwordController.text,
                field: 'Confirm password',
              ),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Reset Password',
              icon: Icons.lock_reset,
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => context.go('/sign-in'),
              child: const Text('Back to Sign In'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SuccessView extends StatelessWidget {
  const _SuccessView({required this.onDone});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final status = StatusColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 84,
            height: 84,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.successContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle_outline,
              size: 40,
              color: status.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Your password has been reset successfully. Please sign in.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(label: 'Go to Sign In', onPressed: onDone),
      ],
    );
  }
}
