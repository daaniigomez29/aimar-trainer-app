// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_control_semanal.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Medidas de un dia concreto, o `null` si ese dia no tiene registro.

@ProviderFor(medidasDelDia)
final medidasDelDiaProvider = MedidasDelDiaFamily._();

/// Medidas de un dia concreto, o `null` si ese dia no tiene registro.

final class MedidasDelDiaProvider
    extends
        $FunctionalProvider<
          AsyncValue<RegistroMedidas?>,
          RegistroMedidas?,
          FutureOr<RegistroMedidas?>
        >
    with $FutureModifier<RegistroMedidas?>, $FutureProvider<RegistroMedidas?> {
  /// Medidas de un dia concreto, o `null` si ese dia no tiene registro.
  MedidasDelDiaProvider._({
    required MedidasDelDiaFamily super.from,
    required (String, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'medidasDelDiaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$medidasDelDiaHash();

  @override
  String toString() {
    return r'medidasDelDiaProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<RegistroMedidas?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<RegistroMedidas?> create(Ref ref) {
    final argument = this.argument as (String, DateTime);
    return medidasDelDia(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is MedidasDelDiaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$medidasDelDiaHash() => r'49615f52163700b63837fad7620d525ca04d782f';

/// Medidas de un dia concreto, o `null` si ese dia no tiene registro.

final class MedidasDelDiaFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<RegistroMedidas?>,
          (String, DateTime)
        > {
  MedidasDelDiaFamily._()
    : super(
        retry: null,
        name: r'medidasDelDiaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Medidas de un dia concreto, o `null` si ese dia no tiene registro.

  MedidasDelDiaProvider call(String clienteId, DateTime fecha) =>
      MedidasDelDiaProvider._(argument: (clienteId, fecha), from: this);

  @override
  String toString() => r'medidasDelDiaProvider';
}

/// Check-in de un dia concreto, o `null`.

@ProviderFor(checkinDelDia)
final checkinDelDiaProvider = CheckinDelDiaFamily._();

/// Check-in de un dia concreto, o `null`.

final class CheckinDelDiaProvider
    extends
        $FunctionalProvider<
          AsyncValue<CheckinRecuperacion?>,
          CheckinRecuperacion?,
          FutureOr<CheckinRecuperacion?>
        >
    with
        $FutureModifier<CheckinRecuperacion?>,
        $FutureProvider<CheckinRecuperacion?> {
  /// Check-in de un dia concreto, o `null`.
  CheckinDelDiaProvider._({
    required CheckinDelDiaFamily super.from,
    required (String, DateTime) super.argument,
  }) : super(
         retry: null,
         name: r'checkinDelDiaProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checkinDelDiaHash();

  @override
  String toString() {
    return r'checkinDelDiaProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<CheckinRecuperacion?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CheckinRecuperacion?> create(Ref ref) {
    final argument = this.argument as (String, DateTime);
    return checkinDelDia(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is CheckinDelDiaProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkinDelDiaHash() => r'a5fe4c98448698dac680589bc05f0b1dcde37020';

/// Check-in de un dia concreto, o `null`.

final class CheckinDelDiaFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<CheckinRecuperacion?>,
          (String, DateTime)
        > {
  CheckinDelDiaFamily._()
    : super(
        retry: null,
        name: r'checkinDelDiaProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Check-in de un dia concreto, o `null`.

  CheckinDelDiaProvider call(String clienteId, DateTime fecha) =>
      CheckinDelDiaProvider._(argument: (clienteId, fecha), from: this);

  @override
  String toString() => r'checkinDelDiaProvider';
}

/// Historico de medidas, de lo mas reciente a lo mas antiguo.

@ProviderFor(historialMedidas)
final historialMedidasProvider = HistorialMedidasFamily._();

/// Historico de medidas, de lo mas reciente a lo mas antiguo.

final class HistorialMedidasProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<RegistroMedidas>>,
          List<RegistroMedidas>,
          FutureOr<List<RegistroMedidas>>
        >
    with
        $FutureModifier<List<RegistroMedidas>>,
        $FutureProvider<List<RegistroMedidas>> {
  /// Historico de medidas, de lo mas reciente a lo mas antiguo.
  HistorialMedidasProvider._({
    required HistorialMedidasFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'historialMedidasProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$historialMedidasHash();

  @override
  String toString() {
    return r'historialMedidasProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<RegistroMedidas>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<RegistroMedidas>> create(Ref ref) {
    final argument = this.argument as String;
    return historialMedidas(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HistorialMedidasProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$historialMedidasHash() => r'3680a1228df7100dda338e8e5c33428f09bd0521';

/// Historico de medidas, de lo mas reciente a lo mas antiguo.

final class HistorialMedidasFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<RegistroMedidas>>, String> {
  HistorialMedidasFamily._()
    : super(
        retry: null,
        name: r'historialMedidasProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Historico de medidas, de lo mas reciente a lo mas antiguo.

  HistorialMedidasProvider call(String clienteId) =>
      HistorialMedidasProvider._(argument: clienteId, from: this);

  @override
  String toString() => r'historialMedidasProvider';
}

/// Historico de check-in.

@ProviderFor(historialCheckins)
final historialCheckinsProvider = HistorialCheckinsFamily._();

/// Historico de check-in.

final class HistorialCheckinsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CheckinRecuperacion>>,
          List<CheckinRecuperacion>,
          FutureOr<List<CheckinRecuperacion>>
        >
    with
        $FutureModifier<List<CheckinRecuperacion>>,
        $FutureProvider<List<CheckinRecuperacion>> {
  /// Historico de check-in.
  HistorialCheckinsProvider._({
    required HistorialCheckinsFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'historialCheckinsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$historialCheckinsHash();

  @override
  String toString() {
    return r'historialCheckinsProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<CheckinRecuperacion>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CheckinRecuperacion>> create(Ref ref) {
    final argument = this.argument as String;
    return historialCheckins(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is HistorialCheckinsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$historialCheckinsHash() => r'f6774908a1703690bac2415d0df76b0cf8d63759';

/// Historico de check-in.

final class HistorialCheckinsFamily extends $Family
    with
        $FunctionalFamilyOverride<FutureOr<List<CheckinRecuperacion>>, String> {
  HistorialCheckinsFamily._()
    : super(
        retry: null,
        name: r'historialCheckinsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Historico de check-in.

  HistorialCheckinsProvider call(String clienteId) =>
      HistorialCheckinsProvider._(argument: clienteId, from: this);

  @override
  String toString() => r'historialCheckinsProvider';
}

/// URL firmada para mostrar una foto. Caduca, asi que el provider se vuelve a
/// pedir cada vez que la pantalla se reconstruye de cero.

@ProviderFor(urlDeFoto)
final urlDeFotoProvider = UrlDeFotoFamily._();

/// URL firmada para mostrar una foto. Caduca, asi que el provider se vuelve a
/// pedir cada vez que la pantalla se reconstruye de cero.

final class UrlDeFotoProvider
    extends $FunctionalProvider<AsyncValue<Uri>, Uri, FutureOr<Uri>>
    with $FutureModifier<Uri>, $FutureProvider<Uri> {
  /// URL firmada para mostrar una foto. Caduca, asi que el provider se vuelve a
  /// pedir cada vez que la pantalla se reconstruye de cero.
  UrlDeFotoProvider._({
    required UrlDeFotoFamily super.from,
    required FotoProgreso super.argument,
  }) : super(
         retry: null,
         name: r'urlDeFotoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$urlDeFotoHash();

  @override
  String toString() {
    return r'urlDeFotoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<Uri> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Uri> create(Ref ref) {
    final argument = this.argument as FotoProgreso;
    return urlDeFoto(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is UrlDeFotoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$urlDeFotoHash() => r'f15b9ee68480a8b381d6932e26987ef263f98b45';

/// URL firmada para mostrar una foto. Caduca, asi que el provider se vuelve a
/// pedir cada vez que la pantalla se reconstruye de cero.

final class UrlDeFotoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<Uri>, FotoProgreso> {
  UrlDeFotoFamily._()
    : super(
        retry: null,
        name: r'urlDeFotoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// URL firmada para mostrar una foto. Caduca, asi que el provider se vuelve a
  /// pedir cada vez que la pantalla se reconstruye de cero.

  UrlDeFotoProvider call(FotoProgreso foto) =>
      UrlDeFotoProvider._(argument: foto, from: this);

  @override
  String toString() => r'urlDeFotoProvider';
}

/// Escrituras del control semanal: medidas, check-in y fotos.
///
/// Medidas y check-in son **dos operaciones independientes**, sin transaccion que
/// las una: se muestran juntas porque se rellenan el mismo dia, pero si el cliente
/// solo completa una, esa se guarda. Es la decision del modelo de dominio
/// (entidad 10), no una limitacion.

@ProviderFor(ControladorControlSemanal)
final controladorControlSemanalProvider = ControladorControlSemanalProvider._();

/// Escrituras del control semanal: medidas, check-in y fotos.
///
/// Medidas y check-in son **dos operaciones independientes**, sin transaccion que
/// las una: se muestran juntas porque se rellenan el mismo dia, pero si el cliente
/// solo completa una, esa se guarda. Es la decision del modelo de dominio
/// (entidad 10), no una limitacion.
final class ControladorControlSemanalProvider
    extends $NotifierProvider<ControladorControlSemanal, EstadoAccion> {
  /// Escrituras del control semanal: medidas, check-in y fotos.
  ///
  /// Medidas y check-in son **dos operaciones independientes**, sin transaccion que
  /// las una: se muestran juntas porque se rellenan el mismo dia, pero si el cliente
  /// solo completa una, esa se guarda. Es la decision del modelo de dominio
  /// (entidad 10), no una limitacion.
  ControladorControlSemanalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorControlSemanalProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorControlSemanalHash();

  @$internal
  @override
  ControladorControlSemanal create() => ControladorControlSemanal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorControlSemanalHash() =>
    r'7cbb238f6457235dee51145212b937cd2755ff82';

/// Escrituras del control semanal: medidas, check-in y fotos.
///
/// Medidas y check-in son **dos operaciones independientes**, sin transaccion que
/// las una: se muestran juntas porque se rellenan el mismo dia, pero si el cliente
/// solo completa una, esa se guarda. Es la decision del modelo de dominio
/// (entidad 10), no una limitacion.

abstract class _$ControladorControlSemanal extends $Notifier<EstadoAccion> {
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
