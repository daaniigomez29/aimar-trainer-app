import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';

/// Andamio temporal de las pantallas principales por rol.
///
/// Solo existe para que el enrutado por rol sea comprobable en la fase 1. Cada
/// rol lo sustituira por su pantalla real en las fases siguientes (biblioteca y
/// planificacion para el entrenador, planning del dia para el cliente, etc.).
class PantallaPrincipalPlaceholder extends ConsumerWidget {
  const PantallaPrincipalPlaceholder({
    required this.titulo,
    required this.pendientes,
    this.accesos = const [],
    super.key,
  });

  final String titulo;

  /// Lo que se construira aqui en fases posteriores.
  final List<String> pendientes;

  /// Secciones ya implementadas a las que se puede entrar.
  final List<AccesoSeccion> accesos;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorSesionProvider);
    final rol = estado is SesionActiva ? estado.perfil.rol.name : 'sin rol';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
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
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sesion iniciada como $rol.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                for (final acceso in accesos)
                  Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      key: Key('acceso_${acceso.ruta}'),
                      leading: Icon(acceso.icono),
                      title: Text(acceso.titulo),
                      subtitle: Text(acceso.descripcion),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => context.go(acceso.ruta),
                    ),
                  ),
                if (accesos.isNotEmpty) const SizedBox(height: 16),
                const Text('Pendiente de implementar:'),
                const SizedBox(height: 8),
                for (final pendiente in pendientes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('- $pendiente'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Enlace a una seccion ya implementada, mostrado en la pantalla principal.
class AccesoSeccion {
  const AccesoSeccion({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.ruta,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final String ruta;
}
