import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_principal_placeholder.dart';

/// Pantalla principal del entrenador. Temporal (ver [PantallaPrincipalPlaceholder]).
class PantallaInicioEntrenador extends StatelessWidget {
  const PantallaInicioEntrenador({super.key});

  @override
  Widget build(BuildContext context) => const PantallaPrincipalPlaceholder(
    titulo: 'Panel del entrenador',
    pendientes: [
      'Biblioteca de ejercicios (fase 2)',
      'Gestion de clientes (fase 3)',
      'Planificacion semanal (fase 4)',
      'Progreso de clientes (fase 5)',
    ],
  );
}
