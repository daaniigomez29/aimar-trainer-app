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
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/presentation/dialogos_ejercicio.dart';
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
  final _busqueda = TextEditingController();

  @override
  void dispose() {
    _busqueda.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rol = ref.watch(rolActualProvider);
    final esEntrenador = rol?.esEntrenador ?? false;
    final ejercicios = ref.watch(ejerciciosFiltradosProvider);
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
                    .read(filtroBibliotecaProvider.notifier)
                    .cambiarTexto(texto),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _ChipsDeGrupo(mostrarEliminados: esEntrenador),
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

/// Chips de grupo muscular. Salen de los datos, no de una lista fija: el grupo
/// es texto libre en la entidad, asi que la unica fuente fiable es la biblioteca.
class _ChipsDeGrupo extends ConsumerWidget {
  const _ChipsDeGrupo({required this.mostrarEliminados});

  final bool mostrarEliminados;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final grupos =
        ref.watch(gruposMuscularesProvider).value ?? const <String>[];
    final filtro = ref.watch(filtroBibliotecaProvider);
    final notificador = ref.read(filtroBibliotecaProvider.notifier);

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: Tokens.margenPantalla),
        children: [
          ChipFiltro(
            etiqueta: 'Todos',
            activo: filtro.grupoMuscular == null,
            onPulsar: () => notificador.cambiarGrupoMuscular(null),
          ),
          for (final grupo in grupos) ...[
            const SizedBox(width: 8),
            ChipFiltro(
              etiqueta: grupo,
              activo: filtro.grupoMuscular == grupo,
              onPulsar: () => notificador.cambiarGrupoMuscular(
                filtro.grupoMuscular == grupo ? null : grupo,
              ),
            ),
          ],
          if (mostrarEliminados) ...[
            const SizedBox(width: 8),
            ChipFiltro(
              etiqueta: 'Dados de baja',
              activo: filtro.soloEliminados,
              onPulsar: () =>
                  notificador.alternarEliminados(solo: !filtro.soloEliminados),
            ),
          ],
          const SizedBox(width: Tokens.margenPantalla),
        ],
      ),
    );
  }
}

class _SinResultados extends ConsumerWidget {
  const _SinResultados({required this.esEntrenador});

  final bool esEntrenador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroBibliotecaProvider);
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
              onPressed: () =>
                  ref.read(filtroBibliotecaProvider.notifier).limpiar(),
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
