import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';

class LocationProvider extends ChangeNotifier {
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLoading = false;

  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLoading => _isLoading;

  Future<void> fetchCurrentLocation() async {
    _isLoading = true;
    notifyListeners();

    final position = await LocationService.getCurrentPosition();
    if (position != null) {
      _currentPosition = position;
      _currentAddress = await LocationService.getAddressFromCoordinates(
        position.latitude,
        position.longitude,
      );
    }

    _isLoading = false;
    notifyListeners();
  }
}
