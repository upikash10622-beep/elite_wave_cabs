import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save a new booking to Firebase
  Future<void> saveBooking({
    required String userId,
    required String pickup,
    required String dropoff,
    required String vehicleType,
    required double fare,
  }) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .add({
      'pickup': pickup,
      'dropoff': dropoff,
      'vehicleType': vehicleType,
      'fare': fare,
      'createdAt': Timestamp.now(),
    });
  }

  // Fetch recent booking list for "My History"
  Stream<QuerySnapshot> getUserBookings(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('bookings')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}
