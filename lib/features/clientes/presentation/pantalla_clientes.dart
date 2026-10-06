import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/navegacion.dart';
import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/autenticacion/domain/rol_usuario.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_ficha_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/presentation/dialogos_cliente.dart';

/// Gestion de clientes (CU-17, CU-18, CU-19).
///
/// La ven el entrenador y el administrador. El administrador puede dar de alta y
/// de baja —lo hace la Edge Function con `service_role`—, pero **no** puede
/// consultar las fichas: RLS no le da ninguna politica de lectura sobre
/// `clientes`, asi que su listado llega vacio. Eso es intencionado (minimizacion
/// de datos), y la pantalla lo explica en lugar de parecer un error.
class PantallaClientes extends ConsumerWidget {
  const PantallaClientes({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rol = ref.watch(rolActualProvider);
    final puedeGestionar =
        rol == RolUsuario.entrenador || rol == RolUsuario.administrador;
    final puedeConsultar = rol == RolUsuario.entrenador;
    final clientes = ref.watch(clientesFiltradosProvider);
    // Se observan para que no se desechen durante los dialogos de CU-18 y la
    // navegacion al formulario.
    ref.watch(controladorBajaClienteProvider);
    ref.watch(controladorFichaClienteProvider);

    final barra = AppBar(
      title: const Text('Clientes'),
      actions: [
        IconButton(
          tooltip: 'Recargar',
          icon: const Icon(Icons.refresh),
          onPressed: () => ref.invalidate(listaClientesProvider),
        ),
      ],
    );
    final botonNuevo = puedeGestionar
        ? FloatingActionButton.extended(
            key: const Key('boton_nuevo_cliente'),
            onPressed: () => abrirFormularioCliente(context, ref),
            icon: const Icon(Icons.person_add_alt),
            label: const Text('Nuevo cliente'),
          )
        : null;

    final cuerpo = Column(
      children: [
        if (puedeConsultar) const _Filtros(),
        if (!puedeConsultar)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.privacy_tip_outlined),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Como administrador puedes dar de alta y de baja '
                        'clientes, pero no consultar sus fichas ni sus datos '
                        'de salud.',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const Divider(height: 1),
        Expanded(
          child: clientes.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _Mensaje(
              icono: Icons.error_outline,
              texto: mensajeDeErrorCliente(error),
              accion: TextButton(
                onPressed: () => ref.invalidate(listaClientesProvider),
                child: const Text('Reintentar'),
              ),
            ),
            data: (lista) => lista.isEmpty
                ? _SinResultados(puedeConsultar: puedeConsultar)
                : _Listado(clientes: lista, puedeGestionar: puedeGestionar),
          ),
        ),
      ],
    );

    // El administrador tambien entra aqui, pero su navegacion no es la del
    // entrenador: se queda con la pantalla suelta y vuelve con la flecha.
    if (rol != RolUsuario.entrenador) {
      return Scaffold(
        appBar: barra,
        floatingActionButton: botonNuevo,
        body: cuerpo,
      );
    }

    return PantallaEntrenador(
      rutaActual: Rutas.clientesEntrenador,
      appBar: barra,
      botonFlotante: botonNuevo,
      cuerpo: cuerpo,
    );
  }
}

/// Abre el formulario de alta (sin `cliente`) o de edicion.
Future<void> abrirFormularioCliente(
  BuildContext context,
  WidgetRef ref, {
  Cliente? cliente,
}) async {
  ref.read(controladorFichaClienteProvider.notifier).reiniciar();
  context.go(
    cliente == null ? Rutas.nuevoCliente() : Rutas.editarCliente(cliente.id),
  );
}

class _Listado extends ConsumerWidget {
  const _Listado({required this.clientes, required this.puedeGestionar});

  final List<Cliente> clientes;
  final bool puedeGestionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esquema = Theme.of(context).colorScheme;

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      itemCount: clientes.length,
      itemBuilder: (context, indice) {
        final cliente = clientes[indice];
        final deBaja = cliente.estado.estaDeBaja;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            key: Key('cliente_${cliente.id}'),
            leading: CircleAvatar(
              backgroundColor: deBaja
                  ? esquema.surfaceContainerHighest
                  : esquema.primaryContainer,
              child: Text(
                cliente.nombre.trim().isEmpty
                    ? '?'
                    : cliente.nombre.trim()[0].toUpperCase(),
              ),
            ),
            title: Text(
              cliente.nombre,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                decoration: deBaja ? TextDecoration.lineThrough : null,
                color: deBaja ? esquema.outline : null,
              ),
            ),
            subtitle: Text(
              deBaja ? '${cliente.correo} · De baja' : cliente.correo,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => context.go(Rutas.fichaDeCliente(cliente.id)),
            trailing: puedeGestionar && !deBaja
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: 'Editar ficha',
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: () => abrirFormularioCliente(
                          context,
                          ref,
                          cliente: cliente,
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dar de baja',
                        icon: const Icon(Icons.person_off_outlined),
                        onPressed: () => confirmarBajaCliente(
                          context: context,
                          ref: ref,
                          cliente: cliente,
                        ),
                      ),
                    ],
                  )
                : const Icon(Icons.chevron_right),
          ),
        );
      },
    );
  }
}

class _Filtros extends ConsumerWidget {
  const _Filtros();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filtro = ref.watch(filtroClientesProvider);
    final controlador = ref.read(filtroClientesProvider.notifier);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          TextField(
            key: const Key('campo_busqueda_clientes'),
            onChanged: controlador.cambiarTexto,
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              labelText: 'Buscar por nombre o correo',
              isDense: true,
            ),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: FilterChip(
              label: const Text('Ver dados de baja'),
              selected: filtro.soloBajas,
              onSelected: (solo) => controlador.alternarBajas(solo: solo),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinResultados extends ConsumerWidget {
  const _SinResultados({required this.puedeConsultar});

  final bool puedeConsultar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!puedeConsultar) {
      return const _Mensaje(
        icono: Icons.lock_outline,
        texto: 'No tienes acceso a las fichas de los clientes.',
      );
    }
    final filtro = ref.watch(filtroClientesProvider);
    if (!filtroClientesVacio(filtro)) {
      return _Mensaje(
        icono: Icons.search_off,
        texto: 'Ningún cliente coincide con la búsqueda.',
        accion: TextButton(
          onPressed: ref.read(filtroClientesProvider.notifier).limpiar,
          child: const Text('Quitar filtros'),
        ),
      );
    }
    return const _Mensaje(
      icono: Icons.people_outline,
      texto: 'Todavía no hay clientes. Da de alta al primero.',
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
          Icon(icono, size: 48, color: Theme.of(context).colorScheme.outline),
          const SizedBox(height: 16),
          Text(texto, textAlign: TextAlign.center),
          if (accion != null) ...[const SizedBox(height: 8), accion!],
        ],
      ),
    ),
  );
}
