import 'package:flutter/material.dart';

enum LogoVariant { circular, horizontal }

class BaleraLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final LogoVariant variant;
  final BorderRadius? borderRadius;
  final bool showShadow;

  const BaleraLogo({
    super.key,
    this.size = 130,
    this.showTagline = true,
    this.variant = LogoVariant.circular,
    this.borderRadius,
    this.showShadow = true,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: showShadow
            ? [
                BoxShadow(
                  color: const Color(0xFF0047BA).withValues(alpha: 0.28),
                  blurRadius: size * 0.18,
                  offset: Offset(0, size * 0.06),
                  spreadRadius: 0,
                ),
                BoxShadow(
                  color: const Color(0xFF00D2FF).withValues(alpha: 0.12),
                  blurRadius: size * 0.25,
                  offset: const Offset(0, 0),
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Image.asset(
          'assets/logo/balera_logo.png',
          width: size,
          height: size,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.high,
          isAntiAlias: true,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: radius,
              ),
              child: Icon(
                Icons.local_shipping_rounded,
                color: const Color(0xFF0047BA),
                size: size * 0.45,
              ),
            );
          },
        ),
      ),
    );
  }
}
