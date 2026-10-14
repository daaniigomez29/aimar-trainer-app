// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ejercicio.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Ejercicio {

 String get id; String get nombre; String get descripcion; TipoEjercicio get tipo; EstadoEjercicio get estado; DateTime get creadoEn;/// Grupo guardado **a mano**, y solo cuando no hay musculo principal (el
/// cardio, que no tiene uno concreto). Con principal, el grupo se deriva de
/// el: usa [grupo], no este campo.
@JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular() GrupoMuscular? get grupoDeclarado;@ConversorMusculo() Musculo? get musculoPrincipal;@ConversorMusculos() List<Musculo> get musculosSecundarios; String? get equipamiento; String? get videoEjemploUrl;/// Si el peso de este ejercicio se cuenta **por lado**: al cliente se le
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
 bool get pesoPorLado;/// Ruta de la ilustracion dentro del bucket publico `imagenes-ejercicios`.
/// No se guarda la URL completa porque el dominio cambia entre local y la
/// nube; la arma el repositorio.
 String? get imagenRuta;
/// Create a copy of Ejercicio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EjercicioCopyWith<Ejercicio> get copyWith => _$EjercicioCopyWithImpl<Ejercicio>(this as Ejercicio, _$identity);

  /// Serializes this Ejercicio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Ejercicio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ejercicio&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.creadoEn, _this.creadoEn) || other.creadoEn == _this.creadoEn)&&(identical(other.grupoDeclarado, _this.grupoDeclarado) || other.grupoDeclarado == _this.grupoDeclarado)&&(identical(other.musculoPrincipal, _this.musculoPrincipal) || other.musculoPrincipal == _this.musculoPrincipal)&&const DeepCollectionEquality().equals(other.musculosSecundarios, _this.musculosSecundarios)&&(identical(other.equipamiento, _this.equipamiento) || other.equipamiento == _this.equipamiento)&&(identical(other.videoEjemploUrl, _this.videoEjemploUrl) || other.videoEjemploUrl == _this.videoEjemploUrl)&&(identical(other.pesoPorLado, _this.pesoPorLado) || other.pesoPorLado == _this.pesoPorLado)&&(identical(other.imagenRuta, _this.imagenRuta) || other.imagenRuta == _this.imagenRuta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Ejercicio;
  return Object.hash(runtimeType,_this.id,_this.nombre,_this.descripcion,_this.tipo,_this.estado,_this.creadoEn,_this.grupoDeclarado,_this.musculoPrincipal,const DeepCollectionEquality().hash(_this.musculosSecundarios),_this.equipamiento,_this.videoEjemploUrl,_this.pesoPorLado,_this.imagenRuta);
}

@override
String toString() {
  final _this = this as Ejercicio;
  return 'Ejercicio(id: ${_this.id}, nombre: ${_this.nombre}, descripcion: ${_this.descripcion}, tipo: ${_this.tipo}, estado: ${_this.estado}, creadoEn: ${_this.creadoEn}, grupoDeclarado: ${_this.grupoDeclarado}, musculoPrincipal: ${_this.musculoPrincipal}, musculosSecundarios: ${_this.musculosSecundarios}, equipamiento: ${_this.equipamiento}, videoEjemploUrl: ${_this.videoEjemploUrl}, pesoPorLado: ${_this.pesoPorLado}, imagenRuta: ${_this.imagenRuta})';
}


}

/// @nodoc
abstract mixin class $EjercicioCopyWith<$Res>  {
  factory $EjercicioCopyWith(Ejercicio value, $Res Function(Ejercicio) _then) = _$EjercicioCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, String descripcion, TipoEjercicio tipo, EstadoEjercicio estado, DateTime creadoEn,@JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular() GrupoMuscular? grupoDeclarado,@ConversorMusculo() Musculo? musculoPrincipal,@ConversorMusculos() List<Musculo> musculosSecundarios, String? equipamiento, String? videoEjemploUrl, bool pesoPorLado, String? imagenRuta
});




}
/// @nodoc
class _$EjercicioCopyWithImpl<$Res>
    implements $EjercicioCopyWith<$Res> {
  _$EjercicioCopyWithImpl(this._self, this._then);

  final Ejercicio _self;
  final $Res Function(Ejercicio) _then;

/// Create a copy of Ejercicio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? descripcion = null,Object? tipo = null,Object? estado = null,Object? creadoEn = null,Object? grupoDeclarado = freezed,Object? musculoPrincipal = freezed,Object? musculosSecundarios = null,Object? equipamiento = freezed,Object? videoEjemploUrl = freezed,Object? pesoPorLado = null,Object? imagenRuta = freezed,}) {
  return _then(Ejercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoEjercicio,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,grupoDeclarado: freezed == grupoDeclarado ? _self.grupoDeclarado : grupoDeclarado // ignore: cast_nullable_to_non_nullable
as GrupoMuscular?,musculoPrincipal: freezed == musculoPrincipal ? _self.musculoPrincipal : musculoPrincipal // ignore: cast_nullable_to_non_nullable
as Musculo?,musculosSecundarios: null == musculosSecundarios ? _self.musculosSecundarios : musculosSecundarios // ignore: cast_nullable_to_non_nullable
as List<Musculo>,equipamiento: freezed == equipamiento ? _self.equipamiento : equipamiento // ignore: cast_nullable_to_non_nullable
as String?,videoEjemploUrl: freezed == videoEjemploUrl ? _self.videoEjemploUrl : videoEjemploUrl // ignore: cast_nullable_to_non_nullable
as String?,pesoPorLado: null == pesoPorLado ? _self.pesoPorLado : pesoPorLado // ignore: cast_nullable_to_non_nullable
as bool,imagenRuta: freezed == imagenRuta ? _self.imagenRuta : imagenRuta // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [Ejercicio].
extension EjercicioPatterns on Ejercicio {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Ejercicio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Ejercicio() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Ejercicio value)  $default,){
final _that = this;
switch (_that) {
case _Ejercicio():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Ejercicio value)?  $default,){
final _that = this;
switch (_that) {
case _Ejercicio() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  String descripcion,  TipoEjercicio tipo,  EstadoEjercicio estado,  DateTime creadoEn, @JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular()  GrupoMuscular? grupoDeclarado, @ConversorMusculo()  Musculo? musculoPrincipal, @ConversorMusculos()  List<Musculo> musculosSecundarios,  String? equipamiento,  String? videoEjemploUrl,  bool pesoPorLado,  String? imagenRuta)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ejercicio() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.tipo,_that.estado,_that.creadoEn,_that.grupoDeclarado,_that.musculoPrincipal,_that.musculosSecundarios,_that.equipamiento,_that.videoEjemploUrl,_that.pesoPorLado,_that.imagenRuta);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  String descripcion,  TipoEjercicio tipo,  EstadoEjercicio estado,  DateTime creadoEn, @JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular()  GrupoMuscular? grupoDeclarado, @ConversorMusculo()  Musculo? musculoPrincipal, @ConversorMusculos()  List<Musculo> musculosSecundarios,  String? equipamiento,  String? videoEjemploUrl,  bool pesoPorLado,  String? imagenRuta)  $default,) {final _that = this;
switch (_that) {
case _Ejercicio():
return $default(_that.id,_that.nombre,_that.descripcion,_that.tipo,_that.estado,_that.creadoEn,_that.grupoDeclarado,_that.musculoPrincipal,_that.musculosSecundarios,_that.equipamiento,_that.videoEjemploUrl,_that.pesoPorLado,_that.imagenRuta);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  String descripcion,  TipoEjercicio tipo,  EstadoEjercicio estado,  DateTime creadoEn, @JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular()  GrupoMuscular? grupoDeclarado, @ConversorMusculo()  Musculo? musculoPrincipal, @ConversorMusculos()  List<Musculo> musculosSecundarios,  String? equipamiento,  String? videoEjemploUrl,  bool pesoPorLado,  String? imagenRuta)?  $default,) {final _that = this;
switch (_that) {
case _Ejercicio() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.tipo,_that.estado,_that.creadoEn,_that.grupoDeclarado,_that.musculoPrincipal,_that.musculosSecundarios,_that.equipamiento,_that.videoEjemploUrl,_that.pesoPorLado,_that.imagenRuta);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ejercicio extends Ejercicio {
  const _Ejercicio({required this.id, required this.nombre, required this.descripcion, required this.tipo, required this.estado, required this.creadoEn, @JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular() this.grupoDeclarado, @ConversorMusculo() this.musculoPrincipal, @ConversorMusculos()  List<Musculo> musculosSecundarios = const <Musculo>[], this.equipamiento, this.videoEjemploUrl, this.pesoPorLado = false, this.imagenRuta}): _musculosSecundarios = musculosSecundarios,super._();
  factory _Ejercicio.fromJson(Map<String, dynamic> json) => _$EjercicioFromJson(json);

@override final  String id;
@override final  String nombre;
@override final  String descripcion;
@override final  TipoEjercicio tipo;
@override final  EstadoEjercicio estado;
@override final  DateTime creadoEn;
/// Grupo guardado **a mano**, y solo cuando no hay musculo principal (el
/// cardio, que no tiene uno concreto). Con principal, el grupo se deriva de
/// el: usa [grupo], no este campo.
@override@JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular() final  GrupoMuscular? grupoDeclarado;
@override@ConversorMusculo() final  Musculo? musculoPrincipal;
 final  List<Musculo> _musculosSecundarios;
@override@JsonKey()@ConversorMusculos() List<Musculo> get musculosSecundarios {
  if (_musculosSecundarios is EqualUnmodifiableListView) return _musculosSecundarios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_musculosSecundarios);
}

@override final  String? equipamiento;
@override final  String? videoEjemploUrl;
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
@override@JsonKey() final  bool pesoPorLado;
/// Ruta de la ilustracion dentro del bucket publico `imagenes-ejercicios`.
/// No se guarda la URL completa porque el dominio cambia entre local y la
/// nube; la arma el repositorio.
@override final  String? imagenRuta;

/// Create a copy of Ejercicio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EjercicioCopyWith<_Ejercicio> get copyWith => __$EjercicioCopyWithImpl<_Ejercicio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EjercicioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ejercicio&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.creadoEn, creadoEn) || other.creadoEn == creadoEn)&&(identical(other.grupoDeclarado, grupoDeclarado) || other.grupoDeclarado == grupoDeclarado)&&(identical(other.musculoPrincipal, musculoPrincipal) || other.musculoPrincipal == musculoPrincipal)&&const DeepCollectionEquality().equals(other.musculosSecundarios, _musculosSecundarios)&&(identical(other.equipamiento, equipamiento) || other.equipamiento == equipamiento)&&(identical(other.videoEjemploUrl, videoEjemploUrl) || other.videoEjemploUrl == videoEjemploUrl)&&(identical(other.pesoPorLado, pesoPorLado) || other.pesoPorLado == pesoPorLado)&&(identical(other.imagenRuta, imagenRuta) || other.imagenRuta == imagenRuta));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nombre,descripcion,tipo,estado,creadoEn,grupoDeclarado,musculoPrincipal,const DeepCollectionEquality().hash(_musculosSecundarios),equipamiento,videoEjemploUrl,pesoPorLado,imagenRuta);
}

@override
String toString() {
    return 'Ejercicio(id: $id, nombre: $nombre, descripcion: $descripcion, tipo: $tipo, estado: $estado, creadoEn: $creadoEn, grupoDeclarado: $grupoDeclarado, musculoPrincipal: $musculoPrincipal, musculosSecundarios: $musculosSecundarios, equipamiento: $equipamiento, videoEjemploUrl: $videoEjemploUrl, pesoPorLado: $pesoPorLado, imagenRuta: $imagenRuta)';
}


}

/// @nodoc
abstract mixin class _$EjercicioCopyWith<$Res> implements $EjercicioCopyWith<$Res> {
  factory _$EjercicioCopyWith(_Ejercicio value, $Res Function(_Ejercicio) _then) = __$EjercicioCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, String descripcion, TipoEjercicio tipo, EstadoEjercicio estado, DateTime creadoEn,@JsonKey(name: 'grupo_muscular')@ConversorGrupoMuscular() GrupoMuscular? grupoDeclarado,@ConversorMusculo() Musculo? musculoPrincipal,@ConversorMusculos() List<Musculo> musculosSecundarios, String? equipamiento, String? videoEjemploUrl, bool pesoPorLado, String? imagenRuta
});




}
/// @nodoc
class __$EjercicioCopyWithImpl<$Res>
    implements _$EjercicioCopyWith<$Res> {
  __$EjercicioCopyWithImpl(this._self, this._then);

  final _Ejercicio _self;
  final $Res Function(_Ejercicio) _then;

/// Create a copy of Ejercicio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? descripcion = null,Object? tipo = null,Object? estado = null,Object? creadoEn = null,Object? grupoDeclarado = freezed,Object? musculoPrincipal = freezed,Object? musculosSecundarios = null,Object? equipamiento = freezed,Object? videoEjemploUrl = freezed,Object? pesoPorLado = null,Object? imagenRuta = freezed,}) {
  return _then(_Ejercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoEjercicio,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,grupoDeclarado: freezed == grupoDeclarado ? _self.grupoDeclarado : grupoDeclarado // ignore: cast_nullable_to_non_nullable
as GrupoMuscular?,musculoPrincipal: freezed == musculoPrincipal ? _self.musculoPrincipal : musculoPrincipal // ignore: cast_nullable_to_non_nullable
as Musculo?,musculosSecundarios: null == musculosSecundarios ? _self._musculosSecundarios : musculosSecundarios // ignore: cast_nullable_to_non_nullable
as List<Musculo>,equipamiento: freezed == equipamiento ? _self.equipamiento : equipamiento // ignore: cast_nullable_to_non_nullable
as String?,videoEjemploUrl: freezed == videoEjemploUrl ? _self.videoEjemploUrl : videoEjemploUrl // ignore: cast_nullable_to_non_nullable
as String?,pesoPorLado: null == pesoPorLado ? _self.pesoPorLado : pesoPorLado // ignore: cast_nullable_to_non_nullable
as bool,imagenRuta: freezed == imagenRuta ? _self.imagenRuta : imagenRuta // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
