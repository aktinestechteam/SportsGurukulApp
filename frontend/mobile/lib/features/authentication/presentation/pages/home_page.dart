import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_theme_extensions.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../core/widgets/app_stat_card.dart';
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
    final name = user?.firstName ?? 'there';
    final role = user?.displayRole ?? 'User';
    final status = user?.accountStatus ?? 'Active';

    return SingleChildScrollView(
      padding: AppBreakpoints.horizontalPadding(
        context,
      ).add(const EdgeInsets.symmetric(vertical: AppSpacing.xl)),
      child: AppBreakpoints.constrain(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _WelcomeHero(name: name, role: role, status: status),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(
              title: 'Overview',
              subtitle: 'Your account at a glance',
            ),
            _AccountStats(user: user),
            const SizedBox(height: AppSpacing.xxl),
            AppSectionHeader(
              title: 'Platform',
              subtitle: 'Choose how you want to join SPORTS GURUKUL',
            ),
            const _PlatformGrid(),
            const SizedBox(height: AppSpacing.xl),
            AppSectionHeader(title: 'Quick Actions', subtitle: 'Common tasks'),
            _QuickActions(
              onChangePassword: () => context.push('/change-password'),
              onLogout: () => context.read<AuthProvider>().signOut(),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

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
    final isDesktop = AppBreakpoints.isDesktop(context);

    return AppCard(
      variant: AppCardVariant.brand,
      padding: EdgeInsets.all(isDesktop ? AppSpacing.xxl : AppSpacing.xl),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 72),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Welcome, $name',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppColors.onBrand,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your SPORTS GURUKUL dashboard is ready.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.onBrand.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppBadge(
                      label: role,
                      backgroundColor: AppColors.onBrand.withValues(
                        alpha: 0.16,
                      ),
                      foregroundColor: AppColors.onBrand,
                      icon: Icons.workspace_premium_outlined,
                    ),
                    AppBadge(
                      label: status,
                      backgroundColor: AppColors.onBrand.withValues(
                        alpha: 0.16,
                      ),
                      foregroundColor: AppColors.onBrand,
                      icon: Icons.check_circle_outline,
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.onBrand.withValues(alpha: 0.12),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.onBrand.withValues(alpha: 0.18),
                ),
              ),
              child: Icon(
                Icons.insights_outlined,
                size: 28,
                color: AppColors.onBrand.withValues(alpha: 0.9),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountStats extends StatelessWidget {
  const _AccountStats({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final role = user?.displayRole ?? 'User';
    final status = user?.accountStatus ?? 'Active';
    final statusColors = StatusColors.of(context);

    final items = <Widget>[
      AppStatCard(
        label: 'Default Role',
        value: role,
        icon: Icons.workspace_premium_outlined,
        subtitle: 'Assigned by the platform',
      ),
      AppStatCard(
        label: 'Account Status',
        value: status,
        icon: Icons.verified_user_outlined,
        accent: statusColors.success,
        subtitle: 'All systems operational',
      ),
      AppStatCard(
        label: 'Modules',
        value: '0',
        icon: Icons.widgets_outlined,
        subtitle: 'Sports modules coming soon',
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

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onChangePassword, required this.onLogout});

  final VoidCallback onChangePassword;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 700;
        final actions = <Widget>[
          _ActionTile(
            icon: Icons.password_outlined,
            title: 'Change Password',
            subtitle: 'Keep your account secure',
            onTap: onChangePassword,
          ),
          _ActionTile(
            icon: Icons.help_outline,
            title: 'Support',
            subtitle: 'Help and documentation',
            onTap: null,
          ),
          _ActionTile(
            icon: Icons.logout,
            title: 'Sign Out',
            subtitle: 'End this session',
            onTap: onLogout,
          ),
        ];

        return Wrap(
          spacing: AppSpacing.md,
          runSpacing: AppSpacing.md,
          children: [
            for (final action in actions)
              SizedBox(
                width: isWide
                    ? (constraints.maxWidth - 2 * AppSpacing.md) / 3
                    : constraints.maxWidth,
                child: action,
              ),
          ],
        );
      },
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      variant: AppCardVariant.interactive,
      padding: const EdgeInsets.all(AppSpacing.lg),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: AppRadii.brMedium,
            ),
            child: Icon(
              icon,
              size: 22,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: onTap == null
                ? Theme.of(context).colorScheme.outline
                : Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
  }
}

class _PlatformGrid extends StatelessWidget {
  const _PlatformGrid();

  static const List<(IconData, String, String, String?)> _options = [
    (
      Icons.school_outlined,
      'Register Academy',
      'Set up a new academy profile',
      null,
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
    final scheme = Theme.of(context).colorScheme;
    final brand = BrandColors.of(context);

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
                child: AppCard(
                  variant: AppCardVariant.interactive,
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  onTap: route != null
                      ? () => context.push(route)
                      : () => AppSnackbar.show(
                          context,
                          '$title is coming soon',
                          type: AppFeedbackType.info,
                        ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          gradient: brand.subtleGradient,
                          borderRadius: AppRadii.brMedium,
                          border: Border.all(
                            color: scheme.primary.withValues(alpha: 0.14),
                          ),
                        ),
                        child: Icon(icon, size: 22, color: scheme.primary),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              title,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: AppSpacing.xs),
                            Text(
                              subtitle,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: scheme.outline,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
