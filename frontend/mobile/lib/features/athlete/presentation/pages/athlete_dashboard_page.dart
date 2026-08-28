import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/batch_schedule_calendar.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';

class AthleteDashboardPage extends StatelessWidget {
  const AthleteDashboardPage({super.key});

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
          builder: (context) => _AthleteDashboardView(user: user),
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

class _AthleteDashboardView extends StatelessWidget {
  const _AthleteDashboardView({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = user?.fullName ?? 'Athlete';
    final role = user?.displayRole ?? 'Athlete';
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
                      subtitle: 'Your athlete dashboard at a glance',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _AccountStats(user: user),
                    const SizedBox(height: AppSpacing.xxxl),
                    const _SectionHeader(
                      title: 'Quick Actions',
                      subtitle: 'Manage your account',
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _QuickActions(
                      onChangePassword: () => context.push('/change-password'),
                      onLogout: () => context.read<AuthProvider>().signOut(),
                    ),
                    const SizedBox(height: AppSpacing.xxxl),
                    AppSectionHeader(
                      title: 'My Schedule',
                      subtitle: 'Your training sessions',
                    ),
                    const SizedBox(height: AppSpacing.md),
                    BatchScheduleCalendar(
                        slots: const [],
                        role: UserRole.athlete,
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

class _FlatPanel extends StatelessWidget {
  const _FlatPanel({required this.child, this.padding});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: child,
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
            'Your athlete dashboard is ready. View your training schedule, '
            'track progress and stay connected with your coaches.',
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

class _AccountStats extends StatelessWidget {
  const _AccountStats({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final role = user?.displayRole ?? 'Athlete';
    final status = user?.accountStatus ?? 'Active';

    final items = <Widget>[
      _StatCell(
        label: 'ROLE',
        value: role,
        subtitle: 'Your assigned role',
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
