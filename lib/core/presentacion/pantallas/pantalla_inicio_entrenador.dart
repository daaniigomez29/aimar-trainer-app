import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_principal_placeholder.dart';

/// Pantalla principal del entrenador. Temporal (ver [PantallaPrincipalPlaceholder]).
class PantallaInicioEntrenador extends StatelessWidget {
  const PantallaInicioEntrenador({super.key});

  @override
  Widget build(BuildContext context) => const PantallaPrincipalPlaceholder(
    titulo: 'Panel del entrenador',
    accesos: [
      AccesoSeccion(
        titulo: 'Biblioteca de ejercicios',
        descripcion: 'Anadir, editar y dar de baja ejercicios',
        icono: Icons.fitness_center,
        ruta: Rutas.bibliotecaEntrenador,
      ),
      AccesoSeccion(
        titulo: 'Clientes',
        descripcion: 'Dar de alta, editar fichas y dar de baja',
        icono: Icons.people_outline,
        ruta: Rutas.clientesEntrenador,
      ),
    ],
    pendientes: [
      'Planificacion semanal (fase 4)',
      'Progreso de clientes (fase 5)',
    ],
  );
}
