import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_principal_placeholder.dart';

/// Pantalla principal del administrador. Temporal (ver [PantallaPrincipalPlaceholder]).
///
/// El administrador puede dar de alta y de baja clientes, pero no tiene acceso a
/// sus fichas, medidas, fotos ni check-in: lo garantiza la ausencia de politicas
/// RLS, no la interfaz.
class PantallaInicioAdministrador extends StatelessWidget {
  const PantallaInicioAdministrador({super.key});

  @override
  Widget build(BuildContext context) => const PantallaPrincipalPlaceholder(
    titulo: 'Administracion',
    accesos: [
      AccesoSeccion(
        titulo: 'Clientes',
        descripcion: 'Dar de alta y de baja (sin acceso a sus fichas)',
        icono: Icons.people_outline,
        ruta: Rutas.clientesAdministrador,
      ),
    ],
    pendientes: [
      'Gestion de cuentas de entrenador (se hace desde el panel de Supabase)',
    ],
  );
}
