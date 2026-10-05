// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_biblioteca.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Biblioteca completa (activos y eliminados), ordenada por nombre.
///
/// Es la unica consulta al servidor del listado: el filtrado se aplica encima en
/// memoria. La lectura la permite RLS a cualquier usuario autenticado, asi que
/// este provider sirve igual al entrenador y al cliente.

@ProviderFor(bibliotecaEjercicios)
final bibliotecaEjerciciosProvider = BibliotecaEjerciciosProvider._();

/// Biblioteca completa (activos y eliminados), ordenada por nombre.
///
/// Es la unica consulta al servidor del listado: el filtrado se aplica encima en
/// memoria. La lectura la permite RLS a cualquier usuario autenticado, asi que
/// este provider sirve igual al entrenador y al cliente.

final class BibliotecaEjerciciosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ejercicio>>,
          List<Ejercicio>,
          FutureOr<List<Ejercicio>>
        >
    with $FutureModifier<List<Ejercicio>>, $FutureProvider<List<Ejercicio>> {
  /// Biblioteca completa (activos y eliminados), ordenada por nombre.
  ///
  /// Es la unica consulta al servidor del listado: el filtrado se aplica encima en
  /// memoria. La lectura la permite RLS a cualquier usuario autenticado, asi que
  /// este provider sirve igual al entrenador y al cliente.
  BibliotecaEjerciciosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bibliotecaEjerciciosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bibliotecaEjerciciosHash();

  @$internal
  @override
  $FutureProviderElement<List<Ejercicio>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Ejercicio>> create(Ref ref) {
    return bibliotecaEjercicios(ref);
  }
}

String _$bibliotecaEjerciciosHash() =>
    r'fbcff9f485cbe8e0cf87efa2eb9a711202cf33cf';

/// Filtro activo del listado (CU-21 usa el mismo patron para su rango de fechas).

@ProviderFor(FiltroBiblioteca)
final filtroBibliotecaProvider = FiltroBibliotecaProvider._();

/// Filtro activo del listado (CU-21 usa el mismo patron para su rango de fechas).
final class FiltroBibliotecaProvider
    extends $NotifierProvider<FiltroBiblioteca, FiltroEjercicios> {
  /// Filtro activo del listado (CU-21 usa el mismo patron para su rango de fechas).
  FiltroBibliotecaProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filtroBibliotecaProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filtroBibliotecaHash();

  @$internal
  @override
  FiltroBiblioteca create() => FiltroBiblioteca();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(FiltroEjercicios value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<FiltroEjercicios>(value),
    );
  }
}

String _$filtroBibliotecaHash() => r'c1702076c59621e4887d64d9f0b11a144c422ce9';

/// Filtro activo del listado (CU-21 usa el mismo patron para su rango de fechas).

abstract class _$FiltroBiblioteca extends $Notifier<FiltroEjercicios> {
  FiltroEjercicios build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<FiltroEjercicios, FiltroEjercicios>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<FiltroEjercicios, FiltroEjercicios>,
              FiltroEjercicios,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Listado ya filtrado que consume la pantalla.

@ProviderFor(ejerciciosFiltrados)
final ejerciciosFiltradosProvider = EjerciciosFiltradosProvider._();

/// Listado ya filtrado que consume la pantalla.

final class EjerciciosFiltradosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ejercicio>>,
          List<Ejercicio>,
          FutureOr<List<Ejercicio>>
        >
    with $FutureModifier<List<Ejercicio>>, $FutureProvider<List<Ejercicio>> {
  /// Listado ya filtrado que consume la pantalla.
  EjerciciosFiltradosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'ejerciciosFiltradosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$ejerciciosFiltradosHash();

  @$internal
  @override
  $FutureProviderElement<List<Ejercicio>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Ejercicio>> create(Ref ref) {
    return ejerciciosFiltrados(ref);
  }
}

String _$ejerciciosFiltradosHash() =>
    r'b6eee4f5e24702abe3d3c402baa1cf7b6828433f';

/// Grupos musculares presentes en la biblioteca, para ofrecerlos como filtro sin
/// mantener una lista fija en el codigo.

@ProviderFor(gruposMusculares)
final gruposMuscularesProvider = GruposMuscularesProvider._();

/// Grupos musculares presentes en la biblioteca, para ofrecerlos como filtro sin
/// mantener una lista fija en el codigo.

final class GruposMuscularesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<String>>,
          List<String>,
          FutureOr<List<String>>
        >
    with $FutureModifier<List<String>>, $FutureProvider<List<String>> {
  /// Grupos musculares presentes en la biblioteca, para ofrecerlos como filtro sin
  /// mantener una lista fija en el codigo.
  GruposMuscularesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'gruposMuscularesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$gruposMuscularesHash();

  @$internal
  @override
  $FutureProviderElement<List<String>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<String>> create(Ref ref) {
    return gruposMusculares(ref);
  }
}

String _$gruposMuscularesHash() => r'a18a2adcaccdd4b6ec7424e153d9e2ba9ffee2c3';

/// Un ejercicio concreto, para la pantalla de detalle.

@ProviderFor(ejercicioPorId)
final ejercicioPorIdProvider = EjercicioPorIdFamily._();

/// Un ejercicio concreto, para la pantalla de detalle.

final class EjercicioPorIdProvider
    extends
        $FunctionalProvider<
          AsyncValue<Ejercicio>,
          Ejercicio,
          FutureOr<Ejercicio>
        >
    with $FutureModifier<Ejercicio>, $FutureProvider<Ejercicio> {
  /// Un ejercicio concreto, para la pantalla de detalle.
  EjercicioPorIdProvider._({
    required EjercicioPorIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'ejercicioPorIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ejercicioPorIdHash();

  @override
  String toString() {
    return r'ejercicioPorIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Ejercicio> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Ejercicio> create(Ref ref) {
    final argument = this.argument as String;
    return ejercicioPorId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EjercicioPorIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ejercicioPorIdHash() => r'fcba13a571d17d53ea602ce8f151faa6544e8c30';

/// Un ejercicio concreto, para la pantalla de detalle.

final class EjercicioPorIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Ejercicio>, String> {
  EjercicioPorIdFamily._()
    : super(
        retry: null,
        name: r'ejercicioPorIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Un ejercicio concreto, para la pantalla de detalle.

  EjercicioPorIdProvider call(String id) =>
      EjercicioPorIdProvider._(argument: id, from: this);

  @override
  String toString() => r'ejercicioPorIdProvider';
}
