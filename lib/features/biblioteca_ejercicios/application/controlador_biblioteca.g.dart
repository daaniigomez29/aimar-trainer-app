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

/// Filtro activo del listado, **uno por ambito** (ver [AmbitoDeFiltro]): la
/// biblioteca y el selector de ejercicios no se pisan la busqueda.

@ProviderFor(FiltroBiblioteca)
final filtroBibliotecaProvider = FiltroBibliotecaFamily._();

/// Filtro activo del listado, **uno por ambito** (ver [AmbitoDeFiltro]): la
/// biblioteca y el selector de ejercicios no se pisan la busqueda.
final class FiltroBibliotecaProvider
    extends $NotifierProvider<FiltroBiblioteca, FiltroEjercicios> {
  /// Filtro activo del listado, **uno por ambito** (ver [AmbitoDeFiltro]): la
  /// biblioteca y el selector de ejercicios no se pisan la busqueda.
  FiltroBibliotecaProvider._({
    required FiltroBibliotecaFamily super.from,
    required AmbitoDeFiltro super.argument,
  }) : super(
         retry: null,
         name: r'filtroBibliotecaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$filtroBibliotecaHash();

  @override
  String toString() {
    return r'filtroBibliotecaProvider'
        ''
        '($argument)';
  }

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

  @override
  bool operator ==(Object other) {
    return other is FiltroBibliotecaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$filtroBibliotecaHash() => r'995ec958ed809d72745336f0d7a230fda8979cc0';

/// Filtro activo del listado, **uno por ambito** (ver [AmbitoDeFiltro]): la
/// biblioteca y el selector de ejercicios no se pisan la busqueda.

final class FiltroBibliotecaFamily extends $Family
    with
        $ClassFamilyOverride<
          FiltroBiblioteca,
          FiltroEjercicios,
          FiltroEjercicios,
          FiltroEjercicios,
          AmbitoDeFiltro
        > {
  FiltroBibliotecaFamily._()
    : super(
        retry: null,
        name: r'filtroBibliotecaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Filtro activo del listado, **uno por ambito** (ver [AmbitoDeFiltro]): la
  /// biblioteca y el selector de ejercicios no se pisan la busqueda.

  FiltroBibliotecaProvider call(AmbitoDeFiltro ambito) =>
      FiltroBibliotecaProvider._(argument: ambito, from: this);

  @override
  String toString() => r'filtroBibliotecaProvider';
}

/// Filtro activo del listado, **uno por ambito** (ver [AmbitoDeFiltro]): la
/// biblioteca y el selector de ejercicios no se pisan la busqueda.

abstract class _$FiltroBiblioteca extends $Notifier<FiltroEjercicios> {
  late final _$args = ref.$arg as AmbitoDeFiltro;
  AmbitoDeFiltro get ambito => _$args;

  FiltroEjercicios build(AmbitoDeFiltro ambito);
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
    return element.handleCreate(ref, () => build(_$args));
  }
}

/// Listado ya filtrado y ordenado que consume la pantalla.

@ProviderFor(ejerciciosFiltrados)
final ejerciciosFiltradosProvider = EjerciciosFiltradosFamily._();

/// Listado ya filtrado y ordenado que consume la pantalla.

final class EjerciciosFiltradosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Ejercicio>>,
          List<Ejercicio>,
          FutureOr<List<Ejercicio>>
        >
    with $FutureModifier<List<Ejercicio>>, $FutureProvider<List<Ejercicio>> {
  /// Listado ya filtrado y ordenado que consume la pantalla.
  EjerciciosFiltradosProvider._({
    required EjerciciosFiltradosFamily super.from,
    required AmbitoDeFiltro super.argument,
  }) : super(
         retry: null,
         name: r'ejerciciosFiltradosProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$ejerciciosFiltradosHash();

  @override
  String toString() {
    return r'ejerciciosFiltradosProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<Ejercicio>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Ejercicio>> create(Ref ref) {
    final argument = this.argument as AmbitoDeFiltro;
    return ejerciciosFiltrados(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is EjerciciosFiltradosProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$ejerciciosFiltradosHash() =>
    r'b5cc4aae9ca0df4380ff11b3e3d7169b371525d9';

/// Listado ya filtrado y ordenado que consume la pantalla.

final class EjerciciosFiltradosFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<Ejercicio>>, AmbitoDeFiltro> {
  EjerciciosFiltradosFamily._()
    : super(
        retry: null,
        name: r'ejerciciosFiltradosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Listado ya filtrado y ordenado que consume la pantalla.

  EjerciciosFiltradosProvider call(AmbitoDeFiltro ambito) =>
      EjerciciosFiltradosProvider._(argument: ambito, from: this);

  @override
  String toString() => r'ejerciciosFiltradosProvider';
}

/// Opciones de filtrado con algun ejercicio detras (ver [FacetasBiblioteca]).
///
/// Se calculan sobre los ejercicios del **estado** que se esta mirando (activos
/// o dados de baja), no sobre la biblioteca entera: en la pestana de bajas los
/// chips tienen que ser los de las bajas. Lo demas del filtro no influye: los
/// chips no se recortan segun lo que el buscador tenga escrito, o irian
/// desapareciendo mientras se teclea.

@ProviderFor(facetasBiblioteca)
final facetasBibliotecaProvider = FacetasBibliotecaFamily._();

/// Opciones de filtrado con algun ejercicio detras (ver [FacetasBiblioteca]).
///
/// Se calculan sobre los ejercicios del **estado** que se esta mirando (activos
/// o dados de baja), no sobre la biblioteca entera: en la pestana de bajas los
/// chips tienen que ser los de las bajas. Lo demas del filtro no influye: los
/// chips no se recortan segun lo que el buscador tenga escrito, o irian
/// desapareciendo mientras se teclea.

final class FacetasBibliotecaProvider
    extends
        $FunctionalProvider<
          AsyncValue<FacetasBiblioteca>,
          FacetasBiblioteca,
          FutureOr<FacetasBiblioteca>
        >
    with
        $FutureModifier<FacetasBiblioteca>,
        $FutureProvider<FacetasBiblioteca> {
  /// Opciones de filtrado con algun ejercicio detras (ver [FacetasBiblioteca]).
  ///
  /// Se calculan sobre los ejercicios del **estado** que se esta mirando (activos
  /// o dados de baja), no sobre la biblioteca entera: en la pestana de bajas los
  /// chips tienen que ser los de las bajas. Lo demas del filtro no influye: los
  /// chips no se recortan segun lo que el buscador tenga escrito, o irian
  /// desapareciendo mientras se teclea.
  FacetasBibliotecaProvider._({
    required FacetasBibliotecaFamily super.from,
    required AmbitoDeFiltro super.argument,
  }) : super(
         retry: null,
         name: r'facetasBibliotecaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$facetasBibliotecaHash();

  @override
  String toString() {
    return r'facetasBibliotecaProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<FacetasBiblioteca> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FacetasBiblioteca> create(Ref ref) {
    final argument = this.argument as AmbitoDeFiltro;
    return facetasBiblioteca(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is FacetasBibliotecaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$facetasBibliotecaHash() => r'73202b0927defebb89078d2d01fda84b19c13c97';

/// Opciones de filtrado con algun ejercicio detras (ver [FacetasBiblioteca]).
///
/// Se calculan sobre los ejercicios del **estado** que se esta mirando (activos
/// o dados de baja), no sobre la biblioteca entera: en la pestana de bajas los
/// chips tienen que ser los de las bajas. Lo demas del filtro no influye: los
/// chips no se recortan segun lo que el buscador tenga escrito, o irian
/// desapareciendo mientras se teclea.

final class FacetasBibliotecaFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<FacetasBiblioteca>, AmbitoDeFiltro> {
  FacetasBibliotecaFamily._()
    : super(
        retry: null,
        name: r'facetasBibliotecaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Opciones de filtrado con algun ejercicio detras (ver [FacetasBiblioteca]).
  ///
  /// Se calculan sobre los ejercicios del **estado** que se esta mirando (activos
  /// o dados de baja), no sobre la biblioteca entera: en la pestana de bajas los
  /// chips tienen que ser los de las bajas. Lo demas del filtro no influye: los
  /// chips no se recortan segun lo que el buscador tenga escrito, o irian
  /// desapareciendo mientras se teclea.

  FacetasBibliotecaProvider call(AmbitoDeFiltro ambito) =>
      FacetasBibliotecaProvider._(argument: ambito, from: this);

  @override
  String toString() => r'facetasBibliotecaProvider';
}

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
