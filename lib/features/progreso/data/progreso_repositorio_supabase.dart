import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_imagenes.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart'
    show soloFecha;
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';
import 'package:aimar_trainer_app/features/progreso/domain/metricas_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/progreso_repositorio.dart';

part 'progreso_repositorio_supabase.g.dart';

@Riverpod(keepAlive: true)
ProgresoRepositorio progresoRepositorio(Ref ref) =>
    ProgresoRepositorioSupabase(cliente: ref.watch(clienteSupabaseProvider));

/// Implementacion de [ProgresoRepositorio].
///
/// Todo pasa por RLS: ninguna operacion necesita `service_role`. Las politicas de
/// `registros_medidas`, `checkins_recuperacion`, `fotos_progreso` y del bucket son
/// las que impiden que un cliente toque lo de otro, y la **ausencia** de politica
/// para el administrador es la que lo deja fuera.
class ProgresoRepositorioSupabase implements ProgresoRepositorio {
  ProgresoRepositorioSupabase({required this.cliente});

  static const String _medidas = 'registros_medidas';
  static const String _checkins = 'checkins_recuperacion';
  static const String _fotos = 'fotos_progreso';
  static const String _vistaProgreso = 'vista_progreso_ejercicios';
  static const String _vistaEjercicios = 'vista_ejercicios_con_registro';

  /// Tope de filas del historico que mira la planificacion. Son series sueltas:
  /// 400 dan de sobra para las ultimas semanas de un planning normal.
  static const int _topeDeHistorico = 400;

  /// Bucket privado de las fotos. Mismo nombre en local (`config.toml`) y en la
  /// nube.
  static const String bucketFotos = 'fotos-progreso';

  /// Lo que dura la URL firmada de una foto: diez minutos, suficiente para verla
  /// y poco para que sirva de nada si se filtra.
  static const int segundosUrlFirmada = 600;

  static const String _funcionRegistrarResultado =
      'registrar_resultado_ejercicio';

  final SupabaseClient cliente;

  // --- CU-20 -------------------------------------------------------------

  @override
  Future<Result<void>> registrarResultado(DatosResultadoEjercicio datos) async {
    try {
      await cliente.rpc<void>(
        _funcionRegistrarResultado,
        params: {
          'p_ejercicio_planificado_id': datos.ejercicioPlanificadoId,
          'p_minutos': datos.minutos,
          'p_series': [for (final serie in datos.series) serie.aJson()],
        },
      );
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  // --- Medidas -----------------------------------------------------------

  /// Las fotos vienen incrustadas: una medida sin sus fotos esta incompleta para
  /// la pantalla, y son pocas.
  static const String _seleccionMedidas = '*, fotos_progreso(*)';

  @override
  Future<Result<List<RegistroMedidas>>> listarMedidas({
    required String clienteId,
    RangoFechas? rango,
  }) async {
    try {
      var consulta = cliente
          .from(_medidas)
          .select(_seleccionMedidas)
          .eq('cliente_id', clienteId);
      if (rango != null) {
        consulta = consulta
            .gte('fecha', soloFecha(rango.desde))
            .lte('fecha', soloFecha(rango.hasta));
      }
      final filas = await consulta.order('fecha', ascending: false);
      return Success(filas.map(RegistroMedidas.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<RegistroMedidas?>> medidasDelDia({
    required String clienteId,
    required DateTime fecha,
  }) async {
    try {
      final fila = await cliente
          .from(_medidas)
          .select(_seleccionMedidas)
          .eq('cliente_id', clienteId)
          .eq('fecha', soloFecha(fecha))
          .maybeSingle();
      return Success(fila == null ? null : RegistroMedidas.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<RegistroMedidas>> guardarMedidas(
    DatosRegistroMedidas datos,
  ) async {
    try {
      // `onConflict` sobre el indice unico (cliente_id, fecha): guardar dos veces
      // el mismo dia corrige el registro, no crea otro.
      final fila = await cliente
          .from(_medidas)
          .upsert(datos.aJson(), onConflict: 'cliente_id,fecha')
          .select(_seleccionMedidas)
          .single();
      return Success(RegistroMedidas.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  // --- Check-in ----------------------------------------------------------

  @override
  Future<Result<List<CheckinRecuperacion>>> listarCheckins({
    required String clienteId,
    RangoFechas? rango,
  }) async {
    try {
      var consulta = cliente
          .from(_checkins)
          .select()
          .eq('cliente_id', clienteId);
      if (rango != null) {
        consulta = consulta
            .gte('fecha', soloFecha(rango.desde))
            .lte('fecha', soloFecha(rango.hasta));
      }
      final filas = await consulta.order('fecha', ascending: false);
      return Success(filas.map(CheckinRecuperacion.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<CheckinRecuperacion?>> checkinDelDia({
    required String clienteId,
    required DateTime fecha,
  }) async {
    try {
      final fila = await cliente
          .from(_checkins)
          .select()
          .eq('cliente_id', clienteId)
          .eq('fecha', soloFecha(fecha))
          .maybeSingle();
      return Success(fila == null ? null : CheckinRecuperacion.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<CheckinRecuperacion>> guardarCheckin(DatosCheckin datos) async {
    try {
      final fila = await cliente
          .from(_checkins)
          .upsert(datos.aJson(), onConflict: 'cliente_id,fecha')
          .select()
          .single();
      return Success(CheckinRecuperacion.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  // --- Fotos -------------------------------------------------------------

  @override
  Future<Result<FotoProgreso>> subirFoto({
    required String clienteId,
    required String registroMedidasId,
    required ImagenParaSubir imagen,
  }) async {
    // La ruta empieza por el id del cliente porque es lo que miran las politicas
    // del bucket: `(storage.foldername(name))[1] = auth.uid()`.
    final ruta =
        '$clienteId/$registroMedidasId/'
        '${DateTime.now().microsecondsSinceEpoch}.${imagen.extension}';

    try {
      await cliente.storage
          .from(bucketFotos)
          .uploadBinary(
            ruta,
            imagen.bytes,
            fileOptions: FileOptions(contentType: imagen.tipoMime),
          );
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }

    try {
      final fila = await cliente
          .from(_fotos)
          .insert({
            'registro_medidas_id': registroMedidasId,
            'ruta_storage': ruta,
          })
          .select()
          .single();
      return Success(FotoProgreso.fromJson(fila));
    } on Object catch (error, traza) {
      // El fichero ya esta subido pero la fila no se ha podido crear: sin fila
      // nadie sabria que existe, asi que se deshace la subida.
      await _borrarDelBucket(ruta);
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<void>> eliminarFoto(FotoProgreso foto) async {
    try {
      await cliente.from(_fotos).delete().eq('id', foto.id);
      // Primero la fila y luego el fichero: al reves, un fallo al borrar la fila
      // dejaria una foto que la interfaz muestra y que ya no se puede descargar.
      await _borrarDelBucket(foto.rutaStorage);
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Uri>> urlFirmadaDe(FotoProgreso foto) async {
    try {
      final url = await cliente.storage
          .from(bucketFotos)
          .createSignedUrl(foto.rutaStorage, segundosUrlFirmada);
      return Success(Uri.parse(url));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  Future<void> _borrarDelBucket(String ruta) async {
    try {
      await cliente.storage.from(bucketFotos).remove([ruta]);
    } on Object catch (error, traza) {
      // Que falle la limpieza no debe tapar el error original.
      Registro.fallo(
        error,
        traza,
        contexto: 'el borrado de una foto del bucket',
      );
    }
  }

  // --- CU-21 -------------------------------------------------------------

  @override
  Future<Result<List<EjercicioConRegistro>>> ejerciciosConRegistro(
    String clienteId,
  ) async {
    try {
      final filas = await cliente
          .from(_vistaEjercicios)
          .select()
          .eq('cliente_id', clienteId)
          .order('ejercicio_nombre');
      return Success(filas.map(EjercicioConRegistro.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<List<RegistroProgreso>>> progresoDeEjercicio({
    required String clienteId,
    required String ejercicioId,
    required RangoFechas rango,
  }) async {
    try {
      final filas = await cliente
          .from(_vistaProgreso)
          .select()
          .eq('cliente_id', clienteId)
          .eq('ejercicio_id', ejercicioId)
          .gte('fecha', soloFecha(rango.desde))
          .lte('fecha', soloFecha(rango.hasta))
          .order('fecha');
      return Success(filas.map(RegistroProgreso.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<List<RegistroProgreso>>> ultimoDeCadaEjercicio({
    required String clienteId,
    required List<String> ejercicioIds,
    required DateTime antesDe,
  }) async {
    if (ejercicioIds.isEmpty) return const Success([]);
    try {
      final filas = await cliente
          .from(_vistaProgreso)
          .select()
          .eq('cliente_id', clienteId)
          .inFilter('ejercicio_id', ejercicioIds)
          .lt('fecha', soloFecha(antesDe))
          .order('fecha', ascending: false)
          // De lo mas reciente hacia atras: el tope solo recorta lo viejo, que es
          // lo que no se va a ensenar. Esta para que un cliente con un ano de
          // historico no se traiga la vida entera en cada planning.
          .limit(_topeDeHistorico);
      return Success(filas.map(RegistroProgreso.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  // --- Traduccion de errores ---------------------------------------------

  ErrorApp _traducir(Object error, StackTrace traza) {
    if (error is ErrorApp) return error;

    if (error is StorageException) {
      return switch (error.statusCode) {
        // El bucket rechaza el tipo o el tamano del fichero.
        '400' || '413' => ErrorValidacion(
          'Esa imagen no se ha podido subir: ${error.message}',
          campo: 'foto',
        ),
        '403' => const ErrorNoAutorizado(),
        '404' => const ErrorServicioNoDisponible('almacenamiento de fotos'),
        _ => Registro.inesperado(
          error,
          traza,
          contexto: 'el almacenamiento de fotos',
        ),
      };
    }

    if (error is PostgrestException) {
      return switch (error.code) {
        // Indices unicos: un registro de medidas o un check-in por dia, una serie
        // por numero, una ruta por foto.
        '23505' => const ErrorValidacion(
          'Ya hay un registro de ese dia. Recarga la pantalla antes de guardar.',
        ),
        '42501' => const ErrorNoAutorizado(),
        'PGRST116' => const ErrorNoEncontrado('Ese registro ya no existe.'),
        // Constraints y `raise` de `registrar_resultado_ejercicio`: sus mensajes
        // ya estan redactados para leerse.
        '23514' || 'P0001' => ErrorValidacion(_limpiar(error.message)),
        'P0002' => const ErrorNoEncontrado('Ese ejercicio ya no existe.'),
        '23502' => const ErrorValidacion('Faltan datos obligatorios.'),
        '23503' => const ErrorValidacion(
          'Falta algo de lo que esto depende, o ya se ha eliminado.',
        ),
        '22003' => const ErrorValidacion(
          'Algun numero esta fuera del rango admitido.',
        ),
        _ => Registro.inesperado(
          error,
          traza,
          contexto: 'el repositorio de progreso',
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
      contexto: 'el repositorio de progreso',
    );
  }

  /// Postgres antepone el nombre de la constraint o el contexto al mensaje; para
  /// el usuario solo sirve la frase.
  static String _limpiar(String mensaje) {
    final sinPrefijo = mensaje.split('\n').first.trim();
    return sinPrefijo.isEmpty
        ? 'No se ha podido guardar: revisa los datos.'
        : sinPrefijo;
  }
}
