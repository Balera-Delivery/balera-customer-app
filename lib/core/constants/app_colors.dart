import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents (Exact match with glowing Wolf & Pin logo)
  static const Color primary = Color(0xFF0062FF); // Vivid Electric Cobalt Blue
  static const Color primaryDark = Color(0xFF0038A8); // Deep Sapphire Blue
  static const Color primaryLight = Color(0xFF0088FF); // Radiant Cyan/Sky Trail
  static const Color accent = Color(0xFF00C7FE); // Neon Electric Cyan (Pin glow)
  static const Color accentLight = Color(0xFFBCEBFE); // Soft Ice Cyan Tint
  static const Color accentDark = Color(0xFF0096C7);

  // Modern Royal Blue Gradients (Matching Home, Tracking & Profile PDF UI)
  static const LinearGradient heroHeaderGradient = LinearGradient(
    colors: [Color(0xFF0D50DB), Color(0xFF1E67FF)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const Color headerBlueDark = Color(0xFF0D50DB);
  static const Color headerBlueVibrant = Color(0xFF1E67FF);
  static const Color heroCardBackground = Color(0xFF1147C4);
  static const Color heroPillBackground = Color(0xFF1B51CF);

  // Service Category Pastel Backgrounds & Icons
  static const Color serviceFoodBg = Color(0xFFFEF3C7);
  static const Color serviceFoodIcon = Color(0xFFD97706);
  static const Color serviceParcelBg = Color(0xFFDBEAFE);
  static const Color serviceParcelIcon = Color(0xFF2563EB);
  static const Color serviceEcommerceBg = Color(0xFFFCE7F3);
  static const Color serviceEcommerceIcon = Color(0xFFDB2777);
  static const Color serviceDocBg = Color(0xFFDCFCE7);
  static const Color serviceDocIcon = Color(0xFF16A34A);
  static const Color serviceElectronicsBg = Color(0xFFEDE9FE);
  static const Color serviceElectronicsIcon = Color(0xFF7C3AED);
  static const Color serviceAnythingBg = Color(0xFFFFEDD5);
  static const Color serviceAnythingIcon = Color(0xFFEA580C);

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
