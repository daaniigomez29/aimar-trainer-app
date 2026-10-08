import 'package:flutter/material.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/avisos.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/core/presentacion/widgets/pantalla_con_navegacion.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/core/presentacion/widgets/formulario_centrado.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_ficha_cliente.dart';
import 'package:aimar_trainer_app/features/clientes/application/controlador_clientes.dart';
import 'package:aimar_trainer_app/features/clientes/domain/cliente.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';

/// CU-17 (alta) y CU-19 (editar ficha).
///
/// Igual que el formulario de ejercicio: acepta la ficha ya cargada o su `id`
/// cuando se llega por la URL.
class PantallaFormularioCliente extends ConsumerWidget {
  const PantallaFormularioCliente({this.cliente, this.idCliente, super.key});

  final Cliente? cliente;
  final String? idCliente;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (idCliente == null || cliente != null) {
      return _FormularioCliente(cliente: cliente);
    }

    return ref
        .watch(clientePorIdProvider(idCliente!))
        .when(
          data: (c) => _FormularioCliente(cliente: c),
          loading: () =>
              const Scaffold(body: Center(child: CircularProgressIndicator())),
          error: (error, _) => Scaffold(
            appBar: AppBar(),
            body: Center(child: Text(mensajeDeErrorCliente(error))),
          ),
        );
  }
}

class _FormularioCliente extends ConsumerStatefulWidget {
  const _FormularioCliente({this.cliente});

  final Cliente? cliente;

  bool get esEdicion => cliente != null;

  @override
  ConsumerState<_FormularioCliente> createState() =>
      _EstadoPantallaFormularioCliente();
}

class _EstadoPantallaFormularioCliente
    extends ConsumerState<_FormularioCliente> {
  late final TextEditingController _nombre;
  late final TextEditingController _correo;
  late final TextEditingController _altura;
  late final TextEditingController _peso;
  late final TextEditingController _objetivos;
  late DiaSemana _diaControl;
  DateTime? _fechaNacimiento;

  @override
  void initState() {
    super.initState();
    final c = widget.cliente;
    _nombre = TextEditingController(text: c?.nombre ?? '');
    _correo = TextEditingController(text: c?.correo ?? '');
    _altura = TextEditingController(text: _comoTexto(c?.alturaCm));
    _peso = TextEditingController(text: _comoTexto(c?.pesoInicialKg));
    _objetivos = TextEditingController(text: c?.objetivos ?? '');
    _diaControl = c?.diaControlPreferido ?? DiaSemana.domingo;
    _fechaNacimiento = c?.fechaNacimiento;
  }

  static String _comoTexto(double? valor) =>
      valor == null ? '' : valor.toStringAsFixed(2).replaceFirst('.00', '');

  @override
  void dispose() {
    _nombre.dispose();
    _correo.dispose();
    _altura.dispose();
    _peso.dispose();
    _objetivos.dispose();
    super.dispose();
  }

  /// La coma se acepta como separador decimal: es lo natural al teclear en
  /// español, y `double.tryParse` solo entiende el punto.
  static double? _comoNumero(String texto) {
    final limpio = texto.trim().replaceAll(',', '.');
    return limpio.isEmpty ? null : double.tryParse(limpio);
  }

  DatosCliente get _datos => DatosCliente(
    nombre: _nombre.text,
    correo: _correo.text,
    diaControlPreferido: _diaControl,
    fechaNacimiento: _fechaNacimiento,
    alturaCm: _comoNumero(_altura.text),
    pesoInicialKg: _comoNumero(_peso.text),
    objetivos: _objetivos.text,
  );

  Future<void> _elegirFecha() async {
    final hoy = DateTime.now();
    final elegida = await showDatePicker(
      context: context,
      initialDate:
          _fechaNacimiento ?? DateTime(hoy.year - 30, hoy.month, hoy.day),
      firstDate: DateTime(hoy.year - DatosCliente.edadMaxima),
      lastDate: DateTime(
        hoy.year - DatosCliente.edadMinima,
        hoy.month,
        hoy.day,
      ),
      helpText: 'Fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (elegida != null) setState(() => _fechaNacimiento = elegida);
  }

  Future<void> _guardar() async {
    final controlador = ref.read(controladorFichaClienteProvider.notifier);
    final cliente = widget.cliente;

    if (cliente == null) {
      final resultado = await controlador.darDeAlta(_datos);
      if (!mounted) return;
      switch (resultado) {
        case Success(:final valor):
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                valor.invitacionEnviada
                    ? 'Cliente dado de alta. Invitación enviada por correo.'
                    : 'Cliente dado de alta, pero la invitación no ha salido: '
                          '${valor.avisoInvitacion ?? "revisa la configuración de correo"}',
              ),
              // El caso de error dura más: lleva un aviso que hay que leer.
              duration: valor.invitacionEnviada
                  ? Avisos.duracion
                  : Avisos.duracionConAccion,
            ),
          );
        case Failure():
          // El motivo ya esta en el estado y se pinta en el formulario.
          break;
      }
      return;
    }

    final resultado = await controlador.editar(id: cliente.id, datos: _datos);
    if (!mounted) return;
    if (resultado.esExito) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: Avisos.duracion,
          content: Text('Ficha actualizada.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(controladorFichaClienteProvider);
    final controlador = ref.read(controladorFichaClienteProvider.notifier);
    final fecha = _fechaNacimiento;

    return FormularioCentrado(
      seccion: SeccionDeNavegacion.clientes,
      titulo: widget.esEdicion ? 'Editar ficha' : 'Nuevo cliente',
      subtitulo: widget.esEdicion
          ? null
          : 'Se creara su cuenta y recibira una invitación por correo.',
      hijos: [
        if (estado.errorGeneral case final mensaje?) ...[
          AvisoEnLinea(mensaje: mensaje),
          const SizedBox(height: 16),
        ],
        TextField(
          key: const Key('campo_nombre_cliente'),
          controller: _nombre,
          enabled: !estado.enCurso,
          textCapitalization: TextCapitalization.words,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Nombre completo *',
            errorText: estado.errorDelCampo('nombre'),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_correo_cliente'),
          controller: _correo,
          // El correo identifica la cuenta de Auth: cambiarlo dejaria la ficha
          // desalineada con el acceso, asi que en edicion es de solo lectura.
          enabled: !estado.enCurso && !widget.esEdicion,
          keyboardType: TextInputType.emailAddress,
          onChanged: (_) => controlador.limpiarError(),
          decoration: InputDecoration(
            labelText: 'Correo *',
            errorText: estado.errorDelCampo('correo'),
            helperText: widget.esEdicion
                ? 'El correo no se puede cambiar: es su usuario de acceso.'
                : 'A esta dirección se envía la invitación.',
          ),
        ),
        const SizedBox(height: 16),
        _SelectorFecha(
          key: const Key('selector_fecha_nacimiento'),
          fecha: fecha,
          habilitado: !estado.enCurso,
          error: estado.errorDelCampo('fechaNacimiento'),
          onElegir: _elegirFecha,
          onBorrar: () => setState(() => _fechaNacimiento = null),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                key: const Key('campo_altura'),
                controller: _altura,
                enabled: !estado.enCurso,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => controlador.limpiarError(),
                decoration: InputDecoration(
                  labelText: 'Altura (cm)',
                  errorText: estado.errorDelCampo('alturaCm'),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                key: const Key('campo_peso'),
                controller: _peso,
                enabled: !estado.enCurso,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                ],
                onChanged: (_) => controlador.limpiarError(),
                decoration: InputDecoration(
                  labelText: 'Peso inicial (kg)',
                  errorText: estado.errorDelCampo('pesoInicialKg'),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        DropdownButtonFormField<DiaSemana>(
          key: const Key('selector_dia_control'),
          initialValue: _diaControl,
          decoration: const InputDecoration(
            labelText: 'Día de control preferido',
            helperText:
                'Día en que se le recordara registrar medidas y check-in.',
          ),
          items: [
            for (final dia in DiaSemana.values)
              DropdownMenuItem(value: dia, child: Text(dia.etiqueta)),
          ],
          onChanged: estado.enCurso
              ? null
              : (dia) => setState(() => _diaControl = dia ?? _diaControl),
        ),
        const SizedBox(height: 16),
        TextField(
          key: const Key('campo_objetivos'),
          controller: _objetivos,
          enabled: !estado.enCurso,
          minLines: 2,
          maxLines: 5,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Objetivos',
            helperText: 'Opcional.',
            alignLabelWithHint: true,
          ),
        ),
        const SizedBox(height: 24),
        FilledButton(
          key: const Key('boton_guardar_cliente'),
          onPressed: estado.enCurso ? null : _guardar,
          child: estado.enCurso
              ? const SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(widget.esEdicion ? 'Guardar cambios' : 'Dar de alta'),
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: estado.enCurso ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
      ],
    );
  }
}

class _SelectorFecha extends StatelessWidget {
  const _SelectorFecha({
    required this.fecha,
    required this.habilitado,
    required this.onElegir,
    required this.onBorrar,
    this.error,
    super.key,
  });

  final DateTime? fecha;
  final bool habilitado;
  final String? error;
  final VoidCallback onElegir;
  final VoidCallback onBorrar;

  @override
  Widget build(BuildContext context) => InputDecorator(
    decoration: InputDecoration(
      labelText: 'Fecha de nacimiento',
      helperText: 'Opcional.',
      errorText: error,
      border: const OutlineInputBorder(),
    ),
    child: Row(
      children: [
        Expanded(
          child: Text(
            fecha == null
                ? 'Sin indicar'
                : '${fecha!.day.toString().padLeft(2, '0')}/'
                      '${fecha!.month.toString().padLeft(2, '0')}/'
                      '${fecha!.year}',
          ),
        ),
        if (fecha != null)
          IconButton(
            tooltip: 'Quitar fecha',
            icon: const Icon(Icons.clear, size: 18),
            onPressed: habilitado ? onBorrar : null,
          ),
        IconButton(
          tooltip: 'Elegir fecha',
          icon: const Icon(Icons.calendar_today, size: 18),
          onPressed: habilitado ? onElegir : null,
        ),
      ],
    ),
  );
}
