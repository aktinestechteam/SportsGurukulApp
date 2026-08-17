import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/theme/app_motion.dart';
import '../../../../core/theme/auth_palette.dart';
import '../../../../core/widgets/sports_gurukul_wordmark.dart';
import '../providers/auth_provider.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: AppMotion.slow,
  );

  @override
  void initState() {
    super.initState();
    _controller.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<AuthProvider>().initialize();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ColoredBox(
        color: Theme.of(context).colorScheme.surface,
        child: Stack(
          children: [
            SafeArea(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0, 0.6, curve: Curves.easeOut),
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 0.92, end: 1).animate(
                          CurvedAnimation(
                            parent: _controller,
                            curve: const Interval(
                              0,
                              0.7,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                        ),
                        child: const SportsGurukulWordmark(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _controller,
                        curve: const Interval(0.2, 0.8, curve: Curves.easeOut),
                      ),
                      child: Text(
                        'TRAIN  ·  COMPETE  ·  EXCEL',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 3.0,
                          color: AuthPalette.muted(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 48,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _controller,
                  curve: const Interval(0.5, 1.0, curve: Curves.easeOut),
                ),
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AuthPalette.red,
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