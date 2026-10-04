import 'package:flutter/material.dart';

/// Tokens de color del diseno (`docs/ui-design.md`, seccion 2).
///
/// Son los valores exactos del prototipo, no aproximaciones a la paleta de
/// Material: por eso estan aqui como constantes y no salen de un
/// `ColorScheme.fromSeed`.
abstract final class Tokens {
  /// Fondo de pantalla.
  static const Color fondo = Color(0xFF050404);

  /// Tarjetas, barras e inputs.
  static const Color superficie = Color(0xFF121214);

  /// Fondos secundarios: iconos, chips inactivos.
  static const Color superficie2 = Color(0xFF1B1C1F);

  /// Pistas de slider y placeholders de imagen.
  static const Color superficie3 = Color(0xFF26282C);

  static const Color borde = Color(0xFF2D2F33);

  static const Color texto = Color(0xFFF5F6F7);
  static const Color textoSuave = Color(0xFF9CA2A9);
  static const Color textoTenue = Color(0xFF6C7278);

  /// Color de marca: CTAs, foco, elementos activos.
  static const Color acento = Color(0xFF1C85FF);
  static const Color sobreAcento = Color(0xFFFFFFFF);

  /// Ambar. **Significa "lo planificado por el entrenador"**, y por eso no se
  /// usa para nada mas: es la clave visual que separa el plan de lo que
  /// registra el cliente (regla de dominio: son independientes).
  static const Color secundario = Color(0xFFFFB136);

  /// Serie completada.
  static const Color exito = Color(0xFF4ADE80);

  /// Errores y avisos.
  static const Color peligro = Color(0xFFFF5A5F);

  /// Fondos de estado activo o seleccionado: el acento al 16%.
  static Color get acentoSuave => acento.withValues(alpha: 0.16);

  /// Chips y etiquetas secundarias: el ambar al 16%.
  static Color get secundarioSuave => secundario.withValues(alpha: 0.16);

  // --- Forma y espaciado (seccion 4) ---

  /// Radio de las tarjetas grandes.
  static const double radioTarjeta = 16;

  /// Radio de botones y CTAs.
  static const double radioBoton = 14;

  /// Radio de chips y pastillas: circular.
  static const double radioPastilla = 999;

  /// Padding horizontal de pantalla.
  static const double margenPantalla = 20;

  /// Separacion entre bloques de una pantalla.
  static const double separacionBloques = 16;

  /// Altura del boton de accion principal.
  static const double alturaCta = 52;

  /// Sombra estandar de tarjeta: `0 16px 32px rgba(0,0,0,0.45)`.
  static const List<BoxShadow> sombraTarjeta = [
    BoxShadow(color: Color(0x73000000), blurRadius: 32, offset: Offset(0, 16)),
  ];
}
