import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_recuperacion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/credenciales.dart';

/// CU-24 Recuperar contrasena, segunda mitad: fijar la contrasena nueva.
///
/// Se llega por el enlace del correo, que abre una sesion de recuperacion.
class PantallaRestablecerContrasena extends ConsumerStatefulWidget {
  const PantallaRestablecerContrasena({super.key});

  @override
  ConsumerState<PantallaRestablecerContrasena> createState() =>
      _EstadoPantallaRestablecerContrasena();
}

class _EstadoPantallaRestablecerContrasena
    extends ConsumerState<PantallaRestablecerContrasena> {
  final _contrasena = TextEditingController();
  final _repeticion = TextEditingController();

  @override
  void dispose() {
    _contrasena.dispose();
    _repeticion.dispose();
    super.dispose();
  }

  Future<void> _enviar() => ref
      .read(controladorRestablecerContrasenaProvider.notifier)
      .establecerContrasena(
        contrasena: _contrasena.text,
        repeticion: _repeticion.text,
      );

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorRestablecerContrasenaProvider);
    final controlador = ref.read(
      controladorRestablecerContrasenaProvider.notifier,
    );

    // Al completarse, Auth emite `userUpdated`: `ControladorSesion` resuelve el
    // perfil y el enrutador lleva a la pantalla principal del rol.
    if (estado.completada) {
      return const FormularioCentrado(
        titulo: 'Contrasena actualizada',
        hijos: [
          AvisoEnLinea(
            esError: false,
            mensaje: 'Ya puedes usar tu contrasena nueva.',
          ),
          SizedBox(height: 24),
          Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return FormularioCentrado(
      titulo: 'Nueva contrasena',
      subtitulo:
          'Debe tener al menos '
          '${Credenciales.longitudMinimaContrasena} caracteres.',
      hijos: [
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('campo_contrasena'),
          controller: _contrasena,
          enabled: !estado.enCurso,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.next,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Contrasena',
            errorText: estado.errorDelCampo('contrasena'),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_repeticion'),
          controller: _repeticion,
          enabled: !estado.enCurso,
          obscureText: true,
          autofillHints: const [AutofillHints.newPassword],
          textInputAction: TextInputAction.done,
          onChanged: (_) => controlador.limpiarError(),
          onSubmitted: (_) => _enviar(),
          decoration: InputDecoration(
            labelText: 'Repite la contrasena',
            errorText: estado.errorDelCampo('repeticion'),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_guardar_contrasena'),
          onPressed: estado.enCurso ? null : _enviar,
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Guardar contrasena'),
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
