import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

class GeoPoint {
  const GeoPoint({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;
}

class LocationController extends AutoDisposeAsyncNotifier<GeoPoint?> {
  @override
  FutureOr<GeoPoint?> build() async {
    return _determinePosition();
  }

  Future<GeoPoint?> refreshLocation() async {
    state = const AsyncLoading();
    final position = await _determinePosition();
    state = AsyncData(position);
    return position;
  }

  Future<GeoPoint?> _determinePosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return null;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      return null;
    }

    final position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    return GeoPoint(latitude: position.latitude, longitude: position.longitude);
  }
}

final locationControllerProvider =
    AutoDisposeAsyncNotifierProvider<LocationController, GeoPoint?>(
  LocationController.new,
  name: 'LocationControllerProvider',
);
