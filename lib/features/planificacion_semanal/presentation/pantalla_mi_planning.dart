import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/presentation/pantalla_mis_plannings.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_ejercicio.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_registro_sesion.dart';

/// Pantalla de entrada del cliente (`docs/ui-design.md`, 6.1).
///
/// Es la misma informacion que ya daba la lista de plannings, pero puesta al
/// reves: lo primero es lo de hoy, y la semana queda como tira de dias. El
/// historico de semanas sigue existiendo, a un toque desde la cabecera.
class PantallaMiPlanning extends ConsumerWidget {
  const PantallaMiPlanning({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idCliente = ref.watch(idUsuarioActualProvider);
    if (idCliente == null) return const PantallaCargando();

    final plannings = ref.watch(misPlanningsProvider);

    return PantallaCliente(
      rutaActual: Rutas.inicioCliente,
      cuerpo: plannings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _Aviso(
          mensaje: mensajeDeErrorPlanificacion(error),
          onReintentar: () => ref.invalidate(misPlanningsProvider),
        ),
        data: (lista) {
          // La semana que incluye hoy; si no hay ninguna, la activa mas
          // reciente, que es lo que el cliente esperaria ver.
          final hoy = DateTime.now();
          final activos = lista.where((p) => p.estado.esActivo).toList();
          final deHoy = activos.where((p) => p.contiene(hoy)).firstOrNull;
          final planning = deHoy ?? activos.firstOrNull;

          if (planning == null) {
            return _Aviso(
              mensaje:
                  'Tu entrenador todavia no te ha preparado ninguna '
                  'semana.',
              onReintentar: () => ref.invalidate(misPlanningsProvider),
            );
          }
          return _Semana(
            idCliente: idCliente,
            planningId: planning.id,
            esLaDeHoy: deHoy != null,
          );
        },
      ),
    );
  }
}

class _Semana extends ConsumerStatefulWidget {
  const _Semana({
    required this.idCliente,
    required this.planningId,
    required this.esLaDeHoy,
  });

  final String idCliente;
  final String planningId;
  final bool esLaDeHoy;

  @override
  ConsumerState<_Semana> createState() => _SemanaState();
}

class _SemanaState extends ConsumerState<_Semana> {
  /// Numero de sesion elegido en la tira. `null` hasta que se carga el planning:
  /// entonces se empieza por la primera que quede pendiente.
  int? _orden;

  @override
  Widget build(BuildContext context) {
    final completo = ref.watch(planningCompletoProvider(widget.planningId));
    final ficha = ref.watch(clientePorIdProvider(widget.idCliente)).value;

    return completo.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => _Aviso(
        mensaje: mensajeDeErrorPlanificacion(error),
        onReintentar: () =>
            ref.invalidate(planningCompletoProvider(widget.planningId)),
      ),
      data: (planning) {
        // Se empieza por la primera sesion sin terminar: es por donde el cliente
        // va a seguir. Si ya estan todas, por la ultima.
        final sesion =
            planning.sesionNumero(_orden ?? -1) ??
            planning.siguientePendiente ??
            planning.sesionesOrdenadas.lastOrNull;

        return RefreshIndicator(
          onRefresh: () async =>
              ref.invalidate(planningCompletoProvider(widget.planningId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(
              Tokens.margenPantalla,
              8,
              Tokens.margenPantalla,
              24,
            ),
            children: [
              _Cabecera(ficha: ficha),
              const SizedBox(height: 18),
              _TiraDeSesiones(
                planning: planning,
                elegida: sesion,
                onElegir: (nueva) => setState(() => _orden = nueva.orden),
              ),
              const SizedBox(height: Tokens.separacionBloques),
              if (sesion == null)
                const _SinSesiones()
              else
                _TarjetaSesion(
                  sesion: sesion,
                  planning: planning,
                  idCliente: widget.idCliente,
                ),
              const SizedBox(height: Tokens.separacionBloques),
              _Estadisticas(planning: planning, ficha: ficha),
              const SizedBox(height: Tokens.separacionBloques),
              if (sesion != null && planning.estado.esActivo)
                BotonCta(
                  etiqueta: _siguientePendiente(sesion) == null
                      ? 'Revisar la sesion'
                      : 'Continuar entrenamiento',
                  onPulsar: () => _abrirSesion(context, planning, sesion),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Entra directo al primer ejercicio sin registrar: es lo que el cliente va a
  /// hacer el 90% de las veces. Si ya estan todos, abre la lista para repasar.
  void _abrirSesion(
    BuildContext context,
    PlanningSemanal planning,
    SesionEntrenamiento sesion,
  ) {
    final pendiente = _siguientePendiente(sesion);
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => pendiente == null
            ? PantallaRegistroSesion(
                planningId: planning.id,
                sesionId: sesion.id,
                clienteId: widget.idCliente,
              )
            : PantallaRegistroEjercicio(
                ejercicio: pendiente,
                planningId: planning.id,
                clienteId: widget.idCliente,
                sesion: sesion,
              ),
      ),
    );
  }
}

EjercicioPlanificado? _siguientePendiente(SesionEntrenamiento sesion) => sesion
    .bloques
    .expand((b) => b.ejercicios)
    .where((e) => !e.estadoRegistro.estaRegistrado)
    .firstOrNull;

class _Cabecera extends StatelessWidget {
  const _Cabecera({required this.ficha});

  final Cliente? ficha;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final nombre = ficha?.nombre ?? '';
    final primerNombre = nombre.split(' ').first;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'AIMAR',
                style: textos.labelMedium?.copyWith(
                  color: Tokens.acento,
                  letterSpacing: 3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                primerNombre.isEmpty ? 'Hola' : 'Hola, $primerNombre',
                style: textos.headlineMedium,
              ),
            ],
          ),
        ),
        IconButton(
          key: const Key('boton_historico_semanas'),
          tooltip: 'Semanas anteriores',
          icon: const Icon(Icons.history),
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PantallaMisPlannings()),
          ),
        ),
        const SizedBox(width: 4),
        CircleAvatar(
          radius: 22,
          backgroundColor: Tokens.superficie2,
          child: Text(_iniciales(nombre), style: textos.titleSmall),
        ),
      ],
    );
  }

  /// Dos iniciales como mucho: "Marta Lopez" -> "ML".
  static String _iniciales(String nombre) {
    final partes = nombre
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty);
    if (partes.isEmpty) return '?';
    return partes.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// Tira horizontal de los siete dias de la semana del planning.
/// Tira horizontal de las sesiones del planning: DIA 1, DIA 2...
///
/// Sustituye a la tira de dias de la semana: la sesion ya no cae en un dia, el
/// cliente la hace cuando puede.
class _TiraDeSesiones extends StatelessWidget {
  const _TiraDeSesiones({
    required this.planning,
    required this.elegida,
    required this.onElegir,
  });

  final PlanningSemanal planning;
  final SesionEntrenamiento? elegida;
  final ValueChanged<SesionEntrenamiento> onElegir;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final sesiones = planning.sesionesOrdenadas;
    if (sesiones.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: sesiones.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, indice) {
          final sesion = sesiones[indice];
          final activa = sesion.id == elegida?.id;

          return InkWell(
            key: Key('sesion_tira_${sesion.orden}'),
            onTap: () => onElegir(sesion),
            borderRadius: BorderRadius.circular(Tokens.radioBoton),
            child: Container(
              width: 72,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: activa ? Tokens.acento : Tokens.superficie2,
                borderRadius: BorderRadius.circular(Tokens.radioBoton),
                border: Border.all(
                  color: activa ? Tokens.acento : Tokens.borde,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'DIA ${sesion.orden}',
                    style: textos.labelMedium?.copyWith(
                      color: activa ? Tokens.sobreAcento : Tokens.textoSuave,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Verde si ya la hizo, ambar si le queda pendiente.
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: sesion.resultadoRegistrado
                          ? Tokens.exito
                          : Tokens.secundario,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SinSesiones extends StatelessWidget {
  const _SinSesiones();

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Semana sin sesiones', style: textos.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Tu entrenador aun no ha anadido ninguna sesion a esta semana.',
            style: textos.bodySmall,
          ),
        ],
      ),
    );
  }
}

/// La sesion del dia elegido, con su progreso y sus ejercicios.
class _TarjetaSesion extends StatelessWidget {
  const _TarjetaSesion({
    required this.sesion,
    required this.planning,
    required this.idCliente,
  });

  final SesionEntrenamiento sesion;
  final PlanningSemanal planning;
  final String idCliente;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = sesion.bloques.expand((b) => b.ejercicios).toList();
    final hechos = ejercicios
        .where((e) => e.estadoRegistro.estaRegistrado)
        .length;
    final siguiente = _siguientePendiente(sesion);

    return Tarjeta(
      resaltada: !sesion.resultadoRegistrado,
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      sesion.fechaRealizada == null
                          ? 'DIA ${sesion.orden}'
                          : 'DIA ${sesion.orden} · HECHA EL '
                                '${_comoFechaCorta(sesion.fechaRealizada!)}',
                      style: textos.labelMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(sesion.nombre, style: textos.headlineSmall),
                    const SizedBox(height: 4),
                    Text(
                      '${ejercicios.length} '
                      '${ejercicios.length == 1 ? "ejercicio" : "ejercicios"}',
                      style: textos.bodySmall,
                    ),
                  ],
                ),
              ),
              ProgresoCircular(hechos: hechos, total: ejercicios.length),
            ],
          ),
          const SizedBox(height: 12),
          for (final ejercicio in ejercicios) ...[
            const Divider(height: 17),
            _FilaEjercicio(
              ejercicio: ejercicio,
              esElSiguiente: ejercicio.id == siguiente?.id,
              onTap: planning.estado.esActivo
                  ? () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => PantallaRegistroEjercicio(
                          ejercicio: ejercicio,
                          planningId: planning.id,
                          clienteId: idCliente,
                          sesion: sesion,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
          if (ejercicios.isEmpty)
            Text(
              'Esta sesion aun no tiene ejercicios.',
              style: textos.bodySmall,
            ),
        ],
      ),
    );
  }
}

class _FilaEjercicio extends StatelessWidget {
  const _FilaEjercicio({
    required this.ejercicio,
    required this.esElSiguiente,
    required this.onTap,
  });

  final EjercicioPlanificado ejercicio;
  final bool esElSiguiente;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final registrado = ejercicio.estadoRegistro.estaRegistrado;

    return InkWell(
      key: Key('ejercicio_hoy_${ejercicio.id}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: registrado
                    ? Tokens.exito.withValues(alpha: 0.16)
                    : esElSiguiente
                    ? Tokens.acentoSuave
                    : Tokens.superficie2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                registrado
                    ? Icons.check
                    : esElSiguiente
                    ? Icons.play_arrow
                    : Icons.circle_outlined,
                size: 18,
                color: registrado
                    ? Tokens.exito
                    : esElSiguiente
                    ? Tokens.acento
                    : Tokens.textoTenue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ejercicio.ejercicio?.nombre ?? 'Ejercicio',
                    style: textos.titleSmall?.copyWith(
                      color: registrado ? Tokens.textoSuave : Tokens.texto,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(resumenDeEjercicio(ejercicio), style: textos.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

/// "4 series · 60-65 kg" o "30 min", a partir de lo planificado.
String resumenDeEjercicio(EjercicioPlanificado ejercicio) {
  if (ejercicio.minutosPlanificados case final minutos?) {
    return '${_numero(minutos)} min';
  }
  final series = ejercicio.series;
  if (series.isEmpty) return 'Sin series planificadas';

  final pesos = series.map((s) => s.pesoPlanificado).nonNulls.toList();
  final cuantas =
      '${series.length} '
      '${series.length == 1 ? "serie" : "series"}';
  if (pesos.isEmpty) return cuantas;

  final minimo = pesos.reduce((a, b) => a < b ? a : b);
  final maximo = pesos.reduce((a, b) => a > b ? a : b);
  final rango = minimo == maximo
      ? '${_numero(minimo)} kg'
      : '${_numero(minimo)}-${_numero(maximo)} kg';
  return '$cuantas · $rango';
}

/// Proximo control y sesiones de la semana.
class _Estadisticas extends StatelessWidget {
  const _Estadisticas({required this.planning, required this.ficha});

  final PlanningSemanal planning;
  final Cliente? ficha;

  @override
  Widget build(BuildContext context) {
    final hechas = planning.sesiones.where((s) => s.resultadoRegistrado).length;

    return Row(
      children: [
        Expanded(
          child: _Dato(
            etiqueta: 'PROXIMO CONTROL',
            valor: ficha?.diaControlPreferido.etiqueta ?? '-',
            color: Tokens.secundario,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _Dato(
            etiqueta: 'ESTA SEMANA',
            valor: '$hechas / ${planning.sesiones.length} sesiones',
            color: Tokens.texto,
          ),
        ),
      ],
    );
  }
}

class _Dato extends StatelessWidget {
  const _Dato({
    required this.etiqueta,
    required this.valor,
    required this.color,
  });

  final String etiqueta;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      padding: const EdgeInsets.all(14),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(etiqueta, style: textos.labelSmall),
          const SizedBox(height: 6),
          Text(valor, style: textos.titleMedium?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Aviso extends StatelessWidget {
  const _Aviso({required this.mensaje, required this.onReintentar});

  final String mensaje;
  final VoidCallback onReintentar;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_month_outlined, size: 48),
          const SizedBox(height: 16),
          Text(
            mensaje,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onReintentar, child: const Text('Reintentar')),
        ],
      ),
    ),
  );
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFechaCorta(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}';
