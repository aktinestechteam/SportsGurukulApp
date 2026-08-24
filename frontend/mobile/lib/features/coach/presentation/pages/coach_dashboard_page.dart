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
import '../../../authentication/domain/entities/user.dart';
import '../../../authentication/presentation/providers/auth_provider.dart';
import '../../domain/entities/coach_profile.dart';
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

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: AppBreakpoints.horizontalPadding(context).add(
        const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
      ),
      child: AppBreakpoints.constrain(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHeader(profile: profile, user: user),
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
            const AppSectionHeader(
              title: 'My Weekly Schedule',
              subtitle: 'Sessions across all your batches',
            ),
            const SizedBox(height: AppSpacing.md),
            _WeeklySchedule(batches: profile.batches),
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
              if (batch.allowCoachBatchEdit)
                IconButton(
                  tooltip: 'Edit Batch',
                  onPressed: () {
                    context.push(
                      '/academies/${batch.academyId}/batches/${batch.batchId}/edit',
                      extra: batch,
                    );
                  },
                  icon: Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AuthPalette.red,
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
                label: '${batch.athletesCount} ${batch.athletesCount == 1 ? 'athlete' : 'athletes'}',
                icon: Icons.people_outline,
                compact: true,
              ),
            ],
          ),
          if (batch.slots.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Schedule',
              style: TextStyle(
                fontSize: 11,
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
          if (batch.coaches.length > 1) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'Other Coaches',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.6,
                color: AuthPalette.muted(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final peer in batch.coaches)
                  AppBadge(
                    label: peer.fullName,
                    icon: Icons.person_outline,
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
              AppBadge(
                label: athlete.batchName!,
                compact: true,
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

// ---------------------------------------------------------------------------
// Section 4 — My Weekly Schedule
// ---------------------------------------------------------------------------

class _WeeklySchedule extends StatelessWidget {
  const _WeeklySchedule({required this.batches});

  final List<CoachBatchInfo> batches;

  @override
  Widget build(BuildContext context) {
    const dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const dayValues = [1, 2, 3, 4, 5, 6, 0];
    const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    final now = DateTime.now();
    final todayDow = now.weekday % 7;

    final sessionsByDay = <int, List<_ScheduleSession>>{};
    for (var i = 0; i < 7; i++) {
      sessionsByDay[dayValues[i]] = [];
    }
    for (final batch in batches) {
      for (final slot in batch.slots) {
        sessionsByDay[slot.dayOfWeek]?.add(_ScheduleSession(
          batch: batch,
          slot: slot,
        ));
      }
    }

    return Column(
      children: [
        for (var dayIndex = 0; dayIndex < 7; dayIndex++) ...[
          if (dayIndex > 0) const SizedBox(height: AppSpacing.sm),
          _DayScheduleSection(
            dayName: dayNames[dayIndex],
            dayShort: dayShort[dayIndex],
            sessions: sessionsByDay[dayValues[dayIndex]] ?? [],
            isToday: dayValues[dayIndex] == todayDow,
          ),
        ],
      ],
    );
  }
}

class _ScheduleSession {
  const _ScheduleSession({required this.batch, required this.slot});

  final CoachBatchInfo batch;
  final CoachBatchSlot slot;
}

class _DayScheduleSection extends StatefulWidget {
  const _DayScheduleSection({
    required this.dayName,
    required this.dayShort,
    required this.sessions,
    required this.isToday,
  });

  final String dayName;
  final String dayShort;
  final List<_ScheduleSession> sessions;
  final bool isToday;

  @override
  State<_DayScheduleSection> createState() => _DayScheduleSectionState();
}

class _DayScheduleSectionState extends State<_DayScheduleSection> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AuthPalette.surface(context),
        borderRadius: AppRadii.brMedium,
        border: Border.all(
          color: widget.isToday ? AuthPalette.red : AuthPalette.border(context),
          width: widget.isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: widget.isToday
                  ? AuthPalette.red.withValues(alpha: 0.06)
                  : AuthPalette.bg(context),
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(AppRadii.medium),
              ),
            ),
            child: Row(
              children: [
                Text(
                  widget.dayShort.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                    color: widget.isToday ? AuthPalette.red : AuthPalette.muted(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  widget.dayName,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AuthPalette.textPrimary(context),
                  ),
                ),
                const Spacer(),
                if (widget.sessions.isNotEmpty)
                  AppBadge(
                    label: '${widget.sessions.length} ${widget.sessions.length == 1 ? 'session' : 'sessions'}',
                    compact: true,
                  )
                else
                  Text(
                    'No sessions',
                    style: TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AuthPalette.muted(context),
                    ),
                  ),
              ],
            ),
          ),
          if (widget.sessions.isNotEmpty)
            Divider(height: 1, thickness: 1, color: AuthPalette.border(context)),
          if (widget.sessions.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.lg,
              ),
              child: Text(
                'Rest day',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AuthPalette.muted(context),
                ),
              ),
            )
          else
            for (var i = 0; i < widget.sessions.length; i++) ...[
              if (i > 0)
                Divider(height: 1, thickness: 0.5, color: AuthPalette.border(context)),
              _ExpandableSessionCard(session: widget.sessions[i]),
            ],
        ],
      ),
    );
  }
}

class _ExpandableSessionCard extends StatefulWidget {
  const _ExpandableSessionCard({required this.session});

  final _ScheduleSession session;

  @override
  State<_ExpandableSessionCard> createState() => _ExpandableSessionCardState();
}

class _ExpandableSessionCardState extends State<_ExpandableSessionCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final slot = widget.session.slot;
    final batch = widget.session.batch;

    return Column(
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 4,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AuthPalette.red,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            batch.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AuthPalette.textPrimary(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${slot.startTime} – ${slot.endTime}',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AuthPalette.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    _AthleteCountChip(count: batch.athletesCount),
                    const SizedBox(width: AppSpacing.sm),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: Icon(
                        Icons.expand_more,
                        size: 20,
                        color: AuthPalette.muted(context),
                      ),
                    ),
                  ],
                ),
                if (slot.location != null && slot.location!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: AuthPalette.muted(context)),
                        const SizedBox(width: 4),
                        Text(
                          slot.location!,
                          style: TextStyle(
                            fontSize: 12,
                            color: AuthPalette.subtitle(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: AppSpacing.xs),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: Wrap(
                    spacing: AppSpacing.xs,
                    runSpacing: AppSpacing.xs,
                    children: [
                      if (batch.sportName != null)
                        AppBadge(
                          label: batch.sportName!,
                          icon: Icons.sports_outlined,
                          compact: true,
                        ),
                      if (batch.coaches.length > 1)
                        AppBadge(
                          label: '${batch.coaches.length} coaches',
                          icon: Icons.group_outlined,
                          compact: true,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: _ExpandedAthleteList(
            batch: batch,
          ),
          crossFadeState: _expanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 200),
        ),
      ],
    );
  }
}

class _AthleteCountChip extends StatelessWidget {
  const _AthleteCountChip({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AuthPalette.red.withValues(alpha: 0.08),
        borderRadius: AppRadii.brPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.people_outline, size: 13, color: AuthPalette.red),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: AuthPalette.red,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandedAthleteList extends StatelessWidget {
  const _ExpandedAthleteList({required this.batch});

  final CoachBatchInfo batch;

  @override
  Widget build(BuildContext context) {
    final athletes = batch.athletes;

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        0,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(height: 1, thickness: 0.5, color: AuthPalette.border(context)),
          const SizedBox(height: AppSpacing.md),
          Text(
            'ATHLETES IN THIS BATCH',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
              color: AuthPalette.muted(context),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (athletes.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
              child: Text(
                'No athletes assigned to this batch yet.',
                style: TextStyle(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: AuthPalette.muted(context),
                ),
              ),
            )
          else
            for (final athlete in athletes)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: AuthPalette.red.withValues(alpha: 0.1),
                      child: Text(
                        _initialsStatic(athlete.fullName),
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
              ),
          if (batch.coaches.length > 1) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'CO-COACHES',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
                color: AuthPalette.muted(context),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                for (final coach in batch.coaches)
                  AppBadge(
                    label: coach.fullName,
                    icon: Icons.person_outline,
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

String _initialsStatic(String fullName) {
  final parts = fullName.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'.toUpperCase();
}
