import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/miniatura_ejercicio.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Un dia de la semana con **lo planificado al lado de lo que hizo el cliente**.
///
/// POR QUE EXISTE: el entrenador no tenia donde ver lo que sus clientes hacen el
/// mismo dia. Lo unico que lo ensenaba era la columna de referencia del editor,
/// y para llegar a ella habia que ponerse a planificar la semana siguiente.
///
/// Es **solo lectura**, a proposito: planificar se hace en el editor
/// (`/entrenador/plannings/:id`) y consultar aqui. Cada vista con su funcion;
/// mezclarlas es lo que hacia que esta pantalla tuviera diez acciones de
/// escritura y ninguna forma de ver un resultado.
///
/// Lo planificado y lo realizado **no se fuerzan a coincidir** (regla de
/// dominio): el cliente puede haber hecho mas series, menos, o ninguna. Por eso
/// se emparejan por numero de serie y las que sobran de un lado se ensenan
/// igual, con un guion en el otro.
class ResultadosDeSesion extends StatelessWidget {
  const ResultadosDeSesion({required this.sesion, super.key});

  final SesionEntrenamiento sesion;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final ejercicios = sesion.bloques.expand((b) => b.ejercicios).toList();
    final hechos = ejercicios
        .where((e) => e.estadoRegistro.estaRegistrado)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Tarjeta(
          hijo: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DÍA ${sesion.orden}', style: textos.labelMedium),
                    const SizedBox(height: 6),
                    Text(sesion.nombre, style: textos.headlineSmall),
                    const SizedBox(height: 4),
                    Text(switch ((sesion.fechaRealizada, hechos)) {
                      (final fecha?, _) => 'Hecha el ${_comoFecha(fecha)}',
                      (null, 0) => 'Sin empezar',
                      _ => 'Empezada, sin fecha registrada',
                    }, style: textos.bodySmall),
                  ],
                ),
              ),
              ProgresoCircular(hechos: hechos, total: ejercicios.length),
            ],
          ),
        ),
        const SizedBox(height: Tokens.separacionBloques),
        if (sesion.bloques.isEmpty)
          Text('Este día no tiene bloques.', style: textos.bodySmall)
        else
          for (final bloque in sesion.bloques) ...[
            _Bloque(bloque: bloque),
            const SizedBox(height: 14),
          ],
      ],
    );
  }
}

class _Bloque extends StatelessWidget {
  const _Bloque({required this.bloque});

  final BloqueEjercicio bloque;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      key: Key('resultado_bloque_${bloque.id}'),
      hijo: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'BLOQUE ${bloque.orden} · ${bloque.tipo.etiqueta.toUpperCase()}',
            style: textos.labelMedium,
          ),
          if (bloque.notas case final notas?) ...[
            const SizedBox(height: 4),
            Text(notas, style: textos.bodySmall),
          ],
          if (bloque.ejercicios.isEmpty) ...[
            const Divider(height: 20),
            Text('Sin ejercicios.', style: textos.bodySmall),
          ],
          for (final ejercicio in bloque.ejercicios) ...[
            const Divider(height: 20),
            _Ejercicio(ejercicio: ejercicio),
          ],
        ],
      ),
    );
  }
}

class _Ejercicio extends StatelessWidget {
  const _Ejercicio({required this.ejercicio});

  final EjercicioPlanificado ejercicio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final registrado = ejercicio.estadoRegistro.estaRegistrado;

    return Column(
      key: Key('resultado_ejercicio_${ejercicio.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            MiniaturaEjercicio(ejercicio: ejercicio.ejercicio, lado: 34),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                ejercicio.ejercicio?.nombre ?? 'Ejercicio',
                style: textos.titleSmall,
              ),
            ),
            Icon(
              registrado ? Icons.task_alt : Icons.schedule,
              size: 16,
              color: registrado ? Tokens.exito : Tokens.textoTenue,
            ),
            const SizedBox(width: 6),
            Text(
              registrado ? 'Registrado' : 'Pendiente',
              style: textos.labelSmall?.copyWith(
                color: registrado ? Tokens.exito : Tokens.textoTenue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (ejercicio.ejercicio?.tipo.vaPorMinutos ?? false)
          _Minutos(ejercicio: ejercicio)
        else
          _Series(ejercicio: ejercicio),
      ],
    );
  }
}

/// Cardio: minutos planificados contra los que hizo.
class _Minutos extends StatelessWidget {
  const _Minutos({required this.ejercicio});

  final EjercicioPlanificado ejercicio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Row(
      children: [
        Expanded(
          child: Text(
            'Plan: ${_minutos(ejercicio.minutosPlanificados)}',
            style: textos.bodyMedium,
          ),
        ),
        Expanded(
          child: Text(
            'Hizo: ${_minutos(ejercicio.minutosRealizados)}',
            key: Key('minutos_realizados_${ejercicio.id}'),
            style: textos.bodyMedium?.copyWith(color: Tokens.exito),
          ),
        ),
      ],
    );
  }

  static String _minutos(double? valor) =>
      valor == null ? '—' : '${_numero(valor)} min';
}

/// Fuerza y Fortalecimiento: una fila por serie, plan contra realizado.
class _Series extends StatelessWidget {
  const _Series({required this.ejercicio});

  final EjercicioPlanificado ejercicio;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    // Todos los numeros de serie que existen en cualquiera de los dos lados: lo
    // realizado puede tener series que no se planificaron, y al reves.
    final numeros = {
      ...ejercicio.series.map((s) => s.numeroSerie),
      ...ejercicio.seriesRealizadas.map((s) => s.numeroSerie),
    }.toList()..sort();

    if (numeros.isEmpty) {
      return Text('Sin series.', style: textos.bodySmall);
    }

    return Column(
      children: [
        Row(
          children: [
            SizedBox(width: 40, child: Text('Serie', style: textos.labelSmall)),
            Expanded(child: Text('Plan', style: textos.labelSmall)),
            Expanded(child: Text('Hizo', style: textos.labelSmall)),
          ],
        ),
        for (final numero in numeros)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              children: [
                SizedBox(
                  width: 40,
                  child: Text('$numero', style: textos.bodyMedium),
                ),
                Expanded(
                  child: Text(
                    _planificada(
                      ejercicio.series
                          .where((s) => s.numeroSerie == numero)
                          .firstOrNull,
                    ),
                    style: textos.bodyMedium,
                  ),
                ),
                Expanded(
                  child: Text(
                    _realizada(
                      ejercicio.seriesRealizadas
                          .where((s) => s.numeroSerie == numero)
                          .firstOrNull,
                    ),
                    key: Key('serie_hecha_${ejercicio.id}_$numero'),
                    style: textos.bodyMedium?.copyWith(color: Tokens.exito),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  static String _planificada(SeriePlanificada? serie) {
    if (serie == null) return '—';
    return [
      if (serie.pesoPlanificado case final peso?) '${_numero(peso)} kg',
      '${serie.repeticionesPlanificadas} reps',
      if (serie.rirPlanificado case final rir?) 'RIR $rir',
    ].join(' · ');
  }

  static String _realizada(SerieRealizada? serie) {
    if (serie == null) return '—';
    return [
      if (serie.pesoReal case final peso?) '${_numero(peso)} kg',
      '${serie.repeticionesRealizadas} reps',
      if (serie.rirReal case final rir?) 'RIR $rir',
    ].join(' · ');
  }
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);

String _comoFecha(DateTime fecha) =>
    '${fecha.day.toString().padLeft(2, '0')}/'
    '${fecha.month.toString().padLeft(2, '0')}/${fecha.year}';
