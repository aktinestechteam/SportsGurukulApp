import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/validators.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitted = false;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final success = await auth.forgotPassword(_emailController.text);
    if (!mounted) {
      return;
    }
    setState(() {
      _loading = false;
      _submitted = success;
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      title: 'Forgot Password',
      subtitle: _submitted
          ? null
          : 'Enter your email and we will send you a reset link.',
      child: _submitted
          ? _buildSuccess(context)
          : Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ErrorBanner(message: auth.errorMessage ?? ''),
                  AppTextField(
                    controller: _emailController,
                    label: 'Email',
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    validator: validateEmail,
                  ),
                  const SizedBox(height: 12),
                  AppButton(
                    label: 'Send Reset Link',
                    loading: _loading,
                    onPressed: _submit,
                  ),
                  const SizedBox(height: 18),
                  Center(
                    child: GestureDetector(
                      onTap: () => context.go('/sign-in'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          'Back to sign in',
                          style: TextStyle(
                            fontSize: 12,
                            color: AuthPalette.subtitle(context),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSuccess(BuildContext context) {
    final status = StatusColors.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: status.successContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.mark_email_read_outlined,
              size: 32,
              color: status.success,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'If an account exists for this email, password reset instructions have been sent.',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AuthPalette.muted(context),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        AppButton(
          label: 'Back to Sign In',
          onPressed: () => context.go('/sign-in'),
        ),
      ],
    );
  }
}
