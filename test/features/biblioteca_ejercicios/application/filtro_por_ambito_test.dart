import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:aimar_trainer_app/features/biblioteca_ejercicios/application/controlador_biblioteca.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/filtro_ejercicios.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';

/// POR QUE ESTE TEST: la pantalla de biblioteca y el selector con el que se
/// añade un ejercicio a un bloque compartían el mismo filtro. Buscar "sent" en
/// el selector dejaba la biblioteca enseñando solo la sentadilla, **sin nada
/// escrito en su buscador** que lo explicara, y no volvía hasta escribir y
/// borrar ahí. Es un fallo que no se ve mirando una pantalla sola.
void main() {
  late ProviderContainer contenedor;

  setUp(() {
    contenedor = ProviderContainer();
    addTearDown(contenedor.dispose);
  });

  FiltroEjercicios filtroDe(AmbitoDeFiltro ambito) =>
      contenedor.read(filtroBibliotecaProvider(ambito));

  FiltroBiblioteca notificadorDe(AmbitoDeFiltro ambito) =>
      contenedor.read(filtroBibliotecaProvider(ambito).notifier);

  test('buscar en el selector no filtra la biblioteca', () {
    notificadorDe(AmbitoDeFiltro.formularioBloque).cambiarTexto('sent');

    expect(filtroDe(AmbitoDeFiltro.formularioBloque).texto, 'sent');
    expect(filtroDe(AmbitoDeFiltro.biblioteca).texto, isEmpty);
    expect(filtroDe(AmbitoDeFiltro.biblioteca).estaVacio, isTrue);
  });

  test('y al revés tampoco', () {
    notificadorDe(AmbitoDeFiltro.biblioteca).cambiarGrupo(GrupoMuscular.pierna);

    expect(filtroDe(AmbitoDeFiltro.biblioteca).grupo, GrupoMuscular.pierna);
    expect(filtroDe(AmbitoDeFiltro.formularioBloque).grupo, isNull);
  });

  // El panel del planning y el formulario pueden verse en el mismo recorrido:
  // que uno herede el filtro del otro se lee como que la pantalla esta rota.
  test('el panel del planning y el formulario tampoco se pisan', () {
    notificadorDe(AmbitoDeFiltro.formularioBloque)
        .cambiarMusculo(Musculo.cuadriceps);

    expect(
      filtroDe(AmbitoDeFiltro.formularioBloque).musculo,
      Musculo.cuadriceps,
    );
    expect(filtroDe(AmbitoDeFiltro.panelPlanning).musculo, isNull);
    expect(filtroDe(AmbitoDeFiltro.panelPlanning).grupo, isNull);
  });

  // Con un musculo elegido, pulsar "Todo pierna" no hacia nada visible:
  // `cambiarGrupo` conservaba el musculo y el chip se quedaba sin marcar.
  test('ver todo el grupo suelta el músculo elegido', () {
    final notificador = notificadorDe(AmbitoDeFiltro.biblioteca);
    notificador.cambiarMusculo(Musculo.cuadriceps);

    notificador.verTodoElGrupo(GrupoMuscular.pierna);

    expect(filtroDe(AmbitoDeFiltro.biblioteca).grupo, GrupoMuscular.pierna);
    expect(filtroDe(AmbitoDeFiltro.biblioteca).musculo, isNull);
  });
}
