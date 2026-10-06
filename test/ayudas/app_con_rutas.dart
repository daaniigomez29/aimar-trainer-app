import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Una `MaterialApp` con rutas de verdad, para los tests de pantallas que
/// navegan con `context.go`.
///
/// POR QUE HACE FALTA: desde que las pantallas de detalle y los formularios son
/// rutas, navegar necesita un `GoRouter` en el árbol; con `MaterialApp(home:)`
/// el test revienta en cuanto se pulsa algo que navega.
///
/// Recibe las rutas tal cual, **anidadas igual que en la aplicación**. Eso
/// importa: con rutas hermanas en vez de hijas, cerrar un formulario vaciaría la
/// pila y el test fallaría por un motivo que no existe en la app.
MaterialApp appConRutas({
  required String rutaInicial,
  required List<RouteBase> rutas,
}) {
  return MaterialApp.router(
    routerConfig: GoRouter(initialLocation: rutaInicial, routes: rutas),
  );
}
