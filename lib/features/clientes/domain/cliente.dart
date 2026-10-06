import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/clientes/domain/dia_semana.dart';
import 'package:aimar_trainer_app/features/clientes/domain/estado_cliente.dart';

part 'cliente.freezed.dart';
part 'cliente.g.dart';

/// Ficha de cliente (entidad 1 de `docs/domain-model.md`).
///
/// `id` es el mismo uuid que `auth.users.id`: no hay id propio duplicado.
@freezed
abstract class Cliente with _$Cliente {
  const factory Cliente({
    required String id,
    required String nombre,
    required String correo,
    required DiaSemana diaControlPreferido,
    required EstadoCliente estado,
    required DateTime fechaAlta,
    DateTime? fechaNacimiento,
    double? alturaCm,
    double? pesoInicialKg,
    String? objetivos,
    DateTime? fechaBaja,
  }) = _Cliente;

  factory Cliente.fromJson(Map<String, dynamic> json) =>
      _$ClienteFromJson(json);
}

/// Edad en anos cumplidos, o `null` si no se conoce la fecha de nacimiento.
extension EdadDelCliente on Cliente {
  int? edadEn(DateTime referencia) {
    final nacimiento = fechaNacimiento;
    if (nacimiento == null) return null;
    var edad = referencia.year - nacimiento.year;
    final noHaCumplido =
        referencia.month < nacimiento.month ||
        (referencia.month == nacimiento.month &&
            referencia.day < nacimiento.day);
    if (noHaCumplido) edad--;
    return edad < 0 ? null : edad;
  }
}

/// Datos personales y objetivos que introduce quien da de alta o edita la ficha
/// (CU-17 y CU-19).
///
/// No incluye `id`, `estado`, `fechaAlta` ni `fechaBaja`: los gestionan la Edge
/// Function de alta y la de baja.
class DatosCliente {
  const DatosCliente({
    required this.nombre,
    required this.correo,
    required this.diaControlPreferido,
    this.fechaNacimiento,
    this.alturaCm,
    this.pesoInicialKg,
    this.objetivos,
  });

  /// `numeric(5,2)` en Postgres: tres enteros y dos decimales.
  static const double valorMaximoNumerico = 999.99;
  static const int longitudMaximaNombre = 120;
  static const int edadMinima = 14;
  static const int edadMaxima = 100;

  static final RegExp _formatoCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  final String nombre;
  final String correo;
  final DiaSemana diaControlPreferido;
  final DateTime? fechaNacimiento;
  final double? alturaCm;
  final double? pesoInicialKg;
  final String? objetivos;

  String get nombreNormalizado => nombre.trim();
  String get correoNormalizado => correo.trim().toLowerCase();
  String? get objetivosNormalizados {
    final limpio = objetivos?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  static ErrorValidacion? validarNombre(String nombre) {
    final valor = nombre.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion(
        'El nombre es obligatorio.',
        campo: 'nombre',
      );
    }
    if (valor.length > longitudMaximaNombre) {
      return const ErrorValidacion(
        'El nombre no puede pasar de $longitudMaximaNombre caracteres.',
        campo: 'nombre',
      );
    }
    return null;
  }

  static ErrorValidacion? validarCorreo(String correo) {
    final valor = correo.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion(
        'El correo es obligatorio: por ahi se envía la invitación.',
        campo: 'correo',
      );
    }
    if (!_formatoCorreo.hasMatch(valor)) {
      return const ErrorValidacion(
        'El correo no tiene un formato valido.',
        campo: 'correo',
      );
    }
    return null;
  }

  /// La fecha de nacimiento es opcional, pero si se indica debe dar una edad
  /// razonable: una fecha futura o un tecleo imposible no deben llegar a la base
  /// de datos, donde la columna los aceptaria sin mas.
  static ErrorValidacion? validarFechaNacimiento(
    DateTime? fecha, {
    DateTime? hoy,
  }) {
    if (fecha == null) return null;
    final referencia = hoy ?? DateTime.now();
    if (fecha.isAfter(referencia)) {
      return const ErrorValidacion(
        'La fecha de nacimiento no puede estar en el futuro.',
        campo: 'fechaNacimiento',
      );
    }
    var edad = referencia.year - fecha.year;
    if (referencia.month < fecha.month ||
        (referencia.month == fecha.month && referencia.day < fecha.day)) {
      edad--;
    }
    if (edad < edadMinima) {
      return const ErrorValidacion(
        'El cliente debe tener al menos $edadMinima anos.',
        campo: 'fechaNacimiento',
      );
    }
    if (edad > edadMaxima) {
      return const ErrorValidacion(
        'Revisa la fecha: sale una edad de mas de $edadMaxima anos.',
        campo: 'fechaNacimiento',
      );
    }
    return null;
  }

  /// `numeric(5,2)` desborda por encima de 999.99 y la Edge Function devolveria
  /// un 500 por "numeric field overflow": se corta aqui con un mensaje util.
  static ErrorValidacion? validarMedida(
    double? valor, {
    required String campo,
    required String etiqueta,
  }) {
    if (valor == null) return null;
    if (valor <= 0) {
      return ErrorValidacion(
        '$etiqueta debe ser mayor que cero.',
        campo: campo,
      );
    }
    if (valor > valorMaximoNumerico) {
      return ErrorValidacion(
        '$etiqueta no puede pasar de $valorMaximoNumerico.',
        campo: campo,
      );
    }
    return null;
  }

  ErrorValidacion? validar({DateTime? hoy}) =>
      validarNombre(nombre) ??
      validarCorreo(correo) ??
      validarFechaNacimiento(fechaNacimiento, hoy: hoy) ??
      validarMedida(alturaCm, campo: 'alturaCm', etiqueta: 'La altura') ??
      validarMedida(
        pesoInicialKg,
        campo: 'pesoInicialKg',
        etiqueta: 'El peso inicial',
      );

  /// Cuerpo para la Edge Function `crear-cliente`, con las claves exactas del
  /// contrato de `docs/architecture.md` (camelCase, no snake_case: es el contrato
  /// de la funcion, no una fila de tabla).
  Map<String, dynamic> aJsonDeAlta() => {
    'nombre': nombreNormalizado,
    'correo': correoNormalizado,
    'fechaNacimiento': _soloFecha(fechaNacimiento),
    'alturaCm': alturaCm,
    'pesoInicialKg': pesoInicialKg,
    'objetivos': objetivosNormalizados,
    'diaControlPreferido': diaControlPreferido.name,
  };

  /// Cuerpo para el `update` de la tabla `clientes` (CU-19). Aqui si va en
  /// `snake_case`, porque son columnas.
  ///
  /// El correo no se incluye: cambiarlo dejaria la ficha desalineada con la
  /// cuenta de Auth, que es la que recibe la invitacion y la recuperacion de
  /// contrasena.
  Map<String, dynamic> aJsonDeEdicion() => {
    'nombre': nombreNormalizado,
    'fecha_nacimiento': _soloFecha(fechaNacimiento),
    'altura_cm': alturaCm,
    'peso_inicial_kg': pesoInicialKg,
    'objetivos': objetivosNormalizados,
    'dia_control_preferido': diaControlPreferido.name,
  };

  static String? _soloFecha(DateTime? fecha) => fecha == null
      ? null
      : '${fecha.year.toString().padLeft(4, '0')}-'
            '${fecha.month.toString().padLeft(2, '0')}-'
            '${fecha.day.toString().padLeft(2, '0')}';

  factory DatosCliente.desdeCliente(Cliente cliente) => DatosCliente(
    nombre: cliente.nombre,
    correo: cliente.correo,
    diaControlPreferido: cliente.diaControlPreferido,
    fechaNacimiento: cliente.fechaNacimiento,
    alturaCm: cliente.alturaCm,
    pesoInicialKg: cliente.pesoInicialKg,
    objetivos: cliente.objetivos,
  );
}
