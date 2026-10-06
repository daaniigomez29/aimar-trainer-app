import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/core/plataforma/servicio_push.dart';
import 'package:aimar_trainer_app/core/presentacion/pantallas/pantalla_cargando.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/supabase/proveedores_supabase.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/notificaciones/application/controlador_notificaciones.dart';

/// Configuracion del cliente (`docs/ui-design.md`, 6.5).
///
/// Solo se puede tocar el push. El correo no tiene interruptor **a proposito**:
/// es el canal de respaldo y el unico que llega siempre, asi que desactivarlo
/// dejaria al cliente sin enterarse de nada. La pantalla lo explica en lugar de
/// mostrar un interruptor apagado que parezca un fallo.
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

    return PantallaCliente(
      rutaActual: Rutas.avisosCliente,
      appBar: AppBar(title: const Text('Configuración')),
      cuerpo: preferencias.when(
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
          padding: const EdgeInsets.fromLTRB(
            Tokens.margenPantalla,
            8,
            Tokens.margenPantalla,
            24,
          ),
          children: [
            Text('Cómo te avisamos', style: textos.titleSmall),
            const SizedBox(height: 12),
            FilaInterruptor(
              clave: const Key('interruptor_push'),
              titulo: 'Notificaciones en el dispositivo',
              descripcion: _explicacionPush(
                activado: datos.pushActivado,
                permiso: ref.watch(permisoPushProvider),
                soportado: ref.watch(pushSoportadoProvider),
                configurado: configurado,
              ),
              valor: datos.pushActivado,
              onCambio: estado.enCurso || !configurado
                  ? null
                  : (quiere) async {
                      final resultado = quiere
                          ? await controlador.activar(clienteId)
                          : await controlador.desactivar(clienteId);
                      if (!context.mounted) return;
                      if (resultado.errorONulo case final error?) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            duration: Avisos.duracion,
                            content: Text(error.mensaje),
                          ),
                        );
                      }
                    },
            ),
            const SizedBox(height: 12),
            Tarjeta(
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
                      Icons.mail_outline,
                      size: 20,
                      color: Tokens.acento,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Correo electronico', style: textos.titleMedium),
                        const SizedBox(height: 4),
                        Text(
                          'Siempre activo. Es el aviso de respaldo: llega '
                          'aunque no tengas las notificaciones puestas.',
                          style: textos.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Pastilla(texto: 'Siempre'),
                ],
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'Te avisamos la tarde de antes de cada sesión y el día que te '
              'toca el control de medidas.',
              style: textos.bodySmall,
            ),
            if (datos.pushActivado) ...[
              const SizedBox(height: 14),
              _Dispositivos(clienteId: clienteId),
            ],
            const SizedBox(height: 24),
            // La unica salida de la app para el cliente: su pantalla de inicio
            // es ahora el planning, que no tiene sitio para esto.
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
                    onPressed: () => ref
                        .read(controladorSesionProvider.notifier)
                        .cerrarSesion(),
                  ),
                ],
              ),
            ),
            if (estado.enCurso) ...[
              const SizedBox(height: 18),
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
      return 'Esta instalación no tiene configurado el push. Avisa a tu '
          'entrenador.';
    }
    if (!soportado) {
      return 'Tu navegador no admite notificaciones. En iPhone funcionan si '
          'añades la app a la pantalla de inicio.';
    }
    if (permiso == EstadoPermisoPush.denegado) {
      return 'Las has bloqueado en el navegador. Para recibirlas, permitelas '
          'en los ajustes de este sitio.';
    }
    return activado
        ? 'Activadas en este dispositivo.'
        : 'Recibe un aviso en el móvil o en el ordenador.';
  }
}

/// Cuantos dispositivos tiene suscritos. Si son cero con el push activado, algo
/// se quedo a medias: conviene decirlo en vez de dejarle esperando avisos.
class _Dispositivos extends ConsumerWidget {
  const _Dispositivos({required this.clienteId});

  final String clienteId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuantos = ref.watch(dispositivosSuscritosProvider(clienteId)).value;
    if (cuantos == null) return const SizedBox.shrink();

    return Text(
      cuantos == 0
          ? 'No hay ningún dispositivo registrado. Vuelve a activarlas desde '
                'el dispositivo en el que quieras recibirlas.'
          : '$cuantos ${cuantos == 1 ? "dispositivo registrado" : "dispositivos registrados"}.',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}
