import 'dart:async';
import 'dart:math' as math;

import 'package:material_ui/material_ui.dart';
import 'package:flutter/services.dart';
import 'package:pin_code_fields/pin_code_fields.dart';

import '../../../core/colors.dart';
import '../home/home_screen.dart';

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    this.phoneNumber = '+91 63826 81458',
  });

  final String phoneNumber;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> with TickerProviderStateMixin {
  // ============================================================
  // OTP
  // ============================================================

  final PinInputController _otpController = PinInputController();

  String _enteredOtp = '';
  bool _isVerifying = false;
  bool _isNavigating = false;

  String? _errorMessage;

  // ============================================================
  // RESEND
  // ============================================================

  Timer? _resendTimer;

  int _resendSeconds = 30;

  bool get _canResend => _resendSeconds <= 0;

  // ============================================================
  // ANIMATIONS
  // ============================================================

  late final AnimationController _entranceController;
  late final AnimationController _iconController;
  late final AnimationController _pulseController;
  late final AnimationController _buttonController;
  late final AnimationController _shakeController;

  late final Animation<double> _fadeAnimation;
  late final Animation<Offset> _slideAnimation;
  late final Animation<double> _iconScaleAnimation;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.18),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _iconScaleAnimation = Tween<double>(
      begin: 0.65,
      end: 1.0,
    ).animate(
      CurvedAnimation(
        parent: _iconController,
        curve: Curves.easeOutBack,
      ),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);

    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _entranceController.forward();

    Future.delayed(
      const Duration(milliseconds: 120),
      () {
        if (mounted) {
          _iconController.forward();
        }
      },
    );

    _startResendTimer();
  }

  // ============================================================
  // RESEND TIMER
  // ============================================================

  void _startResendTimer() {
    _resendTimer?.cancel();

    if (mounted) {
      setState(() {
        _resendSeconds = 30;
      });
    }

    _resendTimer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendSeconds <= 1) {
          timer.cancel();

          setState(() {
            _resendSeconds = 0;
          });
        } else {
          setState(() {
            _resendSeconds--;
          });
        }
      },
    );
  }

  // ============================================================
  // OTP CHANGE
  // ============================================================

  void _onOtpChanged(String value) {
    final otp = value.trim();

    setState(() {
      _enteredOtp = otp;

      if (_errorMessage != null) {
        _errorMessage = null;
      }
    });

    // Auto verify when 6 digits are entered.
    if (otp.length == 6 && !_isVerifying && !_isNavigating) {
      Future.delayed(
        const Duration(milliseconds: 150),
        () {
          if (mounted && !_isVerifying && !_isNavigating) {
            _verifyOtp(otp);
          }
        },
      );
    }
  }

  // ============================================================
  // VERIFY OTP
  // ============================================================

  Future<void> _verifyOtp([String? value]) async {
    if (_isVerifying || _isNavigating) {
      return;
    }

    final otp = (value ?? _otpController.text).trim();

    // Check 6 digits.
    if (otp.length != 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit OTP.';
      });

      _shakeController.forward(from: 0);
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
    });

    final verified = otp == '123456';

    if (!verified) {
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Invalid OTP. Please enter the correct OTP.';
      });

      _shakeController.forward(from: 0);

      return;
    }

    setState(() {
      _isVerifying = false;
      _isNavigating = true;
    });

    await Future.delayed(
      const Duration(milliseconds: 300),
    );

    if (!mounted) {
      return;
    }

    // ==========================================================
    // IMPORTANT:
    // OTP SUCCESS -> HOME SCREEN
    // ==========================================================

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const HomeScreen(),
      ),
    );
  }

  // ============================================================
  // RESEND OTP
  // ============================================================

  Future<void> _resendOtp() async {
    if (!_canResend || _isVerifying || _isNavigating) {
      return;
    }

    _otpController.clear();

    setState(() {
      _errorMessage = null;
    });

    _startResendTimer();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'A new OTP has been sent.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // 3D ICON
  // ============================================================

  Widget _build3DIcon() {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _iconController,
        _pulseController,
      ]),
      builder: (context, child) {
        final pulse = _pulseController.value;

        final scale = _iconScaleAnimation.value * (0.97 + (pulse * 0.03));

        final rotateY = math.sin(
              pulse * math.pi * 2,
            ) *
            0.035;

        final rotateX = math.sin(
              pulse * math.pi * 2,
            ) *
            0.018;

        final matrix = Matrix4.identity();

        matrix.setEntry(
          3,
          2,
          0.0012,
        );

        matrix.rotateX(rotateX);
        matrix.rotateY(rotateY);

        matrix.scaleByDouble(
          scale,
          scale,
          scale,
          1.0,
        );

        return Transform(
          alignment: Alignment.center,
          transform: matrix,
          child: child,
        );
      },
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Outer glow
            Container(
              width: 116,
              height: 116,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(
                  alpha: 0.06,
                ),
              ),
            ),

            // Middle glow
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue.withValues(
                  alpha: 0.10,
                ),
              ),
            ),

            // Main icon
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primaryBlue,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(
                      alpha: 0.30,
                    ),
                    blurRadius: 22,
                    spreadRadius: 3,
                  ),
                ],
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: Colors.white,
                size: 32,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // OTP FIELD
  // ============================================================

  Widget _buildOtpField() {
    final hasError = _errorMessage != null;

    return AnimatedBuilder(
      animation: _shakeController,
      builder: (context, child) {
        final value = _shakeController.value;

        final offset = math.sin(
              value * math.pi * 6,
            ) *
            (1.0 - value) *
            8.0;

        return Transform.translate(
          offset: Offset(offset, 0),
          child: child,
        );
      },
      child: MaterialPinField(
        length: 6,
        pinController: _otpController,
        autoFocus: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        obscureText: false,
        onChanged: _onOtpChanged,
        onCompleted: (value) {
          if (!_isVerifying && !_isNavigating) {
            _verifyOtp(value);
          }
        },
        theme: MaterialPinTheme(
          shape: MaterialPinShape.outlined,
          cellSize: const Size(
            43,
            55,
          ),
          spacing: 7,
          borderRadius: BorderRadius.circular(12),
          borderWidth: 1.5,
          focusedBorderWidth: 2.0,
          borderColor: hasError ? Colors.red : Colors.grey.shade300,
          focusedBorderColor: hasError ? Colors.red : AppColors.primaryBlue,
          filledBorderColor: hasError ? Colors.red : AppColors.primaryBlue,
          fillColor: Colors.white,
          focusedFillColor: hasError
              ? Colors.red.withValues(
                  alpha: 0.04,
                )
              : Colors.white,
          filledFillColor: hasError
              ? Colors.red.withValues(
                  alpha: 0.05,
                )
              : AppColors.primaryLight,
          textStyle: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          entryAnimation: MaterialPinAnimation.scale,
          animationDuration: const Duration(
            milliseconds: 180,
          ),
          animationCurve: Curves.easeOut,
        ),
      ),
    );
  }

  // ============================================================
  // ERROR MESSAGE
  // ============================================================

  Widget _buildErrorMessage() {
    if (_errorMessage == null) {
      return const SizedBox(
        height: 24,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(
        top: 10,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Colors.red,
            size: 17,
          ),
          const SizedBox(
            width: 6,
          ),
          Flexible(
            child: Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.red,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // RESEND BUTTON
  // ============================================================

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _canResend ? _resendOtp : null,
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
          ),
          children: [
            const TextSpan(
              text: "Didn't receive the code?  ",
            ),
            TextSpan(
              text:
                  _canResend ? 'Resend OTP' : 'Resend OTP ($_resendSeconds s)',
              style: TextStyle(
                color: _canResend ? AppColors.primaryBlue : Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // VERIFY BUTTON
  // ============================================================

  Widget _buildVerifyButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        final pulse = 1.0 + (_buttonController.value * 0.012);

        return Transform.scale(
          scale: _isVerifying || _isNavigating ? 1.0 : pulse,
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 56,
        child: ElevatedButton(
          onPressed: (_isVerifying || _isNavigating || _enteredOtp.length != 6)
              ? null
              : () => _verifyOtp(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryBlue,
            foregroundColor: Colors.white,
            elevation: 6,
            shadowColor: AppColors.primaryBlue.withValues(
              alpha: 0.30,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(
              milliseconds: 200,
            ),
            child: _isVerifying || _isNavigating
                ? const SizedBox(
                    key: ValueKey(
                      'loading',
                    ),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Row(
                    key: ValueKey(
                      'verify',
                    ),
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Verify OTP',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      Icon(
                        Icons.arrow_forward_rounded,
                        size: 21,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'OTP Verification',
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: SlideTransition(
              position: _slideAnimation,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(
                    height: 5,
                  ),

                  // 3D ICON
                  _build3DIcon(),

                  const SizedBox(
                    height: 28,
                  ),

                  // TITLE
                  const Text(
                    'Enter Verification Code',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 23,
                      fontWeight: FontWeight.w700,
                    ),
                  ),

                  const SizedBox(
                    height: 8,
                  ),

                  const Text(
                    'Enter the 6-digit code sent to you',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    widget.phoneNumber,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),

                  const SizedBox(
                    height: 38,
                  ),

                  // OTP FIELD
                  _buildOtpField(),

                  // ERROR
                  _buildErrorMessage(),

                  const SizedBox(
                    height: 12,
                  ),

                  // RESEND
                  _buildResendButton(),

                  const SizedBox(
                    height: 30,
                  ),

                  // VERIFY
                  _buildVerifyButton(),

                  const SizedBox(
                    height: 20,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _resendTimer?.cancel();

    _entranceController.dispose();
    _iconController.dispose();
    _pulseController.dispose();
    _buttonController.dispose();
    _shakeController.dispose();

    _otpController.dispose();

    super.dispose();
  }
}
