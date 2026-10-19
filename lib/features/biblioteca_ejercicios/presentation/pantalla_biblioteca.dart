import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/componentes.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/core/theme/tokens.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_baja_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_formulario_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/facetas_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/dialogos_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/estilo_tipo_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/widgets/tarjeta_ejercicio.dart';

/// Biblioteca de ejercicios (`docs/ui-design.md`, 6.4).
///
/// Una sola pantalla para los dos roles: el entrenador ve las acciones de alta,
/// edicion y baja (CU-02 a CU-04); el cliente solo consulta. Quien manda de
/// verdad es RLS: aunque se forzara la interfaz, el `insert` de un cliente lo
/// rechaza la politica.
class PantallaBiblioteca extends ConsumerStatefulWidget {
  const PantallaBiblioteca({super.key});

  @override
  ConsumerState<PantallaBiblioteca> createState() => _PantallaBibliotecaState();
}

class _PantallaBibliotecaState extends ConsumerState<PantallaBiblioteca> {
  late final TextEditingController _busqueda;

  @override
  void initState() {
    super.initState();
    // Arranca con lo que el filtro ya tenga: con un controlador vacio, la
    // lista saldria recortada por un texto que no se ve en ninguna parte.
    _busqueda = TextEditingController(
      text: ref.read(filtroBibliotecaProvider(AmbitoDeFiltro.biblioteca)).texto,
    );
  }

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(rolActualProvider);
    final esEntrenador = rol?.esEntrenador ?? false;
    final ejercicios = ref.watch(
      ejerciciosFiltradosProvider(AmbitoDeFiltro.biblioteca),
    );
    // Se observa, aunque no se use su valor aqui, para que el provider siga vivo
    // mientras esta pantalla lo esta: el flujo de baja de CU-04 pasa por dos
    // dialogos y, sin un oyente, Riverpod lo desecharia entre medias.
    ref.watch(controladorBajaEjercicioProvider);

    final cuerpo = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            Tokens.margenPantalla,
            8,
            Tokens.margenPantalla,
            0,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Biblioteca',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 4),
              _Resumen(ejercicios: ejercicios),
              const SizedBox(height: 14),
              CampoBusqueda(
                clave: const Key('campo_busqueda'),
                controlador: _busqueda,
                onCambio: (texto) => ref
                    .read(
                      filtroBibliotecaProvider(AmbitoDeFiltro.biblioteca)
                          .notifier,
                    )
                    .cambiarTexto(texto),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _FiltrosMusculares(mostrarEliminados: esEntrenador),
        const SizedBox(height: 4),
        Expanded(
          child: ejercicios.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _Mensaje(
              icono: Icons.error_outline,
              texto: mensajeDeError(error),
              accion: TextButton(
                onPressed: () => ref.invalidate(bibliotecaEjerciciosProvider),
                child: const Text('Reintentar'),
              ),
            ),
            data: (lista) => lista.isEmpty
                ? _SinResultados(esEntrenador: esEntrenador)
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(
                      Tokens.margenPantalla,
                      8,
                      Tokens.margenPantalla,
                      24,
                    ),
                    itemCount: lista.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, indice) => TarjetaEjercicio(
                      ejercicio: lista[indice],
                      resaltar: ref
                          .watch(
                            filtroBibliotecaProvider(AmbitoDeFiltro.biblioteca),
                          )
                          .musculo,
                      onTap: () => context.go(
                        Rutas.ejercicioDeLaBiblioteca(
                          rol ?? RolUsuario.cliente,
                          lista[indice].id,
                        ),
                      ),
                      onEditar: esEntrenador
                          ? () => abrirFormularioEjercicio(
                              context,
                              ref,
                              ejercicio: lista[indice],
                            )
                          : null,
                      onDarDeBaja: esEntrenador
                          ? () => confirmarBajaEjercicio(
                              context: context,
                              ref: ref,
                              ejercicio: lista[indice],
                            )
                          : null,
                      onReactivar: esEntrenador
                          ? () => reactivarEjercicio(
                              context: context,
                              ref: ref,
                              ejercicio: lista[indice],
                            )
                          : null,
                    ),
                  ),
          ),
        ),
      ],
    );

    final boton = esEntrenador
        ? FloatingActionButton.extended(
            key: const Key('boton_nuevo_ejercicio'),
            onPressed: () => abrirFormularioEjercicio(context, ref),
            icon: const Icon(Icons.add),
            label: const Text('Nuevo'),
          )
        : null;

    // El cliente llega desde su barra inferior; el entrenador, desde la suya.
    if (esEntrenador) {
      return PantallaEntrenador(
        rutaActual: Rutas.bibliotecaEntrenador,
        botonFlotante: boton,
        cuerpo: cuerpo,
      );
    }
    return PantallaCliente(rutaActual: Rutas.bibliotecaCliente, cuerpo: cuerpo);
  }
}

/// Abre el formulario de alta o edicion, reiniciando el controlador para que no
/// arrastre el error ni el "completada" de la vez anterior.
Future<void> abrirFormularioEjercicio(
  BuildContext context,
  WidgetRef ref, {
  Ejercicio? ejercicio,
}) async {
  ref.read(controladorFormularioEjercicioProvider.notifier).reiniciar();
  context.go(
    ejercicio == null
        ? Rutas.nuevoEjercicio()
        : Rutas.editarEjercicio(ejercicio.id),
  );
}

/// "13 ejercicios · 4 con vídeo de ejemplo", contando lo que hay de verdad.
class _Resumen extends StatelessWidget {
  const _Resumen({required this.ejercicios});

  final AsyncValue<List<Ejercicio>> ejercicios;

  @override
  Widget build(BuildContext context) {
    final lista = ejercicios.value;
    if (lista == null) return const SizedBox(height: 18);

    final conVideo = lista.where((e) => e.videoEjemploUrl != null).length;
    return Text(
      [
        '${lista.length} ${lista.length == 1 ? "ejercicio" : "ejercicios"}',
        if (conVideo > 0) '$conVideo con vídeo de ejemplo',
      ].join(' · '),
      style: Theme.of(context).textTheme.bodySmall,
    );
  }
}

/// Filtros de la biblioteca, en tres niveles.
///
/// Arriba los **principales**, excluyentes: Todos, Fuerza, Cardio,
/// Fortalecimiento y, solo para el entrenador, Dados de baja. Es lo primero que
/// se decide al buscar ("un cardio", "algo de fortalecimiento").
///
/// Debajo, **solo con Fuerza o Fortalecimiento**, los grupos musculares; y al
/// elegir uno, sus musculos. El Cardio no se busca por musculo, y en Todos la
/// fila de grupos competia con los tipos por el mismo sitio. Fuerza y
/// Fortalecimiento **comparten** el filtro muscular (ver
/// `FiltroBiblioteca.elegirPestana`): "pecho" sigue elegido al pasar de una a
/// otra.
///
/// Los chips musculares salen de [FacetasBiblioteca], no de la taxonomia
/// completa: un chip que no devuelve nada al pulsarlo es ruido. Descubrir la
/// taxonomia entera es cosa del formulario, que es donde se clasifica.
class _FiltrosMusculares extends ConsumerWidget {
  const _FiltrosMusculares({required this.mostrarEliminados});

  final bool mostrarEliminados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final facetas =
        ref.watch(facetasBibliotecaProvider(AmbitoDeFiltro.biblioteca)).value ??
        FacetasBiblioteca.vacias;
    final filtro = ref.watch(
      filtroBibliotecaProvider(AmbitoDeFiltro.biblioteca),
    );
    final notificador = ref.read(
      filtroBibliotecaProvider(AmbitoDeFiltro.biblioteca).notifier,
    );
    final pestana = filtro.pestana;

    return Column(
      children: [
        _FilaDeChips(
          clave: const Key('fila_filtros_principales'),
          chips: [
            for (final opcion in PestanaBiblioteca.values)
              if (opcion != PestanaBiblioteca.dadosDeBaja || mostrarEliminados)
                ChipFiltro(
                  key: Key(switch (opcion.tipo) {
                    final tipo? => 'tipo_${tipo.name}',
                    null => 'filtro_${opcion.name}',
                  }),
                  etiqueta: opcion.etiqueta,
                  icono: opcion.tipo?.icono,
                  activo: pestana == opcion,
                  onPulsar: () => notificador.elegirPestana(opcion),
                ),
          ],
        ),
        if (pestana.filtraPorMusculo) ...[
          // Aire entre niveles: pegados no se lee que el de abajo depende del
          // de arriba, parecen una sola fila partida.
          const SizedBox(height: 12),
          _FilaDeChips(
            clave: const Key('fila_filtros_grupo'),
            chips: [
              ChipFiltro(
                key: const Key('grupo_todos'),
                etiqueta: 'Todos los músculos',
                activo: filtro.grupo == null && !filtro.soloSinClasificar,
                onPulsar: () => notificador.alternarSinClasificar(solo: false),
              ),
              for (final grupo in facetas.grupos)
                ChipFiltro(
                  key: Key('grupo_${grupo.valorJson}'),
                  etiqueta: grupo.etiqueta,
                  activo: filtro.grupo == grupo,
                  onPulsar: () => notificador.cambiarGrupo(
                    filtro.grupo == grupo ? null : grupo,
                  ),
                ),
              if (facetas.haySinClasificar)
                ChipFiltro(
                  key: const Key('chip_sin_clasificar'),
                  etiqueta: 'Sin clasificar',
                  activo: filtro.soloSinClasificar,
                  onPulsar: () => notificador.alternarSinClasificar(
                    solo: !filtro.soloSinClasificar,
                  ),
                ),
            ],
          ),
          // El tercer nivel solo existe con un grupo elegido, y solo si ese
          // grupo tiene mas de un musculo con ejercicios: ofrecer un unico
          // musculo que ya equivale al grupo no filtra nada.
          if (filtro.grupo case final grupo?
              when facetas.musculosDe(grupo).length > 1) ...[
            const SizedBox(height: 12),
            _FilaDeChips(
              clave: const Key('fila_filtros_musculo'),
              alto: 40,
              chips: [
                ChipFiltro(
                  etiqueta: 'Todo ${grupo.etiqueta.toLowerCase()}',
                  activo: filtro.musculo == null,
                  onPulsar: () => notificador.cambiarMusculo(null),
                ),
                for (final musculo in facetas.musculosDe(grupo))
                  ChipFiltro(
                    key: Key('musculo_${musculo.valorJson}'),
                    etiqueta: musculo.etiqueta,
                    activo: filtro.musculo == musculo,
                    onPulsar: () => notificador.cambiarMusculo(
                      filtro.musculo == musculo ? null : musculo,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// Una fila de chips con desplazamiento horizontal, con el mismo margen que el
/// resto de la pantalla y aire entre chip y chip.
class _FilaDeChips extends StatelessWidget {
  const _FilaDeChips({
    required this.clave,
    required this.chips,
    this.alto = 44,
  });

  final Key clave;
  final List<Widget> chips;
  final double alto;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: alto,
    child: ListView(
      key: clave,
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: Tokens.margenPantalla),
      children: [
        for (final (indice, chip) in chips.indexed) ...[
          if (indice > 0) const SizedBox(width: 8),
          chip,
        ],
      ],
    ),
  );
}

class _SinResultados extends ConsumerWidget {
  const _SinResultados({required this.esEntrenador});

  final bool esEntrenador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(
      filtroBibliotecaProvider(AmbitoDeFiltro.biblioteca),
    );
    final conFiltro = !filtro.estaVacio;

    return _Mensaje(
      icono: Icons.search_off,
      texto: conFiltro
          ? 'Ningún ejercicio coincide con la búsqueda.'
          : esEntrenador
          ? 'La biblioteca está vacía. Añade el primer ejercicio.'
          : 'Tu entrenador todavía no ha añadido ejercicios.',
      accion: conFiltro
          ? TextButton(
              onPressed: () => ref
                  .read(
                    filtroBibliotecaProvider(AmbitoDeFiltro.biblioteca)
                        .notifier,
                  )
                  .limpiar(),
              child: const Text('Quitar filtros'),
            )
          : null,
    );
  }
}

class _Mensaje extends StatelessWidget {
  const _Mensaje({required this.icono, required this.texto, this.accion});

  final IconData icono;
  final String texto;
  final Widget? accion;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 44, color: Tokens.textoTenue),
          const SizedBox(height: 14),
          Text(
            texto,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          if (accion case final boton?) ...[const SizedBox(height: 8), boton],
        ],
      ),
    ),
  );
}
