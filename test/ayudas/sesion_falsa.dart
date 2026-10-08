import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/autenticacion_repositorio.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';

/// Una sesión abierta de mentira, para los tests que montan una pantalla.
///
/// POR QUE HACE FALTA: desde que toda pantalla lleva su barra de navegación, el
/// andamio pregunta el rol para saber qué barra poner. Sin sesión, ese provider
/// acaba pidiendo el cliente de Supabase, que en un test no está inicializado y
/// revienta. Dárselo aquí es además más fiel: la pantalla se prueba con la
/// navegación que el usuario ve de verdad.
class AutenticacionDeMentira implements AutenticacionRepositorio {
  AutenticacionDeMentira({this.rol = RolUsuario.entrenador, this.id = 'u-1'});

  final RolUsuario rol;
  final String id;

  @override
  String? get idUsuarioActual => id;

  @override
  bool get debeFijarContrasena => false;

  @override
  Stream<EventoAutenticacion> get cambiosDeAutenticacion =>
      const Stream.empty();

  @override
  Future<Result<Perfil>> perfilDeLaSesion() async =>
      Success(Perfil(id: id, rol: rol, creadoEn: DateTime.utc(2026)));

  @override
  Future<Result<Perfil>> iniciarSesion({
    required String correo,
    required String contrasena,
  }) async => perfilDeLaSesion();

  @override
  Future<Result<void>> cerrarSesion() async => const Success(null);

  @override
  Future<Result<void>> enviarCorreoRecuperacion(String correo) async =>
      const Success(null);

  @override
  Future<Result<void>> establecerNuevaContrasena(
    String contrasenaNueva,
  ) async => const Success(null);
}

/// Deja el contenedor con la sesión ya resuelta y lo devuelve, para encadenarlo
/// con `UncontrolledProviderScope`.
///
/// El `refrescarPerfil` no es opcional: sin él el estado se queda en
/// `SesionDesconocida` y el andamio no sabría qué barra pintar.
///
/// Recibe el contenedor ya hecho en lugar de construirlo porque el tipo
/// `Override` de Riverpod no es público y no se puede nombrar en una firma.
Future<ProviderContainer> conSesionAbierta(ProviderContainer contenedor) async {
  await contenedor.read(controladorSesionProvider.notifier).refrescarPerfil();
  return contenedor;
}
