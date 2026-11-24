import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';

import '../../../core/colors.dart';
import '../auth/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  late final AnimationController _ballController;
  late final AnimationController _logoController;
  late final AnimationController _contentController;

  late final Animation<double> _ballYAnimation;
  late final Animation<double> _ballScaleAnimation;
  late final Animation<double> _ballRotationAnimation;

  late final Animation<double> _logoFadeAnimation;
  late final Animation<double> _logoScaleAnimation;

  late final Animation<double> _contentFadeAnimation;
  late final Animation<Offset> _contentSlideAnimation;

  late Timer _navigationTimer;

  @override
  void initState() {
    super.initState();

    // ==========================================
    // SYSTEM UI
    // ==========================================

    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.white,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );

    // ==========================================
    // BOUNCING LOGO CONTROLLER
    // ==========================================

    _ballController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1500,
      ),
    );

    // ==========================================
    // LOGO REVEAL CONTROLLER
    // ==========================================

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 800,
      ),
    );

    // ==========================================
    // TEXT CONTROLLER
    // ==========================================

    _contentController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
    );

    // ==========================================
    // BOUNCE POSITION
    // ==========================================

    _ballYAnimation = TweenSequence<double>(
      [
        // Fall from top
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -220,
            end: 30,
          ).chain(
            CurveTween(
              curve: Curves.easeIn,
            ),
          ),
          weight: 35,
        ),

        // First bounce
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 30,
            end: -70,
          ).chain(
            CurveTween(
              curve: Curves.easeOut,
            ),
          ),
          weight: 15,
        ),

        // Come down
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -70,
            end: 20,
          ).chain(
            CurveTween(
              curve: Curves.easeIn,
            ),
          ),
          weight: 15,
        ),

        // Small bounce
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 20,
            end: -30,
          ).chain(
            CurveTween(
              curve: Curves.easeOut,
            ),
          ),
          weight: 10,
        ),

        // Small drop
        TweenSequenceItem(
          tween: Tween<double>(
            begin: -30,
            end: 8,
          ).chain(
            CurveTween(
              curve: Curves.easeIn,
            ),
          ),
          weight: 10,
        ),

        // Final settle
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 8,
            end: 0,
          ).chain(
            CurveTween(
              curve: Curves.easeOut,
            ),
          ),
          weight: 15,
        ),
      ],
    ).animate(_ballController);

    // ==========================================
    // BOUNCING LOGO SCALE
    // ==========================================

    _ballScaleAnimation = TweenSequence<double>(
      [
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.65,
            end: 1.0,
          ),
          weight: 70,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 1.0,
            end: 0.88,
          ),
          weight: 10,
        ),
        TweenSequenceItem(
          tween: Tween<double>(
            begin: 0.88,
            end: 1.0,
          ),
          weight: 20,
        ),
      ],
    ).animate(
      CurvedAnimation(
        parent: _ballController,
        curve: Curves.easeInOut,
      ),
    );

    // ==========================================
    // BOUNCING LOGO ROTATION
    // ==========================================

    _ballRotationAnimation = Tween<double>(
      begin: -0.15,
      end: 0.15,
    ).animate(
      CurvedAnimation(
        parent: _ballController,
        curve: Curves.easeInOut,
      ),
    );

    // ==========================================
    // MAIN LOGO FADE
    // ==========================================

    _logoFadeAnimation = CurvedAnimation(
      parent: _logoController,
      curve: Curves.easeOut,
    );

    // ==========================================
    // MAIN LOGO SCALE
    // ==========================================

    _logoScaleAnimation = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _logoController,
        curve: Curves.elasticOut,
      ),
    );

    // ==========================================
    // TEXT FADE
    // ==========================================

    _contentFadeAnimation = CurvedAnimation(
      parent: _contentController,
      curve: Curves.easeOut,
    );

    // ==========================================
    // TEXT SLIDE
    // ==========================================

    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _contentController,
        curve: Curves.easeOutCubic,
      ),
    );

    // ==========================================
    // START ANIMATION
    // ==========================================

    _startAnimation();

    // ==========================================
    // NAVIGATE TO LOGIN
    // ==========================================

    _navigationTimer = Timer(
      const Duration(
        milliseconds: 4000,
      ),
      () {
        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (
              context,
              animation,
              secondaryAnimation,
            ) =>
                const LoginScreen(),

            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              return FadeTransition(
                opacity: animation,
                child: child,
              );
            },

            transitionDuration: const Duration(
              milliseconds: 600,
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // ANIMATION SEQUENCE
  // ==========================================

  Future<void> _startAnimation() async {
    // 1. Logo ball falls and bounces
    await _ballController.forward();

    if (!mounted) return;

    // 2. Main logo appears
    await _logoController.forward();

    if (!mounted) return;

    // 3. Text appears
    await _contentController.forward();
  }

  // ==========================================
  // DISPOSE
  // ==========================================

  @override
  void dispose() {
    _navigationTimer.cancel();

    _ballController.dispose();
    _logoController.dispose();
    _contentController.dispose();

    super.dispose();
  }

  // ==========================================
  // BUILD
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      body: Stack(
        children: [
          // ======================================
          // BACKGROUND CIRCLE - TOP RIGHT
          // ======================================

          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(
                  alpha: 0.05,
                ),
              ),
            ),
          ),

          // ======================================
          // BACKGROUND CIRCLE - BOTTOM LEFT
          // ======================================

          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(
                  alpha: 0.04,
                ),
              ),
            ),
          ),

          // ======================================
          // MAIN CONTENT
          // ======================================

          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ==================================
                // BOUNCING APP LOGO
                // ==================================

                AnimatedBuilder(
                  animation: _ballController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        _ballYAnimation.value,
                      ),
                      child: Transform.rotate(
                        angle:
                            _ballRotationAnimation.value,
                        child: Transform.scale(
                          scale:
                              _ballScaleAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },

                  child: Container(
                    width: 72,
                    height: 72,

                    decoration: BoxDecoration(
                      shape: BoxShape.circle,

                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primaryBlue
                              .withValues(
                            alpha: 0.35,
                          ),
                          blurRadius: 25,
                          spreadRadius: 5,
                        ),
                      ],
                    ),

                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.jpg',

                        width: 72,
                        height: 72,

                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 15),

                // ==================================
                // MAIN APP LOGO
                // ==================================

                FadeTransition(
                  opacity: _logoFadeAnimation,

                  child: ScaleTransition(
                    scale: _logoScaleAnimation,

                    child: Container(
                      width: 120,
                      height: 120,

                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(28),

                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primaryBlue
                                .withValues(
                              alpha: 0.25,
                            ),
                            blurRadius: 25,
                            spreadRadius: 3,
                          ),
                        ],
                      ),

                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(28),

                        child: Image.asset(
                          'assets/images/logo.jpg',

                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // ==================================
                // APP NAME + TAGLINE
                // ==================================

                FadeTransition(
                  opacity: _contentFadeAnimation,

                  child: SlideTransition(
                    position:
                        _contentSlideAnimation,

                    child: Column(
                      children: [
                        // APP NAME
                        const Text(
                          'Elite Wave Cabs',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                Color(0xFF1E293B),
                            letterSpacing: 1.0,
                          ),
                        ),

                        const SizedBox(height: 7),

                        // TAGLINE
                        Text(
                          'Anywhere. Anytime.',
                          style: TextStyle(
                            fontSize: 16,
                            color:
                                AppColors.primaryBlue,
                            fontWeight:
                                FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 28),

                        // LOADING DOTS
                        const _LoadingDots(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================================================
// LOADING DOTS
// ==================================================

class _LoadingDots extends StatefulWidget {
  const _LoadingDots();

  @override
  State<_LoadingDots> createState() =>
      _LoadingDotsState();
}

class _LoadingDotsState
    extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 1000,
      ),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,

      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,

          children: List.generate(
            3,
            (index) {
              final double value =
                  (_controller.value +
                          index * 0.2) %
                      1.0;

              final double opacity =
                  0.3 +
                  (0.7 *
                      (1 -
                          (value - 0.5)
                              .abs() *
                              2)
                          .clamp(
                            0.0,
                            1.0,
                          ));

              return Container(
                margin:
                    const EdgeInsets.symmetric(
                  horizontal: 4,
                ),

                width: 7,
                height: 7,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  color: AppColors.primaryBlue
                      .withValues(
                    alpha: opacity,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}