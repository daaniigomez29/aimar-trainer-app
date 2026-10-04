// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_progreso.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Ejercicios con algo registrado, para el desplegable del filtro (CU-21).

@ProviderFor(ejerciciosConRegistro)
final ejerciciosConRegistroProvider = EjerciciosConRegistroFamily._();

/// Ejercicios con algo registrado, para el desplegable del filtro (CU-21).

final class EjerciciosConRegistroProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<EjercicioConRegistro>>,
          List<EjercicioConRegistro>,
          FutureOr<List<EjercicioConRegistro>>
        >
    with
        $FutureModifier<List<EjercicioConRegistro>>,
        $FutureProvider<List<EjercicioConRegistro>> {
  /// Ejercicios con algo registrado, para el desplegable del filtro (CU-21).
  EjerciciosConRegistroProvider._({
    required EjerciciosConRegistroFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ejerciciosConRegistroProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ejerciciosConRegistroHash();

  @override
  String toString() {
    return r'ejerciciosConRegistroProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<EjercicioConRegistro>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<EjercicioConRegistro>> create(Ref ref) {
    final argument = this.argument as String;
    return ejerciciosConRegistro(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EjerciciosConRegistroProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ejerciciosConRegistroHash() =>
    r'a5aed15864c6770599f6a6f21631c7ca7d8334e3';

/// Ejercicios con algo registrado, para el desplegable del filtro (CU-21).

final class EjerciciosConRegistroFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<EjercicioConRegistro>>,
          String
        > {
  EjerciciosConRegistroFamily._()
    : super(
        retry: null,
        name: r'ejerciciosConRegistroProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Ejercicios con algo registrado, para el desplegable del filtro (CU-21).

  EjerciciosConRegistroProvider call(String clienteId) =>
      EjerciciosConRegistroProvider._(argument: clienteId, from: this);

  @override
  String toString() => r'ejerciciosConRegistroProvider';
}

/// Lo registrado de un ejercicio en un rango de fechas, sin resumir.
///
/// El rango viaja como dos fechas sueltas y no como [RangoFechas] porque los
/// parametros de un provider se comparan por igualdad, y `DateTime` la tiene por
/// valor mientras que una clase propia necesitaria implementarla.

@ProviderFor(progresoDeEjercicio)
final progresoDeEjercicioProvider = ProgresoDeEjercicioFamily._();

/// Lo registrado de un ejercicio en un rango de fechas, sin resumir.
///
/// El rango viaja como dos fechas sueltas y no como [RangoFechas] porque los
/// parametros de un provider se comparan por igualdad, y `DateTime` la tiene por
/// valor mientras que una clase propia necesitaria implementarla.

final class ProgresoDeEjercicioProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RegistroProgreso>>,
          List<RegistroProgreso>,
          FutureOr<List<RegistroProgreso>>
        >
    with
        $FutureModifier<List<RegistroProgreso>>,
        $FutureProvider<List<RegistroProgreso>> {
  /// Lo registrado de un ejercicio en un rango de fechas, sin resumir.
  ///
  /// El rango viaja como dos fechas sueltas y no como [RangoFechas] porque los
  /// parametros de un provider se comparan por igualdad, y `DateTime` la tiene por
  /// valor mientras que una clase propia necesitaria implementarla.
  ProgresoDeEjercicioProvider._({
    required ProgresoDeEjercicioFamily super.from,
    required (String, String, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'progresoDeEjercicioProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$progresoDeEjercicioHash();

  @override
  String toString() {
    return r'progresoDeEjercicioProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<RegistroProgreso>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RegistroProgreso>> create(Ref ref) {
    final argument = this.argument as (String, String, DateTime, DateTime);
    return progresoDeEjercicio(
      ref,
      argument.$1,
      argument.$2,
      argument.$3,
      argument.$4,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ProgresoDeEjercicioProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$progresoDeEjercicioHash() =>
    r'12bdc579c7de8dfe51e269fd1244d2ed4a8cb40c';

/// Lo registrado de un ejercicio en un rango de fechas, sin resumir.
///
/// El rango viaja como dos fechas sueltas y no como [RangoFechas] porque los
/// parametros de un provider se comparan por igualdad, y `DateTime` la tiene por
/// valor mientras que una clase propia necesitaria implementarla.

final class ProgresoDeEjercicioFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<RegistroProgreso>>,
          (String, String, DateTime, DateTime)
        > {
  ProgresoDeEjercicioFamily._()
    : super(
        retry: null,
        name: r'progresoDeEjercicioProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Lo registrado de un ejercicio en un rango de fechas, sin resumir.
  ///
  /// El rango viaja como dos fechas sueltas y no como [RangoFechas] porque los
  /// parametros de un provider se comparan por igualdad, y `DateTime` la tiene por
  /// valor mientras que una clase propia necesitaria implementarla.

  ProgresoDeEjercicioProvider call(
    String clienteId,
    String ejercicioId,
    DateTime desde,
    DateTime hasta,
  ) => ProgresoDeEjercicioProvider._(
    argument: (clienteId, ejercicioId, desde, hasta),
    from: this,
  );

  @override
  String toString() => r'progresoDeEjercicioProvider';
}

/// Medidas corporales del rango, para la otra mitad de CU-21.

@ProviderFor(medidasEnRango)
final medidasEnRangoProvider = MedidasEnRangoFamily._();

/// Medidas corporales del rango, para la otra mitad de CU-21.

final class MedidasEnRangoProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RegistroMedidas>>,
          List<RegistroMedidas>,
          FutureOr<List<RegistroMedidas>>
        >
    with
        $FutureModifier<List<RegistroMedidas>>,
        $FutureProvider<List<RegistroMedidas>> {
  /// Medidas corporales del rango, para la otra mitad de CU-21.
  MedidasEnRangoProvider._({
    required MedidasEnRangoFamily super.from,
    required (String, DateTime, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'medidasEnRangoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$medidasEnRangoHash();

  @override
  String toString() {
    return r'medidasEnRangoProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<List<RegistroMedidas>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RegistroMedidas>> create(Ref ref) {
    final argument = this.argument as (String, DateTime, DateTime);
    return medidasEnRango(ref, argument.$1, argument.$2, argument.$3);
  }

  @override
  bool operator ==(Object other) {
    return other is MedidasEnRangoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$medidasEnRangoHash() => r'36ef32271a194b63f293ead39ffd15940e3e9dfc';

/// Medidas corporales del rango, para la otra mitad de CU-21.

final class MedidasEnRangoFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<List<RegistroMedidas>>,
          (String, DateTime, DateTime)
        > {
  MedidasEnRangoFamily._()
    : super(
        retry: null,
        name: r'medidasEnRangoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Medidas corporales del rango, para la otra mitad de CU-21.

  MedidasEnRangoProvider call(
    String clienteId,
    DateTime desde,
    DateTime hasta,
  ) =>
      MedidasEnRangoProvider._(argument: (clienteId, desde, hasta), from: this);

  @override
  String toString() => r'medidasEnRangoProvider';
}
