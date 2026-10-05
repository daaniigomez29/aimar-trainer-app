// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_formulario_ejercicio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CU-02 (anadir) y CU-03 (editar) ejercicio.
///
/// Un solo controlador para los dos casos porque el formulario y las
/// validaciones son identicos; lo unico que cambia es si hay `id` previo.

@ProviderFor(ControladorFormularioEjercicio)
final controladorFormularioEjercicioProvider =
    ControladorFormularioEjercicioProvider._();

/// CU-02 (anadir) y CU-03 (editar) ejercicio.
///
/// Un solo controlador para los dos casos porque el formulario y las
/// validaciones son identicos; lo unico que cambia es si hay `id` previo.
final class ControladorFormularioEjercicioProvider
    extends $NotifierProvider<ControladorFormularioEjercicio, EstadoAccion> {
  /// CU-02 (anadir) y CU-03 (editar) ejercicio.
  ///
  /// Un solo controlador para los dos casos porque el formulario y las
  /// validaciones son identicos; lo unico que cambia es si hay `id` previo.
  ControladorFormularioEjercicioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorFormularioEjercicioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorFormularioEjercicioHash();

  @$internal
  @override
  ControladorFormularioEjercicio create() => ControladorFormularioEjercicio();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorFormularioEjercicioHash() =>
    r'084090ab6c571b9eeeb18883f13a560cb8ba4d5a';

/// CU-02 (anadir) y CU-03 (editar) ejercicio.
///
/// Un solo controlador para los dos casos porque el formulario y las
/// validaciones son identicos; lo unico que cambia es si hay `id` previo.

abstract class _$ControladorFormularioEjercicio
    extends $Notifier<EstadoAccion> {
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
