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
import '../../domain/entities/coach_profile.dart';
import '../../../video/presentation/providers/video_provider.dart';
import '../providers/coach_profile_provider.dart';

class CoachDashboardPage extends StatefulWidget {
  const CoachDashboardPage({super.key});

  @override
  State<CoachDashboardPage> createState() => _CoachDashboardPageState();
}

class _CoachDashboardPageState extends State<CoachDashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<CoachProfileProvider>().loadProfile();
        context.read<VideoProvider>().loadUnreadCount();
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
    final profileState = context.watch<CoachProfileProvider>();

    return ColoredBox(
      color: AuthPalette.bg(context),
      child: Column(
        children: [
          Container(height: 3, color: AuthPalette.red),
          Expanded(
            child: _buildContent(context, profileState),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, CoachProfileProvider state) {
    if (state.status == CoachProfileStatus.loading) {
      return const Center(child: AppLoading(label: 'Loading your dashboard...'));
    }

    if (state.status == CoachProfileStatus.error) {
      return AppErrorState(
        title: 'Could not load dashboard',
        message: state.errorMessage,
        onRetry: () => context.read<CoachProfileProvider>().loadProfile(),
      );
    }

    final profile = state.profile;
    if (profile == null) {
      return const AppEmptyState(
        icon: Icons.sports_outlined,
        title: 'No data available',
        subtitle: 'Your coach profile data could not be loaded.',
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

  final CoachProfile profile;
  final User? user;

  static List<CalendarScheduleSlot> _buildCalendarSlots(
    List<CoachBatchInfo> batches,
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
          athletesCount: batch.athletesCount,
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

  @override
  Widget build(BuildContext context) {
    final totalSessions = profile.batches.fold<int>(
      0,
      (sum, b) => sum + b.slots.length,
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
              athletes: profile.athletes.length,
              sessions: totalSessions,
            ),
            const SizedBox(height: AppSpacing.xxxl),
            AppSectionHeader(
              title: 'Athlete Videos',
              subtitle: 'Review clips, leave feedback and voice notes',
            ),
            const SizedBox(height: AppSpacing.md),
            _VideoEntryCard(
              unreadCount: context.watch<VideoProvider>().unreadCount,
            ),
            const SizedBox(height: AppSpacing.xxxl),
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
                subtitle: '${profile.batches.length} ${profile.batches.length == 1 ? 'batch' : 'batches'} you are assigned to',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final batch in profile.batches) ...[
                _BatchCard(batch: batch),
                const SizedBox(height: AppSpacing.md),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
            if (profile.athletes.isNotEmpty) ...[
              AppSectionHeader(
                title: 'My Athletes',
                subtitle: '${profile.athletes.length} ${profile.athletes.length == 1 ? 'athlete' : 'athletes'} mapped to you',
              ),
              const SizedBox(height: AppSpacing.md),
              for (final athlete in profile.athletes) ...[
                _AthleteTile(athlete: athlete),
                const SizedBox(height: AppSpacing.sm),
              ],
              const SizedBox(height: AppSpacing.xxxl),
            ],
            AppSectionHeader(
              title: 'My Schedule',
              subtitle: 'Sessions across all your batches',
            ),
            const SizedBox(height: AppSpacing.md),
            // Responsive height: enough room for the month calendar + a few
            // timeline sessions without dominating the page on smaller screens.
            BatchScheduleCalendar(
              slots: _buildCalendarSlots(profile.batches),
              role: UserRole.coach,
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
    required this.athletes,
    required this.sessions,
  });

  final int batches;
  final int athletes;
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
            icon: Icons.people_outline,
            label: 'Athletes',
            value: '$athletes',
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

  final CoachProfile profile;
  final User? user;

  @override
  Widget build(BuildContext context) {
    final name = profile.fullName.isNotEmpty ? profile.fullName : (user?.fullName ?? 'Coach');
    final email = profile.email.isNotEmpty ? profile.email : (user?.email ?? '');
    final role = user?.displayRole ?? 'Coach';
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
// Athlete Videos
// ---------------------------------------------------------------------------

class _VideoEntryCard extends StatelessWidget {
  const _VideoEntryCard({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/coach/videos'),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          color: AuthPalette.surface(context),
          borderRadius: AppRadii.brMedium,
          border: Border.all(color: AuthPalette.border(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AuthPalette.red.withValues(alpha: 0.1),
                borderRadius: AppRadii.brMedium,
              ),
              child: const Icon(Icons.videocam_outlined, color: AuthPalette.red, size: 22),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review athlete videos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AuthPalette.textPrimary(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'View new uploads and leave text or voice-note feedback.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.3,
                      color: AuthPalette.subtitle(context),
                    ),
                  ),
                ],
              ),
            ),
            if (unreadCount > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              _UnreadBadge(count: unreadCount),
              const SizedBox(width: AppSpacing.xs),
            ],
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 22, color: AuthPalette.muted(context)),
          ],
        ),
      ),
    );
  }
}

class _UnreadBadge extends StatelessWidget {
  const _UnreadBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AuthPalette.red,
        borderRadius: AppRadii.brPill,
      ),
      child: Text(
        '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 1 — My Academies
// ---------------------------------------------------------------------------

class _AcademyCard extends StatelessWidget {
  const _AcademyCard({required this.academy});

  final CoachAcademyInfo academy;

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
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
          if (academy.sports.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final sport in academy.sports)
                  AppBadge(
                    label: sport.display,
                    icon: Icons.emoji_events_outlined,
                    compact: true,
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section 2 — My Batches
// ---------------------------------------------------------------------------

class _BatchCard extends StatelessWidget {
  const _BatchCard({required this.batch});

  final CoachBatchInfo batch;

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
                AppBadge(
                  label: '${batch.athletesCount} ${batch.athletesCount == 1 ? 'athlete' : 'athletes'}',
                  icon: Icons.people_outline,
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
// Batch details bottom sheet
// ---------------------------------------------------------------------------

class _BatchDetailsSheet extends StatelessWidget {
  const _BatchDetailsSheet({required this.batch});

  final CoachBatchInfo batch;

  @override
  Widget build(BuildContext context) {
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AuthPalette.textPrimary(context),
                        ),
                      ),
                      if (batch.academyName.isNotEmpty)
                        Text(
                          batch.academyName,
                          style: TextStyle(
                            fontSize: 13,
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
                AppBadge(
                  label: '${batch.athletesCount} athletes',
                  icon: Icons.people_outline,
                  compact: true,
                ),
                if (batch.coaches.isNotEmpty)
                  AppBadge(
                    label: '${batch.coaches.length} ${batch.coaches.length == 1 ? 'coach' : 'coaches'}',
                    icon: Icons.person_outline,
                    compact: true,
                  ),
              ],
            ),
            if (batch.slots.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(height: 1, color: AuthPalette.border(context)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'SCHEDULE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AuthPalette.muted(context),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              for (final slot in batch.slots)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: AuthPalette.muted(context)),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          slot.display,
                          style: TextStyle(
                            fontSize: 13,
                            color: AuthPalette.textPrimary(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
            if (batch.athletes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Divider(height: 1, color: AuthPalette.border(context)),
              const SizedBox(height: AppSpacing.md),
              Text(
                'ATHLETES (${batch.athletes.length})',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.6,
                  color: AuthPalette.muted(context),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 200),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: batch.athletes.length,
                  itemBuilder: (context, index) {
                    final athlete = batch.athletes[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 14,
                            backgroundColor: AuthPalette.red.withValues(alpha: 0.1),
                            child: Text(
                              _initials(athlete.fullName),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AuthPalette.red,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  athlete.fullName,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AuthPalette.textPrimary(context),
                                  ),
                                ),
                                if (athlete.sport != null && athlete.sport!.isNotEmpty)
                                  Text(
                                    athlete.sport!,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AuthPalette.subtitle(context),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
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
// Section 3 — My Athletes
// ---------------------------------------------------------------------------

class _AthleteTile extends StatelessWidget {
  const _AthleteTile({required this.athlete});

  final CoachAthleteInfo athlete;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showAthleteSheet(context),
      borderRadius: AppRadii.brMedium,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          color: AuthPalette.surface(context),
          borderRadius: AppRadii.brMedium,
          border: Border.all(color: AuthPalette.border(context)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AuthPalette.red.withValues(alpha: 0.1),
              child: Text(
                _initials(athlete.fullName),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AuthPalette.red,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    athlete.fullName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AuthPalette.textPrimary(context),
                    ),
                  ),
                  if (athlete.sport != null)
                    Text(
                      athlete.sport!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AuthPalette.subtitle(context),
                      ),
                    ),
                ],
              ),
            ),
            if (athlete.batchName != null)
              Flexible(
                child: AppBadge(
                  label: athlete.batchName!,
                  compact: true,
                ),
              ),
            const SizedBox(width: AppSpacing.xs),
            Icon(
              Icons.chevron_right,
              size: 18,
              color: AuthPalette.muted(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showAthleteSheet(BuildContext context) {
    AppBottomSheet.show(
      context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            AppSpacing.xxl,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AuthPalette.red.withValues(alpha: 0.1),
                    child: Text(
                      _initials(athlete.fullName),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AuthPalette.red,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          athlete.fullName,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (athlete.sport != null)
                          Text(
                            athlete.sport!,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.lg),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              if (athlete.batchName != null)
                _DetailRow(label: 'Batch', value: athlete.batchName!),
              if (athlete.email != null && athlete.email!.isNotEmpty)
                _DetailRow(label: 'Email', value: athlete.email!),
              if (athlete.mobileNumber != null && athlete.mobileNumber!.isNotEmpty)
                _DetailRow(label: 'Phone', value: athlete.mobileNumber!),
              if (athlete.sport != null)
                _DetailRow(label: 'Sport', value: athlete.sport!),
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String fullName) {
    final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AuthPalette.muted(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AuthPalette.textPrimary(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}