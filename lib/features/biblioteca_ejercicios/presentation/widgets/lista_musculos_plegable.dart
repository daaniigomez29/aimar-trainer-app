import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';

/// Los musculos agrupados, **con cada grupo plegado**: solo se abre el que
/// interesa.
///
/// POR QUE PLEGADO: son 21 musculos. Pintados de golpe vuelven a ser la lista
/// interminable que esto venia a quitar, y el apartado se come la pantalla.
///
/// Sirve para las dos cosas que hacen falta, porque el widget no decide nada:
/// recibe que esta marcado y avisa de cada pulsacion, y quien lo usa decide si
/// la seleccion es de uno o de varios.
/// - En el formulario del ejercicio, para elegir **varios** secundarios.
/// - Al anadir un ejercicio a un bloque, para **filtrar** por un musculo.
class ListaMusculosPlegable extends StatelessWidget {
  const ListaMusculosPlegable({
    required this.grupos,
    required this.musculosDe,
    required this.seleccionados,
    required this.onMusculo,
    this.ocultar = const <Musculo>{},
    this.grupoSeleccionado,
    this.onGrupo,
    this.resumenDe,
    this.habilitado = true,
    super.key,
  });

  /// Grupos a pintar, en orden. Quien lo usa decide si son todos o solo los
  /// que tienen algun ejercicio detras.
  final List<GrupoMuscular> grupos;

  /// Musculos de cada grupo, por el mismo motivo.
  final List<Musculo> Function(GrupoMuscular) musculosDe;

  final Set<Musculo> seleccionados;
  final ValueChanged<Musculo> onMusculo;

  /// Musculos que no se ofrecen. En el formulario es el principal: tenerlo
  /// tambien de secundario lo rechaza la base de datos, asi que no se ensena
  /// como opcion en lugar de dejar que lo pulse y falle al guardar.
  final Set<Musculo> ocultar;

  /// Solo en modo filtro: pinta un chip "Todo el grupo" al principio de cada
  /// grupo. Sin [onGrupo] no aparece.
  final GrupoMuscular? grupoSeleccionado;
  final ValueChanged<GrupoMuscular>? onGrupo;

  /// Linea bajo el nombre del grupo: cuantos ejercicios hay, o cuales se han
  /// elegido, segun quien lo use.
  final String Function(GrupoMuscular)? resumenDe;

  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Column(
      children: [
        for (final grupo in grupos)
          Theme(
            // El `ExpansionTile` pinta sus propias lineas divisorias, y con una
            // lista de grupos seguidos se convierten en rayas por todas partes.
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              // Conserva abierto/cerrado al reconstruir, que pasa con cada
              // pulsacion.
              key: PageStorageKey('grupo_plegable_${grupo.valorJson}'),
              // Se abre solo el grupo en el que ya hay algo elegido: al volver
              // a esta pantalla, lo elegido esta a la vista y no escondido.
              initiallyExpanded:
                  grupoSeleccionado == grupo ||
                  musculosDe(grupo).any(seleccionados.contains),
              tilePadding: EdgeInsets.zero,
              // Aire entre el nombre del grupo y sus musculos: pegados, no
              // se ve donde acaba la cabecera y empiezan las opciones.
              childrenPadding: const EdgeInsets.only(top: 6, bottom: 14),
              title: Text(grupo.etiqueta, style: textos.titleSmall),
              subtitle: resumenDe == null
                  ? null
                  : Text(resumenDe!(grupo), style: textos.bodySmall),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      if (onGrupo case final alPulsarGrupo?)
                        ChipFiltro(
                          key: Key('todo_${grupo.valorJson}'),
                          etiqueta: 'Todo ${grupo.etiqueta.toLowerCase()}',
                          activo: grupoSeleccionado == grupo,
                          onPulsar: habilitado
                              ? () => alPulsarGrupo(grupo)
                              : () {},
                        ),
                      for (final musculo in musculosDe(grupo))
                        if (!ocultar.contains(musculo))
                          ChipFiltro(
                            key: Key('musculo_${musculo.valorJson}'),
                            etiqueta: musculo.etiqueta,
                            activo: seleccionados.contains(musculo),
                            onPulsar: habilitado
                                ? () => onMusculo(musculo)
                                : () {},
                          ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        if (grupos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No hay ejercicios clasificados todavía.',
              style: textos.bodySmall?.copyWith(color: Tokens.textoTenue),
            ),
          ),
      ],
    );
  }
}
