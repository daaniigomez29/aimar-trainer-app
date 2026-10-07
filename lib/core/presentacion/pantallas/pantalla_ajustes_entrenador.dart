import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';

/// Ajustes del entrenador: el cuarto destino de su navegacion
/// (`docs/ui-design.md`, seccion 5).
///
/// De momento solo cierra la sesion. El resto de la administracion (cuentas,
/// configuracion tecnica) queda **fuera del alcance de la app** por decision de
/// `architecture.md`: se hace desde el panel de Supabase.
class PantallaAjustesEntrenador extends ConsumerWidget {
  const PantallaAjustesEntrenador({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    final cuerpo = ListView(
      padding: const EdgeInsets.all(Tokens.margenPantalla),
      children: [
        Text('Ajustes', style: textos.headlineMedium),
        const SizedBox(height: 18),
        Tarjeta(
          hijo: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Cerrar sesión', style: textos.titleMedium),
                    const SizedBox(height: 4),
                    Text(
                      'Volveras a la pantalla de acceso.',
                      style: textos.bodySmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('boton_cerrar_sesion'),
                tooltip: 'Cerrar sesión',
                icon: const Icon(Icons.logout),
                onPressed: () =>
                    ref.read(controladorSesionProvider.notifier).cerrarSesion(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'La gestión de cuentas y la configuración técnica se hacen desde el '
          'panel de Supabase: no son casos de uso de la app.',
          style: textos.bodySmall,
        ),
      ],
    );

    return PantallaEntrenador(
      rutaActual: Rutas.ajustesEntrenador,
      cuerpo: cuerpo,
    );
  }
}
