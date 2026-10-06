import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_login.dart';

/// CU-01 Iniciar sesion.
class PantallaLogin extends ConsumerStatefulWidget {
  const PantallaLogin({super.key});

  @override
  ConsumerState<PantallaLogin> createState() => _EstadoPantallaLogin();
}

class _EstadoPantallaLogin extends ConsumerState<PantallaLogin> {
  final _correo = TextEditingController();
  final _contrasena = TextEditingController();
  bool _contrasenaVisible = false;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  Future<void> _enviar() => ref
      .read(controladorLoginProvider.notifier)
      .iniciarSesion(correo: _correo.text, contrasena: _contrasena.text);

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorLoginProvider);
    final controlador = ref.read(controladorLoginProvider.notifier);

    return FormularioCentrado(
      titulo: 'Acceso',
      subtitulo: 'Introduce tus credenciales para continuar.',
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
          textInputAction: TextInputAction.next,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Correo',
            errorText: estado.errorDelCampo('correo'),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_contrasena'),
          controller: _contrasena,
          enabled: !estado.enCurso,
          obscureText: !_contrasenaVisible,
          autofillHints: const [AutofillHints.password],
          textInputAction: TextInputAction.done,
          onChanged: (_) => controlador.limpiarError(),
          onSubmitted: (_) => _enviar(),
          decoration: InputDecoration(
            labelText: 'Contraseña',
            errorText: estado.errorDelCampo('contrasena'),
            suffixIcon: IconButton(
              onPressed: () => setState(() {
                _contrasenaVisible = !_contrasenaVisible;
              }),
              icon: Icon(
                _contrasenaVisible ? Icons.visibility_off : Icons.visibility,
              ),
              tooltip: _contrasenaVisible
                  ? 'Ocultar contraseña'
                  : 'Mostrar contraseña',
            ),
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_acceder'),
          onPressed: estado.enCurso ? null : _enviar,
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Acceder'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: estado.enCurso
              ? null
              : () => context.push(Rutas.recuperarContrasena),
          child: const Text('He olvidado mi contraseña'),
        ),
      ],
    );
  }
}
