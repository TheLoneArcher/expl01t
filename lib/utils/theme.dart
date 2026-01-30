import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CampXTheme {
  static const Color _darkBackground = Color(0xFF050510); // Deep cosmic dark
  static const Color _darkSurface = Color(0xFF0F1225);
  static const Color _neonBlue = Color(0xFF00F3FF);
  static const Color _neonPurple = Color(0xFFBC13FE);
  static const Color _white = Color(0xFFE0E0E0);
  static const Color _lightBackground = Color(0xFFF0F5FA);
  static const Color _lightSurface = Color(0xFFFFFFFF);

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _darkBackground,
      primaryColor: _neonBlue,
      colorScheme: const ColorScheme.dark(
        primary: _neonBlue,
        secondary: _neonPurple,
        surface: _darkSurface,
        background: _darkBackground,
        onBackground: _white,
        onSurface: _white,
      ),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: _neonBlue,
          shadows: [
            Shadow(color: _neonBlue.withOpacity(0.5), blurRadius: 10),
          ],
        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: _white,
        ),
        bodyLarge: GoogleFonts.exo2(
          fontSize: 18,
          color: _white.withOpacity(0.9),
        ),
        bodyMedium: GoogleFonts.exo2(
          fontSize: 16,
          color: _white.withOpacity(0.7),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _neonBlue,
          foregroundColor: _darkBackground,
          elevation: 10,
          shadowColor: _neonBlue.withOpacity(0.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Techy sharp corners
            side: const BorderSide(color: _neonBlue, width: 2),
          ),
        ),
      ),
      cardTheme: CardThemeData(

        color: _darkSurface.withOpacity(0.8),
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _neonBlue.withOpacity(0.2)),
        ),
      ),
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFD6DBE1), // Duller Grey-ish White
      primaryColor: _neonBlue,
      colorScheme: const ColorScheme.light(
        primary: _neonBlue,
        secondary: _neonPurple,
        surface: Color(0xFFE8EEF4), // Slightly lighter surface
        background: Color(0xFFD6DBE1),
        onBackground: Color(0xFF2C2F3A), // Softer Dark Grey Text
        onSurface: Color(0xFF2C2F3A),
      ),
      iconTheme: const IconThemeData(color: Color(0xFF2C2F3A)),
      textTheme: TextTheme(
        displayLarge: GoogleFonts.orbitron(
          fontSize: 56,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1B1E28),

        ),
        displayMedium: GoogleFonts.orbitron(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: const Color(0xFF1A1A2E),
        ),
        bodyLarge: GoogleFonts.exo2(
          fontSize: 18,
          color: const Color(0xFF1A1A2E).withOpacity(0.9),
          fontWeight: FontWeight.w500,
        ),
        bodyMedium: GoogleFonts.exo2(
          fontSize: 16,
          color: const Color(0xFF1A1A2E).withOpacity(0.8),
          fontWeight: FontWeight.w500,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _neonBlue,
          foregroundColor: const Color(0xFF050510),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
          textStyle: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0),
            side: const BorderSide(color: _neonBlue, width: 2),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.1), // Softer shadow for light mode
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _neonBlue.withOpacity(0.3), width: 1),
        ),
      ),
    );
  }
}
