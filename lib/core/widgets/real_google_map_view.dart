import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as ll;
import '../constants/app_colors.dart';

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
  final Function(dynamic position)? onLocationPicked;

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
  late final MapController _mapController;
  ll.LatLng? _pickedLocation;

  // Default coordinate: Bale Robe, Ethiopia
  static const ll.LatLng _defaultCenter = ll.LatLng(7.0083, 39.9833);

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    if (widget.destinationLat != null && widget.destinationLng != null) {
      _pickedLocation = ll.LatLng(widget.destinationLat!, widget.destinationLng!);
    }
  }

  @override
  void didUpdateWidget(covariant RealGoogleMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationLat != null && widget.destinationLng != null) {
      _pickedLocation = ll.LatLng(widget.destinationLat!, widget.destinationLng!);
    }
    if (widget.riderLat != null && widget.riderLng != null &&
        (oldWidget.riderLat != widget.riderLat || oldWidget.riderLng != widget.riderLng)) {
      // Smoothly track moving rider
      _mapController.move(ll.LatLng(widget.riderLat!, widget.riderLng!), _mapController.camera.zoom);
    }
  }

  void _onMapTapped(ll.LatLng position) {
    if (!widget.isPicker) return;
    setState(() {
      _pickedLocation = position;
    });
    widget.onLocationPicked?.call(position);
  }

  void _reCenterMap() {
    final target = _pickedLocation ??
        (widget.riderLat != null && widget.riderLng != null
            ? ll.LatLng(widget.riderLat!, widget.riderLng!)
            : (widget.pickupLat != null && widget.pickupLng != null
                ? ll.LatLng(widget.pickupLat!, widget.pickupLng!)
                : _defaultCenter));
    _mapController.move(target, 15.0);
  }

  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // 1. Pickup Marker (Green/Teal Store Icon)
    if (widget.pickupLat != null && widget.pickupLng != null) {
      markers.add(
        Marker(
          point: ll.LatLng(widget.pickupLat!, widget.pickupLng!),
          width: 50,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: const Text(
                  'Pickup',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF059669)),
                ),
              ),
              const Icon(Icons.location_on, color: Color(0xFF059669), size: 36),
            ],
          ),
        ),
      );
    }

    // 2. Destination Marker (Red Flag Icon)
    final destPos = _pickedLocation ??
        (widget.destinationLat != null && widget.destinationLng != null
            ? ll.LatLng(widget.destinationLat!, widget.destinationLng!)
            : null);

    if (destPos != null) {
      markers.add(
        Marker(
          point: destPos,
          width: 60,
          height: 60,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 4)],
                ),
                child: Text(
                  widget.isPicker ? 'Selected' : 'Drop-off',
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.error),
                ),
              ),
              const Icon(Icons.location_on, color: AppColors.error, size: 36),
            ],
          ),
        ),
      );
    }

    // 3. Rider Marker (Cyan / Orange Pulsing Bike Icon)
    if (widget.riderLat != null && widget.riderLng != null) {
      markers.add(
        Marker(
          point: ll.LatLng(widget.riderLat!, widget.riderLng!),
          width: 54,
          height: 54,
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 8, spreadRadius: 3),
              ],
              border: Border.all(color: AppColors.primary, width: 2.5),
            ),
            child: const Center(
              child: Icon(Icons.two_wheeler_rounded, color: AppColors.primary, size: 26),
            ),
          ),
        ),
      );
    }

    return markers;
  }

  List<Polyline> _buildPolylines() {
    final points = <ll.LatLng>[];

    if (widget.pickupLat != null && widget.pickupLng != null) {
      points.add(ll.LatLng(widget.pickupLat!, widget.pickupLng!));
    }
    if (widget.riderLat != null && widget.riderLng != null) {
      points.add(ll.LatLng(widget.riderLat!, widget.riderLng!));
    }
    if (widget.destinationLat != null && widget.destinationLng != null) {
      points.add(ll.LatLng(widget.destinationLat!, widget.destinationLng!));
    }

    if (points.length < 2) return [];

    return [
      Polyline(
        points: points,
        strokeWidth: 4.5,
        color: AppColors.primary,
        strokeCap: StrokeCap.round,
        strokeJoin: StrokeJoin.round,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final initialCenter = _pickedLocation ??
        (widget.destinationLat != null && widget.destinationLng != null
            ? ll.LatLng(widget.destinationLat!, widget.destinationLng!)
            : (widget.pickupLat != null && widget.pickupLng != null
                ? ll.LatLng(widget.pickupLat!, widget.pickupLng!)
                : _defaultCenter));

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: initialCenter,
              initialZoom: 14.5,
              minZoom: 5.0,
              maxZoom: 18.5,
              onTap: (tapPosition, point) => _onMapTapped(point),
            ),
            children: [
              // OpenStreetMap High-Resolution Tile Layer
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.baleradelivery.balera_customer_app',
                maxZoom: 19,
                errorTileCallback: (tile, error, stackTrace) {
                  // Silently handle offline/network unavailable state
                },
              ),

              // Polyline delivery route
              PolylineLayer(
                polylines: _buildPolylines(),
              ),

              // Markers for Pickup, Drop-off, and Rider
              MarkerLayer(
                markers: _buildMarkers(),
              ),
            ],
          ),

          // Floating Controls (Zoom in, Zoom out, Re-center)
          Positioned(
            right: 12,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMapButton(
                  icon: Icons.add,
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.remove,
                  onPressed: () {
                    _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1);
                  },
                ),
                const SizedBox(height: 6),
                _buildMapButton(
                  icon: Icons.my_location_rounded,
                  onPressed: _reCenterMap,
                ),
              ],
            ),
          ),

          // Picker Mode Banner
          if (widget.isPicker)
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 8),
                    Text(
                      'Tap anywhere on the map to set pin',
                      style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMapButton({required IconData icon, required VoidCallback onPressed}) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: AppColors.textPrimary),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
