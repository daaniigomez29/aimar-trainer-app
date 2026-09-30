import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_principal_placeholder.dart';

/// Pantalla principal del administrador. Temporal (ver [PantallaPrincipalPlaceholder]).
///
/// El administrador no tiene acceso a medidas, fotos ni check-in de los
/// clientes: esa restriccion la garantiza la ausencia de politicas RLS.
class PantallaInicioAdministrador extends StatelessWidget {
  const PantallaInicioAdministrador({super.key});

  @override
  Widget build(BuildContext context) => const PantallaPrincipalPlaceholder(
    titulo: 'Administracion',
    pendientes: ['Alta y baja de clientes (fase 3)'],
  );
}
