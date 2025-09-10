import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color searchBg;
  final Color searchOutline;
  final Color searchIcon;
  final Color chipBg;
  final Color cardBg;
  final Color favoriteActive;

  const AppPalette({
    required this.searchBg,
    required this.searchOutline,
    required this.searchIcon,
    required this.chipBg,
    required this.cardBg,
    required this.favoriteActive,
  });

  /// Explicit LIGHT palette (tweak to taste)
  static const AppPalette light = AppPalette(
    searchBg: Color(0xFFEAF2FF), // soft blue-tint chip
    searchOutline: Color(0xFFCBD5E1), // slate-300-ish hairline
    searchIcon: Color(0xFF475569), // slate-600
    chipBg: Color(0xFFF1F5F9), // slate-50/100
    cardBg: Colors.white, // cards, tiles
    favoriteActive: Color.fromARGB(255, 210, 255, 234), // matches your seed
  );

  /// Explicit DARK palette
  static const AppPalette dark = AppPalette(
    searchBg: Color(0xFF252733), // muted surface tint
    searchOutline: Color(0xFF3A3C47), // subtle hairline
    searchIcon: Color(0xFFB0B7C3), // soft gray icon/hint
    chipBg: Color(0xFF2E303C),
    cardBg: Color.fromARGB(255, 11, 9, 36),
    favoriteActive: Color.fromARGB(255, 1, 84, 45), // matches your seed
  );

  /// Optional: build from an existing ThemeData (used as a safe fallback)
  static AppPalette fromTheme(ThemeData theme) {
    final s = theme.colorScheme;
    return AppPalette(
      searchBg: Color.alphaBlend(s.primary.withOpacity(0.08), s.surface),
      searchOutline: s.outlineVariant.withOpacity(0.30),
      searchIcon: s.onSurfaceVariant,
      chipBg: s.surfaceVariant,
      cardBg: s.surface, // safe default across Flutter versions
      favoriteActive: s.primary,
    );
  }

  @override
  AppPalette copyWith({
    Color? searchBg,
    Color? searchOutline,
    Color? searchIcon,
    Color? chipBg,
    Color? cardBg,
    Color? favoriteActive,
  }) {
    return AppPalette(
      searchBg: searchBg ?? this.searchBg,
      searchOutline: searchOutline ?? this.searchOutline,
      searchIcon: searchIcon ?? this.searchIcon,
      chipBg: chipBg ?? this.chipBg,
      cardBg: cardBg ?? this.cardBg,
      favoriteActive: favoriteActive ?? this.favoriteActive,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      searchBg: Color.lerp(searchBg, other.searchBg, t)!,
      searchOutline: Color.lerp(searchOutline, other.searchOutline, t)!,
      searchIcon: Color.lerp(searchIcon, other.searchIcon, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      favoriteActive: Color.lerp(favoriteActive, other.favoriteActive, t)!,
    );
  }
}
