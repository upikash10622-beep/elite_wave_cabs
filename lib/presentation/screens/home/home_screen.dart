import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../../core/colors.dart';
import '../../../data/services/location_service.dart';
import '../booking/plan_ride_screen.dart';
import '../profile/side_menu.dart';
import '../services/services_screen.dart';
import '../activity/activity_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // ============================================================
  // LOCAL / OUTSTATION
  // ============================================================

  bool _isOutstation = false;

  // ============================================================
  // LOCATION
  // ============================================================

  final LocationService _locationService = LocationService();

  GoogleMapController? _mapController;

  static const LatLng _defaultLocation = LatLng(
    10.627143495791035,
    79.25168500411812,
  );

  LatLng _currentLocation = _defaultLocation;

  StreamSubscription<Position>? _positionStream;

  Set<Marker> _markers = <Marker>{};

  bool _hasReceivedLocation = false;
  bool _mapReady = false;
  bool _isStartingLocation = false;

  bool _hasCenteredOnUser = false;

  // ============================================================
  // BOTTOM NAVIGATION
  // ============================================================

  int _selectedBottomIndex = 0;

  // ============================================================
  // ANIMATION STATES
  // ============================================================

  bool _showBottomPanel = false;
  bool _showVehicleCards = false;
  bool _showSearchBox = false;

  bool _locationPulse = false;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addObserver(this);

    Future.delayed(
      const Duration(milliseconds: 250),
      () {
        if (!mounted) return;

        setState(() {
          _showBottomPanel = true;
        });
      },
    );

    Future.delayed(
      const Duration(milliseconds: 450),
      () {
        if (!mounted) return;

        setState(() {
          _showVehicleCards = true;
        });
      },
    );

    Future.delayed(
      const Duration(milliseconds: 700),
      () {
        if (!mounted) return;

        setState(() {
          _showSearchBox = true;
        });
      },
    );

    Future.delayed(
      const Duration(milliseconds: 1200),
      () {
        if (mounted) {
          _startLocationPulse();
        }
      },
    );

    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        _startLocation();
      },
    );
  }

  // ============================================================
  // LOCATION BUTTON PULSE
  // ============================================================

  void _startLocationPulse() {
    if (!mounted) return;

    setState(() {
      _locationPulse = !_locationPulse;
    });

    Future.delayed(
      const Duration(milliseconds: 900),
      () {
        if (mounted) {
          _startLocationPulse();
        }
      },
    );
  }

  // ============================================================
  // APP RESUME
  // ============================================================

  @override
  void didChangeAppLifecycleState(
    AppLifecycleState state,
  ) {
    if (state == AppLifecycleState.resumed) {
      _hasCenteredOnUser = false;

      _startLocation();
    }
  }

  // ============================================================
  // UPDATE MARKER
  // ============================================================

  void _updateCurrentLocationMarker(
    LatLng location,
  ) {
    if (!mounted) return;

    setState(() {
      _currentLocation = location;

      _markers = <Marker>{
        Marker(
          markerId: const MarkerId(
            'current_location',
          ),
          position: location,
          icon: BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(
            title: 'Your Location',
          ),
        ),
      };
    });
  }

  // ============================================================
  // MOVE CAMERA
  // ============================================================

  Future<void> _moveCameraToLocation(
    LatLng location, {
    double zoom = 17,
  }) async {
    final controller = _mapController;

    if (controller == null || !_mapReady) {
      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: zoom,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Camera animation error: $e',
      );
    }
  }

  // ============================================================
  // START LOCATION
  // ============================================================

  Future<void> _startLocation() async {
    if (_isStartingLocation) {
      return;
    }

    _isStartingLocation = true;

    try {
      // ----------------------------------------------------------
      // 1. CHECK LOCATION SERVICE
      // ----------------------------------------------------------

      final serviceEnabled = await _locationService.isServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text(
                'Location is OFF',
              ),
              content: const Text(
                'Please turn on Location to use live location.',
              ),
              actions: [
                ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(dialogContext);

                    await _locationService.openLocationSettings();
                  },
                  child: const Text(
                    'Turn On Location',
                  ),
                ),
              ],
            );
          },
        );

        return;
      }

      // ----------------------------------------------------------
      // 2. CHECK PERMISSION
      // ----------------------------------------------------------

      LocationPermission permission = await _locationService.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await _locationService.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Location permission is required.',
            ),
          ),
        );

        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (!mounted) return;

        await showDialog(
          context: context,
          builder: (dialogContext) {
            return AlertDialog(
              title: const Text(
                'Location Permission',
              ),
              content: const Text(
                'Location permission is permanently denied. '
                'Please enable it from App Settings.',
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);

                    _locationService.openAppSettings();
                  },
                  child: const Text(
                    'Open Settings',
                  ),
                ),
              ],
            );
          },
        );

        return;
      }

      // ----------------------------------------------------------
      // 3. CANCEL OLD STREAM
      // ----------------------------------------------------------

      await _positionStream?.cancel();
      _positionStream = null;

      // ----------------------------------------------------------
      // 4. START LIVE LOCATION STREAM
      // ----------------------------------------------------------

      _positionStream = _locationService.getPositionStream().listen(
        (Position position) {
          debugPrint(
            'LIVE GPS: '
            '${position.latitude}, '
            '${position.longitude}',
          );

          if (!mounted) return;

          final liveLocation = LatLng(
            position.latitude,
            position.longitude,
          );

          _updateCurrentLocationMarker(
            liveLocation,
          );

          if (!_hasCenteredOnUser) {
            _hasCenteredOnUser = true;
            _hasReceivedLocation = true;

            WidgetsBinding.instance.addPostFrameCallback(
              (_) {
                if (!mounted) return;

                _moveCameraToLocation(
                  liveLocation,
                  zoom: 17,
                );
              },
            );
          }
        },
        onError: (Object error) {
          debugPrint(
            'LIVE GPS ERROR: $error',
          );
        },
        cancelOnError: false,
      );

      // ----------------------------------------------------------
      // 5. GET FIRST CURRENT LOCATION
      // ----------------------------------------------------------

      try {
        final position = await _locationService.getCurrentPosition();

        if (!mounted) return;

        final location = LatLng(
          position.latitude,
          position.longitude,
        );

        _hasReceivedLocation = true;

        _updateCurrentLocationMarker(
          location,
        );

        _hasCenteredOnUser = true;

        WidgetsBinding.instance.addPostFrameCallback(
          (_) {
            if (!mounted) return;

            _moveCameraToLocation(
              location,
              zoom: 17,
            );
          },
        );
      } catch (e) {
        debugPrint(
          'Initial GPS Error: $e',
        );
      }
    } catch (e) {
      debugPrint(
        'Location Error: $e',
      );
    } finally {
      _isStartingLocation = false;
    }
  }

  // ============================================================
  // CURRENT LOCATION BUTTON
  // ============================================================

  Future<void> _goToCurrentLocation() async {
    try {
      if (_hasReceivedLocation) {
        await _moveCameraToLocation(
          _currentLocation,
          zoom: 17,
        );
      }

      final position = await _locationService.getCurrentPosition();

      if (!mounted) return;

      final location = LatLng(
        position.latitude,
        position.longitude,
      );

      _hasReceivedLocation = true;
      _hasCenteredOnUser = true;

      _updateCurrentLocationMarker(
        location,
      );

      await _moveCameraToLocation(
        location,
        zoom: 17,
      );
    } catch (e) {
      debugPrint(
        'Current location button error: $e',
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to get current location: $e',
          ),
        ),
      );
    }
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(
      this,
    );

    _positionStream?.cancel();

    _mapController = null;

    super.dispose();
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: const SideMenu(),
      body: Stack(
        children: [
          // ======================================================
          // MAP
          // ======================================================

          _buildMap(),

          // ======================================================
          // SEARCH BOX
          // ======================================================

          _buildFloatingSearch(),

          // ======================================================
          // BOTTOM BOOKING PANEL
          // ======================================================

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: _showBottomPanel ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              child: AnimatedSlide(
                offset: _showBottomPanel ? Offset.zero : const Offset(0, 0.35),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    100,
                  ),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ==================================================
                      // LOCAL / OUTSTATION
                      // ==================================================

                      AnimatedOpacity(
                        opacity: _showVehicleCards ? 1.0 : 0.0,
                        duration: const Duration(
                          milliseconds: 500,
                        ),
                        child: AnimatedSlide(
                          offset: _showVehicleCards
                              ? Offset.zero
                              : const Offset(
                                  0,
                                  0.18,
                                ),
                          duration: const Duration(
                            milliseconds: 650,
                          ),
                          curve: Curves.easeOutCubic,
                          child: Row(
                            children: [
                              // ==================================================
                              // LOCAL
                              // ==================================================

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isOutstation = false;
                                    });
                                  },
                                  child: _buildVehicleButton(
                                    'assets/images/local_car.jpeg',
                                    'Local',
                                    !_isOutstation,
                                  ),
                                ),
                              ),

                              const SizedBox(
                                width: 10,
                              ),

                              // ==================================================
                              // OUTSTATION
                              // ==================================================

                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isOutstation = true;
                                    });
                                  },
                                  child: _buildVehicleButton(
                                    'assets/images/outstation_car.jpeg',
                                    'Outstation',
                                    _isOutstation,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ==========================================================
          // BOTTOM NAVIGATION
          // ==========================================================

          _buildBottomNavigation(),
        ],
      ),
    );
  }

  // ============================================================
  // FLOATING SEARCH BOX
  // ============================================================

  Widget _buildFloatingSearch() {
    return Positioned(
      left: 16,
      right: 16,
      bottom: 700,
      child: AnimatedOpacity(
        opacity: _showSearchBox ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeOut,
        child: AnimatedSlide(
          offset: _showSearchBox ? Offset.zero : const Offset(0, 0.25),
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOutCubic,
          child: GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PlanRideScreen(
                    isOutstation: _isOutstation,
                  ),
                ),
              );
            },
            child: Container(
              height: 58,
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.15,
                    ),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.search,
                    color: AppColors.primaryBlue,
                    size: 25,
                  ),
                  const SizedBox(
                    width: 12,
                  ),
                  const Expanded(
                    child: Text(
                      'Where do you want to go?',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Colors.grey,
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
  // BOTTOM NAVIGATION
  // ============================================================

  Widget _buildBottomNavigation() {
    return Positioned(
      left: 14,
      right: 14,
      bottom: 14,
      child: SafeArea(
        top: false,
        child: AnimatedOpacity(
          opacity: _showBottomPanel ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeOut,
          child: AnimatedSlide(
            offset: _showBottomPanel ? Offset.zero : const Offset(0, 0.5),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeOutBack,
            child: Container(
              height: 70,
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 7,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: 0.16,
                    ),
                    blurRadius: 22,
                    spreadRadius: 1,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: Icons.home_rounded,
                    label: 'Home',
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: Icons.grid_view_rounded,
                    label: 'Services',
                  ),
                  _buildNavItem(
                    index: 2,
                    icon: Icons.bookmark_border_rounded,
                    label: 'Activity',
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: Icons.person_outline_rounded,
                    label: 'Account',
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
  // NAV ITEM
  // ============================================================

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required String label,
  }) {
    final bool selected = _selectedBottomIndex == index;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          // ACCOUNT
          if (index == 3) {
            setState(() {
              _selectedBottomIndex = 3;
            });

            Future.delayed(
              const Duration(milliseconds: 180),
              () {
                if (!mounted) return;

                _scaffoldKey.currentState?.openDrawer();
              },
            );

            return;
          }

          // SERVICES
          if (index == 1) {
            setState(() {
              _selectedBottomIndex = 1;
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ServicesScreen(),
              ),
            );

            return;
          }

          // ACTIVITY
          if (index == 2) {
            setState(() {
              _selectedBottomIndex = 2;
            });

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ActivityScreen(),
              ),
            );

            return;
          }

          // HOME
          if (index == 0) {
            setState(() {
              _selectedBottomIndex = 0;
            });

            return;
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(
            horizontal: 2,
          ),
          decoration: BoxDecoration(
            color: selected ? Colors.grey.shade100 : Colors.transparent,
            borderRadius: BorderRadius.circular(23),
          ),
          child: AnimatedScale(
            scale: selected ? 1.04 : 1.0,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedSwitcher(
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  transitionBuilder: (
                    child,
                    animation,
                  ) {
                    return ScaleTransition(
                      scale: animation,
                      child: child,
                    );
                  },
                  child: Icon(
                    icon,
                    key: ValueKey(
                      '$index-$selected',
                    ),
                    size: 25,
                    color:
                        selected ? AppColors.primaryBlue : Colors.grey.shade600,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                AnimatedDefaultTextStyle(
                  duration: const Duration(
                    milliseconds: 250,
                  ),
                  curve: Curves.easeOutCubic,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color:
                        selected ? AppColors.primaryBlue : Colors.grey.shade600,
                  ),
                  child: Text(label),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // VEHICLE BUTTON
  // ============================================================

  Widget _buildVehicleButton(
    String image,
    String label,
    bool selected,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      height: 65,

      // Reduced horizontal padding
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
      ),

      decoration: BoxDecoration(
        color: selected
            ? AppColors.primaryBlue.withValues(alpha: 0.09)
            : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? AppColors.primaryBlue : Colors.grey.shade300,
          width: selected ? 2.0 : 1.2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: AppColors.primaryBlue.withValues(
                    alpha: 0.25,
                  ),
                  blurRadius: 18,
                  spreadRadius: 2,
                  offset: const Offset(0, 5),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: 0.04,
                  ),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
      ),

      child: Row(
        children: [
          // ======================================================
          // CAR IMAGE
          // ======================================================

          Expanded(
            flex: 2,
            child: AnimatedScale(
              scale: selected ? 1.05 : 1.0,
              duration: const Duration(
                milliseconds: 450,
              ),
              curve: Curves.easeOutBack,
              child: Image.asset(
                image,
                height: 35,
                fit: BoxFit.contain,
              ),
            ),
          ),

          const SizedBox(
            width: 4,
          ),

          // ======================================================
          // LABEL
          // ======================================================

          Expanded(
            flex: 3,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: AnimatedDefaultTextStyle(
                duration: const Duration(
                  milliseconds: 350,
                ),
                curve: Curves.easeOutCubic,
                style: TextStyle(
                  fontSize: selected ? 18 : 17,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
                  color: selected ? AppColors.primaryBlue : Colors.black87,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MAP
  // ============================================================

  Widget _buildMap() {
    final supportsNativeMap = !kIsWeb &&
        (defaultTargetPlatform == TargetPlatform.android ||
            defaultTargetPlatform == TargetPlatform.iOS);

    // ----------------------------------------------------------
    // WEB FALLBACK
    // ----------------------------------------------------------

    if (!supportsNativeMap) {
      return const ColoredBox(
        color: AppColors.primaryLight,
        child: Center(
          child: Icon(
            Icons.map_outlined,
            size: 80,
            color: AppColors.primaryBlue,
          ),
        ),
      );
    }

    // ----------------------------------------------------------
    // GOOGLE MAP
    // ----------------------------------------------------------

    return Stack(
      children: [
        Positioned.fill(
          child: GoogleMap(
            onMapCreated: (GoogleMapController controller) {
              _mapController = controller;
              _mapReady = true;

              debugPrint(
                'Google Map created successfully',
              );

              if (_hasReceivedLocation) {
                WidgetsBinding.instance.addPostFrameCallback(
                  (_) {
                    if (!mounted) return;

                    _moveCameraToLocation(
                      _currentLocation,
                      zoom: 17,
                    );
                  },
                );
              }
            },
            initialCameraPosition: const CameraPosition(
              target: _defaultLocation,
              zoom: 15,
            ),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            markers: _markers,
            zoomControlsEnabled: false,
            compassEnabled: true,
            mapToolbarEnabled: true,
            mapType: MapType.normal,
            minMaxZoomPreference: const MinMaxZoomPreference(
              3,
              20,
            ),
            trafficEnabled: false,
            padding: const EdgeInsets.only(
              top: 40,
              bottom: 110,
            ),
          ),
        ),

        // ======================================================
        // CURRENT LOCATION BUTTON
        // ======================================================

        Positioned(
          right: 16,
          bottom: 190,
          child: AnimatedScale(
            scale: _locationPulse ? 1.08 : 1.0,
            duration: const Duration(
              milliseconds: 850,
            ),
            curve: Curves.easeInOut,
            child: AnimatedContainer(
              duration: const Duration(
                milliseconds: 850,
              ),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withValues(
                      alpha: _locationPulse ? 0.35 : 0.12,
                    ),
                    blurRadius: _locationPulse ? 24 : 10,
                    spreadRadius: _locationPulse ? 3 : 1,
                  ),
                ],
              ),
              child: Material(
                color: Colors.white,
                elevation: 4,
                borderRadius: BorderRadius.circular(
                  25,
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(
                    25,
                  ),
                  onTap: _goToCurrentLocation,
                  child: const SizedBox(
                    width: 48,
                    height: 48,
                    child: Icon(
                      Icons.my_location,
                      color: Colors.black87,
                      size: 25,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
