// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_ficha_cliente.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// CU-17 (alta) y CU-19 (editar ficha).
///
/// Los metodos devuelven el resultado en lugar de dejarlo solo en `state`: este
/// provider es autoDispose y, con dialogos o navegacion de por medio, el estado
/// no es fiable al volver. Misma leccion que el fallo de CU-04.

@ProviderFor(ControladorFichaCliente)
final controladorFichaClienteProvider = ControladorFichaClienteProvider._();

/// CU-17 (alta) y CU-19 (editar ficha).
///
/// Los metodos devuelven el resultado en lugar de dejarlo solo en `state`: este
/// provider es autoDispose y, con dialogos o navegacion de por medio, el estado
/// no es fiable al volver. Misma leccion que el fallo de CU-04.
final class ControladorFichaClienteProvider
    extends $NotifierProvider<ControladorFichaCliente, EstadoAccion> {
  /// CU-17 (alta) y CU-19 (editar ficha).
  ///
  /// Los metodos devuelven el resultado en lugar de dejarlo solo en `state`: este
  /// provider es autoDispose y, con dialogos o navegacion de por medio, el estado
  /// no es fiable al volver. Misma leccion que el fallo de CU-04.
  ControladorFichaClienteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorFichaClienteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorFichaClienteHash();

  @$internal
  @override
  ControladorFichaCliente create() => ControladorFichaCliente();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorFichaClienteHash() =>
    r'0e6601b1dbe4fb89af5a3a8c18b29d8b7c4ca290';

/// CU-17 (alta) y CU-19 (editar ficha).
///
/// Los metodos devuelven el resultado en lugar de dejarlo solo en `state`: este
/// provider es autoDispose y, con dialogos o navegacion de por medio, el estado
/// no es fiable al volver. Misma leccion que el fallo de CU-04.

abstract class _$ControladorFichaCliente extends $Notifier<EstadoAccion> {
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

/// CU-18: baja logica del cliente, con el aviso previo de plannings activos.

@ProviderFor(ControladorBajaCliente)
final controladorBajaClienteProvider = ControladorBajaClienteProvider._();

/// CU-18: baja logica del cliente, con el aviso previo de plannings activos.
final class ControladorBajaClienteProvider
    extends $NotifierProvider<ControladorBajaCliente, EstadoAccion> {
  /// CU-18: baja logica del cliente, con el aviso previo de plannings activos.
  ControladorBajaClienteProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorBajaClienteProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorBajaClienteHash();

  @$internal
  @override
  ControladorBajaCliente create() => ControladorBajaCliente();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorBajaClienteHash() =>
    r'a487dda00179a8af6d918f1ccad79e5a2bbab851';

/// CU-18: baja logica del cliente, con el aviso previo de plannings activos.

abstract class _$ControladorBajaCliente extends $Notifier<EstadoAccion> {
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
