// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_baja_ejercicio.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CU-04: baja logica de un ejercicio, con el aviso previo de si esta en uso.
///
/// Los metodos devuelven el resultado en lugar de obligar a leer `state` despues:
/// el flujo de CU-04 pasa por dos dialogos, y entre ellos este provider puede
/// desecharse (es autoDispose). Quien lo llame debe usar el valor devuelto, no el
/// estado residual.

@ProviderFor(ControladorBajaEjercicio)
final controladorBajaEjercicioProvider = ControladorBajaEjercicioProvider._();

/// CU-04: baja logica de un ejercicio, con el aviso previo de si esta en uso.
///
/// Los metodos devuelven el resultado en lugar de obligar a leer `state` despues:
/// el flujo de CU-04 pasa por dos dialogos, y entre ellos este provider puede
/// desecharse (es autoDispose). Quien lo llame debe usar el valor devuelto, no el
/// estado residual.
final class ControladorBajaEjercicioProvider
    extends $NotifierProvider<ControladorBajaEjercicio, EstadoAccion> {
  /// CU-04: baja logica de un ejercicio, con el aviso previo de si esta en uso.
  ///
  /// Los metodos devuelven el resultado en lugar de obligar a leer `state` despues:
  /// el flujo de CU-04 pasa por dos dialogos, y entre ellos este provider puede
  /// desecharse (es autoDispose). Quien lo llame debe usar el valor devuelto, no el
  /// estado residual.
  ControladorBajaEjercicioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorBajaEjercicioProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorBajaEjercicioHash();

  @$internal
  @override
  ControladorBajaEjercicio create() => ControladorBajaEjercicio();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorBajaEjercicioHash() =>
    r'bb2d03cf675f5e8907bfd94a02af3ab0986ee3eb';

/// CU-04: baja logica de un ejercicio, con el aviso previo de si esta en uso.
///
/// Los metodos devuelven el resultado en lugar de obligar a leer `state` despues:
/// el flujo de CU-04 pasa por dos dialogos, y entre ellos este provider puede
/// desecharse (es autoDispose). Quien lo llame debe usar el valor devuelto, no el
/// estado residual.

abstract class _$ControladorBajaEjercicio extends $Notifier<EstadoAccion> {
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
