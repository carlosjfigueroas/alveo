import 'package:flutter/material.dart';

class AppThemes {
  // ── Colores de fallback / base (usados hasta que se cargue la empresa) ──
  static const Color primaryWhite    = Colors.white;
  static const Color primaryGreen    = Color(0xFF006837);
  static const Color terracottaRed   = Color(0xFFA64F35);
  static const Color backgroundCream = Color(0xFFF9F6F2);

  // ── Temas estáticos (usados en el splash y como fallback) ───────────────
  static final ThemeData lightTheme = buildLightTheme(primaryGreen, terracottaRed);
  static final ThemeData darkTheme  = buildDarkTheme(primaryGreen, terracottaRed);

  // ── Constructores dinámicos ─────────────────────────────────────────────
  /// Genera un tema claro con los colores de marca de la empresa activa.
  static ThemeData buildLightTheme(Color primary, Color secondary) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        onPrimary: Colors.white,
        surface: Colors.white,
        onSurface: primary,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: TextTheme(
        headlineMedium: TextStyle(color: primary, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: primary),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: Colors.white,
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? primary : null,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? primary.withValues(alpha: 0.4)
              : null,
        ),
      ),
    );
  }

  /// Genera un tema oscuro con los colores de marca de la empresa activa.
  static ThemeData buildDarkTheme(Color primary, Color secondary) {
    final darkBg = _darken(primary, 0.85);
    final surfaceColor = _darken(primary, 0.80);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        primary: primary,
        secondary: secondary,
        surface: surfaceColor,
        onSurface: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBg,
      cardColor: surfaceColor,
      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      textTheme: const TextTheme(
        headlineMedium: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        bodyLarge: TextStyle(color: Colors.white),
        bodyMedium: TextStyle(color: Colors.white70),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: const TextStyle(color: Colors.white70),
        hintStyle: const TextStyle(color: Colors.white38),
        prefixIconColor: Colors.white70,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: Colors.white,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceColor,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  /// Oscurece un color el porcentaje indicado (0.0 = sin cambio, 1.0 = negro).
  static Color _darken(Color color, double amount) {
    final hsl = HSLColor.fromColor(color);
    final darkened = hsl.withLightness(
      (hsl.lightness * (1 - amount)).clamp(0.0, 1.0),
    );
    return darkened.toColor();
  }

  /// Convierte un hex string '#RRGGBB' en Color.
  static Color hexToColor(String hex) {
    final h = hex.replaceAll('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
