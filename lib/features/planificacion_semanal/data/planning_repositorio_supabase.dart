import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/enums_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';

part 'planning_repositorio_supabase.g.dart';

@Riverpod(keepAlive: true)
PlanningRepositorio planningRepositorio(Ref ref) =>
    PlanningRepositorioSupabase(cliente: ref.watch(clienteSupabaseProvider));

/// Implementacion de [PlanningRepositorio].
///
/// Todo va directo a las tablas, sujeto a RLS: no hay nada que exija
/// `service_role`. Las politicas `es_entrenador()` son las que impiden que un
/// cliente escriba, aunque se forzara la interfaz.
class PlanningRepositorioSupabase implements PlanningRepositorio {
  PlanningRepositorioSupabase({required this.cliente});

  static const String _plannings = 'plannings_semanales';
  static const String _sesiones = 'sesiones_entrenamiento';
  static const String _bloques = 'bloques_ejercicio';
  static const String _ejerciciosPlanificados = 'ejercicios_planificados';

  /// Funcion de Postgres que guarda el ejercicio y sus series en una transaccion.
  static const String _funcionGuardarEjercicio =
      'guardar_ejercicio_planificado';

  /// Jerarquia completa en una sola consulta. Los nombres de las relaciones
  /// incrustadas coinciden con los `JsonKey` de las entidades.
  static const String _seleccionCompleta = '''
*,
sesiones_entrenamiento(
  *,
  bloques_ejercicio(
    *,
    ejercicios_planificados(
      *,
      ejercicios(*),
      series_planificadas(*),
      series_realizadas(*)
    )
  )
)''';

  final SupabaseClient cliente;

  @override
  Future<Result<List<PlanningSemanal>>> listarDeCliente(
    String clienteId,
  ) async {
    try {
      final filas = await cliente
          .from(_plannings)
          .select()
          .eq('cliente_id', clienteId)
          .order('fecha_inicio', ascending: false);
      return Success(filas.map(PlanningSemanal.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<PlanningSemanal>> obtenerPlanningCompleto(
    String planningId,
  ) async {
    try {
      final fila = await cliente
          .from(_plannings)
          .select(_seleccionCompleta)
          .eq('id', planningId)
          .maybeSingle();
      if (fila == null) {
        return const Failure(ErrorNoEncontrado('Ese planning ya no existe.'));
      }
      return Success(_ordenarJerarquia(PlanningSemanal.fromJson(fila)));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  /// PostgREST no garantiza el orden de las relaciones incrustadas, asi que se
  /// ordena aqui: sesiones por fecha, bloques y ejercicios por `orden`, series por
  /// `numeroSerie`.
  PlanningSemanal _ordenarJerarquia(PlanningSemanal planning) {
    final sesiones = [...planning.sesiones]
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    return planning.copyWith(
      sesiones: [
        for (final sesion in sesiones)
          sesion.copyWith(
            bloques: [
              for (final bloque in [
                ...sesion.bloques,
              ]..sort((a, b) => a.orden.compareTo(b.orden)))
                bloque.copyWith(
                  ejercicios: [
                    for (final ejercicio in [
                      ...bloque.ejercicios,
                    ]..sort((a, b) => a.orden.compareTo(b.orden)))
                      ejercicio.copyWith(
                        series: [...ejercicio.series]
                          ..sort(
                            (a, b) => a.numeroSerie.compareTo(b.numeroSerie),
                          ),
                        seriesRealizadas: [...ejercicio.seriesRealizadas]
                          ..sort(
                            (a, b) => a.numeroSerie.compareTo(b.numeroSerie),
                          ),
                      ),
                  ],
                ),
            ],
          ),
      ],
    );
  }

  // --- Planning ---

  @override
  Future<Result<PlanningSemanal>> crearPlanning(DatosPlanning datos) =>
      _insertarUno(
        tabla: _plannings,
        cuerpo: datos.aJson(),
        desdeJson: PlanningSemanal.fromJson,
      );

  @override
  Future<Result<PlanningSemanal>> editarPlanning({
    required String id,
    required DatosPlanning datos,
  }) => _actualizarUno(
    tabla: _plannings,
    id: id,
    cuerpo: datos.aJson(),
    desdeJson: PlanningSemanal.fromJson,
  );

  @override
  Future<Result<PlanningSemanal>> archivarPlanning(String id) => _actualizarUno(
    tabla: _plannings,
    id: id,
    cuerpo: {'estado': EstadoPlanning.archivado.name},
    desdeJson: PlanningSemanal.fromJson,
  );

  @override
  Future<Result<PlanningSemanal>> reactivarPlanning(String id) =>
      _actualizarUno(
        tabla: _plannings,
        id: id,
        cuerpo: {'estado': EstadoPlanning.activo.name},
        desdeJson: PlanningSemanal.fromJson,
      );

  @override
  Future<Result<void>> eliminarPlanning(String id) => _eliminar(_plannings, id);

  // --- Sesion ---

  @override
  Future<Result<SesionEntrenamiento>> crearSesion(DatosSesion datos) =>
      _insertarUno(
        tabla: _sesiones,
        cuerpo: datos.aJson(),
        desdeJson: SesionEntrenamiento.fromJson,
      );

  @override
  Future<Result<SesionEntrenamiento>> editarSesion({
    required String id,
    required DatosSesion datos,
  }) => _actualizarUno(
    tabla: _sesiones,
    id: id,
    cuerpo: datos.aJson(),
    desdeJson: SesionEntrenamiento.fromJson,
  );

  @override
  Future<Result<void>> eliminarSesion(String id) => _eliminar(_sesiones, id);

  // --- Bloque ---

  @override
  Future<Result<BloqueEjercicio>> crearBloque(DatosBloque datos) =>
      _insertarUno(
        tabla: _bloques,
        cuerpo: datos.aJson(),
        desdeJson: BloqueEjercicio.fromJson,
      );

  @override
  Future<Result<BloqueEjercicio>> editarBloque({
    required String id,
    required DatosBloque datos,
  }) => _actualizarUno(
    tabla: _bloques,
    id: id,
    cuerpo: datos.aJson(),
    desdeJson: BloqueEjercicio.fromJson,
  );

  @override
  Future<Result<void>> eliminarBloque(String id) => _eliminar(_bloques, id);

  // --- Ejercicio planificado ---

  @override
  Future<Result<EjercicioPlanificado>> crearEjercicioPlanificado(
    DatosEjercicioPlanificado datos,
  ) => _guardarEjercicioPlanificado(datos: datos);

  @override
  Future<Result<EjercicioPlanificado>> editarEjercicioPlanificado({
    required String id,
    required DatosEjercicioPlanificado datos,
  }) => _guardarEjercicioPlanificado(id: id, datos: datos);

  /// Guarda el ejercicio y sus series en **una sola transaccion**, delegando en la
  /// funcion `guardar_ejercicio_planificado` de Postgres.
  ///
  /// Antes esto eran tres peticiones (upsert, borrar series, insertar series) y
  /// PostgREST abre una transaccion por peticion, asi que un fallo en la ultima
  /// dejaba el ejercicio sin series. La funcion lo hace todo dentro de la
  /// transaccion de la llamada: o se guarda entero, o no se guarda nada.
  ///
  /// La funcion es `security invoker`, asi que RLS y los triggers siguen actuando
  /// igual que al escribir en las tablas directamente.
  Future<Result<EjercicioPlanificado>> _guardarEjercicioPlanificado({
    required DatosEjercicioPlanificado datos,
    String? id,
  }) async {
    try {
      final idGuardado = await cliente.rpc<String>(
        _funcionGuardarEjercicio,
        params: {
          'p_id': id,
          'p_bloque_id': datos.bloqueId,
          'p_ejercicio_id': datos.ejercicioId,
          'p_orden': datos.orden,
          'p_descanso_seg': datos.esFuerza ? datos.descansoSeg : null,
          'p_minutos': datos.esCardio ? datos.minutos : null,
          'p_series': [
            for (final serie in datos.series)
              {
                'numero_serie': serie.numeroSerie,
                'repeticiones': serie.repeticiones,
                'peso': serie.peso,
                'rir': serie.rir,
              },
          ],
        },
      );
      return await obtenerEjercicioPlanificado(idGuardado);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<void>> eliminarEjercicioPlanificado(String id) =>
      _eliminar(_ejerciciosPlanificados, id);

  /// Relee un ejercicio planificado con su ejercicio de biblioteca y sus series.
  Future<Result<EjercicioPlanificado>> obtenerEjercicioPlanificado(
    String id,
  ) async {
    try {
      final fila = await cliente
          .from(_ejerciciosPlanificados)
          .select('*, ejercicios(*), series_planificadas(*)')
          .eq('id', id)
          .maybeSingle();
      if (fila == null) {
        return const Failure(ErrorNoEncontrado('Ese ejercicio ya no existe.'));
      }
      final ejercicio = EjercicioPlanificado.fromJson(fila);
      return Success(
        ejercicio.copyWith(
          series: [...ejercicio.series]
            ..sort((a, b) => a.numeroSerie.compareTo(b.numeroSerie)),
        ),
      );
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  // --- Operaciones genericas ---

  Future<Result<T>> _insertarUno<T>({
    required String tabla,
    required Map<String, dynamic> cuerpo,
    required T Function(Map<String, dynamic>) desdeJson,
  }) async {
    try {
      final fila = await cliente.from(tabla).insert(cuerpo).select().single();
      return Success(desdeJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  Future<Result<T>> _actualizarUno<T>({
    required String tabla,
    required String id,
    required Map<String, dynamic> cuerpo,
    required T Function(Map<String, dynamic>) desdeJson,
  }) async {
    try {
      final filas = await cliente
          .from(tabla)
          .update(cuerpo)
          .eq('id', id)
          .select();
      if (filas.isEmpty) {
        // Con RLS, cero filas no distingue "no existe" de "no puedes tocarla".
        return const Failure(
          ErrorNoEncontrado('No se ha podido guardar: ya no existe.'),
        );
      }
      return Success(desdeJson(filas.first));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  Future<Result<void>> _eliminar(String tabla, String id) async {
    try {
      await cliente.from(tabla).delete().eq('id', id);
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  ErrorApp _traducir(Object error, StackTrace traza) {
    if (error is ErrorApp) return error;
    if (error is PostgrestException) {
      final mensaje = error.message;
      return switch (error.code) {
        // Indices unicos: planning por semana, sesion por fecha, orden de bloque
        // o de ejercicio, numero de serie.
        '23505' => ErrorValidacion(_mensajeDeDuplicado(mensaje)),
        '42501' => const ErrorNoAutorizado(),
        'PGRST116' => const ErrorNoEncontrado('Ese elemento ya no existe.'),
        // Los triggers de validacion lanzan con errcode check_violation, y su
        // mensaje ya esta redactado para leerse.
        '23514' ||
        'P0001' => ErrorValidacion(_limpiarMensajeDeTrigger(mensaje)),
        '23502' => const ErrorValidacion('Faltan datos obligatorios.'),
        // Lo lanza `guardar_ejercicio_planificado` si el ejercicio ya no esta.
        'P0002' => const ErrorNoEncontrado('Ese ejercicio ya no existe.'),
        '23503' => const ErrorValidacion(
          'Falta algo de lo que esto depende, o ya se ha eliminado.',
        ),
        '22003' => const ErrorValidacion(
          'Algun numero esta fuera del rango admitido.',
        ),
        _ => Registro.inesperado(
          error,
          traza,
          contexto: 'el repositorio de planificacion',
        ),
      };
    }
    if (error is TimeoutException) return const ErrorConexion();
    final nombre = error.runtimeType.toString();
    if (nombre == 'ClientException' || nombre == 'SocketException') {
      return const ErrorConexion();
    }
    return Registro.inesperado(
      error,
      traza,
      contexto: 'el repositorio de planificacion',
    );
  }

  /// Traduce el nombre del indice violado a algo que el entrenador entienda.
  static String _mensajeDeDuplicado(String mensaje) {
    if (mensaje.contains('plannings_cliente_semana_unico')) {
      return 'Ese cliente ya tiene un planning activo para esa semana.';
    }
    if (mensaje.contains('sesiones_planning_fecha_unico')) {
      return 'Ya hay una sesion en esa fecha.';
    }
    if (mensaje.contains('bloques_sesion_orden_unico')) {
      return 'Ya hay un bloque en esa posicion.';
    }
    if (mensaje.contains('ejer_planif_bloque_orden_unico')) {
      return 'Ya hay un ejercicio en esa posicion del bloque.';
    }
    if (mensaje.contains('series_planif_numero_unico')) {
      return 'Hay dos series con el mismo numero.';
    }
    return 'Ese elemento ya existe.';
  }

  /// Los `raise exception` de los triggers llegan con prefijos del motor.
  static String _limpiarMensajeDeTrigger(String mensaje) {
    final limpio = mensaje
        .replaceFirst(RegExp(r'^.*?:\s*'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return limpio.isEmpty ? 'Los datos no son validos.' : limpio;
  }
}
