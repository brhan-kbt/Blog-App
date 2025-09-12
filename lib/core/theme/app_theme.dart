import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_palette.dart';

class AppTheme {
  static ThemeData _make(Brightness brightness) {
    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorSchemeSeed: const Color.fromARGB(255, 1, 0, 3),
      scaffoldBackgroundColor: brightness == Brightness.light
          ? const Color(0xFFF7F8FC)
          : const Color(0xFF04020F),
      textTheme: GoogleFonts.poppinsTextTheme(
        brightness == Brightness.dark ? ThemeData.dark().textTheme : null,
      ),
    );

    // Pick the explicit palette for the current mode
    final palette = brightness == Brightness.light
        ? AppPalette.light
        : AppPalette.dark;

    return base.copyWith(extensions: <ThemeExtension<dynamic>>[palette]);
  }

  static final light = _make(Brightness.light);
  static final dark = _make(Brightness.dark);
}
