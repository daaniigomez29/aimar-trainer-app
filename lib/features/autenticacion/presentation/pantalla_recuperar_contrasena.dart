import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_recuperacion.dart';

/// CU-24 Recuperar contrasena, primera mitad: solicitar el enlace.
class PantallaRecuperarContrasena extends ConsumerStatefulWidget {
  const PantallaRecuperarContrasena({super.key});

  @override
  ConsumerState<PantallaRecuperarContrasena> createState() =>
      _EstadoPantallaRecuperarContrasena();
}

class _EstadoPantallaRecuperarContrasena
    extends ConsumerState<PantallaRecuperarContrasena> {
  final _correo = TextEditingController();

  @override
  void dispose() {
    _correo.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorSolicitudRecuperacionProvider);
    final controlador = ref.read(
      controladorSolicitudRecuperacionProvider.notifier,
    );

    // Mensaje deliberadamente generico: no confirma si el correo existe.
    if (estado.completada) {
      return FormularioCentrado(
        titulo: 'Revisa tu correo',
        hijos: [
          const AvisoEnLinea(
            esError: false,
            mensaje:
                'Si ese correo corresponde a una cuenta, recibiras un enlace '
                'para restablecer la contraseña.',
          ),
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
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('campo_correo'),
          controller: _correo,
          enabled: !estado.enCurso,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          onChanged: (_) => controlador.limpiarError(),
          onSubmitted: (_) => controlador.solicitarEnlace(_correo.text),
          decoration: InputDecoration(
            labelText: 'Correo',
            errorText: estado.errorDelCampo('correo'),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_enviar_enlace'),
          onPressed: estado.enCurso
              ? null
              : () => controlador.solicitarEnlace(_correo.text),
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Enviar enlace'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: estado.enCurso ? null : () => context.go(Rutas.login),
          child: const Text('Volver al acceso'),
        ),
      ],
    );
  }
}
