import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_principal_placeholder.dart';

/// Pantalla principal del cliente. Temporal (ver [PantallaPrincipalPlaceholder]).
class PantallaInicioCliente extends StatelessWidget {
  const PantallaInicioCliente({super.key});

  @override
  Widget build(BuildContext context) => const PantallaPrincipalPlaceholder(
    titulo: 'Mi entrenamiento',
    accesos: [
      AccesoSeccion(
        titulo: 'Mi planning',
        descripcion: 'La semana que te ha preparado tu entrenador',
        icono: Icons.calendar_month,
        ruta: Rutas.planningCliente,
      ),
      AccesoSeccion(
        titulo: 'Mi progreso',
        descripcion: 'Evolucion de tus ejercicios y de tus medidas',
        icono: Icons.show_chart,
        ruta: Rutas.progresoCliente,
      ),
      AccesoSeccion(
        titulo: 'Control semanal',
        descripcion: 'Medidas, fotos de progreso y check-in de recuperacion',
        icono: Icons.straighten,
        ruta: Rutas.controlCliente,
      ),
      AccesoSeccion(
        titulo: 'Avisos',
        descripcion: 'Decide si quieres notificaciones en el dispositivo',
        icono: Icons.notifications_outlined,
        ruta: Rutas.avisosCliente,
      ),
      AccesoSeccion(
        titulo: 'Biblioteca de ejercicios',
        descripcion: 'Consulta la tecnica y los videos de ejemplo',
        icono: Icons.fitness_center,
        ruta: Rutas.bibliotecaCliente,
      ),
    ],
    pendientes: [],
  );
}
