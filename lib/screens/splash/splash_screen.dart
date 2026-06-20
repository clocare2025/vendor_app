import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../auth/login_screen.dart';
import '../onboarding/onboarding_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ── Logo: scale + fade in ──────────────────────────────────────────────────
  late final AnimationController _logoCtrl;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;

  // ── Text: slide up + fade ─────────────────────────────────────────────────
  late final AnimationController _textCtrl;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;

  // ── Loading bar: animated fill ────────────────────────────────────────────
  late final AnimationController _barCtrl;
  late final Animation<double> _barValue;

  // ── Glow pulse on logo ────────────────────────────────────────────────────
  late final AnimationController _glowCtrl;
  late final Animation<double> _glowAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _logoScale = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _logoCtrl, curve: const Interval(0.0, 0.5)));

    _textCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _textCtrl, curve: Curves.easeIn));
    _textSlide = Tween<Offset>(
            begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textCtrl, curve: Curves.easeOutCubic));

    _barCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1800));
    _barValue = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(parent: _barCtrl, curve: Curves.easeInOut));

    _glowCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat(reverse: true);
    _glowAnim = Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: _glowCtrl, curve: Curves.easeInOut));

    // Sequence: logo → text → loading bar
    _logoCtrl.forward().then((_) {
      _textCtrl.forward();
      _barCtrl.forward();
    });

    _init();
  }

  Future<void> _init() async {
    final auth = context.read<AuthProvider>();
    await auth.checkAuthStatus();
    if (auth.isAuthenticated) await auth.getProfile();
    // Minimum splash time of 2.4 s for branding
    await Future.delayed(const Duration(milliseconds: 2400));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder:         (ctx, anim, secondary) => auth.isAuthenticated
            ? vendorLandingScreen(auth.vendor)
            : const LoginScreen(),
        transitionsBuilder:  (ctx, anim, secondary, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  void dispose() {
    _logoCtrl.dispose();
    _textCtrl.dispose();
    _barCtrl.dispose();
    _glowCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(gradient: AppColors.headerGradient),
        child: Stack(
          children: [
            // ── Decorative background circles ────────────────────────────
            Positioned(
              top: -size.width * 0.3,
              right: -size.width * 0.25,
              child: AnimatedBuilder(
                animation: _glowAnim,
                builder: (_, _) => Container(
                  width: size.width * 0.75,
                  height: size.width * 0.75,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white
                        .withAlpha((_glowAnim.value * 12).round()),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -size.width * 0.2,
              left: -size.width * 0.2,
              child: Container(
                width: size.width * 0.6,
                height: size.width * 0.6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withAlpha(8),
                ),
              ),
            ),

            // ── Main content ─────────────────────────────────────────────
            SafeArea(
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  // Logo
                  ScaleTransition(
                    scale: _logoScale,
                    child: FadeTransition(
                      opacity: _logoFade,
                      child: AnimatedBuilder(
                        animation: _glowAnim,
                        builder: (_, child) => Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(22),
                            borderRadius: BorderRadius.circular(34),
                            border: Border.all(
                                color: Colors.white.withAlpha(70), width: 1.5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(50),
                                blurRadius: 40,
                                spreadRadius: 2,
                                offset: const Offset(0, 12),
                              ),
                              BoxShadow(
                                color: Colors.white.withAlpha(
                                    (_glowAnim.value * 30).round()),
                                blurRadius: 60,
                                spreadRadius: 4,
                              ),
                            ],
                          ),
                          child: child,
                        ),
                        child: const Icon(
                          Icons.local_laundry_service_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Brand name + tagline
                  SlideTransition(
                    position: _textSlide,
                    child: FadeTransition(
                      opacity: _textFade,
                      child: Column(
                        children: [
                          const Text(
                            'Spinovo',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withAlpha(18),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withAlpha(45)),
                            ),
                            child: Text(
                              'V E N D O R  P A R T N E R',
                              style: TextStyle(
                                color: Colors.white.withAlpha(210),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Animated loading bar + status text
                  FadeTransition(
                    opacity: _textFade,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 48),
                      child: Column(
                        children: [
                          // Progress bar
                          AnimatedBuilder(
                            animation: _barValue,
                            builder: (_, _) => ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: _barValue.value,
                                minHeight: 4,
                                backgroundColor:
                                    Colors.white.withAlpha(35),
                                valueColor:
                                    const AlwaysStoppedAnimation<Color>(
                                        Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          AnimatedBuilder(
                            animation: _barValue,
                            builder: (_, _) {
                              final pct =
                                  (_barValue.value * 100).round();
                              final msg = pct < 40
                                  ? 'Initialising...'
                                  : pct < 80
                                      ? 'Loading your workspace...'
                                      : 'Almost ready...';
                              return Text(
                                msg,
                                style: TextStyle(
                                  color: Colors.white.withAlpha(160),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Version tag at very bottom
                  FadeTransition(
                    opacity: _textFade,
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        'v1.0.0',
                        style: TextStyle(
                          color: Colors.white.withAlpha(80),
                          fontSize: 11,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
