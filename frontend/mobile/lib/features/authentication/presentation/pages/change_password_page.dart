import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../providers/auth_provider.dart';
import '../widgets/auth_scaffold.dart';
import '../widgets/error_banner.dart';
import '../widgets/password_field.dart';
import '../widgets/validators.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
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
    final success = await auth.changePassword(
      currentPassword: _currentPasswordController.text,
      newPassword: _newPasswordController.text,
      confirmPassword: _confirmPasswordController.text,
    );
    if (!mounted) {
      return;
    }
    setState(() => _loading = false);

    if (success) {
      AppSnackbar.show(
        context,
        'Password changed. Please sign in again.',
        type: AppFeedbackType.success,
      );
      context.go('/sign-in');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return AuthScaffold(
      title: 'Change Password',
      subtitle: 'Update your account password.',
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ErrorBanner(message: auth.errorMessage ?? ''),
            PasswordField(
              controller: _currentPasswordController,
              label: 'Current Password',
              validator: validateRequired,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.password],
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _newPasswordController,
              label: 'New Password',
              validator: validatePassword,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 12),
            PasswordField(
              controller: _confirmPasswordController,
              label: 'Confirm New Password',
              validator: confirmWith(
                () => _newPasswordController.text,
                field: 'Confirm password',
              ),
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.newPassword],
            ),
            const SizedBox(height: 12),
            AppButton(
              label: 'Change Password',
              loading: _loading,
              onPressed: _submit,
            ),
            const SizedBox(height: 18),
            Center(
              child: GestureDetector(
                onTap: () => context.go('/home'),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Cancel',
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
}
