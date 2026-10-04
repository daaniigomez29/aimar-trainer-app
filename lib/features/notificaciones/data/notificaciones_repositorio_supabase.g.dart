// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notificaciones_repositorio_supabase.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(notificacionesRepositorio)
final notificacionesRepositorioProvider = NotificacionesRepositorioProvider._();

final class NotificacionesRepositorioProvider
    extends
        $FunctionalProvider<
          NotificacionesRepositorio,
          NotificacionesRepositorio,
          NotificacionesRepositorio
        >
    with $Provider<NotificacionesRepositorio> {
  NotificacionesRepositorioProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificacionesRepositorioProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificacionesRepositorioHash();

  @$internal
  @override
  $ProviderElement<NotificacionesRepositorio> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificacionesRepositorio create(Ref ref) {
    return notificacionesRepositorio(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificacionesRepositorio value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificacionesRepositorio>(value),
    );
  }
}

String _$notificacionesRepositorioHash() =>
    r'648307181ddaa54311e585d7c9ac65dc31b9647c';
