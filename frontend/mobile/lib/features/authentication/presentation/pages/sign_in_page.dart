import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/password_field.dart';
import '../widgets/validators.dart';

class SignInPage extends StatefulWidget {
  const SignInPage({super.key});

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final auth = context.read<AuthProvider>();
    auth.clearError();
    await auth.signIn(
      email: _emailController.text,
      password: _passwordController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final isLoading = auth.status == AuthStatus.authenticating;

    return AuthScaffold(
      title: 'Welcome back',
      subtitle: 'Sign in to continue to SPORTS GURUKUL',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorBanner(message: auth.errorMessage ?? ''),
            AppTextField(
              controller: _emailController,
              label: 'Email',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [
                AutofillHints.username,
                AutofillHints.email,
              ],
              validator: validateEmail,
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _passwordController,
              validator: validateRequired,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => context.push('/forgot-password'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(
                    'Forgot password?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AuthPalette.red,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            AppButton(
              label: 'Sign In',
              loading: isLoading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: Divider(color: AuthPalette.divider(context)),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'NEW HERE?',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                      color: AuthPalette.muted(context),
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: AuthPalette.divider(context)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    "Don't have an account?",
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: AuthPalette.subtitle(context),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: GestureDetector(
                    onTap: () => context.push('/sign-up'),
                    child: Text(
                      'Create account',
                      textAlign: TextAlign.left,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AuthPalette.red,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}