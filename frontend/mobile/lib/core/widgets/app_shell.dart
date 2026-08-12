import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_motion.dart';
import '../theme/app_radii.dart';
import '../theme/app_spacing.dart';
import '../theme/theme_controller.dart';
import 'app_ambient_background.dart';
import 'app_avatar.dart';
import 'app_brand.dart';
import 'app_loading.dart';
import 'status_badge.dart';

/// A section rendered inside the [AppShell] content area.
class AppShellDestination {
  const AppShellDestination({
    required this.label,
    required this.builder,
  });

  final String label;
  final WidgetBuilder builder;
}

/// Responsive application shell.
///
/// Renders a top bar with the SPORTSGURUKUL brand mark, the active section
/// title, a theme-mode toggle and a profile menu (avatar initials) with
/// profile / settings / change-password / logout actions.
class AppShell extends StatefulWidget {
  const AppShell({
    super.key,
    required this.destinations,
    this.initialIndex = 0,
    this.userName,
    this.userEmail,
    this.userRole,
    this.accountStatus,
    this.onOpenProfile,
    this.onOpenSettings,
    this.onChangePassword,
    this.onLogout,
    this.isLoggingOut = false,
  });

  final List<AppShellDestination> destinations;
  final int initialIndex;

  final String? userName;
  final String? userEmail;
  final String? userRole;
  final String? accountStatus;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onChangePassword;
  final VoidCallback? onLogout;
  final bool isLoggingOut;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final int _index = widget.initialIndex.clamp(
    0,
    widget.destinations.length - 1,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leadingWidth: 72,
        leading: const Padding(
          padding: EdgeInsets.only(left: AppSpacing.xs),
          child: AppBrand(showWordmark: false, tileSize: 44, iconSize: 28),
        ),
        title: Text(widget.destinations[_index].label),
        actions: [
          _ThemeToggleButton(),
          _ProfileMenuButton(shell: this),
        ],
      ),
      body: Stack(
        children: [
          const Positioned.fill(child: AppAmbientBackground()),
          Positioned.fill(
            child: _Content(index: _index, destinations: widget.destinations),
          ),
        ],
      ),
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({required this.index, required this.destinations});

  final int index;
  final List<AppShellDestination> destinations;

  @override
  Widget build(BuildContext context) {
    return IndexedStack(
      index: index,
      children: [for (final d in destinations) d.builder(context)],
    );
  }
}

// ---------------------------------------------------------------------------
// Theme toggle
// ---------------------------------------------------------------------------

class _ThemeToggleButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ThemeController>();
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.xxs),
      child: IconButton(
        onPressed: controller.toggle,
        tooltip: controller.isDark
            ? 'Switch to light mode'
            : 'Switch to dark mode',
        style: IconButton.styleFrom(
          backgroundColor: scheme.surfaceContainerHigh.withValues(alpha: 0.7),
          side: BorderSide(color: scheme.outlineVariant),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.brMedium),
        ),
        icon: AnimatedSwitcher(
          duration: AppMotion.normal,
          transitionBuilder: (child, animation) => ScaleTransition(
            scale: animation,
            child: FadeTransition(opacity: animation, child: child),
          ),
          child: Icon(
            controller.isDark
                ? Icons.light_mode_outlined
                : Icons.dark_mode_outlined,
            key: ValueKey(controller.isDark),
            size: 20,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Profile menu
// ---------------------------------------------------------------------------

class _ProfileMenuButton extends StatelessWidget {
  const _ProfileMenuButton({required this.shell});

  final _AppShellState shell;

  @override
  Widget build(BuildContext context) {
    final name = shell.widget.userName ?? 'User';
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      child: PopupMenuButton<_ProfileAction>(
        tooltip: 'Account menu',
        offset: const Offset(0, 8),
        position: PopupMenuPosition.under,
        onSelected: (action) => _onSelected(context, action),
        itemBuilder: (context) => [
          PopupMenuItem(
            enabled: false,
            child: SizedBox(
              width: 220,
              child: Row(
                children: [
                  AppAvatar(name: name, size: 40),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (shell.widget.userEmail != null)
                          Text(
                            shell.widget.userEmail!,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                        if (shell.widget.accountStatus != null) ...[
                          const SizedBox(height: 6),
                          StatusBadge(status: shell.widget.accountStatus!),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const PopupMenuDivider(),
          if (shell.widget.onOpenProfile != null)
            const PopupMenuItem(
              value: _ProfileAction.profile,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.person_outline),
                title: Text('Profile'),
              ),
            ),
          if (shell.widget.onOpenSettings != null)
            const PopupMenuItem(
              value: _ProfileAction.settings,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.settings_outlined),
                title: Text('Settings'),
              ),
            ),
          if (shell.widget.userRole != null) ...[
            const PopupMenuDivider(),
            PopupMenuItem(
              enabled: false,
              child: Text(
                'Role: ${shell.widget.userRole}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
          const PopupMenuDivider(),
          if (shell.widget.onChangePassword != null)
            const PopupMenuItem(
              value: _ProfileAction.changePassword,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.password_outlined),
                title: Text('Change Password'),
              ),
            ),
          if (shell.widget.onLogout != null)
            PopupMenuItem(
              value: _ProfileAction.logout,
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.logout,
                  color: shell.widget.isLoggingOut
                      ? scheme.onSurfaceVariant
                      : scheme.error,
                ),
                title: shell.widget.isLoggingOut
                    ? const AppLoadingInline(size: 18, strokeWidth: 2)
                    : Text('Logout', style: TextStyle(color: scheme.error)),
              ),
            ),
        ],
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxs),
          child: AppAvatar(name: name, size: 36),
        ),
      ),
    );
  }

  void _onSelected(BuildContext context, _ProfileAction action) {
    switch (action) {
      case _ProfileAction.profile:
        shell.widget.onOpenProfile?.call();
        break;
      case _ProfileAction.settings:
        shell.widget.onOpenSettings?.call();
        break;
      case _ProfileAction.changePassword:
        shell.widget.onChangePassword?.call();
        break;
      case _ProfileAction.logout:
        shell.widget.onLogout?.call();
        break;
    }
  }
}

enum _ProfileAction { profile, settings, changePassword, logout }
