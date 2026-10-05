// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planning_repositorio_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(planningRepositorio)
final planningRepositorioProvider = PlanningRepositorioProvider._();

final class PlanningRepositorioProvider
    extends
        $FunctionalProvider<
          PlanningRepositorio,
          PlanningRepositorio,
          PlanningRepositorio
        >
    with $Provider<PlanningRepositorio> {
  PlanningRepositorioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'planningRepositorioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$planningRepositorioHash();

  @$internal
  @override
  $ProviderElement<PlanningRepositorio> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PlanningRepositorio create(Ref ref) {
    return planningRepositorio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PlanningRepositorio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PlanningRepositorio>(value),
    );
  }
}

String _$planningRepositorioHash() =>
    r'57c0d109879829231c62f22e8baf3b224f537125';
