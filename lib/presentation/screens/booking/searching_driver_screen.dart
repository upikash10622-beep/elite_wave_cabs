import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../../core/colors.dart';

class SearchingDriverScreen extends StatefulWidget {
  final String rideId;
  final String vehicle;
  final double fare;
  final String pickup;
  final String destination;

  const SearchingDriverScreen({
    super.key,
    required this.rideId,
    required this.vehicle,
    required this.fare,
    required this.pickup,
    required this.destination,
  });

  @override
  State<SearchingDriverScreen> createState() =>
      _SearchingDriverScreenState();
}

class _SearchingDriverScreenState
    extends State<SearchingDriverScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _rideSubscription;

  String _status = 'searching';
  String? _driverId;

  bool _isCancelling = false;

  @override
  void initState() {
    super.initState();

    // Taxi animation
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    // Start listening to Firestore ride
    _listenToRide();
  }

  // ------------------------------------------------------------
  // FIRESTORE LIVE LISTENER
  // ------------------------------------------------------------

  void _listenToRide() {
    _rideSubscription = FirebaseFirestore.instance
        .collection('rides')
        .doc(widget.rideId)
        .snapshots()
        .listen(
      (snapshot) {
        if (!mounted) return;

        if (!snapshot.exists) {
          return;
        }

        final data = snapshot.data();

        if (data == null) {
          return;
        }

        final status = data['status'] as String? ?? 'searching';
        final driverId = data['driverId'] as String?;

        setState(() {
          _status = status;
          _driverId = driverId;
        });

        // Stop animation when driver is found
        if (status == 'searching') {
          if (!_controller.isAnimating) {
            _controller.repeat();
          }
        } else {
          _controller.stop();
        }
      },
      onError: (error) {
        debugPrint('Ride listener error: $error');
      },
    );
  }

  // ------------------------------------------------------------
  // CANCEL RIDE
  // ------------------------------------------------------------

  Future<void> _cancelRide() async {
    if (_isCancelling) return;

    setState(() {
      _isCancelling = true;
    });

    try {
      final rideRef = FirebaseFirestore.instance
          .collection('rides')
          .doc(widget.rideId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(rideRef);

        if (!snapshot.exists) {
          throw Exception('Ride not found');
        }

        final data = snapshot.data();

        final currentStatus =
            data?['status'] as String? ?? 'searching';

        // Cancel only if ride is still searching
        if (currentStatus == 'searching') {
          transaction.update(
            rideRef,
            {
              'status': 'cancelled',
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        } else {
          throw Exception(
            'Ride is already $currentStatus',
          );
        }
      });

      if (!mounted) return;

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCancelling = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to cancel ride: $e',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // ------------------------------------------------------------
  // STATUS TEXT
  // ------------------------------------------------------------

  String _getTitle() {
    switch (_status) {
      case 'accepted':
        return 'Driver Found!';

      case 'driver_arriving':
        return 'Driver Is On The Way';

      case 'driver_arrived':
        return 'Driver Has Arrived';

      case 'started':
        return 'Ride Started';

      case 'completed':
        return 'Ride Completed';

      case 'cancelled':
        return 'Ride Cancelled';

      default:
        return 'Finding Your Driver';
    }
  }

  String _getSubtitle() {
    switch (_status) {
      case 'accepted':
        return 'Your driver has accepted the ride.';

      case 'driver_arriving':
        return 'Your driver is coming to the pickup location.';

      case 'driver_arrived':
        return 'Your driver has arrived at the pickup location.';

      case 'started':
        return 'Your ride is now in progress.';

      case 'completed':
        return 'Your ride has been completed.';

      case 'cancelled':
        return 'This ride has been cancelled.';

      default:
        return 'Please wait while we find the nearest driver.';
    }
  }

  // ------------------------------------------------------------
  // STATUS ICON
  // ------------------------------------------------------------

  IconData _getStatusIcon() {
    switch (_status) {
      case 'accepted':
        return Icons.check_circle_rounded;

      case 'driver_arriving':
        return Icons.directions_car_rounded;

      case 'driver_arrived':
        return Icons.location_on_rounded;

      case 'started':
        return Icons.local_taxi_rounded;

      case 'completed':
        return Icons.done_all_rounded;

      case 'cancelled':
        return Icons.cancel_rounded;

      default:
        return Icons.local_taxi_rounded;
    }
  }

  // ------------------------------------------------------------
  // STATUS COLOR
  // ------------------------------------------------------------

  Color _getStatusColor() {
    switch (_status) {
      case 'cancelled':
        return Colors.red;

      case 'completed':
        return Colors.green;

      default:
        return AppColors.primaryBlue;
    }
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final bool searching = _status == 'searching';

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBFF),

      // --------------------------------------------------------
      // APP BAR
      // --------------------------------------------------------

      appBar: AppBar(
        title: const Text(
          'Your Ride',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,

        iconTheme: const IconThemeData(
          color: Colors.black87,
        ),

        automaticallyImplyLeading: false,
      ),

      // --------------------------------------------------------
      // BODY
      // --------------------------------------------------------

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),

          child: Column(
            children: [
              const SizedBox(height: 25),

              // ------------------------------------------------
              // TAXI ANIMATION / STATUS ICON
              // ------------------------------------------------

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 400),

                child: searching
                    ? RotationTransition(
                        key: const ValueKey('searching'),
                        turns: _controller,
                        child: Container(
                          width: 120,
                          height: 120,

                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryBlue
                                .withValues(alpha: 0.10),
                          ),

                          child: Icon(
                            Icons.local_taxi_rounded,
                            size: 65,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      )
                    : Container(
                        key: ValueKey(_status),
                        width: 120,
                        height: 120,

                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _getStatusColor()
                              .withValues(alpha: 0.10),
                        ),

                        child: Icon(
                          _getStatusIcon(),
                          size: 65,
                          color: _getStatusColor(),
                        ),
                      ),
              ),

              const SizedBox(height: 28),

              // ------------------------------------------------
              // TITLE
              // ------------------------------------------------

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),

                child: Text(
                  _getTitle(),
                  key: ValueKey(_status),
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF172033),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ------------------------------------------------
              // SUBTITLE
              // ------------------------------------------------

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),

                child: Text(
                  _getSubtitle(),
                  key: ValueKey('$_status-subtitle'),
                  textAlign: TextAlign.center,

                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ------------------------------------------------
              // DRIVER FOUND CARD
              // ------------------------------------------------

              if (_status != 'searching' &&
                  _status != 'cancelled') ...[
                _driverFoundCard(),

                const SizedBox(height: 15),
              ],

              // ------------------------------------------------
              // RIDE DETAILS
              // ------------------------------------------------

              _infoCard(
                title: 'Pickup',
                value: widget.pickup,
                icon: Icons.location_on_rounded,
              ),

              const SizedBox(height: 12),

              _infoCard(
                title: 'Destination',
                value: widget.destination,
                icon: Icons.flag_rounded,
              ),

              const SizedBox(height: 12),

              _infoCard(
                title: 'Vehicle',
                value: widget.vehicle,
                icon: Icons.directions_car_rounded,
              ),

              const SizedBox(height: 12),

              _infoCard(
                title: 'Fare',
                value: '₹${widget.fare.round()}',
                icon: Icons.payments_rounded,
              ),

              const Spacer(),

              // ------------------------------------------------
              // CANCEL BUTTON
              // ------------------------------------------------

              if (searching)
                SizedBox(
                  width: double.infinity,
                  height: 55,

                  child: OutlinedButton(
                    onPressed:
                        _isCancelling ? null : _cancelRide,

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: Colors.red,
                      ),

                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(16),
                      ),
                    ),

                    child: _isCancelling
                        ? const SizedBox(
                            width: 22,
                            height: 22,

                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red,
                            ),
                          )
                        : const Text(
                            'Cancel Ride',
                            style: TextStyle(
                              color: Colors.red,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // DRIVER FOUND CARD
  // ------------------------------------------------------------

  Widget _driverFoundCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(18),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
 
      child: Row(
        children: [
          // Driver icon
          Container(
            width: 55,
            height: 55,

            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color:
                 AppColors.primaryBlue.withValues(alpha: 0.10),
            ),

            child: Icon(
              Icons.person_rounded,
              color: AppColors.primaryBlue,
              size: 30,
            ),
          ),

          const SizedBox(width: 14),

          // Driver information
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                const Text(
                  'Driver Assigned',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                const Text(
                  'Your driver is assigned',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (_driverId != null) ...[
                  const SizedBox(height: 4),

                  Text(
                    'Driver ID: $_driverId',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,

                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Check icon
          const Icon(
            Icons.check_circle_rounded,
            color: Colors.green,
            size: 28,
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // INFO CARD
  // ------------------------------------------------------------

  Widget _infoCard({
    required String title,
    required String value,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(15),

      decoration: BoxDecoration(
        color: Colors.white,

        borderRadius: BorderRadius.circular(16),

        border: Border.all(
          color: const Color(0xFFE2E8F0),
        ),
      ),

      child: Row(
        children: [
          // Icon
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color:
                  AppColors.primaryBlue.withValues(alpha: 0.08),

              borderRadius:
                  BorderRadius.circular(12),
            ),

            child: Icon(
              icon,
              color: AppColors.primaryBlue,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          // Text
          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  value,

                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,

                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF172033),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // DISPOSE
  // ------------------------------------------------------------

  @override
  void dispose() {
    _rideSubscription?.cancel();
    _controller.dispose();

    super.dispose();
  }
}