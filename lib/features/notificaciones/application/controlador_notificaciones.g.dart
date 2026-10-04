// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_notificaciones.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Preferencias del cliente, con las de por defecto si todavia no tiene fila.

@ProviderFor(preferenciasDeCliente)
final preferenciasDeClienteProvider = PreferenciasDeClienteFamily._();

/// Preferencias del cliente, con las de por defecto si todavia no tiene fila.

final class PreferenciasDeClienteProvider
    extends
        $FunctionalProvider<
          AsyncValue<PreferenciasNotificacion>,
          PreferenciasNotificacion,
          FutureOr<PreferenciasNotificacion>
        >
    with
        $FutureModifier<PreferenciasNotificacion>,
        $FutureProvider<PreferenciasNotificacion> {
  /// Preferencias del cliente, con las de por defecto si todavia no tiene fila.
  PreferenciasDeClienteProvider._({
    required PreferenciasDeClienteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'preferenciasDeClienteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$preferenciasDeClienteHash();

  @override
  String toString() {
    return r'preferenciasDeClienteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PreferenciasNotificacion> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PreferenciasNotificacion> create(Ref ref) {
    final argument = this.argument as String;
    return preferenciasDeCliente(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PreferenciasDeClienteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$preferenciasDeClienteHash() =>
    r'9043a9e85955aefe127b2ca54eb29ac66dbcdfc3';

/// Preferencias del cliente, con las de por defecto si todavia no tiene fila.

final class PreferenciasDeClienteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PreferenciasNotificacion>, String> {
  PreferenciasDeClienteFamily._()
    : super(
        retry: null,
        name: r'preferenciasDeClienteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Preferencias del cliente, con las de por defecto si todavia no tiene fila.

  PreferenciasDeClienteProvider call(String clienteId) =>
      PreferenciasDeClienteProvider._(argument: clienteId, from: this);

  @override
  String toString() => r'preferenciasDeClienteProvider';
}

/// Dispositivos suscritos del cliente. Sirve para avisar de que el push esta
/// activado pero este navegador concreto no esta suscrito.

@ProviderFor(dispositivosSuscritos)
final dispositivosSuscritosProvider = DispositivosSuscritosFamily._();

/// Dispositivos suscritos del cliente. Sirve para avisar de que el push esta
/// activado pero este navegador concreto no esta suscrito.

final class DispositivosSuscritosProvider
    extends $FunctionalProvider<AsyncValue<int>, int, FutureOr<int>>
    with $FutureModifier<int>, $FutureProvider<int> {
  /// Dispositivos suscritos del cliente. Sirve para avisar de que el push esta
  /// activado pero este navegador concreto no esta suscrito.
  DispositivosSuscritosProvider._({
    required DispositivosSuscritosFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'dispositivosSuscritosProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$dispositivosSuscritosHash();

  @override
  String toString() {
    return r'dispositivosSuscritosProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<int> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<int> create(Ref ref) {
    final argument = this.argument as String;
    return dispositivosSuscritos(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is DispositivosSuscritosProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$dispositivosSuscritosHash() =>
    r'5bfd7bee48227037f7c4087a970a3b6e7b41bd01';

/// Dispositivos suscritos del cliente. Sirve para avisar de que el push esta
/// activado pero este navegador concreto no esta suscrito.

final class DispositivosSuscritosFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<int>, String> {
  DispositivosSuscritosFamily._()
    : super(
        retry: null,
        name: r'dispositivosSuscritosProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Dispositivos suscritos del cliente. Sirve para avisar de que el push esta
  /// activado pero este navegador concreto no esta suscrito.

  DispositivosSuscritosProvider call(String clienteId) =>
      DispositivosSuscritosProvider._(argument: clienteId, from: this);

  @override
  String toString() => r'dispositivosSuscritosProvider';
}

/// Estado del permiso de notificaciones en este navegador.
///
/// Va en su propio provider y no en el controlador porque `riverpod_lint`
/// prohibe las propiedades publicas en un notifier: todo lo que expone debe
/// pasar por `state`, y esto no es estado de la operacion, es del navegador.

@ProviderFor(permisoPush)
final permisoPushProvider = PermisoPushProvider._();

/// Estado del permiso de notificaciones en este navegador.
///
/// Va en su propio provider y no en el controlador porque `riverpod_lint`
/// prohibe las propiedades publicas en un notifier: todo lo que expone debe
/// pasar por `state`, y esto no es estado de la operacion, es del navegador.

final class PermisoPushProvider
    extends
        $FunctionalProvider<
          EstadoPermisoPush,
          EstadoPermisoPush,
          EstadoPermisoPush
        >
    with $Provider<EstadoPermisoPush> {
  /// Estado del permiso de notificaciones en este navegador.
  ///
  /// Va en su propio provider y no en el controlador porque `riverpod_lint`
  /// prohibe las propiedades publicas en un notifier: todo lo que expone debe
  /// pasar por `state`, y esto no es estado de la operacion, es del navegador.
  PermisoPushProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'permisoPushProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$permisoPushHash();

  @$internal
  @override
  $ProviderElement<EstadoPermisoPush> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  EstadoPermisoPush create(Ref ref) {
    return permisoPush(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoPermisoPush value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoPermisoPush>(value),
    );
  }
}

String _$permisoPushHash() => r'd59f8f3f1ef40a9a9cb1f71c16040cbd7e772f33';

@ProviderFor(pushSoportado)
final pushSoportadoProvider = PushSoportadoProvider._();

final class PushSoportadoProvider extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  PushSoportadoProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'pushSoportadoProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$pushSoportadoHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return pushSoportado(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$pushSoportadoHash() => r'cb215c46d405bb35cce3a952d5c89548fcd46724';

/// Activar y desactivar el push del cliente (CU-22).
///
/// Activar son tres pasos que tienen que ir juntos: pedir permiso al navegador,
/// guardar la suscripcion y marcar la preferencia. Si el usuario no da permiso,
/// no se marca nada: quedaria el push "activado" sin dispositivo al que enviar, y
/// la Edge Function lo anotaria como fallido todos los dias.

@ProviderFor(ControladorNotificaciones)
final controladorNotificacionesProvider = ControladorNotificacionesProvider._();

/// Activar y desactivar el push del cliente (CU-22).
///
/// Activar son tres pasos que tienen que ir juntos: pedir permiso al navegador,
/// guardar la suscripcion y marcar la preferencia. Si el usuario no da permiso,
/// no se marca nada: quedaria el push "activado" sin dispositivo al que enviar, y
/// la Edge Function lo anotaria como fallido todos los dias.
final class ControladorNotificacionesProvider
    extends $NotifierProvider<ControladorNotificaciones, EstadoAccion> {
  /// Activar y desactivar el push del cliente (CU-22).
  ///
  /// Activar son tres pasos que tienen que ir juntos: pedir permiso al navegador,
  /// guardar la suscripcion y marcar la preferencia. Si el usuario no da permiso,
  /// no se marca nada: quedaria el push "activado" sin dispositivo al que enviar, y
  /// la Edge Function lo anotaria como fallido todos los dias.
  ControladorNotificacionesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorNotificacionesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorNotificacionesHash();

  @$internal
  @override
  ControladorNotificaciones create() => ControladorNotificaciones();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorNotificacionesHash() =>
    r'd7441440db5ff22a32e3556619cf1f73a5e0a471';

/// Activar y desactivar el push del cliente (CU-22).
///
/// Activar son tres pasos que tienen que ir juntos: pedir permiso al navegador,
/// guardar la suscripcion y marcar la preferencia. Si el usuario no da permiso,
/// no se marca nada: quedaria el push "activado" sin dispositivo al que enviar, y
/// la Edge Function lo anotaria como fallido todos los dias.

abstract class _$ControladorNotificaciones extends $Notifier<EstadoAccion> {
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
