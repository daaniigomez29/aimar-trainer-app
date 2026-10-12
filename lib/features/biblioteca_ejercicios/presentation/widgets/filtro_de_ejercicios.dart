import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/facetas_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/estilo_tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/lista_musculos_plegable.dart';

/// Buscador y filtro muscular para **elegir un ejercicio de la biblioteca**.
///
/// Lo usan los dos sitios desde los que se anade un ejercicio a un bloque: el
/// panel lateral del planning y el formulario de CU-08. Antes los dos
/// presentaban la biblioteca entera de una vez —el formulario, en un
/// desplegable— y con veinte ejercicios ya era una lista en la que uno se
/// pierde nada mas abrirla.
///
/// Son **dos niveles de plegado** a proposito: el filtro entero vive dentro de
/// un desplegable, y los musculos dentro del suyo. Asi de partida no se ve mas
/// que el buscador y una linea que dice por que se esta filtrando, que es lo
/// unico que hace falta cuando ya sabes el nombre de lo que buscas.
///
/// Escribe en el filtro del ambito [widget.ambito], que es suyo y
/// **no** el de la pantalla de biblioteca: buscar aqui no puede dejar la
/// biblioteca filtrada por detras. El panel del planning y el formulario de
/// CU-08 si lo comparten entre ellos, que son el mismo gesto en dos sitios.
/// El campo de busqueda
/// **nace con lo que ese filtro ya tenga**: con un controlador vacio, la lista
/// saldria recortada por un texto que no se ve en ninguna parte.
class FiltroDeEjercicios extends ConsumerStatefulWidget {
  const FiltroDeEjercicios({
    required this.ambito,
    this.habilitado = true,
    super.key,
  });

  /// Cual de los filtros se toca: cada pantalla tiene el suyo.
  final AmbitoDeFiltro ambito;

  final bool habilitado;

  @override
  ConsumerState<FiltroDeEjercicios> createState() => _FiltroDeEjerciciosState();
}

class _FiltroDeEjerciciosState extends ConsumerState<FiltroDeEjercicios> {
  late final TextEditingController _busqueda;

  @override
  void initState() {
    super.initState();
    _busqueda = TextEditingController(
      text: ref.read(filtroBibliotecaProvider(widget.ambito)).texto,
    );
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final facetas =
        ref.watch(facetasBibliotecaProvider(widget.ambito)).value ??
        FacetasBiblioteca.vacias;
    final filtro = ref.watch(filtroBibliotecaProvider(widget.ambito));
    final notificador = ref.read(
      filtroBibliotecaProvider(widget.ambito).notifier,
    );

    final resumen = switch ((filtro.musculo, filtro.grupo)) {
      (final musculo?, _) => musculo.etiquetaConGrupo,
      (null, final grupo?) => 'Todo ${grupo.etiqueta.toLowerCase()}',
      _ => 'Todos los músculos',
    };
    final hayFiltroMuscular = filtro.grupo != null || filtro.musculo != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CampoBusqueda(
          clave: const Key('busqueda_ejercicio'),
          controlador: _busqueda,
          onCambio: notificador.cambiarTexto,
        ),
        // Cardio y Fortalecimiento tambien aqui: es donde se monta el bloque, y
        // "ponme un cardio" o "algo de fortalecimiento para el hombro" es como
        // se busca cuando ya sabes que clase de ejercicio quieres. Se cruzan
        // con el filtro muscular de debajo, no lo sustituyen.
        if (facetas.tipos.any((t) => t != TipoEjercicio.fuerza)) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final tipo in facetas.tipos)
                if (tipo != TipoEjercicio.fuerza)
                  ChipFiltro(
                    key: Key('tipo_${tipo.name}'),
                    etiqueta: tipo.etiqueta,
                    icono: tipo.icono,
                    activo: filtro.tipo == tipo,
                    onPulsar: widget.habilitado
                        ? () => notificador.cambiarTipo(
                            filtro.tipo == tipo ? null : tipo,
                          )
                        : () {},
                  ),
            ],
          ),
        ],
        Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            key: const Key('filtro_muscular'),
            // Se abre solo si ya se estaba filtrando, para que al volver no
            // parezca que faltan ejercicios.
            initiallyExpanded: hayFiltroMuscular,
            tilePadding: EdgeInsets.zero,
            childrenPadding: const EdgeInsets.only(left: 8, bottom: 8),
            leading: const Icon(Icons.filter_alt_outlined, size: 18),
            title: Text('Filtrar por músculo', style: textos.labelLarge),
            subtitle: Text(resumen, style: textos.bodySmall),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: ChipFiltro(
                  key: const Key('musculo_todos'),
                  etiqueta: 'Todos',
                  activo: !hayFiltroMuscular,
                  onPulsar: widget.habilitado
                      ? () => notificador.cambiarGrupo(null)
                      : () {},
                ),
              ),
              const SizedBox(height: 4),
              ListaMusculosPlegable(
                grupos: facetas.grupos,
                musculosDe: facetas.musculosDe,
                habilitado: widget.habilitado,
                resumenDe: facetas.resumenDe,
                seleccionados: {?filtro.musculo},
                onMusculo: (musculo) => notificador.cambiarMusculo(
                  filtro.musculo == musculo ? null : musculo,
                ),
                // El chip "Todo el grupo" solo se ve marcado cuando no hay un
                // musculo concreto elegido: elegirlo fija tambien su grupo.
                grupoSeleccionado: filtro.musculo == null ? filtro.grupo : null,
                // `verTodoElGrupo` y no `cambiarGrupo`: con un musculo elegido,
                // el segundo lo conserva y el chip se quedaba sin marcar.
                onGrupo: (grupo) => notificador.verTodoElGrupo(
                  filtro.grupo == grupo && filtro.musculo == null
                      ? null
                      : grupo,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
