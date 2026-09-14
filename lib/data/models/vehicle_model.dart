class VehicleModel {
  final String type;
  final String displayName;
  final int capacity;
  final double basePrice;

  VehicleModel(
      {required this.type,
      required this.displayName,
      required this.capacity,
      required this.basePrice});

  static List<VehicleModel> dummyVehicles() => [
        VehicleModel(
            type: 'RedTaxi',
            displayName: 'RedTaxi',
            capacity: 4,
            basePrice: 197),
        VehicleModel(
            type: 'GoTaxi', displayName: 'GoTaxi', capacity: 4, basePrice: 188),
        VehicleModel(
            type: 'Auto', displayName: 'Auto', capacity: 3, basePrice: 177),
        VehicleModel(
            type: 'Bike', displayName: 'Bike', capacity: 1, basePrice: 82),
      ];
}
