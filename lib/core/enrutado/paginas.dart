import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Pagina de una **seccion principal**: las de la barra de navegacion
/// (Progreso, Control, Biblioteca, Ajustes...). Tambien la de las rutas raiz
/// (carga, login, inicio de cada rol): cambiar entre ellas tampoco es entrar
/// en nada.
///
/// POR QUE EXISTE: esas rutas cuelgan de la de inicio del rol (`/cliente/
/// progreso` es hija de `/cliente`), asi que la pila tiene una pagina debajo y
/// la cabecera ponia sola una flecha de atras. Pero una seccion no es "un
/// sitio dentro de otro": se llega a ella desde la barra, y la flecha solo
/// tiene sentido en lo que se abre **dentro** de una seccion. Tambien cambia
/// sin animacion: cambiar de pestaña no es entrar en nada.
///
/// Lo hace la ruta y no cada pantalla para que ninguna seccion pueda
/// olvidarse de quitar la flecha.
class PaginaDeSeccion<T> extends Page<T> {
  const PaginaDeSeccion({
    required this.child,
    super.key,
    super.name,
    super.arguments,
    super.restorationId,
  });

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) => _RutaDeSeccion<T>(this);
}

class _RutaDeSeccion<T> extends PageRoute<T> {
  _RutaDeSeccion(PaginaDeSeccion<T> pagina) : super(settings: pagina);

  PaginaDeSeccion<T> get _pagina => settings as PaginaDeSeccion<T>;

  /// Lo que lee la `AppBar` para decidir si pone flecha.
  @override
  bool get impliesAppBarDismissal => false;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  Duration get reverseTransitionDuration => Duration.zero;

  @override
  bool get maintainState => true;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _pagina.child;
}

/// Pagina de una vista **dentro** de una seccion: entra y sale con la
/// transicion del tema ([TransicionDeslizante]).
///
/// POR QUE NO VALE `builder:` EN EL `GoRoute`: con `builder`, go_router
/// fabrica la pagina el mismo, y para elegir el tipo busca un `MaterialApp`
/// por encima. Pero go_router 18 usa su copia de Material (`material_ui`), cuyo
/// `MaterialApp` es otra clase que el de Flutter que usa la app: no lo
/// reconoce, cree que no es una app Material y monta **todas** las paginas sin
/// transicion. Por eso nunca hubo animacion al entrar ni al salir. Haciendo
/// aqui la pagina, no depende de ese reconocimiento.
Page<void> paginaDeVista(GoRouterState state, Widget child) =>
    MaterialPage<void>(
      key: state.pageKey,
      name: state.name ?? state.path,
      restorationId: state.pageKey.value,
      child: child,
    );

/// Transicion de las vistas que se abren **dentro** de una seccion (un
/// ejercicio de la biblioteca, la ficha de un cliente...): la nueva entra
/// deslizandose desde la derecha y, al volver, sale por la derecha. Es el
/// gesto que se espera en un movil, y deja claro que se ha entrado en algo.
///
/// La misma en todas las plataformas: en la web, la de Material por defecto
/// apenas se nota. Con "reducir movimiento" del sistema, sin animacion.
class TransicionDeslizante extends PageTransitionsBuilder {
  const TransicionDeslizante();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 280);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 240);

  /// Cuanto esta desplazada la pagina en cada momento de [animation], en
  /// fraccion de su ancho. Lo usa tambien [FijoEnLaTransicion] para
  /// contrarrestarlo exactamente.
  static Animation<Offset> desplazamiento(Animation<double> animation) =>
      Tween(begin: const Offset(1, 0), end: Offset.zero).animate(
        CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
          reverseCurve: Curves.easeInCubic,
        ),
      );

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) return child;
    return SlideTransition(position: desplazamiento(animation), child: child);
  }
}

/// Lo que **no se mueve** cuando la pagina entra o sale deslizandose: las
/// barras de navegacion.
///
/// POR QUE: la barra va dentro de cada pantalla, asi que la pagina que entra
/// traia su barra deslizandose por encima de la de debajo, y parecia un fallo
/// (dos barras superpuestas). Esto la desplaza en sentido contrario y en el
/// mismo instante: se queda en su sitio, encima de la de debajo, que es igual.
///
/// La alternativa de manual seria una barra comun fuera de las paginas
/// (`ShellRoute`), pero obliga a rehacer el enrutador y todas las pantallas.
class FijoEnLaTransicion extends StatelessWidget {
  const FijoEnLaTransicion({required this.child, super.key});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final animacion = ModalRoute.of(context)?.animation;
    if (animacion == null || MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final desplazamiento = TransicionDeslizante.desplazamiento(animacion);
    final ancho = MediaQuery.sizeOf(context).width;
    return AnimatedBuilder(
      animation: desplazamiento,
      builder: (context, hijo) => Transform.translate(
        offset: Offset(-desplazamiento.value.dx * ancho, 0),
        child: hijo,
      ),
      child: child,
    );
  }
}
