import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:aimar_trainer_app/features/progreso/application/controlador_control_semanal.dart';
import 'package:aimar_trainer_app/features/progreso/domain/datos_progreso.dart';
import 'package:aimar_trainer_app/features/progreso/domain/medidas.dart';

/// Formulario de medidas corporales de un dia, con sus fotos.
///
/// Guarda por su cuenta: no comparte boton ni transaccion con el check-in.
class FormularioMedidas extends ConsumerStatefulWidget {
  const FormularioMedidas({
    required this.clienteId,
    required this.fecha,
    required this.soloLectura,
    super.key,
  });

  final String clienteId;
  final DateTime fecha;
  final bool soloLectura;

  @override
  ConsumerState<FormularioMedidas> createState() => _FormularioMedidasState();
}

class _FormularioMedidasState extends ConsumerState<FormularioMedidas> {
  final _peso = TextEditingController();
  final _pecho = TextEditingController();
  final _cintura = TextEditingController();
  final _cadera = TextEditingController();
  final _cuadriceps = TextEditingController();
  final _brazos = TextEditingController();

  /// De que registro se rellenaron los campos, para no pisar lo que el usuario
  /// este escribiendo cada vez que el provider emite.
  String? _idCargado;
  DateTime? _fechaCargada;

  @override
  void dispose() {
    _peso.dispose();
    _pecho.dispose();
    _cintura.dispose();
    _cadera.dispose();
    _cuadriceps.dispose();
    _brazos.dispose();
    super.dispose();
  }

  void _volcar(RegistroMedidas? registro) {
    _idCargado = registro?.id;
    _fechaCargada = widget.fecha;
    _peso.text = registro == null ? '' : _numero(registro.pesoKg);
    _pecho.text = _opcional(registro?.pechoCm);
    _cintura.text = _opcional(registro?.cinturaCm);
    _cadera.text = _opcional(registro?.caderaCm);
    _cuadriceps.text = _opcional(registro?.cuadricepsCm);
    _brazos.text = _opcional(registro?.brazosCm);
  }

  Future<void> _guardar() async {
    final datos = DatosRegistroMedidas(
      clienteId: widget.clienteId,
      fecha: widget.fecha,
      pesoKg: _comoDouble(_peso.text),
      pechoCm: _comoDouble(_pecho.text),
      cinturaCm: _comoDouble(_cintura.text),
      caderaCm: _comoDouble(_cadera.text),
      cuadricepsCm: _comoDouble(_cuadriceps.text),
      brazosCm: _comoDouble(_brazos.text),
    );

    final resultado = await ref
        .read(controladorControlSemanalProvider.notifier)
        .guardarMedidas(datos);
    if (!mounted || resultado.esFallo) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Medidas guardadas.')));
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final estado = ref.watch(controladorControlSemanalProvider);
    final registro = ref.watch(
      medidasDelDiaProvider(widget.clienteId, widget.fecha),
    );

    // Se vuelca una sola vez por registro y fecha: si se hiciera en cada build,
    // el texto que el usuario esta escribiendo se perderia.
    final cargado = registro.value;
    if (_fechaCargada != widget.fecha || _idCargado != cargado?.id) {
      _volcar(cargado);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.straighten),
            const SizedBox(width: 8),
            Text('Medidas corporales', style: textos.titleMedium),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Solo el peso es obligatorio. Deja en blanco lo que no te hayas medido.',
          style: textos.bodySmall,
        ),
        const SizedBox(height: 12),
        _Campo(
          etiqueta: 'Peso',
          unidad: 'kg',
          controlador: _peso,
          error: estado.errorDelCampo('pesoKg'),
          habilitado: !widget.soloLectura,
        ),
        _Campo(
          etiqueta: 'Pecho',
          unidad: 'cm',
          controlador: _pecho,
          error: estado.errorDelCampo('pechoCm'),
          habilitado: !widget.soloLectura,
        ),
        _Campo(
          etiqueta: 'Cintura',
          unidad: 'cm',
          controlador: _cintura,
          error: estado.errorDelCampo('cinturaCm'),
          habilitado: !widget.soloLectura,
        ),
        _Campo(
          etiqueta: 'Cadera',
          unidad: 'cm',
          controlador: _cadera,
          error: estado.errorDelCampo('caderaCm'),
          habilitado: !widget.soloLectura,
        ),
        _Campo(
          etiqueta: 'Cuadriceps',
          unidad: 'cm',
          controlador: _cuadriceps,
          error: estado.errorDelCampo('cuadricepsCm'),
          habilitado: !widget.soloLectura,
        ),
        _Campo(
          etiqueta: 'Brazos',
          unidad: 'cm',
          controlador: _brazos,
          error: estado.errorDelCampo('brazosCm'),
          habilitado: !widget.soloLectura,
        ),
        if (!widget.soloLectura) ...[
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton(
              key: const Key('boton_guardar_medidas'),
              onPressed: estado.enCurso ? null : _guardar,
              child: const Text('Guardar medidas'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        _Fotos(
          clienteId: widget.clienteId,
          registro: cargado,
          soloLectura: widget.soloLectura,
        ),
      ],
    );
  }

  static String _opcional(double? valor) => valor == null ? '' : _numero(valor);

  static double? _comoDouble(String texto) =>
      double.tryParse(texto.trim().replaceAll(',', '.'));
}

/// Las fotos del registro. Solo tienen sentido con un registro ya guardado: la
/// foto cuelga de el (`fotos_progreso.registro_medidas_id`).
class _Fotos extends ConsumerWidget {
  const _Fotos({
    required this.clienteId,
    required this.registro,
    required this.soloLectura,
  });

  final String clienteId;
  final RegistroMedidas? registro;
  final bool soloLectura;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final actual = registro;
    final estado = ref.watch(controladorControlSemanalProvider);

    if (actual == null) {
      return Text(
        'Guarda las medidas de este dia para poder anadirle fotos.',
        style: textos.bodySmall,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Fotos de progreso', style: textos.titleSmall),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final foto in actual.fotos)
              _Miniatura(
                foto: foto,
                onEliminar: soloLectura
                    ? null
                    : () => ref
                          .read(controladorControlSemanalProvider.notifier)
                          .eliminarFoto(
                            clienteId: clienteId,
                            registro: actual,
                            foto: foto,
                          ),
              ),
            if (!soloLectura)
              SizedBox(
                width: 120,
                height: 120,
                child: OutlinedButton(
                  key: const Key('boton_anadir_foto'),
                  onPressed: estado.enCurso
                      ? null
                      : () async {
                          final resultado = await ref
                              .read(controladorControlSemanalProvider.notifier)
                              .anadirFoto(
                                clienteId: clienteId,
                                registro: actual,
                              );
                          if (!context.mounted) return;
                          if (resultado.errorONulo case final error?) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(error.mensaje)),
                            );
                          }
                        },
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo_outlined),
                      SizedBox(height: 4),
                      Text('Anadir foto', textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Las fotos se guardan en privado: solo las veis tu y tu entrenador.',
          style: textos.bodySmall,
        ),
      ],
    );
  }
}

/// La foto se pide con una URL firmada que caduca: el bucket es privado y no hay
/// enlace permanente que poner en un `Image.network`.
class _Miniatura extends ConsumerWidget {
  const _Miniatura({required this.foto, required this.onEliminar});

  final FotoProgreso foto;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final url = ref.watch(urlDeFotoProvider(foto));

    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        fit: StackFit.expand,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: url.when(
              loading: () => const Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
              error: (_, _) => const Center(child: Icon(Icons.broken_image)),
              data: (uri) => Image.network(uri.toString(), fit: BoxFit.cover),
            ),
          ),
          if (onEliminar != null)
            Align(
              alignment: Alignment.topRight,
              child: IconButton.filledTonal(
                key: Key('eliminar_foto_${foto.id}'),
                tooltip: 'Quitar foto',
                visualDensity: VisualDensity.compact,
                icon: const Icon(Icons.close, size: 16),
                onPressed: onEliminar,
              ),
            ),
        ],
      ),
    );
  }
}

class _Campo extends StatelessWidget {
  const _Campo({
    required this.etiqueta,
    required this.unidad,
    required this.controlador,
    required this.error,
    required this.habilitado,
  });

  final String etiqueta;
  final String unidad;
  final TextEditingController controlador;
  final String? error;
  final bool habilitado;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: TextField(
      key: Key('medida_${etiqueta.toLowerCase()}'),
      controller: controlador,
      enabled: habilitado,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: etiqueta,
        suffixText: unidad,
        errorText: error,
        isDense: true,
      ),
    ),
  );
}

String _numero(double valor) => valor == valor.roundToDouble()
    ? valor.toStringAsFixed(0)
    : valor.toStringAsFixed(1);
