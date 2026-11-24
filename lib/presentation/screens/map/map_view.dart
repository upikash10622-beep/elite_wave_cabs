import 'package:material_ui/material_ui.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapView extends StatefulWidget {
  final LatLng? origin;
  final LatLng? destination;
  final Set<Polyline>? polylines;

  const MapView({super.key, this.origin, this.destination, this.polylines});

  @override
  State<MapView> createState() => _MapViewState();
}

class _MapViewState extends State<MapView> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final Set<Marker> markers = {
      if (widget.origin != null)
        Marker(
          markerId: const MarkerId('origin'),
          position: widget.origin!,
        ),
      if (widget.destination != null)
        Marker(
          markerId: const MarkerId('destination'),
          position: widget.destination!,
        ),
    };

    final LatLng initialTarget =
        widget.origin ?? widget.destination ?? const LatLng(0, 0);

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: initialTarget,
        zoom: 12,
      ),
      markers: markers,
      polylines: widget.polylines ?? const <Polyline>{},
      myLocationEnabled: true,
      myLocationButtonEnabled: true,
      onMapCreated: (controller) {
        _mapController = controller;

        _mapController?.animateCamera(
          CameraUpdate.zoomTo(14),
        );
      },
    );
  }
}
