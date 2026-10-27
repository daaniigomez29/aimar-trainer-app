import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/estilo_tipo_ejercicio.dart';

/// Las etiquetas de tipo de un pack en texto: "Fuerza" o "Fuerza + Cardio".
///
/// Con `+` y no con `·`, porque donde se usa ya va detras de un "3 ejercicios
/// · ", y con el mismo separador no se leeria que son dos etiquetas.
String etiquetaDeTipos(List<TipoEjercicio> tipos) =>
    tipos.map((tipo) => tipo.etiqueta).join(' + ');

/// El icono de un pack: el de su tipo, sobre un cuadrado de su color.
///
/// Con varios tipos, un icono por tipo en pequeno, cada uno con su color, para
/// que un pack mixto se reconozca de un vistazo sin inventar un color nuevo.
///
/// POR QUE UN WIDGET: este cuadrado estaba copiado en la lista de packs, en la
/// ficha y en el panel del planning. Con un tipo daba igual; con varios, tres
/// copias de la misma logica son tres sitios en que olvidarse de uno.
class IconoDelPack extends StatelessWidget {
  const IconoDelPack({required this.tipos, this.lado = 38, super.key});

  final List<TipoEjercicio> tipos;
  final double lado;

  @override
  Widget build(BuildContext context) {
    final unico = tipos.length == 1 ? tipos.single : null;

    return Container(
      width: lado,
      height: lado,
      decoration: BoxDecoration(
        color: (unico?.color ?? Tokens.textoSuave).withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(lado * 0.26),
      ),
      child: unico != null
          ? Icon(unico.icono, size: lado * 0.52, color: unico.color)
          : Center(
              child: Wrap(
                alignment: WrapAlignment.center,
                spacing: 1,
                runSpacing: 1,
                children: [
                  for (final tipo in tipos)
                    Icon(tipo.icono, size: lado * 0.34, color: tipo.color),
                ],
              ),
            ),
    );
  }
}
