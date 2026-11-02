import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Contenedor de ancho limitado y centrado para los formularios.
///
/// Evita que en pantalla ancha (la PWA se usa tambien en escritorio) los campos
/// se estiren de lado a lado.
///
/// En escritorio, los formularios largos pueden pedir mas ancho
/// ([anchoEnEscritorio]) y sacar a la derecha lo que se consulta mientras se
/// rellena ([panelLateral]). En movil no cambia nada: una sola columna, y quien
/// usa esto pinta ese contenido entre los campos.
class FormularioCentrado extends StatelessWidget {
  const FormularioCentrado({
    required this.titulo,
    required this.hijos,
    this.subtitulo,
    this.seccion,
    this.anchoEnEscritorio,
    this.panelLateral,
    this.panelOcupaElResto = false,
    super.key,
  });

  static const double _anchoNormal = 420;
  static const double _anchoDelPanel = 400;

  /// El de los formularios de ejercicio, que con un panel al lado ganan a lo
  /// ancho lo que antes les sobraba a los lados.
  static const double anchoFormularioLargo = 720;

  /// Limites del formulario cuando el panel se queda con el resto, con su
  /// margen incluido. Por debajo, las filas de una serie irian apretadas.
  static const double _minimoJuntoAlPanel = 500;
  static const double _maximoJuntoAlPanel = anchoFormularioLargo + 48;

  final String titulo;
  final String? subtitulo;
  final List<Widget> hijos;

  /// Seccion de la navegacion a la que pertenece el formulario, si lo abre
  /// alguien con la sesion abierta. Los de autenticacion la dejan a `null`: no
  /// hay barra que poner cuando todavia no se sabe quien eres.
  final SeccionDeNavegacion? seccion;

  /// Ancho maximo del formulario en escritorio, si necesita mas que el normal.
  final double? anchoEnEscritorio;

  /// Columna fija a la derecha, **solo en escritorio** (se ignora en movil). Se
  /// desplaza por su cuenta: se puede buscar en ella sin perder de vista el
  /// formulario.
  final Widget? panelLateral;

  /// El panel se queda con todo el ancho que no necesita el formulario, en vez
  /// de sus 400 px. Para cuando el panel es lo principal de la pantalla.
  final bool panelOcupaElResto;

  @override
  Widget build(BuildContext context) {
    final cuerpo = _contenido(context);
    return seccion == null
        ? Scaffold(body: cuerpo)
        : PantallaConNavegacion(seccion: seccion!, cuerpo: cuerpo);
  }

  Widget _contenido(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final escritorio = esEscritorio(context);
    final panel = escritorio ? panelLateral : null;

    final formulario = SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: escritorio
              ? (anchoEnEscritorio ?? _anchoNormal)
              : _anchoNormal,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(titulo, style: textos.headlineSmall),
            if (subtitulo != null) ...[
              const SizedBox(height: 8),
              Text(subtitulo!, style: textos.bodyMedium),
            ],
            const SizedBox(height: 24),
            ...hijos,
          ],
        ),
      ),
    );

    if (panel == null) return SafeArea(child: Center(child: formulario));

    // Arriba y no centrado en vertical: el formulario crece al elegir un
    // ejercicio, y centrado daria un salto.
    final arriba = Align(alignment: Alignment.topCenter, child: formulario);
    final columnaDelPanel = Container(
      key: const Key('panel_lateral_formulario'),
      decoration: const BoxDecoration(
        color: Tokens.superficie,
        border: Border(left: BorderSide(color: Tokens.borde)),
      ),
      // Transparente por lo mismo que el panel del planning: los
      // `ExpansionTile` pintan su tinta en el `Material` mas cercano.
      child: Material(type: MaterialType.transparency, child: panel),
    );

    if (panelOcupaElResto) {
      return SafeArea(
        child: LayoutBuilder(
          builder: (context, limites) => Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                width: (limites.maxWidth * 0.42).clamp(
                  _minimoJuntoAlPanel,
                  _maximoJuntoAlPanel,
                ),
                child: arriba,
              ),
              Expanded(child: columnaDelPanel),
            ],
          ),
        ),
      );
    }

    return SafeArea(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: arriba),
          SizedBox(width: _anchoDelPanel, child: columnaDelPanel),
        ],
      ),
    );
  }
}

/// Aviso en linea para errores generales y confirmaciones.
class AvisoEnLinea extends StatelessWidget {
  const AvisoEnLinea({required this.mensaje, this.esError = true, super.key});

  final String mensaje;
  final bool esError;

  @override
  Widget build(BuildContext context) {
    final esquema = Theme.of(context).colorScheme;
    final fondo = esError ? esquema.errorContainer : esquema.secondaryContainer;
    final texto = esError
        ? esquema.onErrorContainer
        : esquema.onSecondaryContainer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: fondo,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            esError ? Icons.error_outline : Icons.check_circle_outline,
            color: texto,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(mensaje, style: TextStyle(color: texto)),
          ),
        ],
      ),
    );
  }
}
