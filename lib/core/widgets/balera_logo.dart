import 'package:flutter/material.dart';

enum LogoVariant { circular, horizontal }

class BaleraLogo extends StatelessWidget {
  final double size;
  final bool showTagline;
  final LogoVariant variant;

  const BaleraLogo({
    super.key,
    this.size = 130,
    this.showTagline = true,
    this.variant = LogoVariant.circular,
  });

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/logo/balera_logo.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
      errorBuilder: (context, error, stackTrace) {
        return Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.local_shipping_rounded,
            color: Color(0xFF0047BA),
            size: 40,
          ),
        );
      },
    );
  }
}
