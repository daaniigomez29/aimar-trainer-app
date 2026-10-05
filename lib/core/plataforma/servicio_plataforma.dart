/// Interfaz para lo que depende de la plataforma (web hoy, Android/iOS en una
/// fase futura). RNF-03: el dominio no debe conocer la plataforma.
///
/// De momento solo cubre lo que la fase 1 necesita. Las implementaciones
/// concretas (`data/` o `plataforma/web/`) llegaran con las features que las usen.
abstract interface class ServicioPlataforma {
  /// URL base publica de la aplicacion, para construir enlaces de retorno.
  Uri get urlBase;

  /// `true` si la plataforma soporta notificaciones push web.
  bool get soportaPushWeb;
}
