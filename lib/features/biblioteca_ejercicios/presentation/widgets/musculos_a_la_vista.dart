import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';

/// Los musculos **todos a la vista**, agrupados: filtrar es un solo clic.
///
/// Es la otra cara de `ListaMusculosPlegable`, para cuando hay una columna
/// entera para ellos. Aimar se quejaba de los tres clics (abrir el filtro, abrir
/// el grupo, elegir el musculo), y plegar solo tiene sentido si el espacio falta.
///
/// El nombre del grupo tambien se pulsa: filtra por el grupo entero.
class MusculosALaVista extends StatelessWidget {
  const MusculosALaVista({
    required this.grupos,
    required this.musculosDe,
    required this.resumenDe,
    required this.onGrupo,
    required this.onMusculo,
    this.grupoSeleccionado,
    this.musculoSeleccionado,
    this.habilitado = true,
    super.key,
  });

  final List<GrupoMuscular> grupos;
  final List<Musculo> Function(GrupoMuscular) musculosDe;
  final String Function(GrupoMuscular) resumenDe;
  final ValueChanged<GrupoMuscular> onGrupo;
  final ValueChanged<Musculo> onMusculo;
  final GrupoMuscular? grupoSeleccionado;
  final Musculo? musculoSeleccionado;
  final bool habilitado;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    if (grupos.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(
          'No hay ejercicios clasificados todavía.',
          style: textos.bodySmall?.copyWith(color: Tokens.textoTenue),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final grupo in grupos) ...[
          const SizedBox(height: 10),
          _CabeceraDeGrupo(
            grupo: grupo,
            resumen: resumenDe(grupo),
            activo: grupoSeleccionado == grupo,
            onPulsar: habilitado ? () => onGrupo(grupo) : null,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final musculo in musculosDe(grupo))
                ChipFiltro(
                  key: Key('musculo_${musculo.valorJson}'),
                  etiqueta: musculo.etiqueta,
                  compacto: true,
                  activo: musculoSeleccionado == musculo,
                  onPulsar: habilitado ? () => onMusculo(musculo) : () {},
                ),
            ],
          ),
        ],
      ],
    );
  }
}

class _CabeceraDeGrupo extends StatelessWidget {
  const _CabeceraDeGrupo({
    required this.grupo,
    required this.resumen,
    required this.activo,
    required this.onPulsar,
  });

  final GrupoMuscular grupo;
  final String resumen;
  final bool activo;
  final VoidCallback? onPulsar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;

    return Semantics(
      button: true,
      selected: activo,
      child: InkWell(
        key: Key('todo_${grupo.valorJson}'),
        onTap: onPulsar,
        borderRadius: BorderRadius.circular(Tokens.radioBoton),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            children: [
              Text(
                grupo.etiqueta,
                style: textos.titleSmall?.copyWith(
                  color: activo ? Tokens.acento : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  resumen,
                  overflow: TextOverflow.ellipsis,
                  style: textos.bodySmall?.copyWith(color: Tokens.textoTenue),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
