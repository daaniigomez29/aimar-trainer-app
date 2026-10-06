// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_clientes.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Fichas visibles para quien consulta, ordenadas por nombre.
///
/// Con RLS, el entrenador ve todas y el cliente solo la suya. El administrador no
/// ve ninguna: puede dar de alta y de baja (lo hace la Edge Function con
/// `service_role`), pero no consultar fichas.

@ProviderFor(listaClientes)
final listaClientesProvider = ListaClientesProvider._();

/// Fichas visibles para quien consulta, ordenadas por nombre.
///
/// Con RLS, el entrenador ve todas y el cliente solo la suya. El administrador no
/// ve ninguna: puede dar de alta y de baja (lo hace la Edge Function con
/// `service_role`), pero no consultar fichas.

final class ListaClientesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Cliente>>,
          List<Cliente>,
          FutureOr<List<Cliente>>
        >
    with $FutureModifier<List<Cliente>>, $FutureProvider<List<Cliente>> {
  /// Fichas visibles para quien consulta, ordenadas por nombre.
  ///
  /// Con RLS, el entrenador ve todas y el cliente solo la suya. El administrador no
  /// ve ninguna: puede dar de alta y de baja (lo hace la Edge Function con
  /// `service_role`), pero no consultar fichas.
  ListaClientesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'listaClientesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$listaClientesHash();

  @$internal
  @override
  $FutureProviderElement<List<Cliente>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Cliente>> create(Ref ref) {
    return listaClientes(ref);
  }
}

String _$listaClientesHash() => r'03bd7a2b7ccda8ecdea171dbcff71128546ad042';

/// Filtro del listado: texto y si se ven SOLO los dados de baja.

@ProviderFor(FiltroClientes)
final filtroClientesProvider = FiltroClientesProvider._();

/// Filtro del listado: texto y si se ven SOLO los dados de baja.
final class FiltroClientesProvider
    extends
        $NotifierProvider<FiltroClientes, ({bool soloBajas, String texto})> {
  /// Filtro del listado: texto y si se ven SOLO los dados de baja.
  FiltroClientesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'filtroClientesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$filtroClientesHash();

  @$internal
  @override
  FiltroClientes create() => FiltroClientes();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(({bool soloBajas, String texto}) value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<({bool soloBajas, String texto})>(
        value,
      ),
    );
  }
}

String _$filtroClientesHash() => r'29fe5de66922ba1cbfe4ad7ec4b73e7e8051b2e6';

/// Filtro del listado: texto y si se ven SOLO los dados de baja.

abstract class _$FiltroClientes
    extends $Notifier<({bool soloBajas, String texto})> {
  ({bool soloBajas, String texto}) build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref
            as $Ref<
              ({bool soloBajas, String texto}),
              ({bool soloBajas, String texto})
            >;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                ({bool soloBajas, String texto}),
                ({bool soloBajas, String texto})
              >,
              ({bool soloBajas, String texto}),
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Listado ya filtrado. Se filtra en memoria: con un solo entrenador, el numero
/// de clientes no justifica paginacion ni una consulta por cada tecla.

@ProviderFor(clientesFiltrados)
final clientesFiltradosProvider = ClientesFiltradosProvider._();

/// Listado ya filtrado. Se filtra en memoria: con un solo entrenador, el numero
/// de clientes no justifica paginacion ni una consulta por cada tecla.

final class ClientesFiltradosProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<Cliente>>,
          List<Cliente>,
          FutureOr<List<Cliente>>
        >
    with $FutureModifier<List<Cliente>>, $FutureProvider<List<Cliente>> {
  /// Listado ya filtrado. Se filtra en memoria: con un solo entrenador, el numero
  /// de clientes no justifica paginacion ni una consulta por cada tecla.
  ClientesFiltradosProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clientesFiltradosProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clientesFiltradosHash();

  @$internal
  @override
  $FutureProviderElement<List<Cliente>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<Cliente>> create(Ref ref) {
    return clientesFiltrados(ref);
  }
}

String _$clientesFiltradosHash() => r'8ac74b1204f89e9b6bf3dd083684c1f6dcff189e';

/// Una ficha concreta, para el detalle. Se resuelve desde la lista ya cargada
/// cuando esta disponible, para no repetir la consulta.

@ProviderFor(clientePorId)
final clientePorIdProvider = ClientePorIdFamily._();

/// Una ficha concreta, para el detalle. Se resuelve desde la lista ya cargada
/// cuando esta disponible, para no repetir la consulta.

final class ClientePorIdProvider
    extends $FunctionalProvider<AsyncValue<Cliente>, Cliente, FutureOr<Cliente>>
    with $FutureModifier<Cliente>, $FutureProvider<Cliente> {
  /// Una ficha concreta, para el detalle. Se resuelve desde la lista ya cargada
  /// cuando esta disponible, para no repetir la consulta.
  ClientePorIdProvider._({
    required ClientePorIdFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'clientePorIdProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$clientePorIdHash();

  @override
  String toString() {
    return r'clientePorIdProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Cliente> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Cliente> create(Ref ref) {
    final argument = this.argument as String;
    return clientePorId(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is ClientePorIdProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$clientePorIdHash() => r'571ae5ef8bd9b79be0c28d1990bbd46c052d6b81';

/// Una ficha concreta, para el detalle. Se resuelve desde la lista ya cargada
/// cuando esta disponible, para no repetir la consulta.

final class ClientePorIdFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Cliente>, String> {
  ClientePorIdFamily._()
    : super(
        retry: null,
        name: r'clientePorIdProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Una ficha concreta, para el detalle. Se resuelve desde la lista ya cargada
  /// cuando esta disponible, para no repetir la consulta.

  ClientePorIdProvider call(String id) =>
      ClientePorIdProvider._(argument: id, from: this);

  @override
  String toString() => r'clientePorIdProvider';
}
