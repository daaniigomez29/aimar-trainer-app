import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_recuperacion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/estado_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/credenciales.dart';

/// Pantalla para fijar la contrasena. Sirve a dos flujos:
///
/// - CU-17: el cliente acaba de aceptar su invitacion y elige su primera
///   contrasena. Es obligatorio: si entrara sin fijarla, no podria volver a
///   entrar nunca (su cuenta se crea sin contrasena).
/// - CU-24: recuperacion, segunda mitad.
///
/// Solo cambian los textos; el formulario y la validacion son los mismos.
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
    final esPrimeraVez =
        ref.watch(controladorSesionProvider) is SesionDebeFijarContrasena;

    // Al completarse, Auth emite `userUpdated`: `ControladorSesion` resuelve el
    // perfil y el enrutador lleva a la pantalla principal del rol.
    if (estado.completada) {
      return FormularioCentrado(
        titulo: esPrimeraVez ? 'Cuenta activada' : 'Contraseña actualizada',
        hijos: [
          AvisoEnLinea(
            esError: false,
            mensaje: esPrimeraVez
                ? 'Ya tienes acceso. Entrando...'
                : 'Ya puedes usar tu contraseña nueva.',
          ),
          const SizedBox(height: 24),
          const Center(child: CircularProgressIndicator()),
        ],
      );
    }

    return FormularioCentrado(
      titulo: esPrimeraVez ? 'Elige tu contraseña' : 'Nueva contraseña',
      subtitulo: esPrimeraVez
          ? 'Tu entrenador te ha dado de alta. Elige una contraseña para '
                'entrar: debe tener al menos '
                '${Credenciales.longitudMinimaContrasena} caracteres.'
          : 'Debe tener al menos '
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
            labelText: 'Contraseña',
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
            labelText: 'Repite la contraseña',
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
              : Text(esPrimeraVez ? 'Activar mi cuenta' : 'Guardar contraseña'),
        ),
        const SizedBox(height: 8),
        // En el flujo de invitacion no se ofrece salir: sin contrasena fijada, el
        // cliente no podria volver a entrar.
        if (!esPrimeraVez)
          TextButton(
            onPressed: estado.enCurso ? null : () => context.go(Rutas.login),
            child: const Text('Volver al acceso'),
          ),
      ],
    );
  }
}
