import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_principal_placeholder.dart';

/// Pantalla principal del cliente. Temporal (ver [PantallaPrincipalPlaceholder]).
class PantallaInicioCliente extends StatelessWidget {
  const PantallaInicioCliente({super.key});

  @override
  Widget build(BuildContext context) => const PantallaPrincipalPlaceholder(
    titulo: 'Mi entrenamiento',
    pendientes: [
      'Planning de la semana (fase 4)',
      'Registro de resultado de sesion (fase 5)',
      'Medidas, fotos y check-in (fase 5)',
    ],
  );
}
