import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Pastel Colors
  static const Color primaryBlue = Color(0xFFAEC6CF);
  static const Color primaryGreen = Color(0xFF77DD77);
  static const Color primaryYellow = Color(0xFFFDFD96);
  static const Color primaryPink = Color(0xFFFFB7B2);
  static const Color background = Color(0xFFF4F7F6);
  static const Color textColor = Color(0xFF333333);

  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryBlue,
      scaffoldBackgroundColor: background,
      colorScheme: ColorScheme.fromSeed(seedColor: primaryBlue),
      textTheme: GoogleFonts.notoSansLaoTextTheme().copyWith(
        displayLarge: GoogleFonts.notoSansLao(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        displayMedium: GoogleFonts.notoSansLao(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
        bodyLarge: GoogleFonts.notoSansLao(fontSize: 18, color: textColor),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
    );
  }
}
