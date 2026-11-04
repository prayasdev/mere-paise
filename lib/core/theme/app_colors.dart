import 'package:flutter/material.dart';

/// Design tokens for "Ledger of the Night" gothic palette and "Vellum" light variant.
class AppColors {
  AppColors._();

  // Dark Theme: "Ledger of the Night"
  static const Color obsidian = Color(0xFF0C0B0D); // App background
  static const Color crypt = Color(0xFF151317);    // Cards, sheets
  static const Color slab = Color(0xFF1E1B21);     // Raised surfaces, keypad, inputs
  static const Color ironLine = Color(0xFF383340); // Hairline borders (1px)
  static const Color ironLineSubtle = Color(0xFF28242E);

  static const Color bone = Color(0xFFF8F4EA);     // Primary text - bright parchment ivory
  static const Color ash = Color(0xFFC7BFB2);      // Secondary / muted text - clear cream ash
  static const Color ashDark = Color(0xFF9E9689);  // Tertiary / hints - readable muted stone

  static const Color brass = Color(0xFFCCA667);    // Primary accent, active, Net - brightened gold
  static const Color brassMuted = Color(0xFF8E7345);
  static const Color brassBright = Color(0xFFE4C48B);

  static const Color oxblood = Color(0xFF8E1B2B);  // Expense base
  static const Color oxbloodLit = Color(0xFFE54B5F); // Expense text on dark - high contrast
  static const Color oxbloodSubtle = Color(0xFF2C0F14);

  static const Color verdigris = Color(0xFF4E7A63);  // Income base
  static const Color verdigrisLit = Color(0xFF6BBE8E); // Income text on dark - high contrast
  static const Color verdigrisSubtle = Color(0xFF132219);

  static const Color tallow = Color(0xFFDBB146);   // Warning / alert

  // Light Theme: "Vellum"
  static const Color vellumParchment = Color(0xFFF7F2E7); // Warm parchment background
  static const Color vellumCrypt = Color(0xFFEDE5D4);     // Cards, sheets, raised surfaces
  static const Color vellumSlab = Color(0xFFE2D9C5);      // Elevated tiles, inputs, keypad
  static const Color vellumIronLine = Color(0xFFB5AA92);  // Hairline borders (1px)
  static const Color vellumInk = Color(0xFF100E12);       // Deep charcoal primary text
  static const Color vellumAsh = Color(0xFF302B24);       // High-contrast secondary text
  static const Color vellumAshDark = Color(0xFF524A3E);   // High-contrast tertiary text

  // Dynamic Theme Helpers
  static bool isDark(BuildContext context) => Theme.of(context).brightness == Brightness.dark;

  static Color bg(BuildContext context) => isDark(context) ? obsidian : vellumParchment;
  static Color surface(BuildContext context) => isDark(context) ? crypt : vellumCrypt;
  static Color elevated(BuildContext context) => isDark(context) ? slab : vellumSlab;
  static Color border(BuildContext context) => isDark(context) ? ironLine : vellumIronLine;
  static Color borderSubtle(BuildContext context) => isDark(context) ? ironLineSubtle : vellumIronLine.withValues(alpha: 0.5);

  static Color textPrimary(BuildContext context) => isDark(context) ? bone : vellumInk;
  static Color textSecondary(BuildContext context) => isDark(context) ? ash : vellumAsh;
  static Color textTertiary(BuildContext context) => isDark(context) ? ashDark : vellumAshDark;

  static Color expense(BuildContext context) => isDark(context) ? oxbloodLit : oxblood;
  static Color income(BuildContext context) => isDark(context) ? verdigrisLit : verdigris;

  // Muted category palette (12 distinct tones)
  static const List<Color> categoryPalette = [
    Color(0xFFA7533B), // Rust
    Color(0xFFB8863A), // Ochre
    Color(0xFF5B7A42), // Moss
    Color(0xFF556877), // Slate
    Color(0xFF744865), // Plum
    Color(0xFF3A7575), // Teal
    Color(0xFF4F4A58), // Charcoal
    Color(0xFFBA7B32), // Amber
    Color(0xFF3C4E72), // Navy
    Color(0xFF617968), // Sage
    Color(0xFF98644A), // Clay
    Color(0xFF8D7B58), // Sand
  ];

  static Color getCategoryColor(int index) {
    return categoryPalette[index % categoryPalette.length];
  }

  static Color getColorByToken(String? token) {
    if (token == null) return brass;
    switch (token.toLowerCase()) {
      case 'rust': return categoryPalette[0];
      case 'ochre': return categoryPalette[1];
      case 'moss': return categoryPalette[2];
      case 'slate': return categoryPalette[3];
      case 'plum': return categoryPalette[4];
      case 'teal': return categoryPalette[5];
      case 'charcoal': return categoryPalette[6];
      case 'amber': return categoryPalette[7];
      case 'navy': return categoryPalette[8];
      case 'sage': return categoryPalette[9];
      case 'clay': return categoryPalette[10];
      case 'sand': return categoryPalette[11];
      case 'oxblood': return oxbloodLit;
      case 'verdigris': return verdigrisLit;
      case 'brass': return brass;
      default:
        final parsed = int.tryParse(token.replaceAll('#', ''), radix: 16);
        if (parsed != null) {
          return Color(0xFF000000 | parsed);
        }
        return brass;
    }
  }
}

