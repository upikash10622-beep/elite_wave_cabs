import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../data/models/ride_model.dart';
import '../../../widgets/custom_button.dart';
import '../map/map_view.dart';

class TripTrackingScreen extends StatelessWidget {
  final RideModel ride;

  const TripTrackingScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Trip Tracking")),
      body: Stack(
        children: [
          MapView(
            origin: LatLng(ride.startLat, ride.startLng),
            destination: LatLng(ride.endLat, ride.endLng),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.white,
              child: Column(
                children: [
                  const Text("Driver is on the way",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("Reaching drop location in 16 mins",
                      style: TextStyle(color: Colors.green)),
                  const SizedBox(height: 20),
                  CustomButton(text: "Contact Driver", onPressed: () {}),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
