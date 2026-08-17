import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../domain/entities/user.dart';
import '../providers/auth_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final isLoggingOut = auth.status == AuthStatus.loggingOut;

    void onChangePassword() => context.push('/change-password');
    void onLogout() => context.read<AuthProvider>().signOut();

    return AppShell(
      destinations: [
        AppShellDestination(
          label: 'Dashboard',
          builder: (context) => _DashboardView(user: user),
        ),
      ],
      userName: user?.fullName,
      userEmail: user?.email,
      userRole: user?.displayRole,
      accountStatus: user?.accountStatus,
      onOpenProfile: () => context.push('/profile'),
      onOpenSettings: () => context.push('/settings'),
      onChangePassword: onChangePassword,
      onLogout: onLogout,
      isLoggingOut: isLoggingOut,
    );
  }
}

// ---------------------------------------------------------------------------
// Dashboard
// ---------------------------------------------------------------------------

class _DashboardView extends StatelessWidget {
  const _DashboardView({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'User';
    final role = user?.displayRole ?? 'User';
    final status = user?.accountStatus ?? 'Active';

    return ColoredBox(
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _WelcomeHero(name: name, role: role, status: status),
                    const SizedBox(height: AppSpacing.xxxl),
                    const _SectionHeader(
                      title: 'Overview',
                      subtitle: 'Your account at a glance',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AccountStats(user: user),
                    const SizedBox(height: AppSpacing.xxxl),
                    const _SectionHeader(
                      title: 'Platform',
                      subtitle: 'Choose how you want to join SPORTS GURUKUL',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    const _PlatformGrid(),
                    const SizedBox(height: AppSpacing.xxxl),
                    const _SectionHeader(
                      title: 'Quick Actions',
                      subtitle: 'Common tasks',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _QuickActions(
                      onChangePassword: () => context.push('/change-password'),
                      onLogout: () => context.read<AuthProvider>().signOut(),
                    ),
                    const SizedBox(height: AppSpacing.xxl),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

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

/// Flat bordered surface. No gradients, no glow, no elevation.
class _FlatPanel extends StatelessWidget {
  const _FlatPanel({required this.child, this.onTap, this.padding});

  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final panel = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: child,
    );
    if (onTap == null) {
      return panel;
    }
    return ClipRRect(
      borderRadius: AppRadii.brMedium,
      child: Material(
        color: Colors.transparent,
        child: InkWell(onTap: onTap, child: panel),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Welcome
// ---------------------------------------------------------------------------

class _WelcomeHero extends StatelessWidget {
  const _WelcomeHero({
    required this.name,
    required this.role,
    required this.status,
  });

  final String name;
  final String role;
  final String status;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'WELCOME,',
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 3.0,
            color: AuthPalette.red,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Align(
          alignment: Alignment.centerLeft,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              name,
              style: GoogleFonts.barlowCondensed(
                fontSize: 40,
                height: 1.0,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AuthPalette.textPrimary(context),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            'Your SPORTS GURUKUL dashboard is ready. Set up your academy, '
            'coaches and athletes from here.',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AuthPalette.subtitle(context),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _InfoPill(dot: AuthPalette.muted(context), label: role),
            _InfoPill(dot: AuthPalette.red, label: status),
          ],
        ),
      ],
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.dot, required this.label});

  final Color dot;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brPill,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AuthPalette.textPrimary(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Account overview
// ---------------------------------------------------------------------------

class _AccountStats extends StatelessWidget {
  const _AccountStats({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final role = user?.displayRole ?? 'User';
    final status = user?.accountStatus ?? 'Active';

    final items = <Widget>[
      _StatCell(
        label: 'DEFAULT ROLE',
        value: role,
        subtitle: 'Assigned by the platform',
        icon: Icons.workspace_premium_outlined,
      ),
      _StatCell(
        label: 'ACCOUNT STATUS',
        value: status,
        subtitle: 'All systems operational',
        icon: Icons.verified_user_outlined,
      ),
      _StatCell(
        label: 'MODULES',
        value: '0',
        subtitle: 'Sports modules coming soon',
        icon: Icons.widgets_outlined,
      ),
    ];

    return AppBreakpoints.isDesktop(context)
        ? Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(width: AppSpacing.lg),
                Expanded(child: items[i]),
              ],
            ],
          )
        : LayoutBuilder(
            builder: (context, constraints) {
              final twoColumns = constraints.maxWidth >= 560;
              return Wrap(
                spacing: AppSpacing.lg,
                runSpacing: AppSpacing.lg,
                children: [
                  for (final item in items)
                    SizedBox(
                      width: twoColumns
                          ? (constraints.maxWidth - AppSpacing.lg) / 2
                          : constraints.maxWidth,
                      child: item,
                    ),
                ],
              );
            },
          );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return _FlatPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: AuthPalette.red),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.6,
                    color: AuthPalette.muted(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: GoogleFonts.barlowCondensed(
                  fontSize: 30,
                  height: 1.0,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                  color: AuthPalette.textPrimary(context),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Divider(
            height: 1,
            thickness: 1,
            color: AuthPalette.divider(context),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AuthPalette.subtitle(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Platform
// ---------------------------------------------------------------------------

class _PlatformGrid extends StatelessWidget {
  const _PlatformGrid();

  static const List<(IconData, String, String, String?)> _options = [
    (
      Icons.school_outlined,
      'Manage Academy',
      'Manage academy profile',
      '/academies',
    ),
    (Icons.groups_outlined, 'Join Academy', 'Join an existing academy', null),
    (Icons.sports_outlined, 'Coach Registration', 'Register as a coach', null),
    (
      Icons.directions_run,
      'Athlete Registration',
      'Register as an athlete',
      null,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 900
            ? 4
            : constraints.maxWidth >= 560
            ? 2
            : 1;
        final itemWidth =
            (constraints.maxWidth - (columns - 1) * AppSpacing.md) / columns;

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final (icon, title, subtitle, route) in _options)
              SizedBox(
                width: itemWidth,
                child: _PlatformTile(
                  icon: icon,
                  title: title,
                  subtitle: subtitle,
                  soon: route == null,
                  onTap: route != null
                      ? () => context.push(route)
                      : () => AppSnackbar.show(
                          context,
                          '$title is coming soon',
                          type: AppFeedbackType.info,
                        ),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _PlatformTile extends StatelessWidget {
  const _PlatformTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.soon,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool soon;

  @override
  Widget build(BuildContext context) {
    return _FlatPanel(
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 22, color: AuthPalette.red),
              if (soon) ...[
                const Spacer(),
                Text(
                  'SOON',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: AuthPalette.muted(context),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: AuthPalette.textPrimary(context),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: AuthPalette.subtitle(context),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onChangePassword, required this.onLogout});

  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[
      _ActionRow(
        icon: Icons.password_outlined,
        title: 'Change Password',
        subtitle: 'Keep your account secure',
        onTap: onChangePassword,
      ),
      _ActionRow(
        icon: Icons.help_outline,
        title: 'Support',
        subtitle: 'Help and documentation',
        onTap: () => AppSnackbar.show(
          context,
          'Support is coming soon',
          type: AppFeedbackType.info,
        ),
      ),
      _ActionRow(
        icon: Icons.logout,
        title: 'Sign Out',
        subtitle: 'End this session',
        onTap: onLogout,
        destructive: true,
      ),
    ];

    return Align(
      alignment: Alignment.centerLeft,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Container(
          decoration: BoxDecoration(
            color: AuthPalette.surface(context),
            borderRadius: AppRadii.brMedium,
            border: Border.all(color: AuthPalette.border(context)),
          ),
          child: ClipRRect(
            borderRadius: AppRadii.brMedium,
            child: Material(
              color: Colors.transparent,
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                        ),
                        child: Divider(
                          height: 1,
                          thickness: 1,
                          color: AuthPalette.divider(context),
                        ),
                      ),
                    rows[i],
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AuthPalette.red),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                      color: destructive
                          ? AuthPalette.red
                          : AuthPalette.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AuthPalette.subtitle(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              size: 20,
              color: AuthPalette.muted(context),
            ),
          ],
        ),
      ),
    );
  }
}
