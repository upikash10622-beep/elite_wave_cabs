import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String placeId;
  final String title;
  final String subtitle;
  final String description;

  const PlaceSuggestion({
    required this.placeId,
    required this.title,
    required this.subtitle,
    required this.description,
  });
}

class DirectionsService {
  // IMPORTANT:
  // Replace this with your Google Maps Platform API key.
  //
  // Enable:
  // 1. Places API (New)
  // 2. Routes API
  // 3. Maps SDK for Android
  //
  // For production, do NOT expose an unrestricted web-service key.
  static const String _apiKey = 'AIzaSyAEQUzAUyGFyWKftCdQYwt4BpHYLqbVTR0';

  String _newSessionToken() {
    return '${DateTime.now().microsecondsSinceEpoch}_${Random().nextInt(999999)}';
  }

  // ============================================================
  // PLACES API (NEW) - AUTOCOMPLETE
  // ============================================================

  Future<List<PlaceSuggestion>> autocomplete(
    String input, {
    LatLng? location,
  }) async {
    final query = input.trim();

    if (query.length < 3) {
      return <PlaceSuggestion>[];
    }

    final Map<String, dynamic> body = <String, dynamic>{
      'input': query,
      'includedRegionCodes': <String>['in'],
      'sessionToken': _newSessionToken(),
    };

    if (location != null) {
      body['locationBias'] = <String, dynamic>{
        'circle': <String, dynamic>{
          'center': <String, dynamic>{
            'latitude': location.latitude,
            'longitude': location.longitude,
          },
          'radius': 50000.0,
        },
      };
    }

    final Uri uri = Uri.parse(
      'https://places.googleapis.com/v1/places:autocomplete',
    );

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'suggestions.placePrediction.placeId,'
              'suggestions.placePrediction.text,'
              'suggestions.placePrediction.structuredFormat',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Autocomplete HTTP ${response.statusCode}: ${response.body}',
        );
        return <PlaceSuggestion>[];
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final suggestions = data['suggestions'];

      if (suggestions is! List) {
        return <PlaceSuggestion>[];
      }

      final List<PlaceSuggestion> result = <PlaceSuggestion>[];

      for (final item in suggestions) {
        if (item is! Map) continue;

        final prediction = item['placePrediction'];

        if (prediction is! Map) continue;

        final placeId = prediction['placeId']?.toString();

        if (placeId == null || placeId.isEmpty) continue;

        String description = '';
        String title = '';
        String subtitle = '';

        final text = prediction['text'];

        if (text is Map) {
          description = text['text']?.toString() ?? '';
        } else if (text != null) {
          description = text.toString();
        }

        final structured = prediction['structuredFormat'];

        if (structured is Map) {
          final mainText = structured['mainText'];
          final secondaryText = structured['secondaryText'];

          if (mainText is Map) {
            title = mainText['text']?.toString() ?? '';
          }

          if (secondaryText is Map) {
            subtitle = secondaryText['text']?.toString() ?? '';
          }
        }

        if (title.isEmpty) {
          title = description;
        }

        if (description.isEmpty) {
          description = title;
        }

        if (subtitle.isEmpty && description != title) {
          subtitle = description;
        }

        result.add(
          PlaceSuggestion(
            placeId: placeId,
            title: title,
            subtitle: subtitle,
            description: description,
          ),
        );
      }

      return result;
    } catch (e) {
      debugPrint('Autocomplete exception: $e');
      return <PlaceSuggestion>[];
    }
  }

  // ============================================================
  // PLACES API (NEW) - PLACE DETAILS
  // ============================================================

  Future<LatLng?> getPlaceLocation(String placeId) async {
    if (placeId.trim().isEmpty) return null;

    final Uri uri = Uri.parse(
      'https://places.googleapis.com/v1/places/'
      '${Uri.encodeComponent(placeId)}',
    );

    try {
      final response = await http.get(
        uri,
        headers: <String, String>{
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask': 'location,formattedAddress',
        },
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Place Details HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      final location = data['location'];

      if (location is! Map) return null;

      final lat = location['latitude'];
      final lng = location['longitude'];

      if (lat is! num || lng is! num) return null;

      return LatLng(
        lat.toDouble(),
        lng.toDouble(),
      );
    } catch (e) {
      debugPrint('Place Details exception: $e');
      return null;
    }
  }

  // ============================================================
  // ROUTES API - COMPUTE ROUTES
  // ============================================================

  Future<Map<String, dynamic>?> getRoute(
    LatLng origin,
    LatLng destination,
  ) async {
    final Uri uri = Uri.parse(
      'https://routes.googleapis.com/directions/v2:computeRoutes',
    );

    final Map<String, dynamic> body = <String, dynamic>{
      'origin': <String, dynamic>{
        'location': <String, dynamic>{
          'latLng': <String, dynamic>{
            'latitude': origin.latitude,
            'longitude': origin.longitude,
          },
        },
      },
      'destination': <String, dynamic>{
        'location': <String, dynamic>{
          'latLng': <String, dynamic>{
            'latitude': destination.latitude,
            'longitude': destination.longitude,
          },
        },
      },
      'travelMode': 'DRIVE',
      'routingPreference': 'TRAFFIC_AWARE',
      'computeAlternativeRoutes': false,
      'units': 'METRIC',
    };

    try {
      final response = await http.post(
        uri,
        headers: <String, String>{
          'Content-Type': 'application/json',
          'X-Goog-Api-Key': _apiKey,
          'X-Goog-FieldMask':
              'routes.distanceMeters,'
              'routes.duration,'
              'routes.polyline.encodedPolyline',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        debugPrint(
          'Routes HTTP ${response.statusCode}: ${response.body}',
        );
        return null;
      }

      final data =
          jsonDecode(response.body) as Map<String, dynamic>;

      if (data['routes'] is! List ||
          (data['routes'] as List).isEmpty) {
        return null;
      }

      return data;
    } catch (e) {
      debugPrint('Routes exception: $e');
      return null;
    }
  }

  // ============================================================
  // ROUTE DISTANCE
  // ============================================================

  double getDistanceKm(Map<String, dynamic>? routeData) {
    if (routeData == null) return 0;

    try {
      final routes = routeData['routes'];

      if (routes is! List || routes.isEmpty) return 0;

      final firstRoute = routes.first;

      if (firstRoute is! Map) return 0;

      final meters = firstRoute['distanceMeters'];

      if (meters is! num) return 0;

      return meters.toDouble() / 1000.0;
    } catch (e) {
      debugPrint('Distance parsing error: $e');
      return 0;
    }
  }

  // ============================================================
  // ROUTE DURATION
  // ============================================================

  int getDurationMinutes(Map<String, dynamic>? routeData) {
    if (routeData == null) return 0;

    try {
      final routes = routeData['routes'];

      if (routes is! List || routes.isEmpty) return 0;

      final firstRoute = routes.first;

      if (firstRoute is! Map) return 0;

      final duration = firstRoute['duration']?.toString();

      if (duration == null || duration.isEmpty) return 0;

      final secondsText = duration.replaceAll('s', '');
      final seconds = double.tryParse(secondsText);

      if (seconds == null) return 0;

      return (seconds / 60.0).ceil();
    } catch (e) {
      debugPrint('Duration parsing error: $e');
      return 0;
    }
  }

  // ============================================================
  // ENCODED POLYLINE
  // ============================================================

  String getEncodedPolyline(
    Map<String, dynamic>? routeData,
  ) {
    if (routeData == null) return '';

    try {
      final routes = routeData['routes'];

      if (routes is! List || routes.isEmpty) return '';

      final firstRoute = routes.first;

      if (firstRoute is! Map) return '';

      final polyline = firstRoute['polyline'];

      if (polyline is! Map) return '';

      return polyline['encodedPolyline']?.toString() ?? '';
    } catch (e) {
      debugPrint('Polyline extraction error: $e');
      return '';
    }
  }

  // ============================================================
  // DECODE POLYLINE
  // ============================================================

  List<LatLng> getRoutePoints(
    Map<String, dynamic>? routeData,
  ) {
    final encoded = getEncodedPolyline(routeData);

    if (encoded.isEmpty) {
      return <LatLng>[];
    }

    return _decodePolyline(encoded);
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<LatLng> points = <LatLng>[];

    int index = 0;
    int latitude = 0;
    int longitude = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;

      while (true) {
        if (index >= encoded.length) return points;

        final int byte =
            encoded.codeUnitAt(index++) - 63;

        result |= (byte & 0x1f) << shift;
        shift += 5;

        if (byte < 0x20) break;
      }

      final int deltaLatitude =
          (result & 1) != 0
              ? ~(result >> 1)
              : (result >> 1);

      latitude += deltaLatitude;

      shift = 0;
      result = 0;

      while (true) {
        if (index >= encoded.length) return points;

        final int byte =
            encoded.codeUnitAt(index++) - 63;

        result |= (byte & 0x1f) << shift;
        shift += 5;

        if (byte < 0x20) break;
      }

      final int deltaLongitude =
          (result & 1) != 0
              ? ~(result >> 1)
              : (result >> 1);

      longitude += deltaLongitude;

      points.add(
        LatLng(
          latitude / 100000.0,
          longitude / 100000.0,
        ),
      );
    }

    return points;
  }
}
