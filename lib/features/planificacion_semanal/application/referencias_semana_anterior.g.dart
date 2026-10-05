// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'referencias_semana_anterior.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Lo que el cliente hizo la ultima vez en cada ejercicio del Dia [orden], para
/// que el entrenador planifique mirandolo.
///
/// Dos fuentes, en este orden:
///  1. El Dia [orden] del planning inmediatamente anterior. Es la referencia
///     buena: misma sesion, una semana antes.
///  2. Para lo que no aparezca ahi (ejercicio nuevo ese dia, o esa semana no lo
///     hizo), lo ultimo que haya registrado de ese ejercicio, venga de cuando
///     venga. Queda marcado como `esSemanaAnterior: false` para que la pantalla
///     avise con la fecha.
///
/// Si algo falla, devuelve lo que tenga en vez de propagar el error: esto es una
/// ayuda, y quedarse sin planificar porque el historico no carga seria peor que
/// no verlo.

@ProviderFor(referenciasDeSesion)
final referenciasDeSesionProvider = ReferenciasDeSesionFamily._();

/// Lo que el cliente hizo la ultima vez en cada ejercicio del Dia [orden], para
/// que el entrenador planifique mirandolo.
///
/// Dos fuentes, en este orden:
///  1. El Dia [orden] del planning inmediatamente anterior. Es la referencia
///     buena: misma sesion, una semana antes.
///  2. Para lo que no aparezca ahi (ejercicio nuevo ese dia, o esa semana no lo
///     hizo), lo ultimo que haya registrado de ese ejercicio, venga de cuando
///     venga. Queda marcado como `esSemanaAnterior: false` para que la pantalla
///     avise con la fecha.
///
/// Si algo falla, devuelve lo que tenga en vez de propagar el error: esto es una
/// ayuda, y quedarse sin planificar porque el historico no carga seria peor que
/// no verlo.

final class ReferenciasDeSesionProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<String, ReferenciaAnterior>>,
          Map<String, ReferenciaAnterior>,
          FutureOr<Map<String, ReferenciaAnterior>>
        >
    with
        $FutureModifier<Map<String, ReferenciaAnterior>>,
        $FutureProvider<Map<String, ReferenciaAnterior>> {
  /// Lo que el cliente hizo la ultima vez en cada ejercicio del Dia [orden], para
  /// que el entrenador planifique mirandolo.
  ///
  /// Dos fuentes, en este orden:
  ///  1. El Dia [orden] del planning inmediatamente anterior. Es la referencia
  ///     buena: misma sesion, una semana antes.
  ///  2. Para lo que no aparezca ahi (ejercicio nuevo ese dia, o esa semana no lo
  ///     hizo), lo ultimo que haya registrado de ese ejercicio, venga de cuando
  ///     venga. Queda marcado como `esSemanaAnterior: false` para que la pantalla
  ///     avise con la fecha.
  ///
  /// Si algo falla, devuelve lo que tenga en vez de propagar el error: esto es una
  /// ayuda, y quedarse sin planificar porque el historico no carga seria peor que
  /// no verlo.
  ReferenciasDeSesionProvider._({
    required ReferenciasDeSesionFamily super.from,
    required (String, int) super.argument,
  }) : super(
         retry: null,
         name: r'referenciasDeSesionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$referenciasDeSesionHash();

  @override
  String toString() {
    return r'referenciasDeSesionProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Map<String, ReferenciaAnterior>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<String, ReferenciaAnterior>> create(Ref ref) {
    final argument = this.argument as (String, int);
    return referenciasDeSesion(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is ReferenciasDeSesionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$referenciasDeSesionHash() =>
    r'2f70c0e5c78591ed8daf0fa5f68f140cb72e76bd';

/// Lo que el cliente hizo la ultima vez en cada ejercicio del Dia [orden], para
/// que el entrenador planifique mirandolo.
///
/// Dos fuentes, en este orden:
///  1. El Dia [orden] del planning inmediatamente anterior. Es la referencia
///     buena: misma sesion, una semana antes.
///  2. Para lo que no aparezca ahi (ejercicio nuevo ese dia, o esa semana no lo
///     hizo), lo ultimo que haya registrado de ese ejercicio, venga de cuando
///     venga. Queda marcado como `esSemanaAnterior: false` para que la pantalla
///     avise con la fecha.
///
/// Si algo falla, devuelve lo que tenga en vez de propagar el error: esto es una
/// ayuda, y quedarse sin planificar porque el historico no carga seria peor que
/// no verlo.

final class ReferenciasDeSesionFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<String, ReferenciaAnterior>>,
          (String, int)
        > {
  ReferenciasDeSesionFamily._()
    : super(
        retry: null,
        name: r'referenciasDeSesionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Lo que el cliente hizo la ultima vez en cada ejercicio del Dia [orden], para
  /// que el entrenador planifique mirandolo.
  ///
  /// Dos fuentes, en este orden:
  ///  1. El Dia [orden] del planning inmediatamente anterior. Es la referencia
  ///     buena: misma sesion, una semana antes.
  ///  2. Para lo que no aparezca ahi (ejercicio nuevo ese dia, o esa semana no lo
  ///     hizo), lo ultimo que haya registrado de ese ejercicio, venga de cuando
  ///     venga. Queda marcado como `esSemanaAnterior: false` para que la pantalla
  ///     avise con la fecha.
  ///
  /// Si algo falla, devuelve lo que tenga en vez de propagar el error: esto es una
  /// ayuda, y quedarse sin planificar porque el historico no carga seria peor que
  /// no verlo.

  ReferenciasDeSesionProvider call(String planningId, int orden) =>
      ReferenciasDeSesionProvider._(argument: (planningId, orden), from: this);

  @override
  String toString() => r'referenciasDeSesionProvider';
}
