import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Tema de la aplicacion, construido a mano desde los tokens de
/// `docs/ui-design.md`.
///
/// **Un solo tema oscuro para los dos roles**, por decision del diseno: la app
/// debe sentirse como una sola pieza. No se elige por preferencia del sistema,
/// asi que no hay tema claro con el que alternar.
abstract final class TemaApp {
  /// Space Grotesk para titulos y cifras destacadas.
  static TextStyle _titulo(double tamano, FontWeight grosor, Color color) =>
      GoogleFonts.spaceGrotesk(
        fontSize: tamano,
        fontWeight: grosor,
        color: color,
        height: 1.2,
      );

  /// IBM Plex Sans para el resto de la interfaz.
  static TextStyle _cuerpo(double tamano, FontWeight grosor, Color color) =>
      GoogleFonts.ibmPlexSans(
        fontSize: tamano,
        fontWeight: grosor,
        color: color,
        height: 1.4,
      );

  static ThemeData oscuro() {
    final esquema = const ColorScheme.dark(
      primary: Tokens.acento,
      onPrimary: Tokens.sobreAcento,
      secondary: Tokens.secundario,
      onSecondary: Color(0xFF1B1200),
      surface: Tokens.superficie,
      onSurface: Tokens.texto,
      surfaceContainerHighest: Tokens.superficie2,
      onSurfaceVariant: Tokens.textoSuave,
      outline: Tokens.borde,
      outlineVariant: Tokens.superficie3,
      error: Tokens.peligro,
      onError: Tokens.sobreAcento,
    );

    final textos = TextTheme(
      // Titulos de pantalla: 22-24.
      headlineMedium: _titulo(24, FontWeight.w700, Tokens.texto),
      headlineSmall: _titulo(22, FontWeight.w700, Tokens.texto),
      // Titulos de tarjeta: 17-19.
      titleLarge: _titulo(19, FontWeight.w600, Tokens.texto),
      titleMedium: _titulo(17, FontWeight.w600, Tokens.texto),
      titleSmall: _cuerpo(15, FontWeight.w600, Tokens.texto),
      // Cuerpo: 14-15.
      bodyLarge: _cuerpo(15, FontWeight.w400, Tokens.texto),
      bodyMedium: _cuerpo(14, FontWeight.w400, Tokens.texto),
      bodySmall: _cuerpo(13, FontWeight.w400, Tokens.textoSuave),
      // Metadatos y etiquetas: 11-13.
      labelLarge: _cuerpo(14, FontWeight.w600, Tokens.texto),
      labelMedium: _cuerpo(12, FontWeight.w600, Tokens.textoSuave),
      labelSmall: _cuerpo(11, FontWeight.w500, Tokens.textoTenue),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: esquema,
      scaffoldBackgroundColor: Tokens.fondo,
      canvasColor: Tokens.fondo,
      textTheme: textos,
      appBarTheme: AppBarTheme(
        backgroundColor: Tokens.fondo,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: _titulo(22, FontWeight.w700, Tokens.texto),
        iconTheme: const IconThemeData(color: Tokens.texto),
      ),
      cardTheme: CardThemeData(
        color: Tokens.superficie,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radioTarjeta),
          side: const BorderSide(color: Tokens.borde),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: Tokens.borde,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Tokens.superficie,
        hintStyle: _cuerpo(15, FontWeight.w400, Tokens.textoTenue),
        labelStyle: _cuerpo(14, FontWeight.w400, Tokens.textoSuave),
        helperStyle: _cuerpo(12, FontWeight.w400, Tokens.textoTenue),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        border: _borde(Tokens.borde),
        enabledBorder: _borde(Tokens.borde),
        focusedBorder: _borde(Tokens.acento, grosor: 1.5),
        errorBorder: _borde(Tokens.peligro),
        focusedErrorBorder: _borde(Tokens.peligro, grosor: 1.5),
        disabledBorder: _borde(Tokens.borde),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: Tokens.acento,
          foregroundColor: Tokens.sobreAcento,
          disabledBackgroundColor: Tokens.superficie2,
          disabledForegroundColor: Tokens.textoTenue,
          minimumSize: const Size.fromHeight(Tokens.alturaCta),
          textStyle: _cuerpo(15, FontWeight.w600, Tokens.sobreAcento),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radioBoton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: Tokens.texto,
          side: const BorderSide(color: Tokens.borde),
          // Alto minimo, pero NO ancho: `Size.fromHeight` pone el ancho a
          // infinito, y un boton asi dentro de una `Row` sin limite rompe el
          // layout y deja la pantalla en negro. Los botones de ancho completo lo
          // piden ellos (`BotonCta` o un `SizedBox`).
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Tokens.radioBoton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: Tokens.acento),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Tokens.superficie2,
        side: const BorderSide(color: Tokens.borde),
        labelStyle: _cuerpo(13, FontWeight.w500, Tokens.textoSuave),
        shape: const StadiumBorder(),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: Tokens.acento,
        inactiveTrackColor: Tokens.superficie3,
        thumbColor: Tokens.acento,
        overlayColor: Tokens.acentoSuave,
        trackHeight: 4,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: const WidgetStatePropertyAll(Colors.white),
        trackColor: WidgetStateProperty.resolveWith(
          (estados) => estados.contains(WidgetState.selected)
              ? Tokens.acento
              : Tokens.superficie3,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: Tokens.superficie2,
        contentTextStyle: _cuerpo(14, FontWeight.w400, Tokens.texto),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radioBoton),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Tokens.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(Tokens.radioTarjeta),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Tokens.superficie,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: Tokens.acento,
      ),
      iconTheme: const IconThemeData(color: Tokens.textoSuave),
    );
  }

  static OutlineInputBorder _borde(Color color, {double grosor = 1}) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(Tokens.radioBoton),
        borderSide: BorderSide(color: color, width: grosor),
      );
}
