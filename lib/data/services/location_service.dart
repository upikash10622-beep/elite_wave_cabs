import 'package:geolocator/geolocator.dart';

class LocationService {
  // ============================================================
  // CHECK LOCATION SERVICE
  // ============================================================

  Future<bool> isServiceEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  // ============================================================
  // CHECK PERMISSION
  // ============================================================

  Future<LocationPermission> checkPermission() async {
    return await Geolocator.checkPermission();
  }

  // ============================================================
  // REQUEST PERMISSION
  // ============================================================

  Future<LocationPermission> requestPermission() async {
    return await Geolocator.requestPermission();
  }

  // ============================================================
  // GET CURRENT LOCATION
  // ============================================================

  Future<Position> getCurrentPosition() async {
    // ----------------------------------------------------------
    // Check GPS service
    // ----------------------------------------------------------

    final bool serviceEnabled =
        await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw Exception(
        'Location service is OFF',
      );
    }

    // ----------------------------------------------------------
    // Check permission
    // ----------------------------------------------------------

    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw Exception(
        'Location permission denied',
      );
    }

    if (permission ==
        LocationPermission.deniedForever) {
      throw Exception(
        'Location permission permanently denied',
      );
    }

    // ----------------------------------------------------------
    // Get GPS position
    // ----------------------------------------------------------

    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration:
            const Duration(seconds: 1),
        forceLocationManager: false,
      ),
    );
  }

  // ============================================================
  // LIVE LOCATION STREAM
  // ============================================================

  Stream<Position> getPositionStream() {
    return Geolocator.getPositionStream(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: 5,
        intervalDuration:
            const Duration(seconds: 1),
        forceLocationManager: false,
      ),
    );
  }

  // ============================================================
  // OPEN LOCATION SETTINGS
  // ============================================================

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  // ============================================================
  // OPEN APP SETTINGS
  // ============================================================

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }
}