import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class BankTheme {
  // Paleta Fintech de Alto Nivel (Estilo Revolut / Mercury / Stripe)
  static const Color background = Color(0xFF090D16);       // Onyx Darkest
  static const Color surface = Color(0xFF101726);          // Card Base
  static const Color surfaceElevated = Color(0xFF172238);  // Modales & Panels
  static const Color border = Color(0xFF22314E);           // Crisp Stroke
  static const Color borderSubtle = Color(0xFF18243A);     // Faint Separators

  // Acentos y Marca
  static const Color primary = Color(0xFF2563EB);          // Royal Electric Blue
  static const Color primaryLight = Color(0xFF3B82F6);     // Hover Blue
  static const Color cyanAccent = Color(0xFF06B6D4);       // Crisp Cyan (KPIs)
  static const Color emeraldSuccess = Color(0xFF10B981);   // Saldo / Aprobado
  static const Color danger = Color(0xFFEF4444);           // Alertas / Fallos
  static const Color warning = Color(0xFFF59E0B);          // Avisos / Espera

  // Tipografía
  static const Color textMain = Color(0xFFF8FAFC);         // Pure White
  static const Color textMuted = Color(0xFF94A3B8);        // Subdued Slate
  static const Color textHint = Color(0xFF64748B);         // Placeholder

  // Gradientes Institucionales
  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF0F172A), Color(0xFF020617)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient brandGradient = LinearGradient(
    colors: [Color(0xFF2563EB), Color(0xFF06B6D4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient successGradient = LinearGradient(
    colors: [Color(0xFF059669), Color(0xFF10B981)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Sombras Profesionales
  static List<BoxShadow> softShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.35),
      blurRadius: 20,
      offset: const Offset(0, 8),
    ),
  ];

  static List<BoxShadow> modalShadow = [
    BoxShadow(
      color: Colors.black.withOpacity(0.65),
      blurRadius: 40,
      offset: const Offset(0, 16),
    ),
  ];

  static List<BoxShadow> glowShadow(Color color) => [
    BoxShadow(
      color: color.withOpacity(0.25),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ThemeData Completo con GoogleFonts (Inter)
  static ThemeData get themeData {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: background,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      colorScheme: const ColorScheme.dark(
        primary: primary,
        surface: surface,
        error: danger,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primary, width: 1.5),
        ),
        hintStyle: const TextStyle(color: textHint, fontSize: 13),
        labelStyle: const TextStyle(color: textMuted, fontSize: 13),
      ),
    );
  }
}
