import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/notificaciones/application/controlador_notificaciones.dart';

/// Preferencias de aviso del cliente (CU-22).
///
/// Solo se puede tocar el push. El correo no tiene interruptor **a proposito**:
/// es el canal de respaldo y el unico que llega siempre, asi que desactivarlo
/// dejaria al cliente sin enterarse de nada. La pantalla lo explica en lugar de
/// mostrar un interruptor desactivado que parezca un fallo.
class PantallaPreferenciasNotificacion extends ConsumerWidget {
  const PantallaPreferenciasNotificacion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clienteId = ref.watch(idUsuarioActualProvider);
    if (clienteId == null) return const PantallaCargando();

    final textos = Theme.of(context).textTheme;
    final preferencias = ref.watch(preferenciasDeClienteProvider(clienteId));
    final estado = ref.watch(controladorNotificacionesProvider);
    final controlador = ref.read(controladorNotificacionesProvider.notifier);
    final configurado = ref
        .watch(configuracionAppProvider)
        .tienePushConfigurado;

    return Scaffold(
      appBar: AppBar(title: const Text('Avisos')),
      body: preferencias.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              error is ErrorApp
                  ? error.mensaje
                  : 'No se han podido cargar tus preferencias.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (datos) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Como te avisamos', style: textos.titleMedium),
            const SizedBox(height: 16),
            Card(
              child: SwitchListTile(
                key: const Key('interruptor_push'),
                title: const Text('Notificaciones en el dispositivo'),
                subtitle: Text(
                  _explicacionPush(
                    activado: datos.pushActivado,
                    permiso: ref.watch(permisoPushProvider),
                    soportado: ref.watch(pushSoportadoProvider),
                    configurado: configurado,
                  ),
                ),
                value: datos.pushActivado,
                onChanged: estado.enCurso || !configurado
                    ? null
                    : (quiere) async {
                        final resultado = quiere
                            ? await controlador.activar(clienteId)
                            : await controlador.desactivar(clienteId);
                        if (!context.mounted) return;
                        if (resultado.errorONulo case final error?) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(error.mensaje)),
                          );
                        }
                      },
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.mark_email_read_outlined),
                title: const Text('Correo electronico'),
                subtitle: const Text(
                  'Siempre activo. Es el aviso de respaldo: llega aunque no '
                  'tengas las notificaciones puestas.',
                ),
                trailing: const Chip(label: Text('Siempre')),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Te avisamos la tarde de antes de cada sesion y el dia que te toca '
              'el control de medidas.',
              style: textos.bodySmall,
            ),
            if (datos.pushActivado) ...[
              const SizedBox(height: 16),
              _Dispositivos(clienteId: clienteId),
            ],
            if (estado.enCurso) ...[
              const SizedBox(height: 16),
              const Center(child: CircularProgressIndicator()),
            ],
          ],
        ),
      ),
    );
  }

  /// Un texto distinto por cada motivo por el que el push puede no estar
  /// disponible: no es lo mismo "no has dado permiso" que "tu navegador no
  /// puede".
  static String _explicacionPush({
    required bool activado,
    required EstadoPermisoPush permiso,
    required bool soportado,
    required bool configurado,
  }) {
    if (!configurado) {
      return 'Esta instalacion no tiene configurado el push. Avisa a tu '
          'entrenador.';
    }
    if (!soportado) {
      return 'Tu navegador no admite notificaciones. En iPhone funcionan si '
          'anades la app a la pantalla de inicio.';
    }
    if (permiso == EstadoPermisoPush.denegado) {
      return 'Las has bloqueado en el navegador. Para recibirlas, permitelas en '
          'los ajustes de este sitio.';
    }
    return activado
        ? 'Activadas en este dispositivo.'
        : 'Recibe un aviso en el movil o en el ordenador.';
  }
}

/// Cuantos dispositivos tiene suscritos. Si son cero con el push activado, algo
/// se quedo a medias: conviene decirlo en vez de dejarle esperando avisos.
class _Dispositivos extends ConsumerWidget {
  const _Dispositivos({required this.clienteId});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final cuantos = ref.watch(dispositivosSuscritosProvider(clienteId)).value;
    if (cuantos == null) return const SizedBox.shrink();

    return Text(
      cuantos == 0
          ? 'No hay ningun dispositivo registrado. Vuelve a activarlas desde el '
                'dispositivo en el que quieras recibirlas.'
          : '$cuantos ${cuantos == 1 ? "dispositivo registrado" : "dispositivos registrados"}.',
      style: textos.bodySmall,
    );
  }
}
