import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_progreso.dart';

/// El progreso del cliente que tiene la sesion abierta (CU-21).
///
/// Solo resuelve el id a partir de la sesion y delega en [PantallaProgreso], que
/// es la misma que usa el entrenador: asi la pantalla del cliente no puede pedir
/// el progreso de otra persona ni por error.
class PantallaMiProgreso extends ConsumerWidget {
  const PantallaMiProgreso({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idCliente = ref.watch(idUsuarioActualProvider);
    if (idCliente == null) return const PantallaCargando();

    return PantallaProgreso(clienteId: idCliente);
  }
}
