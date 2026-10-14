import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:aimar_trainer_app/core/errores/error_app.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/estado_ejercicio.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/grupo_muscular.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/musculo.dart';
import 'package:aimar_trainer_app/features/biblioteca_ejercicios/domain/tipo_ejercicio.dart';

part 'ejercicio.freezed.dart';
part 'ejercicio.g.dart';

/// Ejercicio de la biblioteca (entidad 5 de `docs/domain-model.md`).
///
/// Editar nombre, descripcion o grupo muscular no altera los parametros ya
/// guardados en ejercicios planificados existentes (RF-03): esos guardan su
/// propia copia de series y minutos, y solo referencian el `id`.
@freezed
abstract class Ejercicio with _$Ejercicio {
  // Necesario para que freezed admita los getters derivados de abajo.
  const Ejercicio._();

  const factory Ejercicio({
    required String id,
    required String nombre,
    required String descripcion,
    required TipoEjercicio tipo,
    required EstadoEjercicio estado,
    required DateTime creadoEn,

    /// Grupo guardado **a mano**, y solo cuando no hay musculo principal (el
    /// cardio, que no tiene uno concreto). Con principal, el grupo se deriva de
    /// el: usa [grupo], no este campo.
    @JsonKey(name: 'grupo_muscular')
    @ConversorGrupoMuscular()
    GrupoMuscular? grupoDeclarado,
    @ConversorMusculo() Musculo? musculoPrincipal,
    @ConversorMusculos()
    @Default(<Musculo>[])
    List<Musculo> musculosSecundarios,
    String? equipamiento,
    String? videoEjemploUrl,

    /// Si el peso de este ejercicio se cuenta **por lado**: al cliente se le
    /// presenta "7,5 kg por lado" en vez de "7,5 kg".
    ///
    /// Es una **etiqueta, no una operacion**: el peso se guarda tal cual y nunca
    /// se multiplica. Multiplicarlo volveria incomparable todo el historico ya
    /// registrado.
    ///
    /// Vive en el ejercicio y no en el ejercicio planificado porque describe
    /// como se carga (mancuernas, polea unilateral, barra con discos por lado),
    /// no una semana concreta. La contrapartida, aceptada el 2026-10-14:
    /// desmarcarlo cambia tambien como se lee el historico de ese ejercicio,
    /// igual que renombrarlo renombra todo su historico.
    @Default(false) bool pesoPorLado,

    /// Ruta de la ilustracion dentro del bucket publico `imagenes-ejercicios`.
    /// No se guarda la URL completa porque el dominio cambia entre local y la
    /// nube; la arma el repositorio.
    String? imagenRuta,
  }) = _Ejercicio;

  factory Ejercicio.fromJson(Map<String, dynamic> json) =>
      _$EjercicioFromJson(json);

  /// Grupo muscular efectivo: el del musculo principal si lo hay, y si no el
  /// declarado a mano. `null` si el ejercicio esta sin clasificar.
  GrupoMuscular? get grupo => musculoPrincipal?.grupo ?? grupoDeclarado;

  /// Principal primero, secundarios despues. Vacia si no se ha clasificado.
  List<Musculo> get musculos => [?musculoPrincipal, ...musculosSecundarios];

  /// Todos los grupos que toca el ejercicio, no solo el principal: filtrar por
  /// "Pierna" tiene que encontrar la sentadilla aunque su principal sea
  /// cuadriceps y el gluteo vaya de secundario.
  Set<GrupoMuscular> get grupos => {
    ?grupo,
    for (final musculo in musculosSecundarios) musculo.grupo,
  };

  /// Un ejercicio puede tener secundarios sin principal (en rehabilitacion
  /// tiene sentido decir que musculos entran sin senalar un protagonista), asi
  /// que no basta con mirar el grupo.
  bool get estaClasificado => grupo != null || musculosSecundarios.isNotEmpty;

  /// Trabaja ese musculo, como principal o como secundario.
  bool trabaja(Musculo musculo) =>
      musculoPrincipal == musculo || musculosSecundarios.contains(musculo);

  /// "Pierna · Cuádriceps" o, sin principal, solo "Pierna". Lo que se pinta
  /// bajo el nombre en el listado.
  String? get resumenMuscular =>
      musculoPrincipal?.etiquetaConGrupo ?? grupo?.etiqueta;
}

/// Datos que el entrenador introduce al crear o editar un ejercicio (CU-02,
/// CU-03). No incluye `id`, `estado` ni `creadoEn`: los gestiona la base de datos
/// o el propio flujo de baja.
class DatosEjercicio {
  const DatosEjercicio({
    required this.nombre,
    required this.descripcion,
    required this.tipo,
    this.grupoDeclarado,
    this.musculoPrincipal,
    this.musculosSecundarios = const <Musculo>[],
    this.equipamiento,
    this.videoEjemploUrl,
    this.imagenRuta,
    this.pesoPorLado = false,
  });

  static const int longitudMaximaNombre = 120;
  static const int longitudMaximaDescripcion = 2000;

  final String nombre;
  final String descripcion;
  final TipoEjercicio tipo;

  /// Solo se guarda cuando no hay [musculoPrincipal]; ver [Ejercicio.grupo].
  final GrupoMuscular? grupoDeclarado;
  final Musculo? musculoPrincipal;
  final List<Musculo> musculosSecundarios;
  final String? equipamiento;
  final String? videoEjemploUrl;

  /// Ver [Ejercicio.pesoPorLado].
  final bool pesoPorLado;

  /// Ruta ya subida al bucket. La imagen se sube antes de guardar la fila, asi
  /// que cuando estos datos llegan al repositorio ya es una ruta, no un fichero.
  final String? imagenRuta;

  String get nombreNormalizado => nombre.trim();

  /// El grupo solo viaja si no hay musculo principal: con principal lo deriva
  /// la entidad, y la base de datos rechaza guardar los dos
  /// (`grupo_solo_sin_musculo_principal`).
  GrupoMuscular? get grupoNormalizado =>
      musculoPrincipal == null ? grupoDeclarado : null;

  /// Sin duplicados y sin el principal dentro, conservando el orden en que se
  /// eligieron.
  List<Musculo> get secundariosNormalizados {
    final vistos = <Musculo>{};
    return musculosSecundarios
        .where((musculo) => musculo != musculoPrincipal && vistos.add(musculo))
        .toList();
  }

  /// Campos de texto opcionales: se guardan como `null` si quedan vacios, para
  /// no mezclar cadena vacia y ausencia de dato en la base de datos.
  String? get equipamientoNormalizado => _oNulo(equipamiento);
  String? get videoEjemploUrlNormalizada => _oNulo(videoEjemploUrl);

  static String? _oNulo(String? valor) {
    final limpio = valor?.trim() ?? '';
    return limpio.isEmpty ? null : limpio;
  }

  static ErrorValidacion? validarNombre(String nombre) {
    final valor = nombre.trim();
    if (valor.isEmpty) {
      return const ErrorValidacion(
        'El nombre es obligatorio.',
        campo: 'nombre',
      );
    }
    if (valor.length > longitudMaximaNombre) {
      return const ErrorValidacion(
        'El nombre no puede pasar de $longitudMaximaNombre caracteres.',
        campo: 'nombre',
      );
    }
    return null;
  }

  /// La descripcion es **opcional**: hay ejercicios que se explican solos y
  /// obligar a escribir algo solo conseguia rellenos del tipo "sentadilla".
  /// Vacia se guarda como cadena vacia, no como `null`, porque la columna es
  /// `not null` y no merecia una migracion; la ficha oculta el apartado cuando
  /// no hay nada que contar.
  static ErrorValidacion? validarDescripcion(String descripcion) {
    final valor = descripcion.trim();
    if (valor.length > longitudMaximaDescripcion) {
      return const ErrorValidacion(
        'La descripción no puede pasar de '
        '$longitudMaximaDescripcion caracteres.',
        campo: 'descripcion',
      );
    }
    return null;
  }

  /// El video es opcional, pero si se indica tiene que ser una URL http(s):
  /// se abre en el navegador del cliente.
  static ErrorValidacion? validarVideo(String? url) {
    final valor = url?.trim() ?? '';
    if (valor.isEmpty) return null;

    final uri = Uri.tryParse(valor);
    final esValida =
        uri != null &&
        uri.hasScheme &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        (uri.host.isNotEmpty);
    if (!esValida) {
      return const ErrorValidacion(
        'El enlace del vídeo debe empezar por http:// o https://.',
        campo: 'videoEjemploUrl',
      );
    }
    return null;
  }

  /// La clasificacion muscular es opcional, pero si se usa tiene que ser
  /// coherente: el musculo principal no puede repetirse entre los secundarios.
  /// Los duplicados sueltos no son un error, se descartan en
  /// [secundariosNormalizados]; esto si lo es, porque significa que el
  /// entrenador ha elegido dos cosas distintas para el mismo musculo.
  static ErrorValidacion? validarMusculos({
    required Musculo? principal,
    required List<Musculo> secundarios,
  }) {
    if (principal != null && secundarios.contains(principal)) {
      return ErrorValidacion(
        '${principal.etiqueta} ya es el músculo principal: quítalo de los '
        'secundarios.',
        campo: 'musculos',
      );
    }
    return null;
  }

  /// Primer error de validacion, o `null` si los datos son validos.
  ErrorValidacion? validar() =>
      validarNombre(nombre) ??
      validarDescripcion(descripcion) ??
      validarVideo(videoEjemploUrl) ??
      validarMusculos(
        principal: musculoPrincipal,
        secundarios: musculosSecundarios,
      );

  /// Cuerpo para Supabase. Las claves van en `snake_case` porque aqui se escribe
  /// un filtro/payload a mano, no un modelo generado.
  Map<String, dynamic> aJsonDeEscritura() => {
    'nombre': nombreNormalizado,
    'descripcion': descripcion.trim(),
    'tipo': tipo.name,
    'grupo_muscular': grupoNormalizado?.valorJson,
    'musculo_principal': musculoPrincipal?.valorJson,
    'musculos_secundarios': secundariosNormalizados
        .map((musculo) => musculo.valorJson)
        .toList(),
    'equipamiento': equipamientoNormalizado,
    'video_ejemplo_url': videoEjemploUrlNormalizada,
    'imagen_ruta': _oNulo(imagenRuta),
    'peso_por_lado': pesoPorLado,
  };

  /// Mismos datos con otra imagen. Lo usa el controlador cuando acaba de subir
  /// una: el formulario no conoce la ruta hasta que la subida termina.
  DatosEjercicio conImagen(String? ruta) => DatosEjercicio(
    nombre: nombre,
    descripcion: descripcion,
    tipo: tipo,
    grupoDeclarado: grupoDeclarado,
    musculoPrincipal: musculoPrincipal,
    musculosSecundarios: musculosSecundarios,
    pesoPorLado: pesoPorLado,
    equipamiento: equipamiento,
    videoEjemploUrl: videoEjemploUrl,
    imagenRuta: ruta,
  );

  /// Datos precargados al abrir el formulario de edicion (CU-03, paso 2).
  factory DatosEjercicio.desdeEjercicio(Ejercicio ejercicio) => DatosEjercicio(
    nombre: ejercicio.nombre,
    descripcion: ejercicio.descripcion,
    tipo: ejercicio.tipo,
    grupoDeclarado: ejercicio.grupoDeclarado,
    musculoPrincipal: ejercicio.musculoPrincipal,
    musculosSecundarios: ejercicio.musculosSecundarios,
    equipamiento: ejercicio.equipamiento,
    videoEjemploUrl: ejercicio.videoEjemploUrl,
    imagenRuta: ejercicio.imagenRuta,
  );
}
