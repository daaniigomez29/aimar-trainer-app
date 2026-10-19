// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_packs.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Todos los packs, con sus ejercicios. Solo los ve el entrenador: a cualquier
/// otro, RLS le devuelve una lista vacia.

@ProviderFor(listaPacks)
final listaPacksProvider = ListaPacksProvider._();

/// Todos los packs, con sus ejercicios. Solo los ve el entrenador: a cualquier
/// otro, RLS le devuelve una lista vacia.

final class ListaPacksProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Pack>>,
          List<Pack>,
          FutureOr<List<Pack>>
        >
    with $FutureModifier<List<Pack>>, $FutureProvider<List<Pack>> {
  /// Todos los packs, con sus ejercicios. Solo los ve el entrenador: a cualquier
  /// otro, RLS le devuelve una lista vacia.
  ListaPacksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listaPacksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listaPacksHash();

  @$internal
  @override
  $FutureProviderElement<List<Pack>> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<List<Pack>> create(Ref ref) {
    return listaPacks(ref);
  }
}

String _$listaPacksHash() => r'776d10f4592b0306b0ec77b6b1c8da433ee31d89';

/// Un pack concreto, con sus ejercicios y las series de cada uno.

@ProviderFor(packCompleto)
final packCompletoProvider = PackCompletoFamily._();

/// Un pack concreto, con sus ejercicios y las series de cada uno.

final class PackCompletoProvider
    extends $FunctionalProvider<AsyncValue<Pack>, Pack, FutureOr<Pack>>
    with $FutureModifier<Pack>, $FutureProvider<Pack> {
  /// Un pack concreto, con sus ejercicios y las series de cada uno.
  PackCompletoProvider._({
    required PackCompletoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'packCompletoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$packCompletoHash();

  @override
  String toString() {
    return r'packCompletoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Pack> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Pack> create(Ref ref) {
    final argument = this.argument as String;
    return packCompleto(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PackCompletoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$packCompletoHash() => r'ce5ad6645cd75550143e591c174ef1eeee4a6756';

/// Un pack concreto, con sus ejercicios y las series de cada uno.

final class PackCompletoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Pack>, String> {
  PackCompletoFamily._()
    : super(
        retry: null,
        name: r'packCompletoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Un pack concreto, con sus ejercicios y las series de cada uno.

  PackCompletoProvider call(String packId) =>
      PackCompletoProvider._(argument: packId, from: this);

  @override
  String toString() => r'packCompletoProvider';
}

/// Las escrituras de los packs (CU nuevo; ver `docs/requirements.md`).
///
/// Mismo patron que `ControladorPlanificacion`: un solo [EstadoAccion] para
/// toda la pantalla, y cada operacion recarga lo que haya cambiado.

@ProviderFor(ControladorPacks)
final controladorPacksProvider = ControladorPacksProvider._();

/// Las escrituras de los packs (CU nuevo; ver `docs/requirements.md`).
///
/// Mismo patron que `ControladorPlanificacion`: un solo [EstadoAccion] para
/// toda la pantalla, y cada operacion recarga lo que haya cambiado.
final class ControladorPacksProvider
    extends $NotifierProvider<ControladorPacks, EstadoAccion> {
  /// Las escrituras de los packs (CU nuevo; ver `docs/requirements.md`).
  ///
  /// Mismo patron que `ControladorPlanificacion`: un solo [EstadoAccion] para
  /// toda la pantalla, y cada operacion recarga lo que haya cambiado.
  ControladorPacksProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorPacksProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorPacksHash();

  @$internal
  @override
  ControladorPacks create() => ControladorPacks();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorPacksHash() => r'9f9c4b6a1dc4591812edf0f18252d96150f5554b';

/// Las escrituras de los packs (CU nuevo; ver `docs/requirements.md`).
///
/// Mismo patron que `ControladorPlanificacion`: un solo [EstadoAccion] para
/// toda la pantalla, y cada operacion recarga lo que haya cambiado.

abstract class _$ControladorPacks extends $Notifier<EstadoAccion> {
  EstadoAccion build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<EstadoAccion, EstadoAccion>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<EstadoAccion, EstadoAccion>,
              EstadoAccion,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
