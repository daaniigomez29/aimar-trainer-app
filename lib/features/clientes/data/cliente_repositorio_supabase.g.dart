// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cliente_repositorio_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(clienteRepositorio)
final clienteRepositorioProvider = ClienteRepositorioProvider._();

final class ClienteRepositorioProvider
    extends
        $FunctionalProvider<
          ClienteRepositorio,
          ClienteRepositorio,
          ClienteRepositorio
        >
    with $Provider<ClienteRepositorio> {
  ClienteRepositorioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clienteRepositorioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clienteRepositorioHash();

  @$internal
  @override
  $ProviderElement<ClienteRepositorio> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  ClienteRepositorio create(Ref ref) {
    return clienteRepositorio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ClienteRepositorio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ClienteRepositorio>(value),
    );
  }
}

String _$clienteRepositorioHash() =>
    r'dcf383e64b9ba8df4d138df8bc81cfc94817c502';
