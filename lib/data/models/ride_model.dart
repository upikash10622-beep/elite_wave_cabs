class RideModel {
  final String id;
  final String userId;
  final String driverId;
  final String vehicleType;
  final double price;
  final String status; // pending, accepted, started, completed
  final double startLat;
  final double startLng;
  final double endLat;
  final double endLng;
  final String endAddress;
  final DateTime timestamp;

  RideModel({
    required this.id,
    required this.userId,
    required this.driverId,
    required this.vehicleType,
    required this.price,
    required this.status,
    required this.startLat,
    required this.startLng,
    required this.endLat,
    required this.endLng,
    required this.endAddress,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'driverId': driverId,
        'vehicleType': vehicleType,
        'price': price,
        'status': status,
        'startLat': startLat,
        'startLng': startLng,
        'endLat': endLat,
        'endLng': endLng,
        'endAddress': endAddress,
        'timestamp': timestamp.toIso8601String(),
      };

  factory RideModel.fromMap(Map<String, dynamic> map) => RideModel(
        id: map['id'] ?? '',
        userId: map['userId'] ?? '',
        driverId: map['driverId'] ?? '',
        vehicleType: map['vehicleType'] ?? '',
        price: (map['price'] ?? 0.0).toDouble(),
        status: map['status'] ?? 'pending',
        startLat: (map['startLat'] ?? 0.0).toDouble(),
        startLng: (map['startLng'] ?? 0.0).toDouble(),
        endLat: (map['endLat'] ?? 0.0).toDouble(),
        endLng: (map['endLng'] ?? 0.0).toDouble(),
        endAddress: map['endAddress'] ?? '',
        timestamp: DateTime.parse(
            map['timestamp'] ?? DateTime.now().toIso8601String()),
      );
}
