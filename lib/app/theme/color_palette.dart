/// App-wide color palette — dark dispatcher console theme
/// All colors defined here; never hardcode hex elsewhere.
import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Backgrounds
  static const Color bgScaffold = Color(0xFF060913); // Deepest space black
  static const Color bgPanel = Color(0xFF0B1221); // Slightly lighter
  static const Color bgCard = Color(0xFF131D33); // Card bg
  static const Color bgCardHover = Color(0xFF1A2744); // Card hover bg
  static const Color bgInput = Color(0xFF0F162A); 
  static const Color bgTopBar = Color(0xFF0A101C); 

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
