import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../core/theme/app_theme.dart';
import '../core/theme/theme_controller.dart';
import 'dependencies.dart';
import 'router.dart';

class SportsGurukulApp extends StatefulWidget {
  const SportsGurukulApp({super.key});

  @override
  State<SportsGurukulApp> createState() => _SportsGurukulAppState();
}

class _SportsGurukulAppState extends State<SportsGurukulApp> {
  late final GoRouter _router = AppRouter.create();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: Dependencies.authProvider),
        ChangeNotifierProvider.value(value: Dependencies.academyProvider),
        ChangeNotifierProvider.value(value: Dependencies.coachProvider),
        ChangeNotifierProvider(create: (_) => ThemeController()),
      ],
      child: Consumer<ThemeController>(
        builder: (context, themeController, _) {
          return MaterialApp.router(
            title: 'SPORTSGURUKUL',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeController.mode,
            builder: (context, child) {
              return MediaQuery.withClampedTextScaling(
                minScaleFactor: 0.85,
                maxScaleFactor: 1.5,
                child: child ?? const SizedBox.shrink(),
              );
            },
            routerConfig: _router,
          );
        },
      ),
    );
  }
}
