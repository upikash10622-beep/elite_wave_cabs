import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class RideService {
  RideService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  Future<String> createRide({
    required LatLng pickupLocation,
    required String pickupAddress,
    required LatLng destinationLocation,
    required String destinationAddress,
    required String vehicle,
    required double distanceKm,
    required int durationMinutes,
    required double fare,
    required bool isOutstation,
  }) async {
    final User? user = _auth.currentUser;

    final DocumentReference<Map<String, dynamic>> rideRef =
        _firestore.collection('rides').doc();

    await rideRef.set({
      'rideId': rideRef.id,

      'customerId': user?.uid ?? 'guest',

      'pickup': pickupAddress,
      'pickupLat': pickupLocation.latitude,
      'pickupLng': pickupLocation.longitude,

      'destination': destinationAddress,
      'destinationLat': destinationLocation.latitude,
      'destinationLng': destinationLocation.longitude,

      'vehicle': vehicle,

      'distanceKm': distanceKm,
      'durationMinutes': durationMinutes,

      'fare': fare,

      'isOutstation': isOutstation,

      'status': 'searching',

      'driverId': null,

      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return rideRef.id;
  }
}