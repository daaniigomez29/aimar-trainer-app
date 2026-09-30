import 'package:flutter/material.dart';

/// Tema unico de la aplicacion. Se ampliara cuando haya diseno definitivo.
abstract final class TemaApp {
  static const Color _semilla = Color(0xFF1B5E20);

  static ThemeData claro() {
    final esquema = ColorScheme.fromSeed(seedColor: _semilla);
    return ThemeData(
      colorScheme: esquema,
      useMaterial3: true,
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      ),
    );
  }
}
