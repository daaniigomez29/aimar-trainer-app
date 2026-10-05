import 'dart:async';

import 'package:flutter/foundation.dart';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/diagnostico/registro.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente_repositorio.dart';

part 'cliente_repositorio_supabase.g.dart';

@Riverpod(keepAlive: true)
ClienteRepositorio clienteRepositorio(Ref ref) =>
    ClienteRepositorioSupabase(cliente: ref.watch(clienteSupabaseProvider));

/// Implementacion de [ClienteRepositorio].
///
/// El alta y la baja se delegan en Edge Functions (`crear-cliente`,
/// `dar-de-baja-cliente`), que son las unicas que pueden usar `service_role`. La
/// lectura y la edicion van directas a la tabla, sujetas a RLS.
class ClienteRepositorioSupabase implements ClienteRepositorio {
  ClienteRepositorioSupabase({required this.cliente});

  static const String _tabla = 'clientes';
  static const String _funcionAlta = 'crear-cliente';
  static const String _funcionBaja = 'dar-de-baja-cliente';

  final SupabaseClient cliente;

  @override
  Future<Result<List<Cliente>>> listar() async {
    try {
      final filas = await cliente.from(_tabla).select().order('nombre');
      return Success(filas.map(Cliente.fromJson).toList());
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Cliente>> obtenerPorId(String id) async {
    try {
      final fila = await cliente
          .from(_tabla)
          .select()
          .eq('id', id)
          .maybeSingle();
      if (fila == null) {
        return const Failure(ErrorNoEncontrado('Esa ficha no existe.'));
      }
      return Success(Cliente.fromJson(fila));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<ResultadoAlta>> darDeAlta(DatosCliente datos) async {
    const servicio = 'alta de clientes';
    try {
      final respuesta = await cliente.functions.invoke(
        _funcionAlta,
        body: datos.aJsonDeAlta(),
      );
      final cuerpo = respuesta.data as Map<String, dynamic>?;

      if (respuesta.status != 201) {
        return Failure(
          _traducirRespuestaFuncion(
            respuesta.status,
            cuerpo,
            servicio: servicio,
          ),
        );
      }
      final clienteId = cuerpo?['clienteId'] as String?;
      if (clienteId == null) {
        return const Failure(ErrorInesperado());
      }
      return Success(
        ResultadoAlta(
          clienteId: clienteId,
          invitacionEnviada: cuerpo?['invitacionEnviada'] as bool? ?? false,
          avisoInvitacion: cuerpo?['avisoInvitacion'] as String?,
        ),
      );
    } on FunctionException catch (excepcion) {
      return Failure(
        _traducirRespuestaFuncion(
          excepcion.status,
          excepcion.details is Map<String, dynamic>
              ? excepcion.details as Map<String, dynamic>
              : null,
          servicio: servicio,
        ),
      );
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Cliente>> editar({
    required String id,
    required DatosCliente datos,
  }) async {
    try {
      final filas = await cliente
          .from(_tabla)
          .update(datos.aJsonDeEdicion())
          .eq('id', id)
          .select();
      if (filas.isEmpty) {
        return const Failure(
          ErrorNoEncontrado('No se ha podido actualizar esa ficha.'),
        );
      }
      return Success(Cliente.fromJson(filas.first));
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<Cliente>> darDeBaja(String id) async {
    const servicio = 'baja de clientes';
    try {
      final respuesta = await cliente.functions.invoke(
        _funcionBaja,
        body: {'clienteId': id},
      );
      final cuerpo = respuesta.data as Map<String, dynamic>?;

      if (respuesta.status != 200) {
        return Failure(
          _traducirRespuestaFuncion(
            respuesta.status,
            cuerpo,
            servicio: servicio,
          ),
        );
      }
      // La funcion devuelve solo el id y el estado: se relee la ficha para
      // devolver el cliente completo con su `fecha_baja`. Con `await` dentro del
      // try para que un fallo de la relectura tambien se traduzca aqui.
      return await obtenerPorId(id);
    } on FunctionException catch (excepcion) {
      return Failure(
        _traducirRespuestaFuncion(
          excepcion.status,
          excepcion.details is Map<String, dynamic>
              ? excepcion.details as Map<String, dynamic>
              : null,
          servicio: servicio,
        ),
      );
    } on Object catch (error, traza) {
      return Failure(_traducir(error, traza));
    }
  }

  @override
  Future<Result<int>> contarPlanningsActivos(String id) async {
    // TODO(fase 4): contar sobre `plannings_semanales` con estado = 'activo'.
    // Esa tabla todavia no existe, asi que no hay ningun planning posible y la
    // respuesta correcta es 0.
    return const Success(0);
  }

  /// Expuesto para test: cubre el caso de la funcion caida, que es el que daba un
  /// mensaje inutil.
  @visibleForTesting
  static ErrorApp traducirRespuestaFuncionParaTest(
    int estado,
    Map<String, dynamic>? cuerpo, {
    required String servicio,
  }) => _traducirRespuestaFuncion(estado, cuerpo, servicio: servicio);

  /// Traduce los codigos del contrato de las Edge Functions
  /// (`docs/architecture.md`) a errores de dominio.
  static ErrorApp _traducirRespuestaFuncion(
    int estado,
    Map<String, dynamic>? cuerpo, {
    required String servicio,
  }) {
    final codigo = cuerpo?['error'] as String?;
    // `mensaje` es el del contrato de nuestras funciones. `message` lo usan los
    // errores de la infraestructura (Kong, el runtime de Deno), que vienen en
    // ingles: sin leerlo, un 503 se quedaba sin ninguna explicacion.
    final mensaje =
        cuerpo?['mensaje'] as String? ?? cuerpo?['message'] as String?;

    // Siempre al registro: la interfaz solo puede mostrar un mensaje corto, y el
    // estado y el cuerpo completos son lo que permite entender el fallo.
    final pista = estado >= 500
        ? ' Pista: en local, las Edge Functions necesitan '
              '`supabase functions serve` en otra terminal.'
        : '';
    Registro.fallo(
      'Respondio $estado. Cuerpo: ${cuerpo ?? "(vacio)"}.$pista',
      null,
      contexto: 'la funcion de $servicio',
    );

    return switch (estado) {
      400 => ErrorValidacion(mensaje ?? 'Los datos enviados no son validos.'),
      401 || 403 => const ErrorNoAutorizado(),
      404 => ErrorNoEncontrado(mensaje ?? 'Ese cliente no existe.'),
      409 =>
        codigo == 'ya_de_baja'
            ? ErrorValidacion(mensaje ?? 'Ese cliente ya estaba de baja.')
            : ErrorNombreDuplicado(
                mensaje ?? 'Ya hay un cliente activo con ese correo.',
              ),
      // La funcion no esta desplegada, o en local falta `functions serve`: Kong
      // responde 503 "name resolution failed". No es un fallo de red ni de datos,
      // asi que necesita su propio mensaje.
      502 || 503 || 504 => ErrorServicioNoDisponible(servicio),
      501 => ErrorValidacion(
        mensaje ?? 'Esa operacion todavia no esta implementada.',
      ),
      _ => ErrorInesperado(
        causa:
            'La funcion de $servicio respondio $estado: '
            '${mensaje ?? cuerpo ?? "sin cuerpo"}',
      ),
    };
  }

  ErrorApp _traducir(Object error, StackTrace traza) {
    if (error is ErrorApp) return error;
    if (error is PostgrestException) {
      return switch (error.code) {
        '23505' => const ErrorNombreDuplicado(
          'Ya hay un cliente activo con ese correo.',
        ),
        '42501' => const ErrorNoAutorizado(),
        'PGRST116' => const ErrorNoEncontrado('Esa ficha no existe.'),
        '23502' || '23514' => const ErrorValidacion(
          'Faltan datos obligatorios o alguno no es valido.',
        ),
        // Desbordamiento de numeric(5,2): altura o peso fuera de rango.
        '22003' => const ErrorValidacion(
          'La altura o el peso estan fuera del rango admitido.',
        ),
        _ => Registro.inesperado(
          error,
          traza,
          contexto: 'el repositorio de clientes',
        ),
      };
    }
    if (error is TimeoutException) return const ErrorConexion();
    final nombre = error.runtimeType.toString();
    if (nombre == 'ClientException' || nombre == 'SocketException') {
      return const ErrorConexion();
    }
    Registro.fallo(error, traza, contexto: 'el repositorio de clientes');
    return ErrorInesperado(causa: error, traza: traza);
  }
}
