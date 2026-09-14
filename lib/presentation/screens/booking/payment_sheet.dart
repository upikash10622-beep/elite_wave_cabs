// ignore_for_file: deprecated_member_use

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../booking/searching_driver_screen.dart';
import '../../../core/colors.dart';

class PaymentSheet extends StatefulWidget {
  final double fare;
  final String vehicle;
  final double distanceKm;
  final double durationMinutes;
  final String pickup;
  final String destination;

  const PaymentSheet({
    super.key,
    required this.fare,
    required this.vehicle,
    required this.distanceKm,
    required this.durationMinutes,
    required this.pickup,
    required this.destination,
  });

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet>
    with TickerProviderStateMixin {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cash default
  int _selectedPayment = 2;

  // Myself default
  int _selectedBooking = 1;

  bool _isBooking = false;

  late AnimationController _entranceController;
  late AnimationController _buttonController;

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _buttonController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
      lowerBound: 0.94,
      upperBound: 1.0,
      value: 1.0,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _entranceController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: Curves.easeOutCubic,
      ),
    );

    _entranceController.forward();
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // FARE
  // ------------------------------------------------------------

  double get _finalFare => widget.fare;

  String get _paymentMethod {
    switch (_selectedPayment) {
      case 1:
        return 'Elite Wallet';
      case 2:
        return 'Cash';
      default:
        return 'Cash';
    }
  }

  String get _bookingFor {
    switch (_selectedBooking) {
      case 1:
        return 'Myself';
      case 2:
        return 'Someone Else';
      default:
        return 'Myself';
    }
  }

  String _formatFare(double amount) {
    return '₹${amount.toStringAsFixed(0)}';
  }

  // ------------------------------------------------------------
  // TEXT STYLE
  // ------------------------------------------------------------

  TextStyle _text({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color? color,
  }) {
    return TextStyle(
      fontSize: size,
      fontWeight: weight,
      color: color ?? Colors.black87,
      fontFamily: 'Roboto',
    );
  }

  // ------------------------------------------------------------
  // ERROR
  // ------------------------------------------------------------

  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: _text(
            size: 13,
            weight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOK RIDE - TEMPORARY TEST VERSION
  // ------------------------------------------------------------

  Future<void> _bookRide() async {
    if (_isBooking) {
      debugPrint('⚠️ BOOKING ALREADY IN PROGRESS');
      return;
    }

    debugPrint('🔥 CONFIRM BOOKING CLICKED');

    // ----------------------------------------------------------
    // TEMPORARY USER
    // ----------------------------------------------------------

    final User? authUser = _auth.currentUser;

    final String testUserId = authUser?.uid ?? 'temporary_test_user_001';

    final String testEmail = authUser?.email ?? 'test@example.com';

    final String testPhone = authUser?.phoneNumber ?? '0000000000';
    
    final String userName =
    authUser?.displayName?.trim().isNotEmpty == true
        ? authUser!.displayName!.trim()
        : 'Customer';

    debugPrint('====================================');
    debugPrint('👤 TEMPORARY USER CHECK');
    debugPrint('====================================');
    debugPrint('Auth User : ${authUser != null}');
    debugPrint('User ID   : $testUserId');
    debugPrint('Email     : $testEmail');
    debugPrint('Phone     : $testPhone');

    HapticFeedback.mediumImpact();

    setState(() {
      _isBooking = true;
    });

    try {
      // --------------------------------------------------------
      // STEP 1
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('🔥 STEP 1: STARTING FIRESTORE BOOKING');
      debugPrint('====================================');

      // --------------------------------------------------------
      // RIDE DATA
      // --------------------------------------------------------

      final Map<String, dynamic> rideData = {
  'userId': testUserId,

  'userName': userName,

  'userEmail': testEmail,

  'userPhone': testPhone,

  'vehicle': widget.vehicle,

  'pickup': widget.pickup,

  'destination': widget.destination,

  'distanceKm': widget.distanceKm,

  'durationMinutes': widget.durationMinutes,

  'originalFare': widget.fare,

  'finalFare': _finalFare,

  'paymentMethod': _paymentMethod,

  'bookingFor': _bookingFor,

  'status': 'pending',

  'driverId': null,

  'createdAt': FieldValue.serverTimestamp(),

  'updatedAt': FieldValue.serverTimestamp(),
};
      // --------------------------------------------------------
      // STEP 2
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('🔥 STEP 2: RIDE DATA PREPARED');
      debugPrint('====================================');

      debugPrint('👤 User ID       : $testUserId');
      debugPrint('📧 Email         : $testEmail');
      debugPrint('📱 Phone         : $testPhone');
      debugPrint('🚗 Vehicle       : ${widget.vehicle}');
      debugPrint('📍 Pickup        : ${widget.pickup}');
      debugPrint('📍 Destination   : ${widget.destination}');
      debugPrint('📏 Distance      : ${widget.distanceKm}');
      debugPrint('⏱ Duration      : ${widget.durationMinutes}');
      debugPrint('💰 Original Fare : ${widget.fare}');
      debugPrint('💰 Final Fare    : $_finalFare');
      debugPrint('💳 Payment       : $_paymentMethod');
      debugPrint('👤 Booking For   : $_bookingFor');
      debugPrint('🔎 Status        : pending');

      // --------------------------------------------------------
      // STEP 3
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('🔥 STEP 3: CREATING FIRESTORE DOCUMENT');
      debugPrint('====================================');

      final DocumentReference<Map<String, dynamic>> rideRef =
          await _firestore.collection('rides').add(rideData).timeout(
                const Duration(seconds: 15),
              );

      // --------------------------------------------------------
      // STEP 4
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('✅ STEP 4: RIDE CREATED');
      debugPrint('====================================');

      debugPrint('🆔 Ride ID: ${rideRef.id}');

      // --------------------------------------------------------
      // STEP 5
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('🔥 STEP 5: SAVING RIDE ID');
      debugPrint('====================================');

      await rideRef.update({
        'rideId': rideRef.id,
      }).timeout(
        const Duration(seconds: 10),
      );

      // --------------------------------------------------------
      // STEP 6
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('✅ STEP 6: RIDE ID SAVED');
      debugPrint('====================================');

      debugPrint('🆔 Ride ID: ${rideRef.id}');

      // --------------------------------------------------------
      // SUCCESS
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('🎉 BOOKING SUCCESS');
      debugPrint('====================================');

      if (!mounted) {
        debugPrint('⚠️ SCREEN NOT MOUNTED');
        return;
      }

      // --------------------------------------------------------
      // STEP 7
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('🔥 STEP 7: OPENING SEARCHING DRIVER SCREEN');
      debugPrint('====================================');

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => SearchingDriverScreen(
            rideId: rideRef.id,
            vehicle: widget.vehicle,
            fare: _finalFare,
            pickup: widget.pickup,
            destination: widget.destination,
          ),
        ),
      );

      // --------------------------------------------------------
      // STEP 8
      // --------------------------------------------------------

      debugPrint('====================================');
      debugPrint('✅ STEP 8: NAVIGATION DONE');
      debugPrint('====================================');
    }

    // ----------------------------------------------------------
    // FIREBASE ERROR
    // ----------------------------------------------------------

    on FirebaseException catch (e) {
      debugPrint('====================================');
      debugPrint('❌ FIREBASE BOOKING ERROR');
      debugPrint('====================================');

      debugPrint('❌ Code    : ${e.code}');
      debugPrint('❌ Message : ${e.message}');
      debugPrint('❌ Details : ${e.toString()}');

      if (!mounted) return;

      setState(() {
        _isBooking = false;
      });

      _showError(
        'Firebase Error:\n'
        '${e.code}\n\n'
        '${e.message ?? 'Unknown Firebase error'}',
      );
    }

    // ----------------------------------------------------------
    // TIMEOUT ERROR
    // ----------------------------------------------------------

    on TimeoutException catch (e) {
      debugPrint('====================================');
      debugPrint('❌ FIRESTORE TIMEOUT');
      debugPrint('====================================');

      debugPrint('❌ Error: $e');

      if (!mounted) return;

      setState(() {
        _isBooking = false;
      });

      _showError(
        'Firestore connection timeout.\n\n'
        'Please check your internet connection.',
      );
    }

    // ----------------------------------------------------------
    // GENERAL ERROR
    // ----------------------------------------------------------

    catch (e, stackTrace) {
      debugPrint('====================================');
      debugPrint('❌ BOOKING ERROR');
      debugPrint('====================================');

      debugPrint('❌ Error: $e');
      debugPrint('❌ StackTrace: $stackTrace');

      if (!mounted) return;

      setState(() {
        _isBooking = false;
      });

      _showError(
        'Booking Error:\n$e',
      );
    }
  }

  // ------------------------------------------------------------
  // ANIMATED SECTION
  // ------------------------------------------------------------

  Widget _animatedSection({
    required int index,
    required Widget child,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(
        begin: 0,
        end: 1,
      ),
      duration: Duration(
        milliseconds: 350 + (index * 80),
      ),
      curve: Curves.easeOutCubic,
      builder: (
        BuildContext context,
        double value,
        Widget? child,
      ) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(
              0,
              18 * (1 - value),
            ),
            child: child,
          ),
        );
      },
      child: child,
    );
  }

  // ------------------------------------------------------------
  // PAYMENT OPTION
  // ------------------------------------------------------------

  Widget _paymentOption({
    required int value,
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final bool selected = _selectedPayment == value;

    return GestureDetector(
      onTap: _isBooking
          ? null
          : () {
              setState(() {
                _selectedPayment = value;
              });

              HapticFeedback.selectionClick();
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 13,
        ),
        decoration: BoxDecoration(
          color:
              selected ? AppColors.primaryBlue.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(17),
          border: Border.all(
            color: selected ? AppColors.primaryBlue : Colors.grey.shade200,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(
                selected ? 0.06 : 0.025,
              ),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                color: selected ? AppColors.primaryBlue : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : Colors.grey.shade700,
                size: 22,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: _text(
                      size: 14,
                      weight: FontWeight.w800,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: _text(
                      size: 11,
                      weight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 23,
              height: 23,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color:
                      selected ? AppColors.primaryBlue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue,
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BOOKING FOR OPTION
  // ------------------------------------------------------------

  Widget _bookingOption({
    required int value,
    required String title,
    required IconData icon,
  }) {
    final bool selected = _selectedBooking == value;

    return Expanded(
      child: GestureDetector(
        onTap: _isBooking
            ? null
            : () {
                setState(() {
                  _selectedBooking = value;
                });

                HapticFeedback.selectionClick();
              },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 10,
          ),
          decoration: BoxDecoration(
            color: selected
                ? AppColors.primaryBlue.withOpacity(0.08)
                : Colors.white,
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: selected ? AppColors.primaryBlue : Colors.grey.shade200,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? AppColors.primaryBlue : Colors.grey.shade600,
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    size: 12,
                    weight: FontWeight.w700,
                    color:
                        selected ? AppColors.primaryBlue : Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // RIDE SUMMARY
  // ------------------------------------------------------------

  Widget _rideSummary() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primaryBlue.withOpacity(0.10),
            AppColors.primaryBlue.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.12),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  Icons.local_taxi_rounded,
                  color: AppColors.primaryBlue,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicle,
                      style: _text(
                        size: 15,
                        weight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${widget.distanceKm.toStringAsFixed(1)} km • '
                      '${widget.durationMinutes.toStringAsFixed(0)} min',
                      style: _text(
                        size: 11,
                        weight: FontWeight.w500,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _formatFare(_finalFare),
                style: _text(
                  size: 20,
                  weight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    Icons.radio_button_checked,
                    size: 14,
                    color: AppColors.primaryBlue,
                  ),
                  Container(
                    width: 1,
                    height: 28,
                    color: Colors.grey.shade300,
                  ),
                  const Icon(
                    Icons.location_on_rounded,
                    size: 16,
                    color: Colors.redAccent,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.pickup,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(
                        size: 11,
                        weight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      widget.destination,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: _text(
                        size: 11,
                        weight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // FARE DETAILS
  // ------------------------------------------------------------

  Widget _fareDetails() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ride fare',
                style: _text(
                  size: 12,
                  weight: FontWeight.w500,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                _formatFare(widget.fare),
                style: _text(
                  size: 12,
                  weight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Divider(
            height: 1,
            color: Colors.grey.shade200,
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: _text(
                  size: 15,
                  weight: FontWeight.w900,
                ),
              ),
              Text(
                _formatFare(_finalFare),
                style: _text(
                  size: 18,
                  weight: FontWeight.w900,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // CONFIRM BUTTON
  // ------------------------------------------------------------

  Widget _confirmButton() {
    return AnimatedBuilder(
      animation: _buttonController,
      builder: (context, child) {
        return Transform.scale(
          scale: _buttonController.value,
          child: child,
        );
      },
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.primaryBlue.withOpacity(0.25),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _isBooking
                ? null
                : () async {
                    debugPrint('🔥 BUTTON PRESSED');

                    await _buttonController.reverse();
                    await _buttonController.forward();

                    if (!mounted) return;

                    await _bookRide();
                  },
            style: ElevatedButton.styleFrom(
              elevation: 0,
              backgroundColor: AppColors.primaryBlue,
              disabledBackgroundColor: AppColors.primaryBlue.withOpacity(0.55),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            child: _isBooking
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Booking your ride...',
                        style: _text(
                          size: 14,
                          weight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  )
                : Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(
                          Icons.lock_rounded,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Confirm Booking',
                              style: _text(
                                size: 14.5,
                                weight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Secure your ride now',
                              style: _text(
                                size: 9.5,
                                weight: FontWeight.w500,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        _formatFare(_finalFare),
                        style: _text(
                          size: 17,
                          weight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 35,
                        height: 35,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_forward_rounded,
                          size: 20,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final double bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      top: false,
      child: Material(
        color: Colors.transparent,
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.92,
          ),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            borderRadius: BorderRadius.vertical(
              top: Radius.circular(30),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ------------------------------------------------
              // DRAG HANDLE
              // ------------------------------------------------

              const SizedBox(height: 10),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 7),

              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              Padding(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  8,
                  20,
                  10,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 43,
                      height: 43,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.payment_rounded,
                        color: AppColors.primaryBlue,
                        size: 23,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Payment',
                            style: _text(
                              size: 20,
                              weight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose your payment method',
                            style: _text(
                              size: 11,
                              weight: FontWeight.w500,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap:
                          _isBooking ? null : () => Navigator.of(context).pop(),
                      child: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ------------------------------------------------
              // CONTENT
              // ------------------------------------------------

              Expanded(
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      padding: EdgeInsets.fromLTRB(
                        20,
                        5,
                        20,
                        20 + bottomPadding,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // RIDE SUMMARY
                          _animatedSection(
                            index: 0,
                            child: _rideSummary(),
                          ),

                          const SizedBox(height: 15),

                          // PAYMENT TITLE
                          _animatedSection(
                            index: 1,
                            child: Text(
                              'Payment Methods',
                              style: _text(
                                size: 15,
                                weight: FontWeight.w900,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // PAYMENT OPTIONS
                          _animatedSection(
                            index: 2,
                            child: Column(
                              children: [
                                _paymentOption(
                                  value: 1,
                                  icon: Icons.account_balance_wallet_rounded,
                                  title: 'Elite Wallet',
                                  subtitle: 'Pay securely from your wallet',
                                ),
                                _paymentOption(
                                  value: 2,
                                  icon: Icons.money_rounded,
                                  title: 'Cash',
                                  subtitle: 'Pay directly to the driver',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 5),

                          // BOOKING FOR TITLE
                          _animatedSection(
                            index: 3,
                            child: Text(
                              'Booking For',
                              style: _text(
                                size: 15,
                                weight: FontWeight.w900,
                              ),
                            ),
                          ),

                          const SizedBox(height: 10),

                          // BOOKING FOR
                          _animatedSection(
                            index: 4,
                            child: Row(
                              children: [
                                _bookingOption(
                                  value: 1,
                                  title: 'Myself',
                                  icon: Icons.person_rounded,
                                ),
                                const SizedBox(width: 10),
                                _bookingOption(
                                  value: 2,
                                  title: 'Someone Else',
                                  icon: Icons.people_alt_rounded,
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 15),

                          // FARE DETAILS
                          _animatedSection(
                            index: 5,
                            child: _fareDetails(),
                          ),

                          const SizedBox(height: 18),

                          // CONFIRM BUTTON
                          _animatedSection(
                            index: 6,
                            child: _confirmButton(),
                          ),

                          const SizedBox(height: 12),

                          // SECURITY
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_outline_rounded,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  'Your payment is secure',
                                  style: _text(
                                    size: 10,
                                    weight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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

// ============================================================
// SHOW PAYMENT SHEET
// ============================================================

void showPaymentSheet({
  required BuildContext context,
  required double fare,
  required String vehicle,
  required double distanceKm,
  required double durationMinutes,
  required String pickup,
  required String destination,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.45),
    enableDrag: true,
    isDismissible: true,
    builder: (sheetContext) {
      return PaymentSheet(
        fare: fare,
        vehicle: vehicle,
        distanceKm: distanceKm,
        durationMinutes: durationMinutes,
        pickup: pickup,
        destination: destination,
      );
    },
  );
}
