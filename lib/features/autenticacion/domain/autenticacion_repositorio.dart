import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/perfil.dart';

/// Eventos de sesion que la capa de aplicacion necesita observar.
///
/// Traduccion de los eventos de Supabase Auth a vocabulario de dominio, para
/// que `application/` no dependa de `supabase_flutter`.
enum EventoAutenticacion {
  sesionIniciada,
  sesionCerrada,
  tokenRenovado,
  usuarioActualizado,

  /// El usuario ha abierto el enlace de restablecimiento de contrasena (CU-24).
  /// Hay sesion, pero solo para fijar la contrasena nueva.
  recuperacionContrasena,
}

/// Puerto de dominio para autenticacion (CU-01 y CU-24).
///
/// La implementacion Supabase vive en `data/`; ningun otro sitio habla con Auth.
abstract interface class AutenticacionRepositorio {
  /// Id de Auth del usuario con sesion abierta, o `null` si no hay sesion.
  String? get idUsuarioActual;

  /// `true` si el usuario entro por una invitacion y aun no ha fijado contrasena.
  ///
  /// Lo marca `crear-cliente` en los metadatos del usuario al invitar, porque
  /// GoTrue no distingue un enlace de invitacion de un login normal.
  bool get debeFijarContrasena;

  /// Flujo de cambios de sesion. Emite el estado actual al suscribirse.
  Stream<EventoAutenticacion> get cambiosDeAutenticacion;

  /// CU-01: valida credenciales y devuelve el perfil con su rol.
  Future<Result<Perfil>> iniciarSesion({
    required String correo,
    required String contrasena,
  });

  Future<Result<void>> cerrarSesion();

  /// Perfil del usuario con sesion abierta. Falla si no hay sesion o si la
  /// cuenta no tiene fila en `perfiles`.
  Future<Result<Perfil>> perfilDeLaSesion();

  /// CU-24: envia el enlace de restablecimiento. Devuelve exito tambien cuando
  /// el correo no existe, para no revelar que cuentas estan registradas.
  Future<Result<void>> enviarCorreoRecuperacion(String correo);

  /// CU-24: fija la contrasena nueva sobre la sesion de recuperacion abierta.
  Future<Result<void>> establecerNuevaContrasena(String contrasenaNueva);
}
