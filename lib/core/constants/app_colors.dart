import 'package:flutter/material.dart';

class AppColors {
  // Brand Primary & Accents (Vibrant Blue matching design)
  static const Color primary = Color(0xFF0047BA); // Vibrant Royal / Electric Blue
  static const Color primaryDark = Color(0xFF003893); // Deep Brand Blue
  static const Color primaryLight = Color(0xFF0052CC); // Bright Light Blue
  static const Color accent = Color(0xFF0D9488); // Modern Teal/Emerald
  static const Color accentLight = Color(0xFF14B8A6);

  // Status Colors (Matching Delivery Lifecycle)
  static const Color statusPending = Color(0xFFF59E0B); // Amber
  static const Color statusAssigned = Color(0xFF3B82F6); // Blue
  static const Color statusAccepted = Color(0xFF6366F1); // Indigo
  static const Color statusPickedUp = Color(0xFF8B5CF6); // Purple
  static const Color statusOnTheWay = Color(0xFF0284C7); // Sky Blue
  static const Color statusDelivered = Color(0xFF10B981); // Emerald
  static const Color statusCompleted = Color(0xFF059669); // Dark Green
  static const Color statusCancelled = Color(0xFFEF4444); // Coral Red

  // Background & Surfaces
  static const Color background = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceElevated = Color(0xFFF1F5F9);
  static const Color cardBackground = Color(0xFFFFFFFF);

  // Typography & Content
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);
  static const Color textLight = Color(0xFFFFFFFF);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderFocused = Color(0xFF0047BA);
  static const Color divider = Color(0xFFF1F5F9);

  // Alerts & Notifications
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF0047BA);
}
