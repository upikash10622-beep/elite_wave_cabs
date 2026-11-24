import 'dart:async';

import 'package:material_ui/material_ui.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../booking/payment_sheet.dart';
import '../../../core/colors.dart';
import '../../../data/services/directions_service.dart';
import '../../../data/services/location_service.dart';
import '../../../utils/fare_calculator.dart';

class PlanRideScreen extends StatefulWidget {
  final bool isOutstation;

  const PlanRideScreen({
    super.key,
    required this.isOutstation,
  });

  @override
  State<PlanRideScreen> createState() => _PlanRideScreenState();
}

class _PlanRideScreenState extends State<PlanRideScreen>
    with TickerProviderStateMixin {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController pickupController =
      TextEditingController();

  final TextEditingController destinationController =
      TextEditingController();

  final FocusNode destinationFocusNode =
      FocusNode();

  final LocationService _locationService =
      LocationService();

  final DirectionsService _directionsService =
      DirectionsService();

  GoogleMapController? _mapController;

  StreamSubscription<Position>? _positionSubscription;

  Timer? _autocompleteDebounce;

  // ============================================================
  // LOCATION
  // ============================================================

  LatLng? _currentLocation;

  LatLng? _destinationLocation;

  Set<Marker> _markers = <Marker>{};

  Set<Polyline> _polylines = <Polyline>{};

  List<PlaceSuggestion> _suggestions =
      <PlaceSuggestion>[];

  // ============================================================
  // STATES
  // ============================================================

  bool isLoadingLocation = true;

  bool isSearching = false;

  bool isCalculatingFare = false;

  bool showVehicles = false;

  bool _isFollowingLocation = true;

  bool _routeRequestRunning = false;

  DateTime? _lastRouteRequestTime;

  // ============================================================
  // OUTSTATION SWITCH
  // ============================================================

  bool _isOutstation = false;

  bool _outstationPopupShown = false;

  // ============================================================
  // VEHICLE
  // ============================================================

  int selectedVehicle = 0;

  final List<String> vehicleNames = const [
    'Mini',
    'Sedan',
    'SUV',
  ];

  final List<String> vehicleEta = const [
    '2 min away',
    '4 min away',
    '6 min away',
  ];

  final List<IconData> vehicleIcons = const [
    Icons.local_taxi_rounded,
    Icons.directions_car_rounded,
    Icons.airport_shuttle_rounded,
  ];

  // ============================================================
  // ROUTE DATA
  // ============================================================

  double distanceInKm = 0;

  int durationInMinutes = 0;

  // ============================================================
  // FARES
  // ============================================================

  double miniFare = 0;

  double sedanFare = 0;

  double sedanAcFare = 0;

  double sedanNonAcFare = 0;

  double suvFare = 0;

  double suvAcFare = 0;

  double suvNonAcFare = 0;

  // ============================================================
  // LOW → HIGH DISPLAY FARES
  // ============================================================

  double _displayMiniFare = 0;

  double _displaySedanFare = 0;

  double _displaySuvFare = 0;

  // ============================================================
  // ANIMATIONS
  // ============================================================

  late final AnimationController _pageController;

  late final AnimationController _panelController;

  late final AnimationController _searchController;

  late final AnimationController _vehicleController;

  // ============================================================
  // INIT
  // ============================================================

  @override
  void initState() {
    super.initState();

    _isOutstation = widget.isOutstation;

    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 700,
      ),
    )..forward();

    _panelController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      ),
    );

    _searchController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 450,
      ),
    )..forward();

    _vehicleController = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 500,
      ),
    );

    _startLiveLocation();
  }

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _positionSubscription?.cancel();

    _autocompleteDebounce?.cancel();

    pickupController.dispose();

    destinationController.dispose();

    destinationFocusNode.dispose();

    _pageController.dispose();

    _panelController.dispose();

    _searchController.dispose();

    _vehicleController.dispose();

    super.dispose();
  }

  // ============================================================
  // LIVE LOCATION
  // ============================================================

  Future<void> _startLiveLocation() async {
    try {
      final bool serviceEnabled =
          await _locationService.isServiceEnabled();

      if (!serviceEnabled) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
        });

        _showLocationDialog(
          title: 'Location is disabled',
          message:
              'Please turn on your device location.',
          openLocationSettings: true,
        );

        return;
      }

      LocationPermission permission =
          await _locationService.checkPermission();

      if (permission == LocationPermission.denied) {
        permission =
            await _locationService.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
        });

        _showMessage(
          'Location permission is required.',
        );

        return;
      }

      if (permission ==
          LocationPermission.deniedForever) {
        if (!mounted) return;

        setState(() {
          isLoadingLocation = false;
        });

        _showLocationDialog(
          title: 'Location Permission Required',
          message:
              'Please allow location permission from app settings.',
          openAppSettings: true,
        );

        return;
      }

      await _positionSubscription?.cancel();

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: AndroidSettings(
          accuracy:
              LocationAccuracy.bestForNavigation,
          distanceFilter: 5,
          intervalDuration:
              const Duration(seconds: 3),
        ),
      ).listen(
        _handleLiveLocation,
        onError: (Object error) {
          debugPrint(
            'Location stream error: $error',
          );
        },
      );

      final Position? lastKnownPosition =
          await Geolocator.getLastKnownPosition();

      if (lastKnownPosition != null && mounted) {
        final LatLng lastLocation = LatLng(
          lastKnownPosition.latitude,
          lastKnownPosition.longitude,
        );

        _applyLocationImmediately(
          lastLocation,
          moveCamera: true,
        );

        if (mounted) {
          setState(() {
            isLoadingLocation = false;
          });
        }
      }

      final Position position =
          await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy:
              LocationAccuracy.bestForNavigation,
          distanceFilter: 0,
        ),
      );

      final LatLng location = LatLng(
        position.latitude,
        position.longitude,
      );

      if (!mounted) return;

      _applyLocationImmediately(
        location,
        moveCamera: true,
      );

      setState(() {
        isLoadingLocation = false;
      });
    } catch (e) {
      debugPrint(
        'Live location error: $e',
      );

      if (!mounted) return;

      setState(() {
        isLoadingLocation = false;
      });

      _showMessage(
        'Unable to get live location.',
      );
    }
  }

  // ============================================================
  // APPLY LOCATION
  // ============================================================

  void _applyLocationImmediately(
    LatLng location, {
    bool moveCamera = false,
  }) {
    if (!mounted) return;

    _currentLocation = location;

    pickupController.text = 'Current Location';

    _updateCurrentLocationMarker(location);

    if (moveCamera && _mapController != null) {
      _mapController!.moveCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: 16.5,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    }
  }

  // ============================================================
  // LIVE LOCATION UPDATE
  // ============================================================

  void _handleLiveLocation(
    Position position,
  ) {
    if (!mounted) return;

    final LatLng newLocation = LatLng(
      position.latitude,
      position.longitude,
    );

    debugPrint(
      'LIVE GPS: ${newLocation.latitude}, ${newLocation.longitude}',
    );

    setState(() {
      _currentLocation = newLocation;
      pickupController.text = 'Current Location';
    });

    _updateCurrentLocationMarker(newLocation);

    if (_isFollowingLocation &&
        _mapController != null) {
      _mapController!.moveCamera(
        CameraUpdate.newLatLng(newLocation),
      );
    }
  }

  // ============================================================
  // CURRENT LOCATION MARKER
  // ============================================================

  void _updateCurrentLocationMarker(
    LatLng location,
  ) {
    final Set<Marker> markers =
        Set<Marker>.from(_markers);

    markers.removeWhere(
      (marker) =>
          marker.markerId.value ==
          'current_location',
    );

    markers.add(
      Marker(
        markerId:
            const MarkerId('current_location'),
        position: location,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueAzure,
        ),
        infoWindow: const InfoWindow(
          title: 'You are here',
          snippet: 'Live location',
        ),
        zIndexInt: 10,
      ),
    );

    if (_destinationLocation != null) {
      markers.removeWhere(
        (marker) =>
            marker.markerId.value ==
            'destination',
      );

      markers.add(
        Marker(
          markerId:
              const MarkerId('destination'),
          position: _destinationLocation!,
          icon:
              BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueRed,
          ),
          infoWindow: const InfoWindow(
            title: 'Destination',
          ),
          zIndexInt: 9,
        ),
      );
    }

    if (!mounted) return;

    setState(() {
      _markers = markers;
    });
  }

  // ============================================================
  // CAMERA
  // ============================================================

  Future<void> _moveCameraToLocation(
    LatLng location, {
    double zoom = 16.5,
  }) async {
    final GoogleMapController? controller =
        _mapController;

    if (controller == null) return;

    try {
      await controller.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: location,
            zoom: zoom,
            tilt: 0,
            bearing: 0,
          ),
        ),
      );
    } catch (e) {
      debugPrint(
        'Camera error: $e',
      );
    }
  }

  void _onMapCreated(
    GoogleMapController controller,
  ) {
    _mapController = controller;

    final LatLng? location =
        _currentLocation;

    if (location != null) {
      Future.delayed(
        const Duration(
          milliseconds: 300,
        ),
        () => _moveCameraToLocation(
          location,
          zoom: 16.5,
        ),
      );
    }
  }

  void _onCameraMoveStarted() {
    _isFollowingLocation = false;
  }

  Future<void> _goToMyLocation() async {
    if (_currentLocation == null) {
      await _startLiveLocation();
      return;
    }

    _isFollowingLocation = true;

    await _moveCameraToLocation(
      _currentLocation!,
      zoom: 17,
    );
  }

  // ============================================================
  // LOCATION DIALOG
  // ============================================================

  void _showLocationDialog({
    required String title,
    required String message,
    bool openLocationSettings = false,
    bool openAppSettings = false,
  }) {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop();
              },
              child: const Text(
                'Cancel',
              ),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(
                  dialogContext,
                ).pop();

                if (openLocationSettings) {
                  await _locationService
                      .openLocationSettings();
                }

                if (openAppSettings) {
                  await _locationService
                      .openAppSettings();
                }
              },
              child: const Text(
                'Open Settings',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // MESSAGE
  // ============================================================

  void _showMessage(
    String message,
  ) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
  }

  // ============================================================
  // DESTINATION CHANGE
  // ============================================================

  void _onDestinationChanged(
    String value,
  ) {
    _autocompleteDebounce?.cancel();

    final String query = value.trim();

    if (query.isEmpty) {
      _clearDestination();
      return;
    }

    if (query.length < 3) {
      if (!mounted) return;

      setState(() {
        _suggestions =
            <PlaceSuggestion>[];

        isSearching = false;
      });

      return;
    }

    setState(() {
      isSearching = true;
      showVehicles = false;
    });

    _autocompleteDebounce = Timer(
      const Duration(
        milliseconds: 450,
      ),
      () => _searchSuggestions(query),
    );
  }

  // ============================================================
  // GOOGLE AUTOCOMPLETE
  // ============================================================

  Future<void> _searchSuggestions(
    String query,
  ) async {
    try {
      final List<PlaceSuggestion> results =
          await _directionsService.autocomplete(
        query,
        location: _currentLocation,
      );

      if (!mounted) return;

      if (destinationController.text.trim() !=
          query) {
        return;
      }

      setState(() {
        _suggestions = results;
        isSearching = false;
      });
    } catch (e) {
      debugPrint(
        'Autocomplete error: $e',
      );

      if (!mounted) return;

      setState(() {
        _suggestions =
            <PlaceSuggestion>[];

        isSearching = false;
      });

      _showMessage(
        'Unable to search location.',
      );
    }
  }

  // ============================================================
  // SELECT DESTINATION
  // ============================================================

  Future<void> _selectSuggestion(
    PlaceSuggestion suggestion,
  ) async {
    FocusScope.of(context).unfocus();

    _autocompleteDebounce?.cancel();

    setState(() {
      destinationController.text =
          suggestion.description;

      _suggestions =
          <PlaceSuggestion>[];

      isSearching = false;

      isCalculatingFare = true;
    });

    try {
      final LatLng? destination =
          await _directionsService
              .getPlaceLocation(
        suggestion.placeId,
      );

      if (!mounted) return;

      if (destination == null) {
        setState(() {
          isCalculatingFare = false;
        });

        _showMessage(
          'Unable to get this location. Please select again.',
        );

        return;
      }

      _destinationLocation =
          destination;

      _updateDestinationMarker(
        destination,
      );

      await _calculateRouteFromLiveLocation();
    } catch (e) {
      debugPrint(
        'Place selection error: $e',
      );

      if (!mounted) return;

      setState(() {
        isCalculatingFare = false;
      });

      _showMessage(
        'Unable to find this location.',
      );
    }
  }

  // ============================================================
  // CLEAR DESTINATION
  // ============================================================

  void _clearDestination() {
    if (!mounted) return;

    setState(() {
      _destinationLocation = null;

      _outstationPopupShown = false;

      _suggestions =
          <PlaceSuggestion>[];

      showVehicles = false;

      isCalculatingFare = false;

      distanceInKm = 0;

      durationInMinutes = 0;

      miniFare = 0;

      sedanFare = 0;

      sedanAcFare = 0;

      sedanNonAcFare = 0;

      suvFare = 0;

      suvAcFare = 0;

      suvNonAcFare = 0;

      _displayMiniFare = 0;

      _displaySedanFare = 0;

      _displaySuvFare = 0;

      _polylines =
          <Polyline>{};

      _markers.removeWhere(
        (marker) =>
            marker.markerId.value ==
            'destination',
      );
    });
  }

  // ============================================================
  // DESTINATION MARKER
  // ============================================================

  void _updateDestinationMarker(
    LatLng location,
  ) {
    final Set<Marker> markers =
        Set<Marker>.from(_markers);

    markers.removeWhere(
      (marker) =>
          marker.markerId.value ==
          'destination',
    );

    markers.add(
      Marker(
        markerId:
            const MarkerId('destination'),
        position: location,
        icon:
            BitmapDescriptor.defaultMarkerWithHue(
          BitmapDescriptor.hueRed,
        ),
        infoWindow: const InfoWindow(
          title: 'Destination',
        ),
        zIndexInt: 9,
      ),
    );

    if (!mounted) return;

    setState(() {
      _markers = markers;
    });
  }

  // ============================================================
  // LOW → HIGH FARE MAPPING
  // ============================================================

  void _prepareLowToHighFareDisplay() {
    final List<double> fares = [
      miniFare,
      sedanFare,
      suvFare,
    ];

    fares.sort();

    _displayMiniFare = fares[0];

    _displaySedanFare = fares[1];

    _displaySuvFare = fares[2];
  }

  // ============================================================
  // ROUTE + FARE CALCULATION
  // ============================================================

  Future<void>
      _calculateRouteFromLiveLocation() async {
    final LatLng? pickup =
        _currentLocation;

    final LatLng? destination =
        _destinationLocation;

    if (pickup == null ||
        destination == null) {
      if (mounted) {
        setState(() {
          isCalculatingFare = false;
        });
      }

      _showMessage(
        'Current location or destination is not available.',
      );

      return;
    }

    if (_routeRequestRunning) {
      return;
    }

    if (_lastRouteRequestTime != null) {
      final Duration difference =
          DateTime.now().difference(
        _lastRouteRequestTime!,
      );

      if (difference.inSeconds < 8) {
        return;
      }
    }

    _routeRequestRunning = true;

    _lastRouteRequestTime =
        DateTime.now();

    if (mounted) {
      setState(() {
        isCalculatingFare = true;
      });
    }

    try {
      final Map<String, dynamic>?
          routeData =
          await _directionsService
              .getRoute(
        pickup,
        destination,
      );

      if (!mounted) return;

      if (routeData == null) {
        setState(() {
          isCalculatingFare = false;
          showVehicles = false;
        });

        _showMessage(
          'Unable to calculate route. Please try again.',
        );

        return;
      }

      final double liveDistance =
          _directionsService
              .getDistanceKm(
        routeData,
      );

      final int liveDuration =
          _directionsService
              .getDurationMinutes(
        routeData,
      );

      final double calculatedMini =
          FareCalculator.calculateMiniFare(
        liveDistance,
      );

      final double calculatedSedan;

      if (_isOutstation) {
        calculatedSedan =
            FareCalculator.sedanAcFare(
          liveDistance,
        );
      } else {
        calculatedSedan =
            FareCalculator.sedanLocalFare(
          liveDistance,
        );
      }

      final double calculatedSedanAc =
          FareCalculator.sedanAcFare(
        liveDistance,
      );

      final double calculatedSedanNonAc =
          FareCalculator.sedanNonAcFare(
        liveDistance,
      );

      final double calculatedSuvAc =
          FareCalculator.suvAcFare(
        liveDistance,
      );

      final double calculatedSuvNonAc =
          FareCalculator.suvNonAcFare(
        liveDistance,
      );

      final double calculatedSuv =
          calculatedSuvAc;

      setState(() {
        distanceInKm =
            liveDistance;

        durationInMinutes =
            liveDuration;

        miniFare =
            calculatedMini;

        sedanFare =
            calculatedSedan;

        sedanAcFare =
            calculatedSedanAc;

        sedanNonAcFare =
            calculatedSedanNonAc;

        suvFare =
            calculatedSuv;

        suvAcFare =
            calculatedSuvAc;

        suvNonAcFare =
            calculatedSuvNonAc;

        isCalculatingFare = false;

        showVehicles =
            liveDistance > 0;
      });

      setState(() {
        _prepareLowToHighFareDisplay();
      });

      if (!_isOutstation &&
          liveDistance >= 50 &&
          !_outstationPopupShown) {
        _outstationPopupShown = true;

        WidgetsBinding.instance
            .addPostFrameCallback(
          (_) {
            if (!mounted) return;

            if (!_isOutstation) {
              _showOutstationPopup();
            }
          },
        );
      }

      if (!_panelController.isCompleted) {
        await _panelController.forward();
      }

      _vehicleController
        ..reset()
        ..forward();

      await _drawRoute(
        routeData,
      );
    } catch (e) {
      debugPrint(
        'Route calculation error: $e',
      );

      if (!mounted) return;

      setState(() {
        isCalculatingFare = false;
        showVehicles = false;
      });

      _showMessage(
        'Unable to calculate route.',
      );
    } finally {
      _routeRequestRunning = false;
    }
  }

  // ============================================================
  // OUTSTATION POPUP
  // ============================================================

  void _showOutstationPopup() {
    if (!mounted) return;

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.alt_route_rounded,
                color: Colors.orange,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Long Distance Trip',
                  style: TextStyle(
                    fontWeight:
                        FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          content: Text(
            'This trip is ${distanceInKm.toStringAsFixed(1)} KM long.\n\n'
            'Would you like to switch from Local to Outstation?',
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },
              child: const Text(
                'Keep Local',
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );

                setState(() {
                  _isOutstation = true;
                });

                _recalculateOutstationFare();
              },
              style:
                  ElevatedButton.styleFrom(
                backgroundColor:
                    AppColors.primaryBlue,
                foregroundColor:
                    Colors.white,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),
              child: const Text(
                'Switch to Outstation',
              ),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // RECALCULATE OUTSTATION FARE
  // ============================================================

  void _recalculateOutstationFare() {
    final double distance =
        distanceInKm;

    if (distance <= 0) return;

    final double newMiniFare =
        FareCalculator.calculateMiniFare(
      distance,
    );

    final double newSedanAcFare =
        FareCalculator.sedanAcFare(
      distance,
    );

    final double newSedanNonAcFare =
        FareCalculator.sedanNonAcFare(
      distance,
    );

    final double newSuvAcFare =
        FareCalculator.suvAcFare(
      distance,
    );

    final double newSuvNonAcFare =
        FareCalculator.suvNonAcFare(
      distance,
    );

    setState(() {
      miniFare =
          newMiniFare;

      sedanAcFare =
          newSedanAcFare;

      sedanNonAcFare =
          newSedanNonAcFare;

      sedanFare =
          newSedanAcFare;

      suvAcFare =
          newSuvAcFare;

      suvNonAcFare =
          newSuvNonAcFare;

      suvFare =
          newSuvAcFare;
    });

    setState(() {
      _prepareLowToHighFareDisplay();
    });
  }

  // ============================================================
  // DRAW ROUTE
  // ============================================================

  Future<void> _drawRoute(
    Map<String, dynamic> routeData,
  ) async {
    final List<LatLng> points =
        _directionsService
            .getRoutePoints(
      routeData,
    );

    if (points.isEmpty) {
      debugPrint(
        'No route polyline points found.',
      );

      return;
    }

    final Polyline routePolyline =
        Polyline(
      polylineId:
          const PolylineId(
        'live_route',
      ),
      points: points,
      width: 6,
      color:
          AppColors.primaryBlue,
      startCap: Cap.roundCap,
      endCap: Cap.roundCap,
      jointType:
          JointType.round,
      zIndex: 1,
    );

    if (!mounted) return;

    setState(() {
      _polylines =
          <Polyline>{
        routePolyline,
      };
    });

    await _fitRouteCamera(
      points,
    );
  }

  // ============================================================
  // FIT CAMERA
  // ============================================================

  Future<void> _fitRouteCamera(
    List<LatLng> points,
  ) async {
    final GoogleMapController?
        controller =
        _mapController;

    if (controller == null ||
        points.isEmpty) {
      return;
    }

    if (points.length == 1) {
      await _moveCameraToLocation(
        points.first,
        zoom: 15,
      );

      return;
    }

    double minLat =
        points.first.latitude;

    double maxLat =
        points.first.latitude;

    double minLng =
        points.first.longitude;

    double maxLng =
        points.first.longitude;

    for (final LatLng point in points) {
      if (point.latitude < minLat) {
        minLat =
            point.latitude;
      }

      if (point.latitude > maxLat) {
        maxLat =
            point.latitude;
      }

      if (point.longitude < minLng) {
        minLng =
            point.longitude;
      }

      if (point.longitude > maxLng) {
        maxLng =
            point.longitude;
      }
    }

    if ((maxLat - minLat).abs() <
            0.00001 &&
        (maxLng - minLng).abs() <
            0.00001) {
      await _moveCameraToLocation(
        points.first,
        zoom: 16,
      );

      return;
    }

    try {
      await controller.animateCamera(
        CameraUpdate.newLatLngBounds(
          LatLngBounds(
            southwest: LatLng(
              minLat,
              minLng,
            ),
            northeast: LatLng(
              maxLat,
              maxLng,
            ),
          ),
          90,
        ),
      );
    } catch (e) {
      debugPrint(
        'Fit camera error: $e',
      );
    }
  }

  // ============================================================
  // PRICE
  // ============================================================

  double _getVehicleFare(
    int index,
  ) {
    switch (index) {
      case 0:
        return _displayMiniFare;

      case 1:
        return _displaySedanFare;

      case 2:
        return _displaySuvFare;

      default:
        return 0;
    }
  }

  // ============================================================
  // VEHICLE SUBTITLE
  // ============================================================

  String _getVehicleSubtitle(
    int index,
  ) {
    switch (index) {
      case 0:
        return '3 seater • Local';

      case 1:
        if (_isOutstation) {
          return '5 seater • AC';
        }

        return '5 seater • Local';

      case 2:
        return '7 seater • AC';

      default:
        return '';
    }
  }

  // ============================================================
  // ETA FORMAT
  // ============================================================

  String _formatDuration(
    int totalMinutes,
  ) {
    if (totalMinutes <= 0) {
      return '--';
    }

    final int hours =
        totalMinutes ~/ 60;

    final int minutes =
        totalMinutes % 60;

    if (hours > 0 &&
        minutes > 0) {
      return '$hours hr $minutes min';
    }

    if (hours > 0) {
      return '$hours hr';
    }

    return '$minutes min';
  }

  // ============================================================
  // CONFIRM RIDE
  // ============================================================

  void _confirmRide() {
    if (_currentLocation == null) {
      _showMessage(
        'Current location is not available.',
      );

      return;
    }

    if (_destinationLocation == null) {
      _showMessage(
        'Please select destination.',
      );

      return;
    }

    if (distanceInKm <= 0) {
      _showMessage(
        'Please wait for fare calculation.',
      );

      return;
    }

    final double fare =
        _getVehicleFare(
      selectedVehicle,
    );

    if (fare <= 0) {
      _showMessage(
        'Fare is not available.',
      );

      return;
    }

    // ==========================================================
    // DIRECT PAYMENT SCREEN
    // ==========================================================

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaymentSheet(
          fare: fare,
          vehicle:
              vehicleNames[selectedVehicle],
          distanceKm:
              distanceInKm,
          durationMinutes:
              durationInMinutes
                  .toDouble(),
          pickup:
              pickupController.text
                      .trim()
                      .isEmpty
                  ? 'Current Location'
                  : pickupController.text
                      .trim(),
          destination:
              destinationController.text
                  .trim(),
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      backgroundColor:
          Colors.white,
      body: Stack(
        children: [
          Positioned.fill(
            child:
                _buildGoogleMap(),
          ),

          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child:
                  _buildFloatingSearch(),
            ),
          ),

          Positioned(
            right: 16,
            bottom:
                showVehicles
                    ? 395
                    : 30,
            child:
                _buildMyLocationButton(),
          ),

          if (showVehicles)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: SafeArea(
                top: false,
                child:
                    SlideTransition(
                  position:
                      Tween<Offset>(
                    begin:
                        const Offset(
                      0,
                      1,
                    ),
                    end:
                        Offset.zero,
                  ).animate(
                    CurvedAnimation(
                      parent:
                          _panelController,
                      curve: Curves
                          .easeOutCubic,
                    ),
                  ),
                  child:
                      FadeTransition(
                    opacity:
                        _panelController,
                    child:
                        _buildBottomRidePanel(),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // GOOGLE MAP
  // ============================================================

  Widget _buildGoogleMap() {
    final LatLng
        defaultLocation =
        _currentLocation ??
            const LatLng(
              10.627143495791035,
              79.25168500411812,
            );

    return GoogleMap(
      initialCameraPosition:
          CameraPosition(
        target:
            defaultLocation,
        zoom: 15,
      ),
      onMapCreated:
          _onMapCreated,
      onCameraMoveStarted:
          _onCameraMoveStarted,
      myLocationEnabled:
          false,
      myLocationButtonEnabled:
          false,
      zoomControlsEnabled:
          false,
      compassEnabled: true,
      mapToolbarEnabled:
          false,
      buildingsEnabled: true,
      trafficEnabled: false,
      markers: _markers,
      polylines:
          _polylines,
      mapType:
          MapType.normal,
      padding:
          EdgeInsets.only(
        top: 165,
        bottom:
            showVehicles
                ? 390
                : 40,
      ),
    );
  }

  // ============================================================
  // FLOATING SEARCH
  // ============================================================

  Widget _buildFloatingSearch() {
    return AnimatedBuilder(
      animation:
          _searchController,
      builder:
          (context, child) {
        final double value =
            _searchController
                .value;

        return Transform.translate(
          offset: Offset(
            0,
            -25 *
                (1 - value),
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Padding(
        padding:
            const EdgeInsets
                .fromLTRB(
          12,
          8,
          12,
          0,
        ),
        child: Column(
          children: [
            _buildFloatingLocationField(
              controller:
                  pickupController,
              hint:
                  'Current Location',
              icon:
                  Icons.my_location_rounded,
              iconColor:
                  Colors.green,
              readOnly: true,
              loading:
                  isLoadingLocation,
            ),

            const SizedBox(
              height: 10,
            ),

            _buildDestinationArea(),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // DESTINATION AREA
  // ============================================================

  Widget _buildDestinationArea() {
    return Column(
      children: [
        _buildFloatingLocationField(
          controller:
              destinationController,
          hint:
              'Where do you want to go?',
          icon:
              Icons.location_on_rounded,
          iconColor:
              Colors.red,
          readOnly: false,
          loading:
              isSearching ||
                  isCalculatingFare,
          onChanged:
              _onDestinationChanged,
        ),

        if (_suggestions
            .isNotEmpty)
          _buildSuggestionsList(),
      ],
    );
  }

  // ============================================================
  // SUGGESTIONS
  // ============================================================

  Widget _buildSuggestionsList() {
    return TweenAnimationBuilder<
        double>(
      duration:
          const Duration(
        milliseconds: 300,
      ),
      curve:
          Curves.easeOutCubic,
      tween:
          Tween<double>(
        begin: 0,
        end: 1,
      ),
      builder: (
        context,
        value,
        child,
      ) {
        return Transform.translate(
          offset: Offset(
            0,
            -10 *
                (1 - value),
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Container(
        margin:
            const EdgeInsets.only(
          top: 5,
        ),
        constraints:
            const BoxConstraints(
          maxHeight: 270,
        ),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(
            16,
          ),
          boxShadow: const [
            BoxShadow(
              blurRadius: 18,
              spreadRadius: 1,
              offset:
                  Offset(0, 5),
              color:
                  Colors.black26,
            ),
          ],
        ),
        child:
            ListView.separated(
          shrinkWrap: true,
          padding:
              const EdgeInsets.symmetric(
            vertical: 6,
          ),
          itemCount:
              _suggestions.length,
          separatorBuilder:
              (_, __) =>
                  Divider(
            height: 1,
            color: Colors
                .grey
                .shade200,
          ),
          itemBuilder:
              (context, index) {
            final PlaceSuggestion
                suggestion =
                _suggestions[
                    index];

            return InkWell(
              onTap: () =>
                  _selectSuggestion(
                suggestion,
              ),
              child: Padding(
                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration:
                          BoxDecoration(
                        color: AppColors
                            .primaryBlue
                            .withValues(
                          alpha: 0.09,
                        ),
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          Icon(
                        Icons
                            .location_on_rounded,
                        color: AppColors
                            .primaryBlue,
                        size: 21,
                      ),
                    ),

                    const SizedBox(
                      width: 12,
                    ),

                    Expanded(
                      child:
                          Column(
                        crossAxisAlignment:
                            CrossAxisAlignment
                                .start,
                        children: [
                          Text(
                            suggestion
                                .title,
                            maxLines: 1,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                const TextStyle(
                              fontWeight:
                                  FontWeight
                                      .w800,
                              fontSize:
                                  14,
                            ),
                          ),

                          const SizedBox(
                            height: 3,
                          ),

                          Text(
                            suggestion
                                .subtitle,
                            maxLines: 2,
                            overflow:
                                TextOverflow
                                    .ellipsis,
                            style:
                                TextStyle(
                              color: Colors
                                  .grey
                                  .shade600,
                              fontSize:
                                  12,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Icon(
                      Icons
                          .chevron_right_rounded,
                      color:
                          Colors.grey,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LOCATION FIELD
  // ============================================================

  Widget _buildFloatingLocationField({
    required TextEditingController
        controller,
    required String hint,
    required IconData icon,
    required Color iconColor,
    required bool readOnly,
    required bool loading,
    ValueChanged<String>?
        onChanged,
  }) {
    return AnimatedContainer(
      duration:
          const Duration(
        milliseconds: 250,
      ),
      decoration:
          BoxDecoration(
        borderRadius:
            BorderRadius.circular(
          16,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black
                .withValues(
              alpha: 0.16,
            ),
            blurRadius: 12,
            offset:
                const Offset(
              0,
              4,
            ),
          ),
        ],
      ),
      child: TextField(
        controller:
            controller,
        focusNode:
            readOnly
                ? null
                : destinationFocusNode,
        readOnly:
            readOnly,
        onChanged:
            onChanged,
        textInputAction:
            TextInputAction.search,
        style:
            const TextStyle(
          color:
              Colors.black87,
          fontSize: 15,
          fontWeight:
              FontWeight.w600,
        ),
        decoration:
            InputDecoration(
          hintText:
              hint,
          hintStyle:
              TextStyle(
            color: Colors
                .grey
                .shade600,
            fontSize: 15,
            fontWeight:
                FontWeight.w500,
          ),
          prefixIcon:
              Icon(
            icon,
            color:
                iconColor,
            size: 23,
          ),
          suffixIcon:
              loading
                  ? const Padding(
                      padding:
                          EdgeInsets.all(
                        13,
                      ),
                      child:
                          SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth:
                              2,
                        ),
                      ),
                    )
                  : controller
                              .text
                              .isNotEmpty &&
                          !readOnly
                      ? IconButton(
                          icon:
                              const Icon(
                            Icons
                                .close_rounded,
                          ),
                          onPressed:
                              () {
                            controller
                                .clear();

                            _clearDestination();
                          },
                        )
                      : null,
          filled: true,
          fillColor:
              Colors.white,
          border:
              OutlineInputBorder(
            borderRadius:
                BorderRadius
                    .circular(
              16,
            ),
            borderSide:
                BorderSide.none,
          ),
          enabledBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius
                    .circular(
              16,
            ),
            borderSide:
                BorderSide.none,
          ),
          focusedBorder:
              OutlineInputBorder(
            borderRadius:
                BorderRadius
                    .circular(
              16,
            ),
            borderSide:
                BorderSide(
              color: AppColors
                  .primaryBlue,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets
                  .symmetric(
            horizontal: 14,
            vertical: 16,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // MY LOCATION BUTTON
  // ============================================================

  Widget _buildMyLocationButton() {
    return Material(
      color: Colors.white,
      elevation: 7,
      shape:
          const CircleBorder(),
      child: InkWell(
        customBorder:
            const CircleBorder(),
        onTap:
            _goToMyLocation,
        child:
            const SizedBox(
          width: 52,
          height: 52,
          child: Icon(
            Icons
                .my_location_rounded,
            color:
                Colors.black87,
            size: 24,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM RIDE PANEL
  // ============================================================

  Widget _buildBottomRidePanel() {
    return Container(
      constraints:
          const BoxConstraints(
        maxHeight: 405,
      ),
      padding:
          const EdgeInsets
              .fromLTRB(
        16,
        12,
        16,
        12,
      ),
      decoration:
          const BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.vertical(
          top:
              Radius.circular(
            25,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color:
                Colors.black26,
            blurRadius: 18,
            offset:
                Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize:
            MainAxisSize.min,
        children: [
          Container(
            width: 45,
            height: 4,
            margin:
                const EdgeInsets
                    .only(
              bottom: 10,
            ),
            decoration:
                BoxDecoration(
              color: Colors
                  .grey
                  .shade300,
              borderRadius:
                  BorderRadius
                      .circular(
                10,
              ),
            ),
          ),

          _buildRouteSummary(),

          const SizedBox(
            height: 8,
          ),

          Expanded(
            child:
                ListView.builder(
              physics:
                  const BouncingScrollPhysics(),
              itemCount:
                  vehicleNames.length,
              itemBuilder:
                  (context, index) {
                return AnimatedBuilder(
                  animation:
                      _vehicleController,
                  builder:
                      (context, child) {
                    final double
                        start =
                        index *
                            0.15;

                    final double
                        end =
                        start +
                            0.55;

                    final double
                        raw =
                        ((_vehicleController
                                        .value -
                                    start) /
                                (end -
                                    start))
                            .clamp(
                      0.0,
                      1.0,
                    );

                    final double
                        value =
                        Curves
                            .easeOutCubic
                            .transform(
                      raw,
                    );

                    return Transform
                        .translate(
                      offset:
                          Offset(
                        0,
                        25 *
                            (1 -
                                value),
                      ),
                      child:
                          Opacity(
                        opacity:
                            value,
                        child:
                            child,
                      ),
                    );
                  },
                  child:
                      _buildCompactVehicle(
                    index:
                        index,
                    icon:
                        vehicleIcons[
                            index],
                  ),
                );
              },
            ),
          ),

          const SizedBox(
            height: 8,
          ),

          SizedBox(
            width:
                double.infinity,
            height: 52,
            child:
                ElevatedButton(
              onPressed:
                  isCalculatingFare
                      ? null
                      : _confirmRide,
              style:
                  ElevatedButton
                      .styleFrom(
                backgroundColor:
                    AppColors
                        .primaryBlue,
                disabledBackgroundColor:
                    Colors
                        .grey
                        .shade400,
                elevation: 0,
                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius
                          .circular(
                    14,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  const Text(
                    'CONFIRM RIDE',
                    style:
                        TextStyle(
                      color:
                          Colors.white,
                      fontSize:
                          16,
                      fontWeight:
                          FontWeight
                              .w800,
                    ),
                  ),

                  const SizedBox(
                    width: 10,
                  ),

                  AnimatedSwitcher(
                    duration:
                        const Duration(
                      milliseconds:
                          250,
                    ),
                    child:
                        Text(
                      '₹${_getVehicleFare(selectedVehicle).toStringAsFixed(0)}',
                      key:
                          ValueKey(
                        _getVehicleFare(
                          selectedVehicle,
                        ).round(),
                      ),
                      style:
                          const TextStyle(
                        color:
                            Colors.white,
                        fontSize:
                            16,
                        fontWeight:
                            FontWeight
                                .w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ROUTE SUMMARY
  // ============================================================

  Widget _buildRouteSummary() {
    return AnimatedSwitcher(
      duration:
          const Duration(
        milliseconds: 300,
      ),
      transitionBuilder:
          (child, animation) {
        return FadeTransition(
          opacity:
              animation,
          child:
              SlideTransition(
            position:
                Tween<Offset>(
              begin:
                  const Offset(
                0,
                0.15,
              ),
              end:
                  Offset.zero,
            ).animate(
              animation,
            ),
            child:
                child,
          ),
        );
      },
      child: Row(
        key: ValueKey(
          '$distanceInKm-$durationInMinutes',
        ),
        children: [
          Expanded(
            child:
                Column(
              children: [
                Text(
                  '${distanceInKm.toStringAsFixed(1)} km',
                  style:
                      const TextStyle(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Distance',
                  style:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize:
                        12,
                  ),
                ),
              ],
            ),
          ),

          Container(
            width: 1,
            height: 35,
            color:
                Colors.grey.shade300,
          ),

          Expanded(
            child:
                Column(
              children: [
                Text(
                  _formatDuration(
                    durationInMinutes,
                  ),
                  style:
                      const TextStyle(
                    fontSize:
                        17,
                    fontWeight:
                        FontWeight
                            .w800,
                  ),
                ),
                const SizedBox(
                  height: 2,
                ),
                Text(
                  'Estimated time',
                  style:
                      TextStyle(
                    color: Colors
                        .grey
                        .shade600,
                    fontSize:
                        12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // VEHICLE CARD
  // ============================================================

  Widget _buildCompactVehicle({
    required int index,
    required IconData icon,
  }) {
    final bool selected =
        selectedVehicle ==
            index;

    final double fare =
        _getVehicleFare(
      index,
    );

    return GestureDetector(
      onTap: () {
        if (!mounted) return;

        setState(() {
          selectedVehicle =
              index;
        });
      },
      child:
          AnimatedContainer(
        duration:
            const Duration(
          milliseconds: 300,
        ),
        curve:
            Curves.easeOutCubic,
        margin:
            const EdgeInsets
                .only(
          bottom: 6,
        ),
        padding:
            const EdgeInsets
                .symmetric(
          horizontal: 10,
          vertical: 7,
        ),
        decoration:
            BoxDecoration(
          color: selected
              ? AppColors
                  .primaryBlue
                  .withValues(
                  alpha: 0.08,
                )
              : Colors.white,
          borderRadius:
              BorderRadius.circular(
            12,
          ),
          border:
              Border.all(
            color: selected
                ? AppColors
                    .primaryBlue
                : Colors
                    .grey
                    .shade200,
            width:
                selected
                    ? 1.4
                    : 1,
          ),
          boxShadow:
              selected
                  ? [
                      BoxShadow(
                        color: AppColors
                            .primaryBlue
                            .withValues(
                          alpha:
                              0.10,
                        ),
                        blurRadius:
                            10,
                        offset:
                            const Offset(
                          0,
                          3,
                        ),
                      ),
                    ]
                  : null,
        ),
        child:
            Row(
          children: [
            AnimatedScale(
              scale:
                  selected
                      ? 1.12
                      : 1.0,
              duration:
                  const Duration(
                milliseconds:
                    250,
              ),
              child:
                  Icon(
                icon,
                size: 29,
                color: selected
                    ? AppColors
                        .primaryBlue
                    : Colors
                        .grey
                        .shade700,
              ),
            ),

            const SizedBox(
              width: 12,
            ),

            Expanded(
              child:
                  Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,
                children: [
                  Text(
                    vehicleNames[
                        index],
                    style:
                        TextStyle(
                      fontSize:
                          14,
                      fontWeight:
                          FontWeight
                              .w800,
                      color: selected
                          ? AppColors
                              .primaryBlue
                          : Colors
                              .black87,
                    ),
                  ),
                  Text(
                    _getVehicleSubtitle(
                      index,
                    ),
                    style:
                        TextStyle(
                      fontSize:
                          11,
                      color: Colors
                          .grey
                          .shade600,
                    ),
                  ),
                ],
              ),
            ),

            AnimatedSwitcher(
              duration:
                  const Duration(
                milliseconds:
                    250,
              ),
              transitionBuilder:
                  (
                child,
                animation,
              ) {
                return ScaleTransition(
                  scale:
                      animation,
                  child:
                      child,
                );
              },
              child:
                  Text(
                '₹${fare.toStringAsFixed(0)}',
                key:
                    ValueKey(
                  '$index-${fare.round()}',
                ),
                style:
                    TextStyle(
                  fontSize:
                      15,
                  fontWeight:
                      FontWeight
                          .w800,
                  color: selected
                      ? AppColors
                          .primaryBlue
                      : Colors
                          .black87,
                ),
              ),
            ),

            const SizedBox(
              width: 7,
            ),

            AnimatedScale(
              scale:
                  selected
                      ? 1
                      : 0,
              duration:
                  const Duration(
                milliseconds:
                    250,
              ),
              child:
                  Container(
                width: 21,
                height: 21,
                decoration:
                    BoxDecoration(
                  color: AppColors
                      .primaryBlue,
                  shape:
                      BoxShape
                          .circle,
                ),
                child:
                    const Icon(
                  Icons.check,
                  size: 13,
                  color:
                      Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}