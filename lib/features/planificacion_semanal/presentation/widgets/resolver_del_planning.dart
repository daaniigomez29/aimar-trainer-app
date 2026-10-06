import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';

/// Carga un planning y entrega la pieza concreta que la pantalla necesita.
///
/// POR QUE EXISTE: desde que el bloque, la sesión y el ejercicio planificado se
/// alcanzan **por la URL**, ya no llegan como objeto: llegan como `id`. Y un
/// bloque solo existe dentro de su planning, así que se resuelve cargándolo
/// entero, que es lo que la pantalla iba a hacer de todos modos.
///
/// Si el id no aparece (un enlace viejo, algo que se borró), se dice en vez de
/// quedarse en blanco.
class ResolverDelPlanning<T> extends ConsumerWidget {
  const ResolverDelPlanning({
    required this.planningId,
    required this.buscar,
    required this.construir,
    this.noEncontrado = 'Eso ya no existe en este planning.',
    super.key,
  });

  final String planningId;

  /// Saca del planning la pieza buscada, o `null` si ya no está.
  final T? Function(PlanningSemanal planning) buscar;

  final Widget Function(PlanningSemanal planning, T encontrado) construir;
  final String noEncontrado;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref
        .watch(planningCompletoProvider(planningId))
        .when(
          data: (planning) {
            final encontrado = buscar(planning);
            if (encontrado == null) {
              return Scaffold(
                appBar: AppBar(),
                body: Center(child: Text(noEncontrado)),
              );
            }
            return construir(planning, encontrado);
          },
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(mensajeDeErrorPlanificacion(error))),
          ),
        );
  }
}

/// Busca un bloque por su id dentro del planning.
BloqueEjercicio? bloquePorId(PlanningSemanal planning, String idBloque) {
  for (final sesion in planning.sesiones) {
    for (final bloque in sesion.bloques) {
      if (bloque.id == idBloque) return bloque;
    }
  }
  return null;
}

/// Busca una sesión por su id.
SesionEntrenamiento? sesionPorId(PlanningSemanal planning, String idSesion) =>
    planning.sesiones.where((s) => s.id == idSesion).firstOrNull;

/// Busca un ejercicio planificado por su id.
EjercicioPlanificado? ejercicioPlanificadoPorId(
  PlanningSemanal planning,
  String id,
) {
  for (final sesion in planning.sesiones) {
    for (final bloque in sesion.bloques) {
      for (final ejercicio in bloque.ejercicios) {
        if (ejercicio.id == id) return ejercicio;
      }
    }
  }
  return null;
}
