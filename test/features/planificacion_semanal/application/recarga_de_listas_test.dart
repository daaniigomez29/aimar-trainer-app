import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:aimar_trainer_app/core/errores/result.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/application/controlador_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/data/planning_repositorio_supabase.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/datos_planificacion.dart';
import 'package:aimar_trainer_app/features/planificacion_semanal/domain/planning_repositorio.dart';

import '../ayudas_planificacion.dart';

class PlanningFalso extends Mock implements PlanningRepositorio {}

/// Lo que cambia **qué plannings hay** tiene que dejar las listas al día solo.
///
/// El fallo que esto cubre: al eliminar un planning, el histórico del cliente
/// seguía enseñándolo hasta pulsar "recargar", porque la invalidación estaba en
/// cada pantalla y a esta se le había olvidado.
void main() {
  late PlanningFalso repositorio;
  late ProviderContainer contenedor;

  setUpAll(() {
    registerFallbackValue(
      DatosPlanning(clienteId: 'cli-1', fechaInicio: DateTime(2026)),
    );
  });

  setUp(() {
    repositorio = PlanningFalso();
    when(() => repositorio.listarDeCliente('cli-1'))
        .thenAnswer((_) async => Success([planningDePrueba()]));
    contenedor = ProviderContainer(
      overrides: [planningRepositorioProvider.overrideWithValue(repositorio)],
    );
    addTearDown(contenedor.dispose);
  });

  /// Deja la lista cargada y con alguien escuchando, como una pantalla abierta.
  Future<void> conLaListaAbierta() async {
    contenedor.listen(planningsDeClienteProvider('cli-1'), (_, _) {});
    await contenedor.read(planningsDeClienteProvider('cli-1').future);
    verify(() => repositorio.listarDeCliente('cli-1')).called(1);
  }

  test('eliminar un planning recarga la lista del cliente', () async {
    when(() => repositorio.eliminarPlanning(any()))
        .thenAnswer((_) async => const Success(null));
    await conLaListaAbierta();

    await contenedor
        .read(controladorPlanificacionProvider.notifier)
        .eliminarPlanning('p-1');
    await contenedor.read(planningsDeClienteProvider('cli-1').future);

    verify(() => repositorio.listarDeCliente('cli-1')).called(1);
  });

  test('crear un planning recarga la lista del cliente', () async {
    when(() => repositorio.crearPlanning(any()))
        .thenAnswer((_) async => Success(planningDePrueba()));
    await conLaListaAbierta();

    await contenedor
        .read(controladorPlanificacionProvider.notifier)
        .crearPlanning(
          DatosPlanning(
            clienteId: 'cli-1',
            fechaInicio: DateTime(2026, 10, 12),
          ),
        );
    await contenedor.read(planningsDeClienteProvider('cli-1').future);

    verify(() => repositorio.listarDeCliente('cli-1')).called(1);
  });

  test('archivar un planning recarga la lista del cliente', () async {
    when(() => repositorio.archivarPlanning(any()))
        .thenAnswer((_) async => Success(planningDePrueba()));
    await conLaListaAbierta();

    await contenedor
        .read(controladorPlanificacionProvider.notifier)
        .archivarPlanning('p-1');
    await contenedor.read(planningsDeClienteProvider('cli-1').future);

    verify(() => repositorio.listarDeCliente('cli-1')).called(1);
  });

  // Lo de dentro de un planning no toca las listas: cambia el contenido de uno,
  // no cuáles hay.
  test('eliminar una sesión no recarga la lista', () async {
    when(() => repositorio.eliminarSesion(any()))
        .thenAnswer((_) async => const Success(null));
    await conLaListaAbierta();

    await contenedor
        .read(controladorPlanificacionProvider.notifier)
        .eliminarSesion(id: 's-1', planningId: 'p-1');

    verifyNever(() => repositorio.listarDeCliente('cli-1'));
  });
}
