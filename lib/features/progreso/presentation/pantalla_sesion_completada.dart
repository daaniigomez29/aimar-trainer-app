import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/referencias_semana_anterior.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/progreso/domain/resumen_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/informe/formato_informe.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/widgets/celebracion.dart';

/// La celebracion al terminar una sesion: lo que se ha hecho y lo que se ha
/// mejorado frente a la ultima vez.
///
/// Se llega al guardar el ultimo ejercicio, antes de volver al planning. Toda
/// la animacion la mueve **un solo controlador**: un toque en cualquier sitio
/// la lleva al final, y si el sistema pide reducir movimiento sale ya quieta.
/// Dura poco y termina sola: no hay nada en bucle.
class PantallaSesionCompletada extends ConsumerStatefulWidget {
  const PantallaSesionCompletada({
    required this.planningId,
    required this.sesion,
    super.key,
  });

  final String planningId;
  final SesionEntrenamiento sesion;

  @override
  ConsumerState<PantallaSesionCompletada> createState() =>
      _PantallaSesionCompletadaState();
}

class _PantallaSesionCompletadaState
    extends ConsumerState<PantallaSesionCompletada>
    with SingleTickerProviderStateMixin {
  late final AnimationController _celebracion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2200),
  );

  late final Animation<double> _check = CurvedAnimation(
    parent: _celebracion,
    curve: const Interval(0, 0.45),
  );
  late final Animation<double> _confeti = CurvedAnimation(
    parent: _celebracion,
    curve: const Interval(0.12, 1),
  );
  late final Animation<double> _cifras = CurvedAnimation(
    parent: _celebracion,
    curve: const Interval(0.3, 0.8, curve: Curves.easeOutCubic),
  );

  /// Las entradas de los textos y tarjetas (con `flutter_animate`) se
  /// recrean ya terminadas cuando esto pasa a `true`.
  bool _saltada = false;
  bool _empezada = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_empezada) return;
    _empezada = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _saltar();
    } else {
      _celebracion.forward();
    }
  }

  @override
  void dispose() {
    _celebracion.dispose();
    super.dispose();
  }

  void _saltar() {
    if (_saltada) return;
    _celebracion.value = 1;
    setState(() => _saltada = true);
  }

  /// Entrada escalonada de cada pieza. Saltada, ya en su sitio.
  Widget _entra(Widget hijo, {required int orden}) => hijo
      .animate(
        // Una clave por pieza: compartida, la lista las confundia.
        key: ValueKey((orden, _saltada)),
        delay: _saltada
            ? Duration.zero
            : Duration(milliseconds: 500 + 90 * orden),
        value: _saltada ? 1 : 0,
      )
      .fadeIn(duration: 350.ms)
      .slideY(begin: 0.25, duration: 350.ms, curve: Curves.easeOutCubic);

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final sesion = widget.sesion;
    final ultimaVez = ref
        .watch(referenciasDeSesionProvider(widget.planningId, sesion.orden))
        .value;
    final resumen = resumirSesion(sesion, ultimaVez: ultimaVez ?? const {});

    final cifras = <Widget>[
      _Cifra(
        clave: 'cifra_series',
        etiqueta: 'Series',
        valor: resumen.seriesHechas.toDouble(),
        formato: (v) => '${v.round()}',
        detalle: 'de ${resumen.seriesPlanificadas} planificadas',
        progreso: _cifras,
      ),
      if (resumen.volumenKg > 0)
        _Cifra(
          clave: 'cifra_volumen',
          etiqueta: 'Volumen',
          valor: resumen.volumenKg,
          formato: (v) => '${miles(v)} kg',
          detalle: 'peso x repeticiones',
          progreso: _cifras,
        ),
      if (resumen.minutosCardio > 0)
        _Cifra(
          clave: 'cifra_cardio',
          etiqueta: 'Cardio',
          valor: resumen.minutosCardio,
          formato: (v) => '${kg(v)} min',
          detalle: 'de actividad',
          progreso: _cifras,
        ),
    ];

    return PantallaConNavegacion(
      seccion: SeccionDeNavegacion.inicio,
      ctaInferior: FilledButton(
        key: const Key('volver_al_planning'),
        onPressed: () => context.go(Rutas.inicioClienteEnDia(sesion.orden)),
        child: const Text('Volver al planning'),
      ),
      cuerpo: GestureDetector(
        key: const Key('sesion_completada'),
        behavior: HitTestBehavior.translucent,
        onTap: _saltar,
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(
                    Tokens.margenPantalla,
                    32,
                    Tokens.margenPantalla,
                    24,
                  ),
                  children: [
                    Center(child: CheckDibujado(progreso: _check)),
                    const SizedBox(height: 20),
                    _entra(
                      Text(
                        '¡Sesión completada!',
                        textAlign: TextAlign.center,
                        style: textos.headlineSmall,
                      ),
                      orden: 0,
                    ),
                    const SizedBox(height: 6),
                    _entra(
                      Text(
                        'Día ${sesion.orden} · ${sesion.nombre}',
                        textAlign: TextAlign.center,
                        style: textos.bodyMedium?.copyWith(
                          color: Tokens.textoSuave,
                        ),
                      ),
                      orden: 1,
                    ),
                    const SizedBox(height: 24),
                    _entra(
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 10,
                        runSpacing: 10,
                        children: cifras,
                      ),
                      orden: 2,
                    ),
                    if (ultimaVez != null && ultimaVez.isNotEmpty) ...[
                      const SizedBox(height: 28),
                      if (resumen.mejoras.isEmpty)
                        _entra(
                          Text(
                            'Hoy has mantenido tus marcas de la última vez. '
                            'La constancia también suma.',
                            key: const Key('sin_mejoras'),
                            textAlign: TextAlign.center,
                            style: textos.bodyMedium?.copyWith(
                              color: Tokens.textoSuave,
                            ),
                          ),
                          orden: 3,
                        )
                      else ...[
                        _entra(
                          Text(
                            'Has superado la última vez',
                            style: textos.titleMedium,
                          ),
                          orden: 3,
                        ),
                        const SizedBox(height: 10),
                        for (final (i, mejora) in resumen.mejoras.indexed)
                          _entra(_FilaMejora(mejora: mejora), orden: 4 + i),
                      ],
                    ],
                  ],
                ),
              ),
            ),
            Positioned.fill(child: Confeti(progreso: _confeti)),
          ],
        ),
      ),
    );
  }
}

class _Cifra extends StatelessWidget {
  const _Cifra({
    required this.clave,
    required this.etiqueta,
    required this.valor,
    required this.formato,
    required this.detalle,
    required this.progreso,
  });

  final String clave;
  final String etiqueta;
  final double valor;
  final String Function(double) formato;
  final String detalle;
  final Animation<double> progreso;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return SizedBox(
      width: 160,
      child: Tarjeta(
        key: Key(clave),
        padding: const EdgeInsets.all(14),
        hijo: Column(
          children: [
            Text(etiqueta, style: textos.bodySmall),
            const SizedBox(height: 4),
            CifraQueSube(
              progreso: progreso,
              valor: valor,
              formato: formato,
              estilo: textos.headlineSmall?.copyWith(color: Tokens.acento),
            ),
            Text(detalle, style: textos.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _FilaMejora extends StatelessWidget {
  const _FilaMejora({required this.mejora});

  final Mejora mejora;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final unidad = unidadDe(mejora);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Tarjeta(
        key: Key('mejora_${mejora.ejercicio}'),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        hijo: Row(
          children: [
            const Icon(Icons.trending_up, color: Tokens.exito),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(mejora.ejercicio, style: textos.titleSmall),
                  Text(
                    '${kg(mejora.antes)} → ${kg(mejora.ahora)} $unidad · '
                    'respecto ${respectoA(mejora)}',
                    style: textos.bodySmall,
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Tokens.exito.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(Tokens.radioPastilla),
              ),
              child: Text(
                '+${kg(mejora.diferencia)} $unidad',
                style: textos.labelMedium?.copyWith(color: Tokens.exito),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
