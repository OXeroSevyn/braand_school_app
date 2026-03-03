import 'package:flutter/material.dart';

class AppColors {
  // Base Colors
  static const Color primary = Color(
    0xFF11D473,
  ); // Emerald Green / Vibrant Green
  static const Color primaryBlue = Color(0xFF1E88E5); // Bright Blue
  static const Color background = Color(
    0xFFF8F9FA,
  ); // Off-white / Very light grey
  static const Color card = Color(0xFFFFFFFF);

  // Text Colors
  static const Color textPrimary = Color(0xFF1A1A1A); // Almost black
  static const Color textSecondary = Color(0xFF8E929C); // Soft grey

  // Status Colors
  static const Color onlinePulse = Color(0xFF22C55E); // Green pulse
  static const Color offlineAlert = Color(0xFFEF4444); // Red alert

  static const Color error = Color(0xFFE53935);
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFDD835);

  // Gradients
  static const LinearGradient teamCardGradient = LinearGradient(
    colors: [Color(0xFF11D473), Color(0xFF1E40AF)], // Green to Deep Blue
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
