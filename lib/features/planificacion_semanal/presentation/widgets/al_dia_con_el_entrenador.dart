import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';

/// Mantiene al dia lo que el cliente esta mirando de su planificacion.
///
/// POR QUE EXISTE: quien planifica y quien mira son dos sesiones distintas. El
/// entrenador borraba un planning y el cliente lo seguia viendo hasta cambiar
/// de pestana o pulsar "recargar". Pedirle eso al usuario es pedirle que haga
/// el trabajo de la aplicacion.
///
/// Dos vias, porque ninguna cubre sola todos los casos:
///
/// - **Realtime** (`cambiosEnMisPlannings`): el aviso llega al momento, aunque
///   el cliente este con la pantalla delante sin tocar nada.
/// - **Al recuperar el foco**: si el socket se cayo —movil dormido, pestana en
///   segundo plano, red inestable— al volver se vuelve a pedir todo. Ademas
///   cubre lo que no viaja por realtime: los cambios de **dentro** del planning
///   (sesiones, bloques, ejercicios), que solo se ven al abrirlo.
class AlDiaConElEntrenador extends ConsumerStatefulWidget {
  const AlDiaConElEntrenador({required this.hijo, super.key});

  final Widget hijo;

  @override
  ConsumerState<AlDiaConElEntrenador> createState() =>
      _EstadoAlDiaConElEntrenador();
}

class _EstadoAlDiaConElEntrenador extends ConsumerState<AlDiaConElEntrenador> {
  late final AppLifecycleListener _ciclo;

  @override
  void initState() {
    super.initState();
    _ciclo = AppLifecycleListener(onResume: _volverAPedir);
  }

  @override
  void dispose() {
    _ciclo.dispose();
    super.dispose();
  }

  /// Invalida la familia entera de plannings completos, no uno concreto: desde
  /// aqui no se sabe cual tiene abierto la pantalla de debajo.
  void _volverAPedir() {
    ref
      ..invalidate(misPlanningsProvider)
      ..invalidate(planningCompletoProvider);
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cambiosEnMisPlanningsProvider, (_, _) => _volverAPedir());
    return widget.hijo;
  }
}
