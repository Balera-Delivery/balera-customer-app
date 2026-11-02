import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents (Exact match with glowing Wolf & Pin logo)
  static const Color primary = Color(0xFF0062FF); // Vivid Electric Cobalt Blue
  static const Color primaryDark = Color(0xFF0038A8); // Deep Sapphire Blue
  static const Color primaryLight = Color(0xFF0088FF); // Radiant Cyan/Sky Trail
  static const Color accent = Color(0xFF00C7FE); // Neon Electric Cyan (Pin glow)
  static const Color accentLight = Color(0xFFBCEBFE); // Soft Ice Cyan Tint
  static const Color accentDark = Color(0xFF0096C7);

  // Deep Navy Cosmic Tones (Matching Logo Badge Background & Modern Cards)
  static const Color navyDark = Color(0xFF030D26); // Midnight Obsidian Blue
  static const Color navySurface = Color(0xFF08173E); // Elevated Card Navy
  static const Color navyBorder = Color(0xFF132A60); // Glowing Border for Dark cards

  // Signature Logo Gradients
  static const LinearGradient logoGradient = LinearGradient(
    colors: [Color(0xFF0047BA), Color(0xFF0062FF), Color(0xFF00C7FE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient logoDarkGradient = LinearGradient(
    colors: [Color(0xFF002B82), Color(0xFF0047BA), Color(0xFF0062FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF004FC7), Color(0xFF0077FF)],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkCardGradient = LinearGradient(
    colors: [Color(0xFF030D26), Color(0xFF0B1D48)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Status Colors (Matching Delivery Lifecycle)
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusAssigned = Color(0xFF0088FF); // Sky Cyan Blue
  static const Color statusAccepted = Color(0xFF6366F1); // Indigo
  static const Color statusPickedUp = Color(0xFF8B5CF6); // Purple
  static const Color statusOnTheWay = Color(0xFF0284C7); // Sky Blue
  static const Color statusDelivered = Color(0xFF10B981); // Emerald
  static const Color statusCompleted = Color(0xFF059669); // Dark Green
  static const Color statusCancelled = Color(0xFFEF4444); // Coral Red

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFD); // Ice tint background
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFEFF6FF); // Soft blue surface tint
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Typography & Content
  static const Color textPrimary = Color(0xFF0A122A); // Rich Obsidian Black
  static const Color textSecondary = Color(0xFF475569); // Slate Grey
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF0062FF); // Active Logo Blue
  static const Color divider = Color(0xFFF1F5F9);

  // Alerts & Notifications
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0062FF);
}
