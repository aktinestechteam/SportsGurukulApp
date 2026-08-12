import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/app_ambient_background.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_profile.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../providers/auth_provider.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isLoggingOut = auth.status == AuthStatus.loggingOut;

    void onChangePassword() => context.push('/change-password');
    void onLogout() => context.read<AuthProvider>().signOut();

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: SingleChildScrollView(
              padding: AppBreakpoints.horizontalPadding(
                context,
              ).add(const EdgeInsets.symmetric(vertical: AppSpacing.xl)),
              child: AppBreakpoints.constrain(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      AppSectionHeader(
                        title: 'Profile',
                        subtitle: 'Your personal information',
                      ),
                      AppCard(
                        padding: const EdgeInsets.all(AppSpacing.xl),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AppProfileHeader(
                              name: user?.fullName ?? 'User',
                              subtitle: user?.displayRole ?? 'User',
                              email: user?.email,
                              accountStatus: user == null ||
                                      user.accountStatus.isEmpty
                                  ? null
                                  : user.accountStatus,
                              avatarSize: 72,
                            ),
                            const Padding(
                              padding: EdgeInsets.symmetric(
                                vertical: AppSpacing.lg,
                              ),
                              child: Divider(),
                            ),
                            AppInfoRow(
                              label: 'Full Name',
                              value: user?.fullName ?? 'User',
                              icon: Icons.badge_outlined,
                            ),
                            AppInfoRow(
                              label: 'Email Address',
                              value: user?.email ?? '',
                              icon: Icons.mail_outline,
                            ),
                            AppInfoRow(
                              label: 'Mobile Number',
                              value: user?.mobileNumber ?? '',
                              icon: Icons.phone_outlined,
                            ),
                            AppInfoRow(
                              label: 'Default Role',
                              value: user?.displayRole ?? 'User',
                              icon: Icons.workspace_premium_outlined,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Change Password',
                              variant: AppButtonVariant.outlined,
                              icon: Icons.password_outlined,
                              onPressed: onChangePassword,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: AppButton(
                              label: 'Sign Out',
                              variant: AppButtonVariant.destructive,
                              icon: Icons.logout,
                              loading: isLoggingOut,
                              onPressed: onLogout,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
