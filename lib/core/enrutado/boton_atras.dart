import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';

/// Vuelve **de donde se vino**, no al padre de la ruta.
///
/// El orden importa: primero el origen que dejó dicho quien navegó
/// ([Rutas.conVuelta]); si no lo hay, la pila, que es el comportamiento de
/// siempre; y en último lugar [alternativa], para no dejar una pantalla sin
/// salida cuando se ha llegado a ella escribiendo la URL.
void volverAtras(BuildContext context, {String? alternativa}) {
  final origen = GoRouterState.of(context)
      .uri
      .queryParameters[Rutas.paramVolver];
  if (origen != null && origen.isNotEmpty) {
    context.go(origen);
  } else if (context.canPop()) {
    context.pop();
  } else if (alternativa != null) {
    context.go(alternativa);
  }
}

/// La flecha de atrás de la cabecera, con el comportamiento de [volverAtras].
///
/// POR QUE NO VALE LA AUTOMÁTICA: con rutas anidadas, `context.go` a una ruta
/// profunda monta la pila entera, así que la flecha de `AppBar` lleva al padre.
/// El cliente que abre un ejercicio desde su inicio acababa en la pantalla de
/// registrar sesión, por la que no había pasado.
class BotonAtras extends StatelessWidget {
  const BotonAtras({this.alternativa, super.key});

  /// A dónde ir si no hay origen ni pila de la que tirar.
  final String? alternativa;

  @override
  Widget build(BuildContext context) => IconButton(
    key: const Key('boton_atras'),
    icon: const Icon(Icons.arrow_back),
    tooltip: 'Atrás',
    onPressed: () => volverAtras(context, alternativa: alternativa),
  );
}
