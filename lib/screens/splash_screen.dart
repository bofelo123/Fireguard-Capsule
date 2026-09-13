import 'dart:async';
import 'package:flutter/material.dart';
import 'login_screen.dart';

// ===============================================================
// COLORS
// ===============================================================
class AppColors {
  static const Color bg = Color(0xFF07111F);
  static const Color primaryText = Color(0xFFF5F7FA);
  static const Color secondaryText = Color(0xFF8FA3B8);
  static const Color primary = Color(0xFF4DA3FF);
  static const Color border = Color(0xFF1B3045);
  static const Color cardBg = Color(0xFF0D1B2A);
  static const Color error = Color(0xFFFF4D3D);
}

// ===============================================================
// SPLASH SCREEN
// ===============================================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  Timer? _timer;

  bool _hasError = false;
  bool _isNavigating = false;

  static const Duration splashDuration = Duration(seconds: 4);
  static const Duration transitionDuration =
      Duration(milliseconds: 400);

  @override
  void initState() {
    super.initState();

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOut,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.96,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _fadeController,
        curve: Curves.easeOutCubic,
      ),
    );

    _fadeController.forward();

    _startSplashTimer();
  }

  // =============================================================
  // START SPLASH TIMER
  // =============================================================
  void _startSplashTimer() {
    _timer?.cancel();

    if (mounted) {
      setState(() {
        _hasError = false;
        _isNavigating = false;
      });
    }

    _timer = Timer(
      splashDuration,
      _navigateToWelcome,
    );
  }

  // =============================================================
  // SPLASH → WELCOME
  // =============================================================
  Future<void> _navigateToWelcome() async {
    if (_isNavigating || !mounted) {
      return;
    }

    _isNavigating = true;

    try {
      // ---------------------------------------------------------
      // Future startup checks can be placed here.
      //
      // Example:
      // await AppInitService.initialize();
      // ---------------------------------------------------------

      if (!mounted) {
        return;
      }

      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: transitionDuration,
          pageBuilder: (
            context,
            animation,
            secondaryAnimation,
          ) {
            return const WelcomeScreen();
          },
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
        ),
      );
    } catch (e) {
      if (!mounted) {
        return;
      }

      setState(() {
        _hasError = true;
        _isNavigating = false;
      });
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _fadeController.dispose();
    super.dispose();
  }

  // =============================================================
  // BUILD SPLASH SCREEN
  // =============================================================
  @override
  Widget build(BuildContext context) {
    final double screenWidth =
        MediaQuery.of(context).size.width;

    final bool isMobile = screenWidth < 600;

    final bool isTablet =
        screenWidth >= 600 && screenWidth < 1200;

    final double logoSize = isMobile
        ? 80.0
        : isTablet
            ? 88.0
            : 96.0;

    final double titleSize =
        isMobile ? 28.0 : 32.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Spacer(flex: 3),

                // -------------------------------------------------
                // LOGO
                // -------------------------------------------------
                Container(
                  width: logoSize,
                  height: logoSize,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.border,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Image.asset(
                      'assets/images/fireguard_logo.png',
                      width: logoSize,
                      height: logoSize,
                      fit: BoxFit.contain,
                      errorBuilder: (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return Container(
                          width: logoSize,
                          height: logoSize,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF4DA3FF),
                                Color(0xFF25C281),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius:
                                BorderRadius.circular(20),
                          ),
                          child: Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: logoSize * 0.5,
                          ),
                        );
                      },
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // -------------------------------------------------
                // APP NAME
                // -------------------------------------------------
                Text(
                  'FireGuard',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: titleSize,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryText,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                // -------------------------------------------------
                // SUBTITLE
                // -------------------------------------------------
                const Text(
                  'National Wildfire Protection System',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: AppColors.secondaryText,
                    letterSpacing: 0.2,
                  ),
                ),

                const SizedBox(height: 32),

                // -------------------------------------------------
                // LOADING / ERROR
                // -------------------------------------------------
                _hasError
                    ? _buildErrorState()
                    : _buildLoadingState(),

                const Spacer(flex: 3),

                // -------------------------------------------------
                // FOOTER
                // -------------------------------------------------
                Padding(
                  padding:
                      const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Secure • Government Grade',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppColors.secondaryText
                          .withValues(alpha: 0.5),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =============================================================
  // LOADING STATE
  // =============================================================
  Widget _buildLoadingState() {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
            strokeWidth: 2.2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.primary,
            ),
          ),
        ),
        SizedBox(height: 10),
        Text(
          'Starting FireGuard...',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 11,
            fontWeight: FontWeight.w400,
            color: AppColors.secondaryText,
          ),
        ),
      ],
    );
  }

  // =============================================================
  // ERROR STATE
  // =============================================================
  Widget _buildErrorState() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Text(
          'Unable to start FireGuard',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryText,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 36,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                color: AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
              ),
            ),
            onPressed: _startSplashTimer,
            child: const Text(
              'Retry',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ===============================================================
// WELCOME SCREEN
// ===============================================================
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  // =============================================================
  // WELCOME → LOGIN
  // =============================================================
  void _continueToLogin(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // -------------------------------------------------
              // LOGO
              // -------------------------------------------------
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius:
                      BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.border,
                  ),
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 36,
                ),
              ),

              const SizedBox(height: 16),

              // -------------------------------------------------
              // TITLE
              // -------------------------------------------------
              const Text(
                'Welcome to FireGuard',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryText,
                ),
              ),

              const SizedBox(height: 8),

              // -------------------------------------------------
              // DESCRIPTION
              // -------------------------------------------------
              const Text(
                'National Wildfire Protection System',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 13,
                  color: AppColors.secondaryText,
                ),
              ),

              const SizedBox(height: 24),

              // -------------------------------------------------
              // CONTINUE TO LOGIN
              // -------------------------------------------------
              SizedBox(
                height: 44,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 28,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10),
                    ),
                  ),

                  // IMPORTANT:
                  // This now navigates to LoginScreen.
                  onPressed: () {
                    _continueToLogin(context);
                  },

                  child: const Text(
                    'Continue to Login',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}