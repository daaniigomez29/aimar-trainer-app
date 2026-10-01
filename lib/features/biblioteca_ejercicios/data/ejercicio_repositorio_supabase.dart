import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio_repositorio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';

part 'ejercicio_repositorio_supabase.g.dart';

@Riverpod(keepAlive: true)
EjercicioRepositorio ejercicioRepositorio(Ref ref) =>
    EjercicioRepositorioSupabase(cliente: ref.watch(clienteSupabaseProvider));

/// Implementacion de [EjercicioRepositorio] sobre la tabla `ejercicios`.
///
/// Quien puede escribir lo decide RLS (`es_entrenador()`), no esta clase: un
/// cliente que intentara crear recibe un `42501` que aqui se traduce a
/// [ErrorNoAutorizado].
class EjercicioRepositorioSupabase implements EjercicioRepositorio {
  EjercicioRepositorioSupabase({required this.cliente});

  static const String _tabla = 'ejercicios';

  final SupabaseClient cliente;

  @override
  Future<Result<List<Ejercicio>>> listar() async {
    try {
      final filas = await cliente.from(_tabla).select().order('nombre');
      return Success(filas.map(Ejercicio.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Ejercicio>> obtenerPorId(String id) async {
    try {
      final fila = await cliente
          .from(_tabla)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (fila == null) {
        return const Failure(ErrorNoEncontrado('Ese ejercicio ya no existe.'));
      }
      return Success(Ejercicio.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Ejercicio>> crear(DatosEjercicio datos) async {
    try {
      final fila = await cliente
          .from(_tabla)
          .insert(datos.aJsonDeEscritura())
          .select()
          .single();
      return Success(Ejercicio.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Ejercicio>> editar({
    required String id,
    required DatosEjercicio datos,
  }) async {
    try {
      final filas = await cliente
          .from(_tabla)
          .update(datos.aJsonDeEscritura())
          .eq('id', id)
          .select();
      // Cero filas con RLS activo no distingue "no existe" de "no puedes
      // tocarla": ambas se presentan como no encontrado, sin filtrar informacion.
      if (filas.isEmpty) {
        return const Failure(
          ErrorNoEncontrado('No se ha podido actualizar ese ejercicio.'),
        );
      }
      return Success(Ejercicio.fromJson(filas.first));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Ejercicio>> darDeBaja(String id) =>
      _cambiarEstado(id, EstadoEjercicio.eliminado);

  @override
  Future<Result<Ejercicio>> reactivar(String id) =>
      _cambiarEstado(id, EstadoEjercicio.activo);

  /// Baja y reactivacion son el mismo `update` de `estado`; nunca un `DELETE`.
  Future<Result<Ejercicio>> _cambiarEstado(
    String id,
    EstadoEjercicio estado,
  ) async {
    try {
      final filas = await cliente
          .from(_tabla)
          .update({'estado': estado.name})
          .eq('id', id)
          .select();
      if (filas.isEmpty) {
        return const Failure(
          ErrorNoEncontrado('No se ha podido actualizar ese ejercicio.'),
        );
      }
      return Success(Ejercicio.fromJson(filas.first));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<int>> contarUsosEnPlanningsActivos(String id) async {
    // TODO(fase 4): contar sobre `ejercicios_planificados` unido a
    // `bloques_ejercicio`, `sesiones_entrenamiento` y `plannings_semanales` con
    // `estado = 'activo'`. Esas tablas todavia no existen, asi que de momento no
    // hay ningun uso posible y la respuesta correcta es 0.
    return const Success(0);
  }

  ErrorApp _traducir(Object error, StackTrace traza) {
    if (error is ErrorApp) return error;
    if (error is PostgrestException) {
      return switch (error.code) {
        // Violacion de `ejercicios_nombre_activo_unico`.
        '23505' => const ErrorNombreDuplicado(
          'Ya existe un ejercicio activo con ese nombre.',
        ),
        // Violacion de una politica RLS: no es entrenador.
        '42501' => const ErrorNoAutorizado(),
        'PGRST116' => const ErrorNoEncontrado('Ese ejercicio ya no existe.'),
        // Un `not null` o un `check` que la validacion de dominio no cubrio.
        '23502' || '23514' => const ErrorValidacion(
          'Faltan datos obligatorios o alguno no es valido.',
        ),
        _ => Registro.inesperado(
          error,
          traza,
          contexto: 'el repositorio de ejercicios',
        ),
      };
    }
    if (error is TimeoutException) return const ErrorConexion();
    final nombre = error.runtimeType.toString();
    if (nombre == 'ClientException' || nombre == 'SocketException') {
      return const ErrorConexion();
    }
    Registro.fallo(error, traza, contexto: 'el repositorio de ejercicios');
    return ErrorInesperado(causa: error, traza: traza);
  }
}
