import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class MockMapView extends StatelessWidget {
  final String? pickupAddress;
  final String? destinationAddress;
  final bool showRoute;
  final bool showRider;
  final double height;

  const MockMapView({
    super.key,
    this.pickupAddress,
    this.destinationAddress,
    this.showRoute = true,
    this.showRider = false,
    this.height = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final pLabel = (pickupAddress != null && pickupAddress!.trim().isNotEmpty)
        ? (pickupAddress!.trim().length > 16
            ? '${pickupAddress!.trim().substring(0, 14)}...'
            : pickupAddress!.trim())
        : 'Pickup';
    final dLabel = (destinationAddress != null && destinationAddress!.trim().isNotEmpty)
        ? (destinationAddress!.trim().length > 16
            ? '${destinationAddress!.trim().substring(0, 14)}...'
            : destinationAddress!.trim())
        : 'Destination';

    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E7EB),
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Map Grid Background Pattern
            CustomPaint(
              size: Size.infinite,
              painter: MapGridPainter(),
            ),

            // Route Polyline & Markers
            if (showRoute)
              CustomPaint(
                size: Size.infinite,
                painter: RoutePainter(),
              ),

            // Pickup Marker
            Positioned(
              top: 70,
              left: 60,
              child: Column(
                children: [
                  const Icon(Icons.location_pin, color: AppColors.primary, size: 34),
                  const SizedBox(height: 2),
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        pLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Rider Marker (if enabled)
            if (showRider)
              const Positioned(
                top: 150,
                left: 130,
                child: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.two_wheeler_rounded, color: Colors.white, size: 20),
                ),
              ),

            // Destination Marker
            Positioned(
              bottom: 80,
              right: 60,
              child: Column(
                children: [
                  const Icon(Icons.location_pin, color: AppColors.accent, size: 34),
                  const SizedBox(height: 2),
                  Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(6),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.1),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: Text(
                        dLabel,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.accent,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 14
      ..style = PaintingStyle.stroke;

    final roadBorderPaint = Paint()
      ..color = const Color(0xFFD1D5DB)
      ..strokeWidth = 16
      ..style = PaintingStyle.stroke;

    final greenAreaPaint = Paint()
      ..color = const Color(0xFFD1FAE5)
      ..style = PaintingStyle.fill;

    // Draw some parks/landmarks
    canvas.drawRRect(
      RRect.fromRectAndRadius(const Rect.fromLTWH(20, 30, 80, 100), const Radius.circular(8)),
      greenAreaPaint,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(size.width - 100, 180, 80, 90), const Radius.circular(8)),
      greenAreaPaint,
    );

    // Draw streets
    final path1 = Path()
      ..moveTo(0, size.height * 0.3)
      ..lineTo(size.width, size.height * 0.4);

    final path2 = Path()
      ..moveTo(size.width * 0.3, 0)
      ..lineTo(size.width * 0.4, size.height);

    final path3 = Path()
      ..moveTo(0, size.height * 0.75)
      ..lineTo(size.width, size.height * 0.65);

    canvas.drawPath(path1, roadBorderPaint);
    canvas.drawPath(path1, roadPaint);
    canvas.drawPath(path2, roadBorderPaint);
    canvas.drawPath(path2, roadPaint);
    canvas.drawPath(path3, roadBorderPaint);
    canvas.drawPath(path3, roadPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final routePaint = Paint()
      ..color = const Color(0xFF2563EB)
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(88, 110)
      ..cubicTo(120, 140, 130, 160, 150, 180)
      ..cubicTo(180, 210, 220, 240, size.width - 98, size.height - 115);

    canvas.drawPath(path, routePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
