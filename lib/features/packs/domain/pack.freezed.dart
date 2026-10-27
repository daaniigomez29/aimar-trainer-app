// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pack.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Pack {

 String get id; String get nombre;/// Etiquetas de tipo, al menos una, sin repetidos y en el orden del enum
/// (lo normaliza un trigger). **Solo descriptivas** desde el 2026-10-27:
/// dicen de que va el pack, pero no limitan que ejercicios admite. Si un
/// ejercicio lleva series o minutos lo decide su propio tipo.
 List<TipoEjercicio> get tipos; DateTime get creadoEn;@JsonKey(name: 'pack_ejercicios') List<PackEjercicio> get ejercicios;
/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackCopyWith<Pack> get copyWith => _$PackCopyWithImpl<Pack>(this as Pack, _$identity);

  /// Serializes this Pack to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as Pack;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Pack&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&const DeepCollectionEquality().equals(other.tipos, _this.tipos)&&(identical(other.creadoEn, _this.creadoEn) || other.creadoEn == _this.creadoEn)&&const DeepCollectionEquality().equals(other.ejercicios, _this.ejercicios));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as Pack;
  return Object.hash(runtimeType,_this.id,_this.nombre,const DeepCollectionEquality().hash(_this.tipos),_this.creadoEn,const DeepCollectionEquality().hash(_this.ejercicios));
}

@override
String toString() {
  final _this = this as Pack;
  return 'Pack(id: ${_this.id}, nombre: ${_this.nombre}, tipos: ${_this.tipos}, creadoEn: ${_this.creadoEn}, ejercicios: ${_this.ejercicios})';
}


}

/// @nodoc
abstract mixin class $PackCopyWith<$Res>  {
  factory $PackCopyWith(Pack value, $Res Function(Pack) _then) = _$PackCopyWithImpl;
@useResult
$Res call({
 String id, String nombre, List<TipoEjercicio> tipos, DateTime creadoEn,@JsonKey(name: 'pack_ejercicios') List<PackEjercicio> ejercicios
});




}
/// @nodoc
class _$PackCopyWithImpl<$Res>
    implements $PackCopyWith<$Res> {
  _$PackCopyWithImpl(this._self, this._then);

  final Pack _self;
  final $Res Function(Pack) _then;

/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? nombre = null,Object? tipos = null,Object? creadoEn = null,Object? ejercicios = null,}) {
  return _then(Pack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,tipos: null == tipos ? _self.tipos : tipos // ignore: cast_nullable_to_non_nullable
as List<TipoEjercicio>,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,ejercicios: null == ejercicios ? _self.ejercicios : ejercicios // ignore: cast_nullable_to_non_nullable
as List<PackEjercicio>,
  ));
}

}


/// Adds pattern-matching-related methods to [Pack].
extension PackPatterns on Pack {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Pack value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Pack() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Pack value)  $default,){
final _that = this;
switch (_that) {
case _Pack():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Pack value)?  $default,){
final _that = this;
switch (_that) {
case _Pack() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String nombre,  List<TipoEjercicio> tipos,  DateTime creadoEn, @JsonKey(name: 'pack_ejercicios')  List<PackEjercicio> ejercicios)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Pack() when $default != null:
return $default(_that.id,_that.nombre,_that.tipos,_that.creadoEn,_that.ejercicios);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String nombre,  List<TipoEjercicio> tipos,  DateTime creadoEn, @JsonKey(name: 'pack_ejercicios')  List<PackEjercicio> ejercicios)  $default,) {final _that = this;
switch (_that) {
case _Pack():
return $default(_that.id,_that.nombre,_that.tipos,_that.creadoEn,_that.ejercicios);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String nombre,  List<TipoEjercicio> tipos,  DateTime creadoEn, @JsonKey(name: 'pack_ejercicios')  List<PackEjercicio> ejercicios)?  $default,) {final _that = this;
switch (_that) {
case _Pack() when $default != null:
return $default(_that.id,_that.nombre,_that.tipos,_that.creadoEn,_that.ejercicios);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Pack extends Pack {
  const _Pack({required this.id, required this.nombre, required  List<TipoEjercicio> tipos, required this.creadoEn, @JsonKey(name: 'pack_ejercicios')  List<PackEjercicio> ejercicios = const []}): _tipos = tipos,_ejercicios = ejercicios,super._();
  factory _Pack.fromJson(Map<String, dynamic> json) => _$PackFromJson(json);

@override final  String id;
@override final  String nombre;
/// Etiquetas de tipo, al menos una, sin repetidos y en el orden del enum
/// (lo normaliza un trigger). **Solo descriptivas** desde el 2026-10-27:
/// dicen de que va el pack, pero no limitan que ejercicios admite. Si un
/// ejercicio lleva series o minutos lo decide su propio tipo.
 final  List<TipoEjercicio> _tipos;
/// Etiquetas de tipo, al menos una, sin repetidos y en el orden del enum
/// (lo normaliza un trigger). **Solo descriptivas** desde el 2026-10-27:
/// dicen de que va el pack, pero no limitan que ejercicios admite. Si un
/// ejercicio lleva series o minutos lo decide su propio tipo.
@override List<TipoEjercicio> get tipos {
  if (_tipos is EqualUnmodifiableListView) return _tipos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tipos);
}

@override final  DateTime creadoEn;
 final  List<PackEjercicio> _ejercicios;
@override@JsonKey(name: 'pack_ejercicios') List<PackEjercicio> get ejercicios {
  if (_ejercicios is EqualUnmodifiableListView) return _ejercicios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ejercicios);
}


/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackCopyWith<_Pack> get copyWith => __$PackCopyWithImpl<_Pack>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Pack&&(identical(other.id, id) || other.id == id)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&const DeepCollectionEquality().equals(other.tipos, _tipos)&&(identical(other.creadoEn, creadoEn) || other.creadoEn == creadoEn)&&const DeepCollectionEquality().equals(other.ejercicios, _ejercicios));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,nombre,const DeepCollectionEquality().hash(_tipos),creadoEn,const DeepCollectionEquality().hash(_ejercicios));
}

@override
String toString() {
    return 'Pack(id: $id, nombre: $nombre, tipos: $tipos, creadoEn: $creadoEn, ejercicios: $ejercicios)';
}


}

/// @nodoc
abstract mixin class _$PackCopyWith<$Res> implements $PackCopyWith<$Res> {
  factory _$PackCopyWith(_Pack value, $Res Function(_Pack) _then) = __$PackCopyWithImpl;
@override @useResult
$Res call({
 String id, String nombre, List<TipoEjercicio> tipos, DateTime creadoEn,@JsonKey(name: 'pack_ejercicios') List<PackEjercicio> ejercicios
});




}
/// @nodoc
class __$PackCopyWithImpl<$Res>
    implements _$PackCopyWith<$Res> {
  __$PackCopyWithImpl(this._self, this._then);

  final _Pack _self;
  final $Res Function(_Pack) _then;

/// Create a copy of Pack
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? nombre = null,Object? tipos = null,Object? creadoEn = null,Object? ejercicios = null,}) {
  return _then(_Pack(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,tipos: null == tipos ? _self._tipos : tipos // ignore: cast_nullable_to_non_nullable
as List<TipoEjercicio>,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,ejercicios: null == ejercicios ? _self._ejercicios : ejercicios // ignore: cast_nullable_to_non_nullable
as List<PackEjercicio>,
  ));
}


}


/// @nodoc
mixin _$PackEjercicio {

 String get id; String get packId; String get ejercicioId; int get orden;@JsonKey(name: 'descanso_seg') int? get descansoSeg; double? get minutos;/// El ejercicio de la biblioteca, incrustado por la consulta. Es quien dice
/// como se llama y si esta dado de baja.
@JsonKey(name: 'ejercicios') Ejercicio? get ejercicio;@JsonKey(name: 'pack_series') List<PackSerie> get series;
/// Create a copy of PackEjercicio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackEjercicioCopyWith<PackEjercicio> get copyWith => _$PackEjercicioCopyWithImpl<PackEjercicio>(this as PackEjercicio, _$identity);

  /// Serializes this PackEjercicio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PackEjercicio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackEjercicio&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.packId, _this.packId) || other.packId == _this.packId)&&(identical(other.ejercicioId, _this.ejercicioId) || other.ejercicioId == _this.ejercicioId)&&(identical(other.orden, _this.orden) || other.orden == _this.orden)&&(identical(other.descansoSeg, _this.descansoSeg) || other.descansoSeg == _this.descansoSeg)&&(identical(other.minutos, _this.minutos) || other.minutos == _this.minutos)&&(identical(other.ejercicio, _this.ejercicio) || other.ejercicio == _this.ejercicio)&&const DeepCollectionEquality().equals(other.series, _this.series));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PackEjercicio;
  return Object.hash(runtimeType,_this.id,_this.packId,_this.ejercicioId,_this.orden,_this.descansoSeg,_this.minutos,_this.ejercicio,const DeepCollectionEquality().hash(_this.series));
}

@override
String toString() {
  final _this = this as PackEjercicio;
  return 'PackEjercicio(id: ${_this.id}, packId: ${_this.packId}, ejercicioId: ${_this.ejercicioId}, orden: ${_this.orden}, descansoSeg: ${_this.descansoSeg}, minutos: ${_this.minutos}, ejercicio: ${_this.ejercicio}, series: ${_this.series})';
}


}

/// @nodoc
abstract mixin class $PackEjercicioCopyWith<$Res>  {
  factory $PackEjercicioCopyWith(PackEjercicio value, $Res Function(PackEjercicio) _then) = _$PackEjercicioCopyWithImpl;
@useResult
$Res call({
 String id, String packId, String ejercicioId, int orden,@JsonKey(name: 'descanso_seg') int? descansoSeg, double? minutos,@JsonKey(name: 'ejercicios') Ejercicio? ejercicio,@JsonKey(name: 'pack_series') List<PackSerie> series
});


$EjercicioCopyWith<$Res>? get ejercicio;

}
/// @nodoc
class _$PackEjercicioCopyWithImpl<$Res>
    implements $PackEjercicioCopyWith<$Res> {
  _$PackEjercicioCopyWithImpl(this._self, this._then);

  final PackEjercicio _self;
  final $Res Function(PackEjercicio) _then;

/// Create a copy of PackEjercicio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? packId = null,Object? ejercicioId = null,Object? orden = null,Object? descansoSeg = freezed,Object? minutos = freezed,Object? ejercicio = freezed,Object? series = null,}) {
  return _then(PackEjercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,descansoSeg: freezed == descansoSeg ? _self.descansoSeg : descansoSeg // ignore: cast_nullable_to_non_nullable
as int?,minutos: freezed == minutos ? _self.minutos : minutos // ignore: cast_nullable_to_non_nullable
as double?,ejercicio: freezed == ejercicio ? _self.ejercicio : ejercicio // ignore: cast_nullable_to_non_nullable
as Ejercicio?,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<PackSerie>,
  ));
}
/// Create a copy of PackEjercicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EjercicioCopyWith<$Res>? get ejercicio {
    if (_self.ejercicio == null) {
    return null;
  }

  return $EjercicioCopyWith<$Res>(_self.ejercicio!, (value) {
    return _then(_self.copyWith(ejercicio: value));
  });
}
}


/// Adds pattern-matching-related methods to [PackEjercicio].
extension PackEjercicioPatterns on PackEjercicio {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackEjercicio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackEjercicio() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackEjercicio value)  $default,){
final _that = this;
switch (_that) {
case _PackEjercicio():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackEjercicio value)?  $default,){
final _that = this;
switch (_that) {
case _PackEjercicio() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String packId,  String ejercicioId,  int orden, @JsonKey(name: 'descanso_seg')  int? descansoSeg,  double? minutos, @JsonKey(name: 'ejercicios')  Ejercicio? ejercicio, @JsonKey(name: 'pack_series')  List<PackSerie> series)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackEjercicio() when $default != null:
return $default(_that.id,_that.packId,_that.ejercicioId,_that.orden,_that.descansoSeg,_that.minutos,_that.ejercicio,_that.series);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String packId,  String ejercicioId,  int orden, @JsonKey(name: 'descanso_seg')  int? descansoSeg,  double? minutos, @JsonKey(name: 'ejercicios')  Ejercicio? ejercicio, @JsonKey(name: 'pack_series')  List<PackSerie> series)  $default,) {final _that = this;
switch (_that) {
case _PackEjercicio():
return $default(_that.id,_that.packId,_that.ejercicioId,_that.orden,_that.descansoSeg,_that.minutos,_that.ejercicio,_that.series);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String packId,  String ejercicioId,  int orden, @JsonKey(name: 'descanso_seg')  int? descansoSeg,  double? minutos, @JsonKey(name: 'ejercicios')  Ejercicio? ejercicio, @JsonKey(name: 'pack_series')  List<PackSerie> series)?  $default,) {final _that = this;
switch (_that) {
case _PackEjercicio() when $default != null:
return $default(_that.id,_that.packId,_that.ejercicioId,_that.orden,_that.descansoSeg,_that.minutos,_that.ejercicio,_that.series);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PackEjercicio extends PackEjercicio {
  const _PackEjercicio({required this.id, required this.packId, required this.ejercicioId, required this.orden, @JsonKey(name: 'descanso_seg') this.descansoSeg, this.minutos, @JsonKey(name: 'ejercicios') this.ejercicio, @JsonKey(name: 'pack_series')  List<PackSerie> series = const []}): _series = series,super._();
  factory _PackEjercicio.fromJson(Map<String, dynamic> json) => _$PackEjercicioFromJson(json);

@override final  String id;
@override final  String packId;
@override final  String ejercicioId;
@override final  int orden;
@override@JsonKey(name: 'descanso_seg') final  int? descansoSeg;
@override final  double? minutos;
/// El ejercicio de la biblioteca, incrustado por la consulta. Es quien dice
/// como se llama y si esta dado de baja.
@override@JsonKey(name: 'ejercicios') final  Ejercicio? ejercicio;
 final  List<PackSerie> _series;
@override@JsonKey(name: 'pack_series') List<PackSerie> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}


/// Create a copy of PackEjercicio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackEjercicioCopyWith<_PackEjercicio> get copyWith => __$PackEjercicioCopyWithImpl<_PackEjercicio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackEjercicioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackEjercicio&&(identical(other.id, id) || other.id == id)&&(identical(other.packId, packId) || other.packId == packId)&&(identical(other.ejercicioId, ejercicioId) || other.ejercicioId == ejercicioId)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.descansoSeg, descansoSeg) || other.descansoSeg == descansoSeg)&&(identical(other.minutos, minutos) || other.minutos == minutos)&&(identical(other.ejercicio, ejercicio) || other.ejercicio == ejercicio)&&const DeepCollectionEquality().equals(other.series, _series));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,packId,ejercicioId,orden,descansoSeg,minutos,ejercicio,const DeepCollectionEquality().hash(_series));
}

@override
String toString() {
    return 'PackEjercicio(id: $id, packId: $packId, ejercicioId: $ejercicioId, orden: $orden, descansoSeg: $descansoSeg, minutos: $minutos, ejercicio: $ejercicio, series: $series)';
}


}

/// @nodoc
abstract mixin class _$PackEjercicioCopyWith<$Res> implements $PackEjercicioCopyWith<$Res> {
  factory _$PackEjercicioCopyWith(_PackEjercicio value, $Res Function(_PackEjercicio) _then) = __$PackEjercicioCopyWithImpl;
@override @useResult
$Res call({
 String id, String packId, String ejercicioId, int orden,@JsonKey(name: 'descanso_seg') int? descansoSeg, double? minutos,@JsonKey(name: 'ejercicios') Ejercicio? ejercicio,@JsonKey(name: 'pack_series') List<PackSerie> series
});


@override $EjercicioCopyWith<$Res>? get ejercicio;

}
/// @nodoc
class __$PackEjercicioCopyWithImpl<$Res>
    implements _$PackEjercicioCopyWith<$Res> {
  __$PackEjercicioCopyWithImpl(this._self, this._then);

  final _PackEjercicio _self;
  final $Res Function(_PackEjercicio) _then;

/// Create a copy of PackEjercicio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? packId = null,Object? ejercicioId = null,Object? orden = null,Object? descansoSeg = freezed,Object? minutos = freezed,Object? ejercicio = freezed,Object? series = null,}) {
  return _then(_PackEjercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,packId: null == packId ? _self.packId : packId // ignore: cast_nullable_to_non_nullable
as String,ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,descansoSeg: freezed == descansoSeg ? _self.descansoSeg : descansoSeg // ignore: cast_nullable_to_non_nullable
as int?,minutos: freezed == minutos ? _self.minutos : minutos // ignore: cast_nullable_to_non_nullable
as double?,ejercicio: freezed == ejercicio ? _self.ejercicio : ejercicio // ignore: cast_nullable_to_non_nullable
as Ejercicio?,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<PackSerie>,
  ));
}

/// Create a copy of PackEjercicio
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$EjercicioCopyWith<$Res>? get ejercicio {
    if (_self.ejercicio == null) {
    return null;
  }

  return $EjercicioCopyWith<$Res>(_self.ejercicio!, (value) {
    return _then(_self.copyWith(ejercicio: value));
  });
}
}


/// @nodoc
mixin _$PackSerie {

 String get id; String get packEjercicioId; int get numeroSerie; int get repeticiones; double? get peso; int? get rir;
/// Create a copy of PackSerie
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PackSerieCopyWith<PackSerie> get copyWith => _$PackSerieCopyWithImpl<PackSerie>(this as PackSerie, _$identity);

  /// Serializes this PackSerie to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PackSerie;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PackSerie&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.packEjercicioId, _this.packEjercicioId) || other.packEjercicioId == _this.packEjercicioId)&&(identical(other.numeroSerie, _this.numeroSerie) || other.numeroSerie == _this.numeroSerie)&&(identical(other.repeticiones, _this.repeticiones) || other.repeticiones == _this.repeticiones)&&(identical(other.peso, _this.peso) || other.peso == _this.peso)&&(identical(other.rir, _this.rir) || other.rir == _this.rir));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PackSerie;
  return Object.hash(runtimeType,_this.id,_this.packEjercicioId,_this.numeroSerie,_this.repeticiones,_this.peso,_this.rir);
}

@override
String toString() {
  final _this = this as PackSerie;
  return 'PackSerie(id: ${_this.id}, packEjercicioId: ${_this.packEjercicioId}, numeroSerie: ${_this.numeroSerie}, repeticiones: ${_this.repeticiones}, peso: ${_this.peso}, rir: ${_this.rir})';
}


}

/// @nodoc
abstract mixin class $PackSerieCopyWith<$Res>  {
  factory $PackSerieCopyWith(PackSerie value, $Res Function(PackSerie) _then) = _$PackSerieCopyWithImpl;
@useResult
$Res call({
 String id, String packEjercicioId, int numeroSerie, int repeticiones, double? peso, int? rir
});




}
/// @nodoc
class _$PackSerieCopyWithImpl<$Res>
    implements $PackSerieCopyWith<$Res> {
  _$PackSerieCopyWithImpl(this._self, this._then);

  final PackSerie _self;
  final $Res Function(PackSerie) _then;

/// Create a copy of PackSerie
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? packEjercicioId = null,Object? numeroSerie = null,Object? repeticiones = null,Object? peso = freezed,Object? rir = freezed,}) {
  return _then(PackSerie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,packEjercicioId: null == packEjercicioId ? _self.packEjercicioId : packEjercicioId // ignore: cast_nullable_to_non_nullable
as String,numeroSerie: null == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int,repeticiones: null == repeticiones ? _self.repeticiones : repeticiones // ignore: cast_nullable_to_non_nullable
as int,peso: freezed == peso ? _self.peso : peso // ignore: cast_nullable_to_non_nullable
as double?,rir: freezed == rir ? _self.rir : rir // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PackSerie].
extension PackSeriePatterns on PackSerie {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PackSerie value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PackSerie() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PackSerie value)  $default,){
final _that = this;
switch (_that) {
case _PackSerie():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PackSerie value)?  $default,){
final _that = this;
switch (_that) {
case _PackSerie() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String packEjercicioId,  int numeroSerie,  int repeticiones,  double? peso,  int? rir)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PackSerie() when $default != null:
return $default(_that.id,_that.packEjercicioId,_that.numeroSerie,_that.repeticiones,_that.peso,_that.rir);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String packEjercicioId,  int numeroSerie,  int repeticiones,  double? peso,  int? rir)  $default,) {final _that = this;
switch (_that) {
case _PackSerie():
return $default(_that.id,_that.packEjercicioId,_that.numeroSerie,_that.repeticiones,_that.peso,_that.rir);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String packEjercicioId,  int numeroSerie,  int repeticiones,  double? peso,  int? rir)?  $default,) {final _that = this;
switch (_that) {
case _PackSerie() when $default != null:
return $default(_that.id,_that.packEjercicioId,_that.numeroSerie,_that.repeticiones,_that.peso,_that.rir);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PackSerie implements PackSerie {
  const _PackSerie({required this.id, required this.packEjercicioId, required this.numeroSerie, required this.repeticiones, this.peso, this.rir});
  factory _PackSerie.fromJson(Map<String, dynamic> json) => _$PackSerieFromJson(json);

@override final  String id;
@override final  String packEjercicioId;
@override final  int numeroSerie;
@override final  int repeticiones;
@override final  double? peso;
@override final  int? rir;

/// Create a copy of PackSerie
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PackSerieCopyWith<_PackSerie> get copyWith => __$PackSerieCopyWithImpl<_PackSerie>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PackSerieToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PackSerie&&(identical(other.id, id) || other.id == id)&&(identical(other.packEjercicioId, packEjercicioId) || other.packEjercicioId == packEjercicioId)&&(identical(other.numeroSerie, numeroSerie) || other.numeroSerie == numeroSerie)&&(identical(other.repeticiones, repeticiones) || other.repeticiones == repeticiones)&&(identical(other.peso, peso) || other.peso == peso)&&(identical(other.rir, rir) || other.rir == rir));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,packEjercicioId,numeroSerie,repeticiones,peso,rir);
}

@override
String toString() {
    return 'PackSerie(id: $id, packEjercicioId: $packEjercicioId, numeroSerie: $numeroSerie, repeticiones: $repeticiones, peso: $peso, rir: $rir)';
}


}

/// @nodoc
abstract mixin class _$PackSerieCopyWith<$Res> implements $PackSerieCopyWith<$Res> {
  factory _$PackSerieCopyWith(_PackSerie value, $Res Function(_PackSerie) _then) = __$PackSerieCopyWithImpl;
@override @useResult
$Res call({
 String id, String packEjercicioId, int numeroSerie, int repeticiones, double? peso, int? rir
});




}
/// @nodoc
class __$PackSerieCopyWithImpl<$Res>
    implements _$PackSerieCopyWith<$Res> {
  __$PackSerieCopyWithImpl(this._self, this._then);

  final _PackSerie _self;
  final $Res Function(_PackSerie) _then;

/// Create a copy of PackSerie
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? packEjercicioId = null,Object? numeroSerie = null,Object? repeticiones = null,Object? peso = freezed,Object? rir = freezed,}) {
  return _then(_PackSerie(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,packEjercicioId: null == packEjercicioId ? _self.packEjercicioId : packEjercicioId // ignore: cast_nullable_to_non_nullable
as String,numeroSerie: null == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int,repeticiones: null == repeticiones ? _self.repeticiones : repeticiones // ignore: cast_nullable_to_non_nullable
as int,peso: freezed == peso ? _self.peso : peso // ignore: cast_nullable_to_non_nullable
as double?,rir: freezed == rir ? _self.rir : rir // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
