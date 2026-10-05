// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'controlador_planificacion.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Plannings de un cliente, para su historico (CU-23).

@ProviderFor(planningsDeCliente)
final planningsDeClienteProvider = PlanningsDeClienteFamily._();

/// Plannings de un cliente, para su historico (CU-23).

final class PlanningsDeClienteProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanningSemanal>>,
          List<PlanningSemanal>,
          FutureOr<List<PlanningSemanal>>
        >
    with
        $FutureModifier<List<PlanningSemanal>>,
        $FutureProvider<List<PlanningSemanal>> {
  /// Plannings de un cliente, para su historico (CU-23).
  PlanningsDeClienteProvider._({
    required PlanningsDeClienteFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planningsDeClienteProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planningsDeClienteHash();

  @override
  String toString() {
    return r'planningsDeClienteProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<List<PlanningSemanal>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanningSemanal>> create(Ref ref) {
    final argument = this.argument as String;
    return planningsDeCliente(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanningsDeClienteProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planningsDeClienteHash() =>
    r'014b99ade29dc997d6fa8167eaf330bb1de2b3c6';

/// Plannings de un cliente, para su historico (CU-23).

final class PlanningsDeClienteFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<List<PlanningSemanal>>, String> {
  PlanningsDeClienteFamily._()
    : super(
        retry: null,
        name: r'planningsDeClienteProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Plannings de un cliente, para su historico (CU-23).

  PlanningsDeClienteProvider call(String clienteId) =>
      PlanningsDeClienteProvider._(argument: clienteId, from: this);

  @override
  String toString() => r'planningsDeClienteProvider';
}

/// Plannings del cliente que tiene la sesion abierta, para consultar los suyos.
///
/// No recibe el id por parametro a proposito: lo toma de la sesion, asi que la
/// pantalla del cliente no puede pedir el historico de otro ni por error. RLS ya
/// lo impide en el servidor; esto evita siquiera intentarlo.

@ProviderFor(misPlannings)
final misPlanningsProvider = MisPlanningsProvider._();

/// Plannings del cliente que tiene la sesion abierta, para consultar los suyos.
///
/// No recibe el id por parametro a proposito: lo toma de la sesion, asi que la
/// pantalla del cliente no puede pedir el historico de otro ni por error. RLS ya
/// lo impide en el servidor; esto evita siquiera intentarlo.

final class MisPlanningsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<PlanningSemanal>>,
          List<PlanningSemanal>,
          FutureOr<List<PlanningSemanal>>
        >
    with
        $FutureModifier<List<PlanningSemanal>>,
        $FutureProvider<List<PlanningSemanal>> {
  /// Plannings del cliente que tiene la sesion abierta, para consultar los suyos.
  ///
  /// No recibe el id por parametro a proposito: lo toma de la sesion, asi que la
  /// pantalla del cliente no puede pedir el historico de otro ni por error. RLS ya
  /// lo impide en el servidor; esto evita siquiera intentarlo.
  MisPlanningsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'misPlanningsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$misPlanningsHash();

  @$internal
  @override
  $FutureProviderElement<List<PlanningSemanal>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<PlanningSemanal>> create(Ref ref) {
    return misPlannings(ref);
  }
}

String _$misPlanningsHash() => r'b28ffabb97a55e99c3487b2177c1dbcb35d92165';

/// Un planning con toda su jerarquia. Es la fuente de la pantalla de edicion.

@ProviderFor(planningCompleto)
final planningCompletoProvider = PlanningCompletoFamily._();

/// Un planning con toda su jerarquia. Es la fuente de la pantalla de edicion.

final class PlanningCompletoProvider
    extends
        $FunctionalProvider<
          AsyncValue<PlanningSemanal>,
          PlanningSemanal,
          FutureOr<PlanningSemanal>
        >
    with $FutureModifier<PlanningSemanal>, $FutureProvider<PlanningSemanal> {
  /// Un planning con toda su jerarquia. Es la fuente de la pantalla de edicion.
  PlanningCompletoProvider._({
    required PlanningCompletoFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'planningCompletoProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$planningCompletoHash();

  @override
  String toString() {
    return r'planningCompletoProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<PlanningSemanal> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<PlanningSemanal> create(Ref ref) {
    final argument = this.argument as String;
    return planningCompleto(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is PlanningCompletoProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$planningCompletoHash() => r'78d25e0b1fc789a8e59ed5b759276ba5b461d14d';

/// Un planning con toda su jerarquia. Es la fuente de la pantalla de edicion.

final class PlanningCompletoFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<PlanningSemanal>, String> {
  PlanningCompletoFamily._()
    : super(
        retry: null,
        name: r'planningCompletoProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Un planning con toda su jerarquia. Es la fuente de la pantalla de edicion.

  PlanningCompletoProvider call(String planningId) =>
      PlanningCompletoProvider._(argument: planningId, from: this);

  @override
  String toString() => r'planningCompletoProvider';
}

/// Orquesta todas las operaciones de escritura de la planificacion (CU-05 a
/// CU-16).
///
/// Un solo controlador para los cuatro niveles porque comparten el mismo patron:
/// validar en dominio, escribir, recargar el planning. Cada metodo devuelve su
/// `Result` en lugar de dejarlo solo en el estado, por la leccion del fallo de
/// CU-04: con dialogos de por medio, un provider autoDispose puede desecharse.

@ProviderFor(ControladorPlanificacion)
final controladorPlanificacionProvider = ControladorPlanificacionProvider._();

/// Orquesta todas las operaciones de escritura de la planificacion (CU-05 a
/// CU-16).
///
/// Un solo controlador para los cuatro niveles porque comparten el mismo patron:
/// validar en dominio, escribir, recargar el planning. Cada metodo devuelve su
/// `Result` en lugar de dejarlo solo en el estado, por la leccion del fallo de
/// CU-04: con dialogos de por medio, un provider autoDispose puede desecharse.
final class ControladorPlanificacionProvider
    extends $NotifierProvider<ControladorPlanificacion, EstadoAccion> {
  /// Orquesta todas las operaciones de escritura de la planificacion (CU-05 a
  /// CU-16).
  ///
  /// Un solo controlador para los cuatro niveles porque comparten el mismo patron:
  /// validar en dominio, escribir, recargar el planning. Cada metodo devuelve su
  /// `Result` en lugar de dejarlo solo en el estado, por la leccion del fallo de
  /// CU-04: con dialogos de por medio, un provider autoDispose puede desecharse.
  ControladorPlanificacionProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'controladorPlanificacionProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$controladorPlanificacionHash();

  @$internal
  @override
  ControladorPlanificacion create() => ControladorPlanificacion();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(EstadoAccion value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<EstadoAccion>(value),
    );
  }
}

String _$controladorPlanificacionHash() =>
    r'b465da7ac8983a9e9958664ced85054ebfa005ba';

/// Orquesta todas las operaciones de escritura de la planificacion (CU-05 a
/// CU-16).
///
/// Un solo controlador para los cuatro niveles porque comparten el mismo patron:
/// validar en dominio, escribir, recargar el planning. Cada metodo devuelve su
/// `Result` en lugar de dejarlo solo en el estado, por la leccion del fallo de
/// CU-04: con dialogos de por medio, un provider autoDispose puede desecharse.

abstract class _$ControladorPlanificacion extends $Notifier<EstadoAccion> {
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
