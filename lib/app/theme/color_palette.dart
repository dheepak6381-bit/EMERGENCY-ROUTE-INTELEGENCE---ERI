/// App-wide color palette — dark dispatcher console theme
/// All colors defined here; never hardcode hex elsewhere.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgScaffold = Color(0xFF04060A); // Pitch black/deep space
  static const Color bgPanel = Color(0x880A0F1A); // 53% opacity for frosted glass
  static const Color bgCard = Color(0x66131D33); // Card bg translucent
  static const Color bgCardHover = Color(0xAA1A2744); // Card hover translucent
  static const Color bgInput = Color(0x660F162A); 
  static const Color bgTopBar = Color(0xBB04060A); 

  // Accent / Interactive (from ERI Logo)
  static const Color accentBlue = Color(0xFF0055FF); // Vibrant logo blue
  static const Color accentCyan = Color(0xFF00D4FF); // Keep for route lines
  static const Color accentRed = Color(0xFFFF1E1E); // Vibrant logo red

  // Status — used IDENTICALLY for capacity bars, traffic badges, road overlays
  static const Color statusGreen = Color(0xFF22C55E);   // < 50% load / Light traffic
  static const Color statusAmber = Color(0xFFF59E0B);   // 50-80% load / Moderate
  static const Color statusRed = Color(0xFFEF4444);     // > 80% load / Heavy / Blocked
  static const Color statusCyan = Color(0xFF06B6D4);    // Improvement events

  // Text
  static const Color textPrimary = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8B9BBE);
  static const Color textTertiary = Color(0xFF4B5A7A);
  static const Color textAccent = Color(0xFF3A7DFF);

  // Borders & Dividers
  static const Color borderDefault = Color(0xFF1E2D4A);
  static const Color borderActive = Color(0xFF3A7DFF);

  // Route
  static const Color routeLine = Color(0xFF00D4FF);
  static const Color routeBlocked = Color(0xFFEF4444);

  // Map overlay
  static const Color overlayDark = Color(0xCC0A0E1A);

  // Emergency type badge colors
  static const Color badgeCardiac = Color(0xFFEF4444);
  static const Color badgeTrauma = Color(0xFFF59E0B);
  static const Color badgeBurns = Color(0xFFFF6B35);
  static const Color badgeRespiratory = Color(0xFF06B6D4);
  static const Color badgeGeneral = Color(0xFF8B5CF6);
}
