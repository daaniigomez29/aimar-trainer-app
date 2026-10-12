// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'url_de_arranque.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// URL con la que se ha abierto la aplicacion.
///
/// Vive en un provider, y no leyendo `Uri.base` donde haga falta, para poder
/// sustituirla en los tests: el caso que importa —llegar con el error de un
/// enlace de correo ya gastado— no se puede montar de ninguna otra forma.
///
/// `keepAlive` porque es un dato del arranque: no cambia mientras la app vive.
/// Una navegacion dentro de la PWA no la toca.

@ProviderFor(urlDeArranque)
final urlDeArranqueProvider = UrlDeArranqueProvider._();

/// URL con la que se ha abierto la aplicacion.
///
/// Vive en un provider, y no leyendo `Uri.base` donde haga falta, para poder
/// sustituirla en los tests: el caso que importa —llegar con el error de un
/// enlace de correo ya gastado— no se puede montar de ninguna otra forma.
///
/// `keepAlive` porque es un dato del arranque: no cambia mientras la app vive.
/// Una navegacion dentro de la PWA no la toca.

final class UrlDeArranqueProvider extends $FunctionalProvider<Uri, Uri, Uri>
    with $Provider<Uri> {
  /// URL con la que se ha abierto la aplicacion.
  ///
  /// Vive en un provider, y no leyendo `Uri.base` donde haga falta, para poder
  /// sustituirla en los tests: el caso que importa —llegar con el error de un
  /// enlace de correo ya gastado— no se puede montar de ninguna otra forma.
  ///
  /// `keepAlive` porque es un dato del arranque: no cambia mientras la app vive.
  /// Una navegacion dentro de la PWA no la toca.
  UrlDeArranqueProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'urlDeArranqueProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$urlDeArranqueHash();

  @$internal
  @override
  $ProviderElement<Uri> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Uri create(Ref ref) {
    return urlDeArranque(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Uri value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Uri>(value),
    );
  }
}

String _$urlDeArranqueHash() => r'0b14effed550c58423c6e505a317be7ccc513341';
