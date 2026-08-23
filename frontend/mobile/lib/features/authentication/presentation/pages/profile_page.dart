import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_avatar.dart';
import '../../../../core/widgets/app_button.dart';
import '../../domain/entities/user.dart';
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
      body: ColoredBox(
        color: AuthPalette.bg(context),
        child: Column(
          children: [
            Container(height: 3, color: AuthPalette.red),
            Expanded(
              child: SingleChildScrollView(
                padding: AppBreakpoints.horizontalPadding(context).add(
                  const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
                ),
                child: AppBreakpoints.constrain(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 720),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _SectionHeader(
                          title: 'Profile',
                          subtitle: 'Your personal information',
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        _ProfilePanel(user: user),
                        const SizedBox(height: AppSpacing.lg),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: 'Change Password',
                                variant: AppButtonVariant.primary,
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
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.subtitle});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              title.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 2.0,
                color: AuthPalette.textPrimary(context),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Divider(
                height: 1,
                thickness: 1,
                color: AuthPalette.divider(context),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle!,
            style: TextStyle(
              fontSize: 12.5,
              color: AuthPalette.subtitle(context),
            ),
          ),
        ],
      ],
    );
  }
}

class _ProfilePanel extends StatelessWidget {
  const _ProfilePanel({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'User';
    final role = user?.displayRole ?? 'User';
    final email = user?.email ?? '';
    final mobile = user?.mobileNumber ?? '';
    final status =
        (user?.accountStatus ?? '').isEmpty ? null : user?.accountStatus;

    return Container(
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppAvatar(name: name, size: 72),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.barlowCondensed(
                        fontSize: 30,
                        height: 1.05,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                        color: AuthPalette.textPrimary(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AuthPalette.red,
                      ),
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        email,
                        style: TextStyle(
                          fontSize: 12,
                          color: AuthPalette.subtitle(context),
                        ),
                      ),
                    ],
                    if (status != null) ...[
                      const SizedBox(height: AppSpacing.sm),
                      _StatusPill(label: status),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: Divider(
              height: 1,
              thickness: 1,
              color: AuthPalette.lightDivider,
            ),
          ),
          _InfoRow(
            label: 'Full Name',
            value: name,
            icon: Icons.badge_outlined,
          ),
          _InfoRow(
            label: 'Email Address',
            value: email,
            icon: Icons.mail_outline,
          ),
          _InfoRow(
            label: 'Mobile Number',
            value: mobile,
            icon: Icons.phone_outlined,
          ),
          _InfoRow(
            label: 'Default Role',
            value: role,
            icon: Icons.workspace_premium_outlined,
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: AppRadii.brPill,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: AuthPalette.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AuthPalette.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AuthPalette.red),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                    color: AuthPalette.muted(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AuthPalette.textPrimary(context),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
