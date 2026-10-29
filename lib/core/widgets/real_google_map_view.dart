import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_colors.dart';
import 'mock_map_view.dart';

class RealGoogleMapView extends StatefulWidget {
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;

  final double? destinationLat;
  final double? destinationLng;
  final String? destinationAddress;

  final double? riderLat;
  final double? riderLng;

  final bool isPicker;
  final Function(LatLng position)? onLocationPicked;

  const RealGoogleMapView({
    super.key,
    this.pickupLat,
    this.pickupLng,
    this.pickupAddress,
    this.destinationLat,
    this.destinationLng,
    this.destinationAddress,
    this.riderLat,
    this.riderLng,
    this.isPicker = false,
    this.onLocationPicked,
  });

  @override
  State<RealGoogleMapView> createState() => _RealGoogleMapViewState();
}

class _RealGoogleMapViewState extends State<RealGoogleMapView> {
  GoogleMapController? _mapController;
  LatLng? _pickedLocation;
  bool _hasMapError = false;

  // Default coordinate: Bale Robe, Ethiopia
  static const LatLng _defaultCenter = LatLng(7.0083, 39.9833);

  @override
  void initState() {
    super.initState();
    if (widget.destinationLat != null && widget.destinationLng != null) {
      _pickedLocation = LatLng(widget.destinationLat!, widget.destinationLng!);
    }
  }

  @override
  void didUpdateWidget(covariant RealGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationLat != null && widget.destinationLng != null) {
      _pickedLocation = LatLng(widget.destinationLat!, widget.destinationLng!);
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    // 1. Pickup Marker
    if (widget.pickupLat != null && widget.pickupLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('pickup_marker'),
          position: LatLng(widget.pickupLat!, widget.pickupLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
          infoWindow: InfoWindow(
            title: 'Pickup Location',
            snippet: widget.pickupAddress ?? 'Origin',
          ),
        ),
      );
    }

    // 2. Destination Marker
    final destPosition = _pickedLocation ??
        (widget.destinationLat != null && widget.destinationLng != null
            ? LatLng(widget.destinationLat!, widget.destinationLng!)
            : null);

    if (destPosition != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('destination_marker'),
          position: destPosition,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(
            title: 'Destination',
            snippet: widget.destinationAddress ?? 'Delivery Point',
          ),
        ),
      );
    }

    // 3. Rider Live Marker
    if (widget.riderLat != null && widget.riderLng != null) {
      markers.add(
        Marker(
          markerId: const MarkerId('rider_marker'),
          position: LatLng(widget.riderLat!, widget.riderLng!),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
          infoWindow: const InfoWindow(
            title: 'Rider Location 🚴',
            snippet: 'On the way to destination',
          ),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildPolylines() {
    if (widget.pickupLat == null ||
        widget.pickupLng == null ||
        widget.destinationLat == null ||
        widget.destinationLng == null) {
      return {};
    }

    return {
      Polyline(
        polylineId: const PolylineId('delivery_route'),
        color: AppColors.primary,
        width: 4,
        points: [
          LatLng(widget.pickupLat!, widget.pickupLng!),
          if (widget.riderLat != null && widget.riderLng != null)
            LatLng(widget.riderLat!, widget.riderLng!),
          LatLng(widget.destinationLat!, widget.destinationLng!),
        ],
      ),
    };
  }

  void _onMapTapped(LatLng position) {
    if (!widget.isPicker) return;
    setState(() {
      _pickedLocation = position;
    });
    widget.onLocationPicked?.call(position);
  }

  @override
  Widget build(BuildContext context) {
    if (_hasMapError) {
      return MockMapView(
        pickupAddress: widget.pickupAddress,
        destinationAddress: widget.destinationAddress,
        showRoute: true,
        showRider: widget.riderLat != null,
      );
    }

    final initialCenter = _pickedLocation ??
        (widget.destinationLat != null && widget.destinationLng != null
            ? LatLng(widget.destinationLat!, widget.destinationLng!)
            : (widget.pickupLat != null && widget.pickupLng != null
                ? LatLng(widget.pickupLat!, widget.pickupLng!)
                : _defaultCenter));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: initialCenter,
              zoom: 14.5,
            ),
            markers: _buildMarkers(),
            polylines: _buildPolylines(),
            myLocationEnabled: !kIsWeb,
            myLocationButtonEnabled: !kIsWeb,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            onMapCreated: (controller) {
              _mapController = controller;
            },
            onTap: _onMapTapped,
          ),

          if (widget.isPicker)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.touch_app_rounded, size: 16, color: AppColors.primary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Tap anywhere on the map to pin destination',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
