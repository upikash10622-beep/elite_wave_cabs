class DriverModel {
  final String id;
  final String name;
  final String phone;
  final String vehicleNumber;
  final String vehicleType; // e.g., "RedTaxi", "Auto"
  final double rating;
  final bool isOnline;
  final double latitude;
  final double longitude;

  DriverModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.vehicleNumber,
    required this.vehicleType,
    required this.rating,
    required this.isOnline,
    required this.latitude,
    required this.longitude,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'phone': phone,
        'vehicleNumber': vehicleNumber,
        'vehicleType': vehicleType,
        'rating': rating,
        'isOnline': isOnline,
        'latitude': latitude,
        'longitude': longitude,
      };

  factory DriverModel.fromMap(Map<String, dynamic> map) => DriverModel(
        id: map['id'] ?? '',
        name: map['name'] ?? '',
        phone: map['phone'] ?? '',
        vehicleNumber: map['vehicleNumber'] ?? '',
        vehicleType: map['vehicleType'] ?? '',
        rating: (map['rating'] ?? 0.0).toDouble(),
        isOnline: map['isOnline'] ?? false,
        latitude: (map['latitude'] ?? 0.0).toDouble(),
        longitude: (map['longitude'] ?? 0.0).toDouble(),
      );
}
