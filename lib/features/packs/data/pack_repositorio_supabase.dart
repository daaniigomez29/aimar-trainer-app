import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/packs/domain/datos_pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack.dart';
import 'package:aimar_trainer_app/features/packs/domain/pack_repositorio.dart';

part 'pack_repositorio_supabase.g.dart';

@Riverpod(keepAlive: true)
PackRepositorio packRepositorio(Ref ref) =>
    PackRepositorioSupabase(cliente: ref.watch(clienteSupabaseProvider));

/// Implementacion de [PackRepositorio] sobre Supabase.
///
/// Todo va directo a las tablas o a las tres funciones de Postgres, sujeto a
/// RLS: las politicas `es_entrenador()` son las que impiden que nadie mas los
/// toque, aunque se forzara la interfaz.
class PackRepositorioSupabase implements PackRepositorio {
  PackRepositorioSupabase({required this.cliente});

  static const String _packs = 'packs';
  static const String _packEjercicios = 'pack_ejercicios';

  /// Guarda el ejercicio y sus series en una transaccion: PostgREST abre una
  /// por peticion, asi que esto no se puede hacer con tres llamadas.
  static const String _funcionGuardarEjercicio = 'guardar_ejercicio_del_pack';
  static const String _funcionReordenar = 'reordenar_pack_ejercicios';
  static const String _funcionAplicar = 'aplicar_pack_a_bloque';

  /// El pack entero en una consulta. Los nombres de las relaciones incrustadas
  /// coinciden con los `JsonKey` de las entidades.
  static const String _seleccionCompleta = '''
*,
pack_ejercicios(
  *,
  ejercicios(*),
  pack_series(*)
)''';

  final SupabaseClient cliente;

  @override
  Future<Result<List<Pack>>> listar() async {
    try {
      final filas = await cliente
          .from(_packs)
          .select(_seleccionCompleta)
          .order('nombre');
      return Success([for (final fila in filas) _ordenar(Pack.fromJson(fila))]);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Pack>> obtener(String id) async {
    try {
      final fila = await cliente
          .from(_packs)
          .select(_seleccionCompleta)
          .eq('id', id)
          .maybeSingle();
      if (fila == null) {
        return const Failure(ErrorNoEncontrado('Ese pack ya no existe.'));
      }
      return Success(_ordenar(Pack.fromJson(fila)));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  /// PostgREST no garantiza el orden de las relaciones incrustadas, asi que se
  /// ordena aqui: los ejercicios por su `orden` y las series por su numero.
  Pack _ordenar(Pack pack) => pack.copyWith(
    ejercicios: [
      for (final ejercicio in pack.ejerciciosOrdenados)
        ejercicio.copyWith(series: ejercicio.seriesOrdenadas),
    ],
  );

  @override
  Future<Result<Pack>> crear(DatosPack datos) async {
    try {
      final fila = await cliente
          .from(_packs)
          .insert(datos.aJson())
          .select()
          .single();
      return Success(Pack.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Pack>> editar({
    required String id,
    required DatosPack datos,
  }) async {
    try {
      final filas = await cliente
          .from(_packs)
          .update(datos.aJson())
          .eq('id', id)
          .select();
      // Con RLS, un update prohibido no da error: no toca filas (trampa 8).
      if (filas.isEmpty) {
        return const Failure(ErrorNoEncontrado('Ese pack ya no existe.'));
      }
      return Success(Pack.fromJson(filas.first));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<void>> eliminar(String id) => _eliminarDe(_packs, id);

  @override
  Future<Result<void>> eliminarEjercicio(String id) =>
      _eliminarDe(_packEjercicios, id);

  Future<Result<void>> _eliminarDe(String tabla, String id) async {
    try {
      await cliente.from(tabla).delete().eq('id', id);
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<String>> guardarEjercicio({
    required DatosPackEjercicio datos,
    String? id,
  }) async {
    final error = datos.validar();
    if (error != null) return Failure(error);

    try {
      final guardado = await cliente.rpc<String>(
        _funcionGuardarEjercicio,
        params: datos.aParametrosDeRpc(id: id),
      );
      return Success(guardado);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<void>> reordenarEjercicios({
    required String packId,
    required List<String> idsEnOrden,
  }) async {
    try {
      await cliente.rpc<void>(
        _funcionReordenar,
        params: {'p_pack_id': packId, 'p_ids': idsEnOrden},
      );
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<ResultadoAplicarPack>> aplicarABloque({
    required String packId,
    required String bloqueId,
  }) async {
    try {
      final respuesta = await cliente.rpc<Map<String, dynamic>>(
        _funcionAplicar,
        params: {'p_pack_id': packId, 'p_bloque_id': bloqueId},
      );
      return Success(ResultadoAplicarPack.fromJson(respuesta));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  ErrorApp _traducir(Object error, StackTrace traza) {
    if (error is ErrorApp) return error;
    if (error is PostgrestException) {
      return switch (error.code) {
        // El indice unico del nombre, o el del orden dentro del pack.
        '23505' => ErrorValidacion(_mensajeDeDuplicado(error.message)),
        '42501' => const ErrorNoAutorizado(),
        'PGRST116' => const ErrorNoEncontrado('Ese pack ya no existe.'),
        // Los triggers de tipo y las funciones lanzan con estos codigos, y su
        // mensaje ya esta redactado para leerse tal cual.
        '23514' || 'P0001' => ErrorValidacion(_limpiarMensaje(error.message)),
        'P0002' => ErrorNoEncontrado(_limpiarMensaje(error.message)),
        '23502' => const ErrorValidacion('Faltan datos obligatorios.'),
        '23503' => const ErrorValidacion(
          'Falta algo de lo que esto depende, o ya se ha eliminado.',
        ),
        '22003' => const ErrorValidacion(
          'Algún número está fuera del rango admitido.',
        ),
        _ => Registro.inesperado(
          error,
          traza,
          contexto: 'el repositorio de packs',
        ),
      };
    }
    if (error is TimeoutException) return const ErrorConexion();
    final nombre = error.runtimeType.toString();
    if (nombre == 'ClientException' || nombre == 'SocketException') {
      return const ErrorConexion();
    }
    Registro.fallo(error, traza, contexto: 'el repositorio de packs');
    return ErrorInesperado(causa: error, traza: traza);
  }

  String _mensajeDeDuplicado(String mensaje) =>
      mensaje.contains('packs_nombre_unico')
      ? 'Ya tienes un pack con ese nombre.'
      : 'Ese orden ya está ocupado en el pack.';

  /// Postgres antepone el contexto a los mensajes de los triggers; aqui solo
  /// interesa la frase, que ya esta escrita para el entrenador.
  String _limpiarMensaje(String mensaje) {
    final corte = mensaje.lastIndexOf(': ');
    final limpio = corte < 0 ? mensaje : mensaje.substring(corte + 2);
    return limpio.trim().isEmpty ? 'No se ha podido guardar.' : limpio.trim();
  }
}
