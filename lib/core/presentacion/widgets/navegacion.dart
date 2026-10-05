import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Barras de navegacion de los dos roles (`docs/ui-design.md`, seccion 5).
///
/// El destino se identifica por su ruta, asi que cada pantalla solo tiene que
/// decir en cual esta; no hay un indice que mantener sincronizado a mano.

class Destino {
  const Destino({
    required this.etiqueta,
    required this.icono,
    required this.iconoActivo,
    required this.ruta,
    this.etiquetaCorta,
  });

  final String etiqueta;

  /// Version que cabe en la barra inferior de un movil de 375 px. Sin ella,
  /// "Control semanal" o "Configuracion" se parten o se cortan.
  final String? etiquetaCorta;

  String get etiquetaDeBarra => etiquetaCorta ?? etiqueta;
  final IconData icono;
  final IconData iconoActivo;
  final String ruta;
}

/// Los cinco destinos del cliente, en el orden del diseno.
const List<Destino> destinosCliente = [
  Destino(
    etiqueta: 'Mi planning',
    icono: Icons.home_outlined,
    iconoActivo: Icons.home,
    ruta: Rutas.inicioCliente,
  ),
  Destino(
    etiqueta: 'Mi progreso',
    icono: Icons.trending_up_outlined,
    iconoActivo: Icons.trending_up,
    ruta: Rutas.progresoCliente,
  ),
  Destino(
    etiqueta: 'Control semanal',
    etiquetaCorta: 'Control',
    icono: Icons.calendar_today_outlined,
    iconoActivo: Icons.calendar_today,
    ruta: Rutas.controlCliente,
  ),
  Destino(
    etiqueta: 'Biblioteca',
    icono: Icons.bookmark_border,
    iconoActivo: Icons.bookmark,
    ruta: Rutas.bibliotecaCliente,
  ),
  Destino(
    etiqueta: 'Configuracion',
    etiquetaCorta: 'Ajustes',
    icono: Icons.settings_outlined,
    iconoActivo: Icons.settings,
    ruta: Rutas.avisosCliente,
  ),
];

/// Los cuatro del entrenador.
const List<Destino> destinosEntrenador = [
  Destino(
    etiqueta: 'Planificacion',
    etiquetaCorta: 'Planning',
    icono: Icons.calendar_month_outlined,
    iconoActivo: Icons.calendar_month,
    ruta: Rutas.inicioEntrenador,
  ),
  Destino(
    etiqueta: 'Clientes',
    icono: Icons.people_outline,
    iconoActivo: Icons.people,
    ruta: Rutas.clientesEntrenador,
  ),
  Destino(
    etiqueta: 'Biblioteca',
    icono: Icons.bookmark_border,
    iconoActivo: Icons.bookmark,
    ruta: Rutas.bibliotecaEntrenador,
  ),
  Destino(
    etiqueta: 'Ajustes',
    icono: Icons.settings_outlined,
    iconoActivo: Icons.settings,
    ruta: Rutas.ajustesEntrenador,
  ),
];

/// Barra inferior. La usan el cliente (5 destinos) y el entrenador en movil (4).
class BarraInferior extends StatelessWidget {
  const BarraInferior({
    required this.destinos,
    required this.rutaActual,
    super.key,
  });

  final List<Destino> destinos;
  final String rutaActual;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      decoration: const BoxDecoration(
        color: Tokens.superficie,
        border: Border(top: BorderSide(color: Tokens.borde)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              for (final destino in destinos)
                Expanded(
                  child: InkWell(
                    key: Key('nav_${destino.ruta}'),
                    onTap: () => context.go(destino.ruta),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            rutaActual == destino.ruta
                                ? destino.iconoActivo
                                : destino.icono,
                            size: 22,
                            color: rutaActual == destino.ruta
                                ? Tokens.acento
                                : Tokens.textoTenue,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            destino.etiquetaDeBarra,
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: textos.labelSmall?.copyWith(
                              color: rutaActual == destino.ruta
                                  ? Tokens.acento
                                  : Tokens.textoTenue,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Barra lateral del entrenador en escritorio: marca arriba y los destinos
/// debajo, con el activo sobre `accentSoft`.
class BarraLateral extends StatelessWidget {
  const BarraLateral({required this.rutaActual, super.key});

  final String rutaActual;

  static const double ancho = 92;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Container(
      width: ancho,
      decoration: const BoxDecoration(
        color: Tokens.superficie,
        border: Border(right: BorderSide(color: Tokens.borde)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Text(
            'AIMAR',
            style: textos.labelMedium?.copyWith(
              color: Tokens.acento,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 24),
          for (final destino in destinosEntrenador)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: InkWell(
                key: Key('nav_${destino.ruta}'),
                onTap: () => context.go(destino.ruta),
                borderRadius: BorderRadius.circular(Tokens.radioBoton),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: rutaActual == destino.ruta
                        ? Tokens.acentoSuave
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(Tokens.radioBoton),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        rutaActual == destino.ruta
                            ? destino.iconoActivo
                            : destino.icono,
                        size: 22,
                        color: rutaActual == destino.ruta
                            ? Tokens.acento
                            : Tokens.textoSuave,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        destino.etiqueta,
                        textAlign: TextAlign.center,
                        style: textos.labelSmall?.copyWith(
                          color: rutaActual == destino.ruta
                              ? Tokens.acento
                              : Tokens.textoSuave,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A partir de aqui se considera escritorio: el entrenador ve barra lateral y
/// el panel de biblioteca fijo. Por debajo, barra inferior y modal.
const double anchoEscritorio = 1000;

bool esEscritorio(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= anchoEscritorio;

/// Andamio comun de las pantallas del entrenador: barra lateral en escritorio y
/// barra inferior en movil.
///
/// Tiene que envolver **todas** sus pantallas, no solo la de planificacion: sin
/// el, entrar en Clientes o en Biblioteca dejaba al entrenador sin ninguna
/// navegacion a la vista.
class PantallaEntrenador extends StatelessWidget {
  const PantallaEntrenador({
    required this.rutaActual,
    required this.cuerpo,
    this.appBar,
    this.botonFlotante,
    super.key,
  });

  final String rutaActual;
  final Widget cuerpo;
  final PreferredSizeWidget? appBar;
  final Widget? botonFlotante;

  @override
  Widget build(BuildContext context) {
    final escritorio = esEscritorio(context);

    return Scaffold(
      // En escritorio la barra lateral llega hasta arriba, asi que la cabecera
      // va dentro de la columna de la derecha y no como `appBar` del Scaffold.
      appBar: escritorio ? null : appBar,
      floatingActionButton: botonFlotante,
      body: SafeArea(
        bottom: false,
        child: escritorio
            ? Row(
                children: [
                  BarraLateral(rutaActual: rutaActual),
                  Expanded(
                    child: Column(
                      children: [
                        ?appBar,
                        Expanded(child: cuerpo),
                      ],
                    ),
                  ),
                ],
              )
            : cuerpo,
      ),
      bottomNavigationBar: escritorio
          ? null
          : BarraInferior(destinos: destinosEntrenador, rutaActual: rutaActual),
    );
  }
}

/// Andamio comun de las pantallas del cliente: fondo, barra inferior y el
/// padding horizontal de 20 que pide el diseno.
class PantallaCliente extends StatelessWidget {
  const PantallaCliente({
    required this.rutaActual,
    required this.cuerpo,
    this.appBar,
    this.ctaInferior,
    super.key,
  });

  final String rutaActual;
  final Widget cuerpo;
  final PreferredSizeWidget? appBar;

  /// CTA fijo sobre la barra de navegacion (registro de ejercicio, control).
  final Widget? ctaInferior;

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: appBar,
    body: SafeArea(bottom: false, child: cuerpo),
    bottomNavigationBar: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (ctaInferior case final cta?)
          Container(
            color: Tokens.fondo,
            padding: const EdgeInsets.fromLTRB(
              Tokens.margenPantalla,
              12,
              Tokens.margenPantalla,
              12,
            ),
            child: cta,
          ),
        BarraInferior(destinos: destinosCliente, rutaActual: rutaActual),
      ],
    ),
  );
}
