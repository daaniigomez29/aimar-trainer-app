import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:aimar_trainer_app/core/enrutado/rutas.dart';

import 'package:aimar_trainer_app/features/autenticacion/application/controlador_sesion.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_ficha_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/presentation/dialogos_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/presentation/pantalla_clientes.dart';

/// Ficha completa de un cliente. El entrenador puede editarla y dar de baja.
class PantallaDetalleCliente extends ConsumerWidget {
  const PantallaDetalleCliente({required this.idCliente, super.key});

  final String idCliente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final esEntrenador = ref.watch(rolActualProvider)?.esEntrenador ?? false;
    final ficha = ref.watch(clientePorIdProvider(idCliente));
    ref.watch(controladorBajaClienteProvider);
    ref.watch(controladorFichaClienteProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ficha de cliente'),
        actions: [
          if (esEntrenador && ficha.value != null)
            IconButton(
              tooltip: 'Editar ficha',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => abrirFormularioCliente(
                context,
                ref,
                cliente: ficha.requireValue,
              ),
            ),
        ],
      ),
      body: ficha.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              mensajeDeErrorCliente(error),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (cliente) =>
            _Contenido(cliente: cliente, esEntrenador: esEntrenador),
      ),
    );
  }
}

class _Contenido extends ConsumerWidget {
  const _Contenido({required this.cliente, required this.esEntrenador});

  final Cliente cliente;
  final bool esEntrenador;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final edad = cliente.edadEn(DateTime.now());

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(cliente.nombre, style: textos.headlineSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            Chip(
              avatar: Icon(
                cliente.estado.esActivo
                    ? Icons.check_circle_outline
                    : Icons.block,
                size: 18,
              ),
              label: Text(cliente.estado.etiqueta),
            ),
          ],
        ),
        const Divider(height: 32),
        // Solo para el entrenador: el administrador ve la ficha, pero no el
        // progreso ni el control. Aunque entrara, RLS no le devolveria nada.
        if (esEntrenador) ...[
          Card(
            child: ListTile(
              key: const Key('acceso_plannings'),
              leading: const Icon(Icons.calendar_month),
              title: const Text('Plannings'),
              subtitle: const Text('Planificación semanal e historico'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.go(Rutas.planningsDeCliente(cliente.id)),
            ),
          ),
          Card(
            child: ListTile(
              key: const Key('acceso_progreso'),
              leading: const Icon(Icons.show_chart),
              title: const Text('Progreso'),
              subtitle: const Text('Evolución por ejercicio y medidas'),
              trailing: const Icon(Icons.chevron_right),
              // El nombre viaja en la consulta para que el título siga saliendo
              // al entrar por la URL, donde no hay objeto que pasar.
              onTap: () => context.go(
                Uri(
                  path: Rutas.progresoDeCliente(cliente.id),
                  queryParameters: {'nombre': cliente.nombre},
                ).toString(),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Card(
              child: ListTile(
                key: const Key('acceso_control_semanal'),
                leading: const Icon(Icons.straighten),
                title: const Text('Control semanal'),
                subtitle: const Text(
                  'Medidas, fotos y check-in (solo consulta)',
                ),
                trailing: const Icon(Icons.chevron_right),
                // El entrenador consulta; registrar es del cliente (la ruta
                // entra en modo solo lectura).
                onTap: () => context.go(Rutas.controlDeCliente(cliente.id)),
              ),
            ),
          ),
        ],
        _Dato(etiqueta: 'Correo', valor: cliente.correo),
        if (edad != null) _Dato(etiqueta: 'Edad', valor: '$edad años'),
        if (cliente.alturaCm case final altura?)
          _Dato(etiqueta: 'Altura', valor: '${_sinCerosSobrantes(altura)} cm'),
        if (cliente.pesoInicialKg case final peso?)
          _Dato(
            etiqueta: 'Peso inicial',
            valor: '${_sinCerosSobrantes(peso)} kg',
          ),
        _Dato(
          etiqueta: 'Día de control',
          valor: cliente.diaControlPreferido.etiqueta,
        ),
        _Dato(etiqueta: 'Alta', valor: _comoFecha(cliente.fechaAlta)),
        if (cliente.fechaBaja case final baja?)
          _Dato(etiqueta: 'Baja', valor: _comoFecha(baja)),
        if (cliente.objetivos case final objetivos?) ...[
          const Divider(height: 32),
          Text('Objetivos', style: textos.titleMedium),
          const SizedBox(height: 8),
          Text(objetivos),
        ],
        if (esEntrenador && cliente.estado.esActivo) ...[
          const Divider(height: 32),
          OutlinedButton.icon(
            onPressed: () async {
              await confirmarBajaCliente(
                context: context,
                ref: ref,
                cliente: cliente,
              );
              if (context.mounted) Navigator.of(context).maybePop();
            },
            icon: const Icon(Icons.person_off_outlined),
            label: const Text('Dar de baja'),
          ),
        ],
        if (cliente.estado.estaDeBaja) ...[
          const Divider(height: 32),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Este cliente está de baja: no puede acceder a la aplicación. '
                'Su historico se conserva completo.',
              ),
            ),
          ),
        ],
      ],
    );
  }

  static String _sinCerosSobrantes(double valor) =>
      valor.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');

  static String _comoFecha(DateTime fecha) {
    final local = fecha.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _Dato extends StatelessWidget {
  const _Dato({required this.etiqueta, required this.valor});

  final String etiqueta;
  final String valor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 140,
          child: Text(etiqueta, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(child: Text(valor)),
      ],
    ),
  );
}
