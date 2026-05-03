import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/auth_providers.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  // Stage 1 — logo scales + fades in (0.0 → 0.45)
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;

  // Stage 2 — app name fades in (0.3 → 0.55)
  late final Animation<double> _nameOpacity;

  // Stage 3 — tagline slides up + fades in (0.5 → 0.72)
  late final Animation<double> _taglineOpacity;
  late final Animation<Offset> _taglineSlide;

  bool _navigated = false;
  bool _animationDone = false;
  bool _authResolved = false;

  @override
  void initState() {
    super.initState();

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    _logoScale = Tween(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );

    _logoOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );

    _nameOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.3, 0.55, curve: Curves.easeOut),
      ),
    );

    _taglineOpacity = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 0.72, curve: Curves.easeOut),
      ),
    );

    _taglineSlide = Tween(
      begin: const Offset(0, 0.6),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: const Interval(0.5, 0.72, curve: Curves.easeOut),
      ),
    );

    // Animation done — mark and try navigate
    _ctrl.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _animationDone = true;
        _tryNavigate();
      }
    });

    _ctrl.forward();

    // Auth resolved — mark and try navigate
    // Check immediately in case auth is already resolved
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final current = ref.read(authStateProvider);
      if (!current.isLoading) {
        _authResolved = true;
        _tryNavigate();
      }
      ref.listenManual(authStateProvider, (prev, next) {
        if (!next.isLoading) {
          _authResolved = true;
          _tryNavigate();
        }
      });
    });
  }

  /// Only navigates when BOTH animation is done AND auth is resolved.
  void _tryNavigate() {
    if (!_animationDone || !_authResolved) return;
    _navigate();
  }

  void _navigate() {
    if (_navigated || !mounted) return;
    _navigated = true;
    _checkFirstLaunch();
  }

  Future<void> _checkFirstLaunch() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenWelcome = prefs.getBool('has_seen_welcome') ?? false;
    
    if (!mounted) return;
    
    final authState = ref.read(authStateProvider);
    final isAuthenticated = authState.value != null;
    
    if (!hasSeenWelcome && !isAuthenticated) {
      context.go('/welcome');
    } else {
      context.go(isAuthenticated ? '/home' : '/login');
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (context, child) {
        return Scaffold(
          backgroundColor: AppColors.primary,
          body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Logo — scale bounce + fade in
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoOpacity,
                      child: Hero(
                        tag: 'repayiq_logo',
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(26),
                          child: Image.asset(
                            'assets/images/logo_light.png',
                            width: 116,
                            height: 116,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // App name — separate fade, slightly after logo
                  FadeTransition(
                    opacity: _nameOpacity,
                    child: const Text(
                      'RepayIQ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Tagline — slides up last
                  SlideTransition(
                    position: _taglineSlide,
                    child: FadeTransition(
                      opacity: _taglineOpacity,
                      child: const Text(
                        'Repay smarter, live better.',
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
