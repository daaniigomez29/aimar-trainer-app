// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'proveedores_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Configuracion de compilacion. Se sobreescribe en tests con un override.

@ProviderFor(configuracionApp)
final configuracionAppProvider = ConfiguracionAppProvider._();

/// Configuracion de compilacion. Se sobreescribe en tests con un override.

final class ConfiguracionAppProvider
    extends
        $FunctionalProvider<
          ConfiguracionApp,
          ConfiguracionApp,
          ConfiguracionApp
        >
    with $Provider<ConfiguracionApp> {
  /// Configuracion de compilacion. Se sobreescribe en tests con un override.
  ConfiguracionAppProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'configuracionAppProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$configuracionAppHash();

  @$internal
  @override
  $ProviderElement<ConfiguracionApp> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ConfiguracionApp create(Ref ref) {
    return configuracionApp(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ConfiguracionApp value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ConfiguracionApp>(value),
    );
  }
}

String _$configuracionAppHash() => r'5de048663c30a514813062a5707a49545b43a29a';

/// Cliente de Supabase ya inicializado en `main()`.
///
/// Unico punto de acceso: ningun archivo fuera de un repositorio en `data/`
/// debe usar `Supabase.instance` directamente.

@ProviderFor(clienteSupabase)
final clienteSupabaseProvider = ClienteSupabaseProvider._();

/// Cliente de Supabase ya inicializado en `main()`.
///
/// Unico punto de acceso: ningun archivo fuera de un repositorio en `data/`
/// debe usar `Supabase.instance` directamente.

final class ClienteSupabaseProvider
    extends $FunctionalProvider<SupabaseClient, SupabaseClient, SupabaseClient>
    with $Provider<SupabaseClient> {
  /// Cliente de Supabase ya inicializado en `main()`.
  ///
  /// Unico punto de acceso: ningun archivo fuera de un repositorio en `data/`
  /// debe usar `Supabase.instance` directamente.
  ClienteSupabaseProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'clienteSupabaseProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$clienteSupabaseHash();

  @$internal
  @override
  $ProviderElement<SupabaseClient> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  SupabaseClient create(Ref ref) {
    return clienteSupabase(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SupabaseClient value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SupabaseClient>(value),
    );
  }
}

String _$clienteSupabaseHash() => r'bb8ca70ffa4fe7cb879e8899eeae8e8d1f736d67';
