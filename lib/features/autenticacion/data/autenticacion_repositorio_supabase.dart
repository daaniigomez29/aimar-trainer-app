import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:aimar_trainer_app/core/configuracion/configuracion_app.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';

part 'autenticacion_repositorio_supabase.g.dart';

@Riverpod(keepAlive: true)
AutenticacionRepositorio autenticacionRepositorio(Ref ref) =>
    AutenticacionRepositorioSupabase(
      cliente: ref.watch(clienteSupabaseProvider),
      configuracion: ref.watch(configuracionAppProvider),
    );

/// Implementacion de [AutenticacionRepositorio] sobre Supabase Auth y `perfiles`.
///
/// Todas las excepciones de Supabase se capturan aqui y se traducen a [ErrorApp]:
/// ni `AuthException` ni `PostgrestException` salen de esta clase.
class AutenticacionRepositorioSupabase implements AutenticacionRepositorio {
  AutenticacionRepositorioSupabase({
    required this.cliente,
    required this.configuracion,
  });

  static const String _tablaPerfiles = 'perfiles';

  final SupabaseClient cliente;
  final ConfiguracionApp configuracion;

  GoTrueClient get _auth => cliente.auth;

  @override
  String? get idUsuarioActual => _auth.currentUser?.id;

  @override
  Stream<EventoAutenticacion> get cambiosDeAutenticacion => _auth
      .onAuthStateChange
      .map((estado) => _traducirEvento(estado.event))
      .where((evento) => evento != null)
      .cast<EventoAutenticacion>();

  @override
  Future<Result<Perfil>> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async {
    try {
      final respuesta = await _auth.signInWithPassword(
        email: correo.trim(),
        password: contrasena,
      );
      if (respuesta.user == null) {
        return const Failure(ErrorCredencialesInvalidas());
      }
      final perfil = await perfilDeLaSesion();
      // Una cuenta sin perfil no puede enrutarse a ninguna pantalla: se cierra
      // la sesion para no dejar al usuario en un estado a medias.
      if (perfil.esFallo) {
        await _auth.signOut();
      }
      return perfil;
    } on AuthException catch (excepcion) {
      return Failure(_traducirErrorAuth(excepcion));
    } on Object catch (error, traza) {
      return Failure(_traducirErrorGenerico(error, traza));
    }
  }

  @override
  Future<Result<void>> cerrarSesion() async {
    try {
      await _auth.signOut();
      return const Success(null);
    } on AuthException catch (excepcion) {
      return Failure(_traducirErrorAuth(excepcion));
    } on Object catch (error, traza) {
      return Failure(_traducirErrorGenerico(error, traza));
    }
  }

  @override
  Future<Result<Perfil>> perfilDeLaSesion() async {
    final idUsuario = idUsuarioActual;
    if (idUsuario == null) {
      return const Failure(ErrorNoAutorizado());
    }
    try {
      final fila = await cliente
          .from(_tablaPerfiles)
          .select()
          .eq('id', idUsuario)
          .maybeSingle();
      if (fila == null) {
        return const Failure(ErrorPerfilSinRol());
      }
      return Success(Perfil.fromJson(fila));
    } on PostgrestException catch (excepcion) {
      return Failure(_traducirErrorPostgrest(excepcion));
    } on Object catch (error, traza) {
      return Failure(_traducirErrorGenerico(error, traza));
    }
  }

  @override
  Future<Result<void>> enviarCorreoRecuperacion(String correo) async {
    try {
      await _auth.resetPasswordForEmail(
        correo.trim(),
        redirectTo: configuracion.urlRedireccionRestablecerContrasena
            .toString(),
      );
      return const Success(null);
    } on AuthException catch (excepcion) {
      final traducido = _traducirErrorAuth(excepcion);
      // CU-24: no se distingue "correo no registrado" de exito, para no revelar
      // que cuentas existen. Solo se informa del limite de envios, que si es
      // accionable para quien lo ve.
      if (traducido is ErrorDemasiadasPeticiones) {
        return Failure(traducido);
      }
      return const Success(null);
    } on Object catch (error, traza) {
      return Failure(_traducirErrorGenerico(error, traza));
    }
  }

  @override
  Future<Result<void>> establecerNuevaContrasena(String contrasenaNueva) async {
    if (idUsuarioActual == null) {
      return const Failure(ErrorEnlaceCaducado());
    }
    try {
      await _auth.updateUser(UserAttributes(password: contrasenaNueva));
      return const Success(null);
    } on AuthException catch (excepcion) {
      return Failure(_traducirErrorAuth(excepcion));
    } on Object catch (error, traza) {
      return Failure(_traducirErrorGenerico(error, traza));
    }
  }

  static EventoAutenticacion? _traducirEvento(AuthChangeEvent evento) =>
      switch (evento) {
        AuthChangeEvent.initialSession ||
        AuthChangeEvent.signedIn => EventoAutenticacion.sesionIniciada,
        AuthChangeEvent.signedOut => EventoAutenticacion.sesionCerrada,
        AuthChangeEvent.tokenRefreshed => EventoAutenticacion.tokenRenovado,
        AuthChangeEvent.userUpdated => EventoAutenticacion.usuarioActualizado,
        AuthChangeEvent.passwordRecovery =>
          EventoAutenticacion.recuperacionContrasena,
        _ => null,
      };

  static ErrorApp _traducirErrorAuth(AuthException excepcion) {
    final codigo = excepcion.code;
    if (codigo != null) {
      final traducido = switch (codigo) {
        'invalid_credentials' ||
        'invalid_grant' => const ErrorCredencialesInvalidas(),
        'user_banned' => const ErrorCuentaNoDisponible(),
        'email_not_confirmed' => const ErrorCuentaSinActivar(),
        'otp_expired' ||
        'reauthentication_needed' => const ErrorEnlaceCaducado(),
        'weak_password' => const ErrorValidacion(
          'La contrasena es demasiado debil. Combina letras y numeros.',
          campo: 'contrasena',
        ),
        'same_password' => const ErrorValidacion(
          'La contrasena nueva debe ser distinta de la anterior.',
          campo: 'contrasena',
        ),
        'over_request_rate_limit' ||
        'over_email_send_rate_limit' => const ErrorDemasiadasPeticiones(),
        _ => null,
      };
      if (traducido != null) return traducido;
    }
    return switch (excepcion.statusCode) {
      '400' || '401' => const ErrorCredencialesInvalidas(),
      '403' => const ErrorCuentaNoDisponible(),
      '422' => const ErrorValidacion('Los datos enviados no son validos.'),
      '429' => const ErrorDemasiadasPeticiones(),
      _ => ErrorInesperado(causa: excepcion),
    };
  }

  static ErrorApp _traducirErrorPostgrest(PostgrestException excepcion) =>
      switch (excepcion.code) {
        // `.single()` sin filas devueltas.
        'PGRST116' => const ErrorNoEncontrado(),
        // Violacion de una politica RLS.
        '42501' => const ErrorNoAutorizado(),
        _ => ErrorInesperado(causa: excepcion),
      };

  static ErrorApp _traducirErrorGenerico(Object error, StackTrace traza) {
    if (error is ErrorApp) return error;
    if (error is TimeoutException) return const ErrorConexion();
    // `ClientException` (package:http) y `SocketException` (dart:io) se
    // comprueban por nombre para no acoplar esta capa a ambos paquetes.
    final nombre = error.runtimeType.toString();
    if (nombre == 'ClientException' || nombre == 'SocketException') {
      return const ErrorConexion();
    }
    return ErrorInesperado(causa: error, traza: traza);
  }
}
