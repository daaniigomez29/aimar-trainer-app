// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_informe.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Informe de progresion de los plannings [idsPlannings], separados por comas.
///
/// POR QUE UN TEXTO y no una lista: los parametros de un provider se comparan
/// por igualdad, y dos `List` con los mismos ids no son iguales para Dart. Con
/// una lista, cada repintado de la pantalla pediria el informe de nuevo.
/// Quien lo llama los ordena antes de unirlos: [clavePlannings].

@ProviderFor(informeProgresion)
final informeProgresionProvider = InformeProgresionFamily._();

/// Informe de progresion de los plannings [idsPlannings], separados por comas.
///
/// POR QUE UN TEXTO y no una lista: los parametros de un provider se comparan
/// por igualdad, y dos `List` con los mismos ids no son iguales para Dart. Con
/// una lista, cada repintado de la pantalla pediria el informe de nuevo.
/// Quien lo llama los ordena antes de unirlos: [clavePlannings].

final class InformeProgresionProvider
    extends
        $FunctionalProvider<
          AsyncValue<InformeProgresion>,
          InformeProgresion,
          FutureOr<InformeProgresion>
        >
    with
        $FutureModifier<InformeProgresion>,
        $FutureProvider<InformeProgresion> {
  /// Informe de progresion de los plannings [idsPlannings], separados por comas.
  ///
  /// POR QUE UN TEXTO y no una lista: los parametros de un provider se comparan
  /// por igualdad, y dos `List` con los mismos ids no son iguales para Dart. Con
  /// una lista, cada repintado de la pantalla pediria el informe de nuevo.
  /// Quien lo llama los ordena antes de unirlos: [clavePlannings].
  InformeProgresionProvider._({
    required InformeProgresionFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'informeProgresionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$informeProgresionHash();

  @override
  String toString() {
    return r'informeProgresionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<InformeProgresion> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<InformeProgresion> create(Ref ref) {
    final argument = this.argument as String;
    return informeProgresion(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is InformeProgresionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$informeProgresionHash() => r'baf56ac420cae83b330488f850f61632d3f81655';

/// Informe de progresion de los plannings [idsPlannings], separados por comas.
///
/// POR QUE UN TEXTO y no una lista: los parametros de un provider se comparan
/// por igualdad, y dos `List` con los mismos ids no son iguales para Dart. Con
/// una lista, cada repintado de la pantalla pediria el informe de nuevo.
/// Quien lo llama los ordena antes de unirlos: [clavePlannings].

final class InformeProgresionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<InformeProgresion>, String> {
  InformeProgresionFamily._()
    : super(
        retry: null,
        name: r'informeProgresionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Informe de progresion de los plannings [idsPlannings], separados por comas.
  ///
  /// POR QUE UN TEXTO y no una lista: los parametros de un provider se comparan
  /// por igualdad, y dos `List` con los mismos ids no son iguales para Dart. Con
  /// una lista, cada repintado de la pantalla pediria el informe de nuevo.
  /// Quien lo llama los ordena antes de unirlos: [clavePlannings].

  InformeProgresionProvider call(String idsPlannings) =>
      InformeProgresionProvider._(argument: idsPlannings, from: this);

  @override
  String toString() => r'informeProgresionProvider';
}

/// Quien entrega el PDF al usuario. Va tras una interfaz porque es codigo de
/// plataforma (en la web, una descarga del navegador), y en los tests se
/// sustituye.

@ProviderFor(descargadorPdf)
final descargadorPdfProvider = DescargadorPdfProvider._();

/// Quien entrega el PDF al usuario. Va tras una interfaz porque es codigo de
/// plataforma (en la web, una descarga del navegador), y en los tests se
/// sustituye.

final class DescargadorPdfProvider
    extends $FunctionalProvider<DescargadorPdf, DescargadorPdf, DescargadorPdf>
    with $Provider<DescargadorPdf> {
  /// Quien entrega el PDF al usuario. Va tras una interfaz porque es codigo de
  /// plataforma (en la web, una descarga del navegador), y en los tests se
  /// sustituye.
  DescargadorPdfProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'descargadorPdfProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$descargadorPdfHash();

  @$internal
  @override
  $ProviderElement<DescargadorPdf> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  DescargadorPdf create(Ref ref) {
    return descargadorPdf(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DescargadorPdf value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DescargadorPdf>(value),
    );
  }
}

String _$descargadorPdfHash() => r'8aafa3d516a006728e8c8316d9e6a9ab135ccd5f';
