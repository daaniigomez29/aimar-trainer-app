import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'url_de_arranque.g.dart';

/// URL con la que se ha abierto la aplicacion.
///
/// Vive en un provider, y no leyendo `Uri.base` donde haga falta, para poder
/// sustituirla en los tests: el caso que importa —llegar con el error de un
/// enlace de correo ya gastado— no se puede montar de ninguna otra forma.
///
/// `keepAlive` porque es un dato del arranque: no cambia mientras la app vive.
/// Una navegacion dentro de la PWA no la toca.
@Riverpod(keepAlive: true)
Uri urlDeArranque(Ref ref) => Uri.base;
