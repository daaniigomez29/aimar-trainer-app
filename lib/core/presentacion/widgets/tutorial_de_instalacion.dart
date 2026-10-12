import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';

/// Como añadir la app a la pantalla de inicio del movil.
///
/// POR QUE ESTA EN LA APP Y NO EN UN CORREO: esto es una PWA, asi que no hay
/// ficha en ninguna tienda que lo explique. Sin instalarla se entra por el
/// navegador cada vez, con su barra de direcciones robando pantalla, y en
/// **iPhone los avisos push no existen hasta que la app esta instalada**: es
/// una limitacion de Safari, no algo que se pueda arreglar desde aqui.
///
/// Va plegado: es un paso que se da una vez, y desplegado ocuparia media
/// pantalla de ajustes para siempre.
class TutorialDeInstalacion extends StatelessWidget {
  const TutorialDeInstalacion({super.key});

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Tarjeta(
      hijo: Theme(
        // Sin la linea divisoria que `ExpansionTile` pinta por su cuenta: la
        // tarjeta ya la enmarca.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: const Key('tutorial_instalacion'),
          tilePadding: EdgeInsets.zero,
          childrenPadding: const EdgeInsets.only(bottom: 4),
          leading: const Icon(Icons.install_mobile, size: 20),
          title: Text('Instalar la app en el móvil', style: textos.titleMedium),
          subtitle: Text(
            'Para abrirla desde un icono, a pantalla completa.',
            style: textos.bodySmall,
          ),
          children: const [
            _Pasos(
              titulo: 'iPhone y iPad',
              icono: Icons.phone_iphone,
              // Chrome en iOS no puede: la instalacion la hace el sistema a
              // traves de Safari, y decirlo evita el intento fallido.
              aviso: 'Tiene que ser con Safari.',
              pasos: [
                'Abre esta web en Safari.',
                'Toca el botón de Compartir, el cuadrado con la flecha hacia '
                    'arriba.',
                'Baja por el menú y elige "Añadir a pantalla de inicio".',
                'Pulsa "Añadir" arriba a la derecha.',
              ],
            ),
            SizedBox(height: 14),
            _Pasos(
              titulo: 'Android',
              icono: Icons.phone_android,
              aviso: 'Con Chrome u otro navegador basado en Chromium.',
              pasos: [
                'Abre esta web en el navegador.',
                'Si sale abajo el aviso de "Instalar aplicación", púlsalo.',
                'Si no sale, abre el menú de los tres puntos de arriba a la '
                    'derecha.',
                'Elige "Instalar aplicación" o "Añadir a la pantalla de '
                    'inicio".',
                'Confirma: el icono aparece junto al resto de tus apps.',
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Pasos extends StatelessWidget {
  const _Pasos({
    required this.titulo,
    required this.icono,
    required this.aviso,
    required this.pasos,
  });

  final String titulo;
  final IconData icono;
  final String aviso;
  final List<String> pasos;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icono, size: 18, color: Tokens.acento),
            const SizedBox(width: 8),
            Text(titulo, style: textos.titleSmall),
          ],
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.only(left: 26),
          child: Text(
            aviso,
            style: textos.bodySmall?.copyWith(color: Tokens.secundario),
          ),
        ),
        const SizedBox(height: 8),
        for (final (indice, paso) in pasos.indexed)
          Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 20,
                  child: Text(
                    '${indice + 1}.',
                    style: textos.bodyMedium?.copyWith(
                      color: Tokens.textoSuave,
                    ),
                  ),
                ),
                Expanded(child: Text(paso, style: textos.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}
