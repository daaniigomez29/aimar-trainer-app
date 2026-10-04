// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'servicio_push.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(servicioPush)
final servicioPushProvider = ServicioPushProvider._();

final class ServicioPushProvider
    extends $FunctionalProvider<ServicioPush, ServicioPush, ServicioPush>
    with $Provider<ServicioPush> {
  ServicioPushProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'servicioPushProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$servicioPushHash();

  @$internal
  @override
  $ProviderElement<ServicioPush> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ServicioPush create(Ref ref) {
    return servicioPush(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ServicioPush value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ServicioPush>(value),
    );
  }
}

String _$servicioPushHash() => r'15dbdd5eba3fbdd577ff25ba7966cd4b550aa355';
