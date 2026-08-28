import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_breakpoints.dart';
import '../../../../core/theme/app_radii.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/app_badge.dart';
import '../../../../core/widgets/app_bottom_sheet.dart';
import '../../../../core/widgets/app_empty_state.dart';
import '../../../../core/widgets/app_error_state.dart';
import '../../../../core/widgets/app_loading.dart';
import '../../../../core/widgets/app_section_header.dart';
import '../../../../core/widgets/app_shell.dart';
import '../../../../core/widgets/batch_schedule_calendar.dart';
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/athlete_profile.dart';
import '../providers/athlete_profile_provider.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) => '${_months[d.month - 1]} ${d.day}, ${d.year}';

class AthleteDashboardPage extends StatefulWidget {
  const AthleteDashboardPage({super.key});

  @override
  State<AthleteDashboardPage> createState() => _AthleteDashboardPageState();
}

class _AthleteDashboardPageState extends State<AthleteDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AthleteProfileProvider>().loadProfile();
      }
    });
  }

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
          builder: (context) => _DashboardBody(user: user),
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
// Dashboard body — handles loading / error / loaded states
// ---------------------------------------------------------------------------

class _DashboardBody extends StatelessWidget {
  const _DashboardBody({this.user});

  final User? user;

  @override
  Widget build(BuildContext context) {
    final profileState = context.watch<AthleteProfileProvider>();

    return ColoredBox(
      color: AuthPalette.bg(context),
      child: Column(
        children: [
          Container(height: 3, color: AuthPalette.red),
          Expanded(child: _buildContent(context, profileState)),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, AthleteProfileProvider state) {
    if (state.status == AthleteProfileStatus.loading) {
      return const Center(child: AppLoading(label: 'Loading your dashboard...'));
    }

    if (state.status == AthleteProfileStatus.error) {
      return AppErrorState(
        title: 'Could not load dashboard',
        message: state.errorMessage,
        onRetry: () => context.read<AthleteProfileProvider>().loadProfile(),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const AppEmptyState(
        icon: Icons.sports_outlined,
        title: 'No data available',
        subtitle: 'Your athlete profile data could not be loaded.',
      );
    }

    return _LoadedDashboard(profile: profile, user: user);
  }
}

// ---------------------------------------------------------------------------
// Loaded dashboard with all sections
// ---------------------------------------------------------------------------

class _LoadedDashboard extends StatelessWidget {
  const _LoadedDashboard({required this.profile, this.user});

  final AthleteProfile profile;
  final User? user;

  static List<CalendarScheduleSlot> _buildCalendarSlots(
    List<AthleteBatchInfo> batches,
  ) {
    final slots = <CalendarScheduleSlot>[];
    for (final batch in batches) {
      for (final slot in batch.slots) {
        slots.add(CalendarScheduleSlot(
          batchId: batch.batchId,
          batchName: batch.name,
          sportName: batch.sportName,
          startTime: slot.startTime,
          endTime: slot.endTime,
          location: slot.location,
          athletesCount: 0,
          coachName: batch.coaches
              .map((c) => c.fullName)
              .where((n) => n.isNotEmpty)
              .join(', '),
          startDate: batch.startDate,
          endDate: batch.endDate,
        ));
      }
    }
    return slots;
  }

  static Map<String, List<AthleteCoachInfo>> _groupCoachesBySport(
    List<AthleteBatchInfo> batches,
  ) {
    final groups = <String, Map<String, AthleteCoachInfo>>{};
    for (final batch in batches) {
      final sport = batch.sportName != null && batch.sportName!.trim().isNotEmpty
          ? batch.sportName!
          : 'General';
      final coaches = groups.putIfAbsent(sport, () => <String, AthleteCoachInfo>{});
      for (final coach in batch.coaches) {
        coaches.putIfAbsent(coach.coachId, () => coach);
      }
    }
    final result = <String, List<AthleteCoachInfo>>{};
    groups.forEach((sport, coaches) => result[sport] = coaches.values.toList());
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final totalSessions = profile.batches.fold<int>(
      0,
      (sum, b) => sum + b.slots.length,
    );
    final coachesBySport = _groupCoachesBySport(profile.batches);
    final totalCoaches = coachesBySport.values.fold<int>(
      0,
      (sum, coaches) => sum + coaches.length,
    );

    return SingleChildScrollView(
      padding: AppBreakpoints.horizontalPadding(context).add(
        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      ),
      child: AppBreakpoints.constrain(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(profile: profile, user: user),
            const SizedBox(height: AppSpacing.xl),
            _QuickStats(
              batches: profile.batches.length,
              sports: profile.sports.length,
              sessions: totalSessions,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            if (profile.sports.isNotEmpty) ...[
              AppSectionHeader(
                title: 'My Sports',
                subtitle: '${profile.sports.length} ${profile.sports.length == 1 ? 'sport' : 'sports'} you are enrolled in',
              ),
              const SizedBox(height: AppSpacing.md),
              Align(
                alignment: Alignment.centerLeft,
                child: Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final sport in profile.sports)
                      AppBadge(
                        label: sport.name,
                        icon: Icons.sports_outlined,
                        compact: true,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xxxl),
            ],
            if (coachesBySport.isNotEmpty) ...[
              AppSectionHeader(
                title: 'My Coaches',
                subtitle: '$totalCoaches ${totalCoaches == 1 ? 'coach' : 'coaches'} across ${coachesBySport.length} ${coachesBySport.length == 1 ? 'sport' : 'sports'}',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final entry in coachesBySport.entries) ...[
                _SportCoachGroup(sport: entry.key, coaches: entry.value),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
            if (profile.academies.isNotEmpty) ...[
              AppSectionHeader(
                title: 'My Academies',
                subtitle: '${profile.academies.length} ${profile.academies.length == 1 ? 'academy' : 'academies'} you belong to',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final academy in profile.academies) ...[
                _AcademyCard(academy: academy),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
            if (profile.batches.isNotEmpty) ...[
              AppSectionHeader(
                title: 'My Batches',
                subtitle: '${profile.batches.length} ${profile.batches.length == 1 ? 'batch' : 'batches'} you are enrolled in',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final batch in profile.batches) ...[
                _BatchCard(batch: batch),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
            AppSectionHeader(
              title: 'My Schedule',
              subtitle: 'Sessions across all your batches',
            ),
            const SizedBox(height: AppSpacing.md),
            BatchScheduleCalendar(
              slots: _buildCalendarSlots(profile.batches),
              role: UserRole.athlete,
              onSessionTap: (slot) {
                final batch = profile.batches.firstWhere(
                  (b) => b.batchId == slot.batchId,
                  orElse: () => profile.batches.first,
                );
                AppBottomSheet.show(
                  context,
                  builder: (_) => _BatchDetailsSheet(batch: batch),
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header
// ---------------------------------------------------------------------------

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.batches,
    required this.sports,
    required this.sessions,
  });

  final int batches;
  final int sports;
  final int sessions;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.group_outlined,
            label: 'Batches',
            value: '$batches',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.sports_outlined,
            label: 'Sports',
            value: '$sports',
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _StatTile(
            icon: Icons.event_outlined,
            label: 'Sessions',
            value: '$sessions',
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AuthPalette.red),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AuthPalette.textPrimary(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: AuthPalette.muted(context),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.profile, this.user});

  final AthleteProfile profile;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.isNotEmpty ? profile.fullName : (user?.fullName ?? 'Athlete');
    final email = profile.email.isNotEmpty ? profile.email : (user?.email ?? '');
    final role = user?.displayRole ?? 'Athlete';
    final status = user?.accountStatus ?? 'Active';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
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
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 13,
                        color: AuthPalette.subtitle(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            _InfoPill(dot: AuthPalette.muted(context), label: role),
            _InfoPill(dot: AuthPalette.red, label: status),
            _InfoPill(
              dot: AuthPalette.muted(context),
              label: '${profile.academies.length} ${profile.academies.length == 1 ? 'Academy' : 'Academies'}',
            ),
            _InfoPill(
              dot: AuthPalette.muted(context),
              label: '${profile.batches.length} ${profile.batches.length == 1 ? 'Batch' : 'Batches'}',
            ),
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
// Section 1 — My Academies
// ---------------------------------------------------------------------------

class _AcademyCard extends StatelessWidget {
  const _AcademyCard({required this.academy});

  final AthleteAcademyInfo academy;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Row(
        children: [
          Icon(Icons.school_outlined, size: 20, color: AuthPalette.red),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              academy.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AuthPalette.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// My Coaches — grouped by sport
// ---------------------------------------------------------------------------

class _SportCoachGroup extends StatelessWidget {
  const _SportCoachGroup({
    required this.sport,
    required this.coaches,
  });

  final String sport;
  final List<AthleteCoachInfo> coaches;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(color: AuthPalette.border(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.sports_outlined, size: 20, color: AuthPalette.red),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  sport,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AuthPalette.textPrimary(context),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              AppBadge(
                label: '${coaches.length} ${coaches.length == 1 ? 'coach' : 'coaches'}',
                icon: Icons.person_outline,
                compact: true,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final coach in coaches) ...[
            Divider(height: 1, color: AuthPalette.divider(context)),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AuthPalette.red.withValues(alpha: 0.1),
                    child: Text(
                      _initials(coach.fullName),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AuthPalette.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      coach.fullName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AuthPalette.textPrimary(context),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  AppBadge(
                    label: 'Coach',
                    icon: Icons.person_pin_outlined,
                    compact: true,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

String _initials(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}

// ---------------------------------------------------------------------------
// Section 2 — My Batches
// ---------------------------------------------------------------------------

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final AthleteBatchInfo batch;

  void _openDetails(BuildContext context) {
    AppBottomSheet.show(
      context,
      builder: (_) => _BatchDetailsSheet(batch: batch),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openDetails(context),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AuthPalette.surface(context),
          borderRadius: AppRadii.brMedium,
          border: Border.all(color: AuthPalette.border(context)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.group_outlined, size: 20, color: AuthPalette.red),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AuthPalette.textPrimary(context),
                        ),
                      ),
                      if (batch.academyName.isNotEmpty)
                        Text(
                          batch.academyName,
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
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (batch.sportName != null)
                  AppBadge(
                    label: batch.sportName!,
                    icon: Icons.sports_outlined,
                    compact: true,
                  ),
                if (batch.coaches.isNotEmpty) ...[
                  AppBadge(
                    label: 'Coach',
                    icon: Icons.person_outline,
                    compact: true,
                  ),
                  AppBadge(
                    label: batch.coaches
                        .map((c) => c.fullName)
                        .where((n) => n.isNotEmpty)
                        .join(', '),
                    compact: true,
                  ),
                ],
                if (batch.slots.isNotEmpty)
                  AppBadge(
                    label: '${batch.slots.length} ${batch.slots.length == 1 ? 'session' : 'sessions'}',
                    icon: Icons.event_outlined,
                    compact: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Batch details bottom sheet (athlete view — no other-athlete information)
// ---------------------------------------------------------------------------

class _BatchDetailsSheet extends StatelessWidget {
  const _BatchDetailsSheet({required this.batch});

  final AthleteBatchInfo batch;

  @override
  Widget build(BuildContext context) {
    final coaches = batch.coaches
        .map((c) => c.fullName)
        .where((n) => n.isNotEmpty)
        .toList();

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Container(
                  width: 4,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AuthPalette.red,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        batch.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AuthPalette.textPrimary(context),
                        ),
                      ),
                      if (batch.academyName.isNotEmpty)
                        Text(
                          batch.academyName,
                          style: TextStyle(
                            fontSize: 12,
                            color: AuthPalette.subtitle(context),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                if (batch.sportName != null)
                  AppBadge(
                    label: batch.sportName!,
                    icon: Icons.sports_outlined,
                    compact: true,
                  ),
                if (coaches.isNotEmpty) ...[
                  AppBadge(
                    label: 'Coach',
                    icon: Icons.person_outline,
                    compact: true,
                  ),
                  AppBadge(
                    label: coaches.join(', '),
                    compact: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (batch.startDate != null && batch.endDate != null) ...[
              Divider(height: 1, color: AuthPalette.border(context)),
              const SizedBox(height: AppSpacing.md),
              _InfoRow(
                icon: Icons.date_range_outlined,
                text:
                    '${_formatDate(batch.startDate!)} – ${_formatDate(batch.endDate!)}',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            if (batch.slots.isNotEmpty) ...[
              Divider(height: 1, color: AuthPalette.border(context)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'WEEKLY SCHEDULE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: AuthPalette.muted(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final slot in batch.slots)
                _InfoRow(
                  icon: Icons.access_time,
                  text: slot.display,
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: AuthPalette.muted(context)),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12.5,
                color: AuthPalette.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}