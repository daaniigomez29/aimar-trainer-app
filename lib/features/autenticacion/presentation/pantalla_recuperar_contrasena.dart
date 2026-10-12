import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_recuperacion.dart';
import 'package:aimar_trainer_app/features/autenticacion/presentation/widgets/solicitud_de_enlace.dart';

/// CU-24 Recuperar contrasena, primera mitad: solicitar el enlace.
///
/// El formulario en si lo pone [SolicitudDeEnlace], compartido con la pantalla
/// de fijar la contrasena: alli hace falta lo mismo cuando el enlace del correo
/// llega ya gastado.
class PantallaRecuperarContrasena extends ConsumerWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(controladorSolicitudRecuperacionProvider);

    // Mensaje deliberadamente generico: no confirma si el correo existe.
    if (estado.completada) {
      return FormularioCentrado(
        titulo: 'Revisa tu correo',
        hijos: [
          const AvisoEnLinea(esError: false, mensaje: mensajeEnlaceEnviado),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () => context.go(Rutas.login),
            child: const Text('Volver al acceso'),
          ),
        ],
      );
    }

    return FormularioCentrado(
      titulo: 'Recuperar contraseña',
      subtitulo: 'Te enviaremos un enlace para fijar una contraseña nueva.',
      hijos: [
        const SolicitudDeEnlace(),
        const SizedBox(height: 8),
        TextButton(
          onPressed: estado.enCurso ? null : () => context.go(Rutas.login),
          child: const Text('Volver al acceso'),
        ),
      ],
    );
  }
}
