import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/progreso/presentation/pantalla_control_semanal.dart';

/// El control semanal del cliente que tiene la sesion abierta: medidas, fotos y
/// check-in de recuperacion.
///
/// Igual que [PantallaMiProgreso], el id sale de la sesion y no de un parametro.
class PantallaMiControl extends ConsumerWidget {
  const PantallaMiControl({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final idCliente = ref.watch(idUsuarioActualProvider);
    if (idCliente == null) return const PantallaCargando();

    return PantallaControlSemanal(clienteId: idCliente);
  }
}
