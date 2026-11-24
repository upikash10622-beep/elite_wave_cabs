import 'package:material_ui/material_ui.dart';
import '../../../data/models/ride_model.dart';
import '../../../widgets/custom_button.dart';

class TripCompletedScreen extends StatelessWidget {
  final RideModel ride;

  const TripCompletedScreen({super.key, required this.ride});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text("Trip Completed!",
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Text("Total Fare: ₹${ride.price}",
                  style: const TextStyle(fontSize: 20, color: Colors.grey)),
              const SizedBox(height: 30),
              CustomButton(text: "Rate Driver", onPressed: () {}),
              const SizedBox(height: 10),
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Back to Home")),
            ],
          ),
        ),
      ),
    );
  }
}
