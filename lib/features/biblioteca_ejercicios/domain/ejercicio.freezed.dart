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

 String get id; String get nombre; String get descripcion; TipoEjercicio get tipo; EstadoEjercicio get estado; DateTime get creadoEn; String? get grupoMuscular; String? get equipamiento; String? get videoEjemploUrl;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Ejercicio&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.descripcion, _this.descripcion) || other.descripcion == _this.descripcion)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.creadoEn, _this.creadoEn) || other.creadoEn == _this.creadoEn)&&(identical(other.grupoMuscular, _this.grupoMuscular) || other.grupoMuscular == _this.grupoMuscular)&&(identical(other.equipamiento, _this.equipamiento) || other.equipamiento == _this.equipamiento)&&(identical(other.videoEjemploUrl, _this.videoEjemploUrl) || other.videoEjemploUrl == _this.videoEjemploUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Ejercicio;
  return Object.hash(runtimeType,_this.id,_this.nombre,_this.descripcion,_this.tipo,_this.estado,_this.creadoEn,_this.grupoMuscular,_this.equipamiento,_this.videoEjemploUrl);
}

@override
String toString() {
  final _this = this as Ejercicio;
  return 'Ejercicio(id: ${_this.id}, nombre: ${_this.nombre}, descripcion: ${_this.descripcion}, tipo: ${_this.tipo}, estado: ${_this.estado}, creadoEn: ${_this.creadoEn}, grupoMuscular: ${_this.grupoMuscular}, equipamiento: ${_this.equipamiento}, videoEjemploUrl: ${_this.videoEjemploUrl})';
}


}

/// @nodoc
abstract mixin class $EjercicioCopyWith<$Res>  {
  factory $EjercicioCopyWith(Ejercicio value, $Res Function(Ejercicio) _then) = _$EjercicioCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, String descripcion, TipoEjercicio tipo, EstadoEjercicio estado, DateTime creadoEn, String? grupoMuscular, String? equipamiento, String? videoEjemploUrl
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
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? descripcion = null,Object? tipo = null,Object? estado = null,Object? creadoEn = null,Object? grupoMuscular = freezed,Object? equipamiento = freezed,Object? videoEjemploUrl = freezed,}) {
  return _then(Ejercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoEjercicio,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,grupoMuscular: freezed == grupoMuscular ? _self.grupoMuscular : grupoMuscular // ignore: cast_nullable_to_non_nullable
as String?,equipamiento: freezed == equipamiento ? _self.equipamiento : equipamiento // ignore: cast_nullable_to_non_nullable
as String?,videoEjemploUrl: freezed == videoEjemploUrl ? _self.videoEjemploUrl : videoEjemploUrl // ignore: cast_nullable_to_non_nullable
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  String descripcion,  TipoEjercicio tipo,  EstadoEjercicio estado,  DateTime creadoEn,  String? grupoMuscular,  String? equipamiento,  String? videoEjemploUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Ejercicio() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.tipo,_that.estado,_that.creadoEn,_that.grupoMuscular,_that.equipamiento,_that.videoEjemploUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  String descripcion,  TipoEjercicio tipo,  EstadoEjercicio estado,  DateTime creadoEn,  String? grupoMuscular,  String? equipamiento,  String? videoEjemploUrl)  $default,) {final _that = this;
switch (_that) {
case _Ejercicio():
return $default(_that.id,_that.nombre,_that.descripcion,_that.tipo,_that.estado,_that.creadoEn,_that.grupoMuscular,_that.equipamiento,_that.videoEjemploUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  String descripcion,  TipoEjercicio tipo,  EstadoEjercicio estado,  DateTime creadoEn,  String? grupoMuscular,  String? equipamiento,  String? videoEjemploUrl)?  $default,) {final _that = this;
switch (_that) {
case _Ejercicio() when $default != null:
return $default(_that.id,_that.nombre,_that.descripcion,_that.tipo,_that.estado,_that.creadoEn,_that.grupoMuscular,_that.equipamiento,_that.videoEjemploUrl);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Ejercicio implements Ejercicio {
  const _Ejercicio({required this.id, required this.nombre, required this.descripcion, required this.tipo, required this.estado, required this.creadoEn, this.grupoMuscular, this.equipamiento, this.videoEjemploUrl});
  factory _Ejercicio.fromJson(Map<String, dynamic> json) => _$EjercicioFromJson(json);

@override final  String id;
@override final  String nombre;
@override final  String descripcion;
@override final  TipoEjercicio tipo;
@override final  EstadoEjercicio estado;
@override final  DateTime creadoEn;
@override final  String? grupoMuscular;
@override final  String? equipamiento;
@override final  String? videoEjemploUrl;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Ejercicio&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.descripcion, descripcion) || other.descripcion == descripcion)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.creadoEn, creadoEn) || other.creadoEn == creadoEn)&&(identical(other.grupoMuscular, grupoMuscular) || other.grupoMuscular == grupoMuscular)&&(identical(other.equipamiento, equipamiento) || other.equipamiento == equipamiento)&&(identical(other.videoEjemploUrl, videoEjemploUrl) || other.videoEjemploUrl == videoEjemploUrl));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nombre,descripcion,tipo,estado,creadoEn,grupoMuscular,equipamiento,videoEjemploUrl);
}

@override
String toString() {
    return 'Ejercicio(id: $id, nombre: $nombre, descripcion: $descripcion, tipo: $tipo, estado: $estado, creadoEn: $creadoEn, grupoMuscular: $grupoMuscular, equipamiento: $equipamiento, videoEjemploUrl: $videoEjemploUrl)';
}


}

/// @nodoc
abstract mixin class _$EjercicioCopyWith<$Res> implements $EjercicioCopyWith<$Res> {
  factory _$EjercicioCopyWith(_Ejercicio value, $Res Function(_Ejercicio) _then) = __$EjercicioCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, String descripcion, TipoEjercicio tipo, EstadoEjercicio estado, DateTime creadoEn, String? grupoMuscular, String? equipamiento, String? videoEjemploUrl
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
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? descripcion = null,Object? tipo = null,Object? estado = null,Object? creadoEn = null,Object? grupoMuscular = freezed,Object? equipamiento = freezed,Object? videoEjemploUrl = freezed,}) {
  return _then(_Ejercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,descripcion: null == descripcion ? _self.descripcion : descripcion // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoEjercicio,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoEjercicio,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,grupoMuscular: freezed == grupoMuscular ? _self.grupoMuscular : grupoMuscular // ignore: cast_nullable_to_non_nullable
as String?,equipamiento: freezed == equipamiento ? _self.equipamiento : equipamiento // ignore: cast_nullable_to_non_nullable
as String?,videoEjemploUrl: freezed == videoEjemploUrl ? _self.videoEjemploUrl : videoEjemploUrl // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
