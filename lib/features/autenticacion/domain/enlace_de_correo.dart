import 'package:aimar_trainer_app/core/errores/error_app.dart';

/// Motivo que trae la URL de arranque cuando se ha llegado por un enlace de
/// correo de Auth que **no** ha servido, o `null` si la URL no dice nada.
///
/// POR QUE HACE FALTA: los enlaces de invitacion (CU-17) y de recuperacion
/// (CU-24) son de **un solo uso** y caducan; GoTrue borra el token al canjearlo.
/// Al pinchar uno gastado no se abre sesion: redirige a la app con el motivo en
/// la URL (`#error=access_denied&error_code=otp_expired`). Y eso **no llega
/// como evento** de Auth, asi que sin leerlo aqui la app se queda esperando un
/// evento que no va a venir: el cliente se queda mirando la pantalla de carga
/// sin forma de fijar su contrasena, que es el fallo del 2026-10-12.
///
/// Se mira el fragmento **y** la query: el flujo implicito deja los parametros
/// en el fragmento y el de PKCE en la query, y un enlace gastado puede llegar
/// por cualquiera de los dos.
ErrorApp? errorDeEnlaceDeCorreo(Uri url) {
  // Un fragmento que no es una lista de parametros (con enrutado por hash es
  // la propia ruta, `#/restablecer-contrasena`) sale de aqui sin claves utiles.
  final enElFragmento = Uri.splitQueryString(url.fragment);
  String? parametro(String clave) =>
      url.queryParameters[clave] ?? enElFragmento[clave];

  final error = parametro('error');
  final codigo = parametro('error_code');
  if (error == null && codigo == null) return null;

  // `otp_expired` es el mismo codigo para "ya se ha usado" y "ha caducado":
  // GoTrue no los distingue, y para quien lo recibe la salida es la misma.
  // `access_denied` es como llega cuando el token ya no existe.
  return codigo == 'otp_expired' || error == 'access_denied'
      ? const ErrorEnlaceCaducado()
      // Cualquier otro fallo del enlace (`server_error`, `invalid_request`):
      // mensaje genérico, pero la salida que se ofrece es la misma.
      : const ErrorInesperado();
}
