import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';

/// Pantalla principal del administrador.
///
/// No tiene diseno propio en el prototipo porque su alcance es minimo: gestiona
/// las fichas de cliente y poco mas. **No ve medidas, fotos, check-in ni
/// progreso**, y no por omision de esta pantalla: no tiene politica RLS en
/// ninguna de esas tablas.
class PantallaInicioAdministrador extends ConsumerWidget {
  const PantallaInicioAdministrador({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Administracion'),
        actions: [
          IconButton(
            key: const Key('boton_cerrar_sesion'),
            tooltip: 'Cerrar sesion',
            icon: const Icon(Icons.logout),
            onPressed: () =>
                ref.read(controladorSesionProvider.notifier).cerrarSesion(),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: ListView(
            padding: const EdgeInsets.all(Tokens.margenPantalla),
            shrinkWrap: true,
            children: [
              Tarjeta(
                onTap: () => context.go(Rutas.clientesAdministrador),
                hijo: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Tokens.acentoSuave,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.people_outline,
                        size: 20,
                        color: Tokens.acento,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Clientes', style: textos.titleMedium),
                          const SizedBox(height: 4),
                          Text(
                            'Altas y bajas. Sin acceso a sus datos de salud.',
                            style: textos.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
