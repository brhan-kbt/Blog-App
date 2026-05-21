import 'package:flutter/material.dart';

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color primary;
  final Color searchBg;
  final Color searchOutline;
  final Color searchIcon;
  final Color chipBg;
  final Color cardBg;
  final Color favoriteActive;

  const AppPalette({
    required this.primary,
    required this.searchBg,
    required this.searchOutline,
    required this.searchIcon,
    required this.chipBg,
    required this.cardBg,
    required this.favoriteActive,
  });

  /// Explicit LIGHT palette (tweak to taste)
  static const AppPalette light = AppPalette(
    primary: Color(0xFF104a59), // e94873
    searchBg: Color.fromARGB(255, 252, 254, 255), // soft blue-tint chip
    searchOutline: Color(0xFF104a59), // slate-300-ish hairline
    searchIcon: Color(0xFF104a59), // e94873
    chipBg: Color.fromARGB(255, 168, 168, 168), // slate-50/100
    cardBg: Colors.white, // cards, tiles
    favoriteActive: Color.fromARGB(255, 137, 198, 211), // matches your seed
  );

  /// Explicit DARK palette
  static const AppPalette dark = AppPalette(
    primary: Color(0xFFD3D3D3), // e94873
    searchBg: Color.fromARGB(255, 31, 46, 48), // soft blue-tint chip
    searchOutline: Color.fromARGB(255, 232, 234, 235), // slate-300-ish hairline
    searchIcon: Color(0xFFD3D3D3), // e94873
    chipBg: Color.fromARGB(255, 46, 48, 60),
    cardBg: Color.fromARGB(255, 11, 9, 36),
    favoriteActive: Color.fromARGB(255, 23, 57, 73), // matches your seed
  );

  /// Optional: build from an existing ThemeData (used as a safe fallback)
  static AppPalette fromTheme(ThemeData theme) {
    final s = theme.colorScheme;
    return AppPalette(
      primary: s.primary,
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
    Color? primary,
    Color? searchBg,
    Color? searchOutline,
    Color? searchIcon,
    Color? chipBg,
    Color? cardBg,
    Color? favoriteActive,
  }) {
    return AppPalette(
      primary: primary ?? this.primary,
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
      primary: Color.lerp(primary, other.primary, t)!,
      searchBg: Color.lerp(searchBg, other.searchBg, t)!,
      searchOutline: Color.lerp(searchOutline, other.searchOutline, t)!,
      searchIcon: Color.lerp(searchIcon, other.searchIcon, t)!,
      chipBg: Color.lerp(chipBg, other.chipBg, t)!,
      cardBg: Color.lerp(cardBg, other.cardBg, t)!,
      favoriteActive: Color.lerp(favoriteActive, other.favoriteActive, t)!,
    );
  }
}
