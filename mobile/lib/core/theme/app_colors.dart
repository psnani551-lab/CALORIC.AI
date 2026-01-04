import 'package:flutter/material.dart';

class AppColors {
  // Core Palette
  static const Color background = Color(0xFF000000); // Pure OLED Black
  static const Color surface = Color(0xFF0A0A0A);    // Deep Charcoal
  static const Color surfaceLight = Color(0xFF161616); // Subtle Elevation
  
  // Accents & State
  static const Color primary = Color(0xFFFFFFFF);     // Pure White
  static const Color secondary = Color(0xFF8E8E93);   // Soft Grey
  static const Color tertiary = Color(0xFF2C2C2E);    // Deep Grey
  
  // Macros & Nutrition
  static const Color protein = Color(0xFFFFFFFF); 
  static const Color carbs = Color(0xFFC7C7CC); 
  static const Color fats = Color(0xFF48484A); 
  
  // Text System
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFF8E8E93);
  static const Color textTertiary = Color(0xFF636366);
  
  // Feedback
  static const Color error = Color(0xFFFF453A);
  static const Color success = Color(0xFF32D74B);
  
  // Premium Design Elements
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBackground = Color(0x1AFFFFFF);
  static const Color border = Color(0x33FFFFFF); // Added for legacy support

  // Premium Gradients
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF1C1C1E),
      Color(0xFF000000),
    ],
  );

  static const LinearGradient meshGradient = LinearGradient(
    begin: Alignment.topRight,
    end: Alignment.bottomLeft,
    colors: [
      Color(0xFF161616),
      Color(0xFF000000),
      Color(0xFF0A0A0A),
    ],
  );
}
