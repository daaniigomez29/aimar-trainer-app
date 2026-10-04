// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'planning.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PlanningSemanal {

 String get id; String get clienteId; DateTime get fechaInicio; EstadoPlanning get estado; DateTime get creadoEn; String? get nombreObjetivo;/// OJO con el `JsonKey`: la consulta incrusta el recurso con el nombre de la
/// tabla (`sesiones_entrenamiento`), no con el del campo. Sin el, la lista
/// llegaba siempre vacia y la semana se veia entera como dias de descanso.
@JsonKey(name: 'sesiones_entrenamiento') List<SesionEntrenamiento> get sesiones;
/// Create a copy of PlanningSemanal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PlanningSemanalCopyWith<PlanningSemanal> get copyWith => _$PlanningSemanalCopyWithImpl<PlanningSemanal>(this as PlanningSemanal, _$identity);

  /// Serializes this PlanningSemanal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PlanningSemanal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PlanningSemanal&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.clienteId, _this.clienteId) || other.clienteId == _this.clienteId)&&(identical(other.fechaInicio, _this.fechaInicio) || other.fechaInicio == _this.fechaInicio)&&(identical(other.estado, _this.estado) || other.estado == _this.estado)&&(identical(other.creadoEn, _this.creadoEn) || other.creadoEn == _this.creadoEn)&&(identical(other.nombreObjetivo, _this.nombreObjetivo) || other.nombreObjetivo == _this.nombreObjetivo)&&const DeepCollectionEquality().equals(other.sesiones, _this.sesiones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PlanningSemanal;
  return Object.hash(runtimeType,_this.id,_this.clienteId,_this.fechaInicio,_this.estado,_this.creadoEn,_this.nombreObjetivo,const DeepCollectionEquality().hash(_this.sesiones));
}

@override
String toString() {
  final _this = this as PlanningSemanal;
  return 'PlanningSemanal(id: ${_this.id}, clienteId: ${_this.clienteId}, fechaInicio: ${_this.fechaInicio}, estado: ${_this.estado}, creadoEn: ${_this.creadoEn}, nombreObjetivo: ${_this.nombreObjetivo}, sesiones: ${_this.sesiones})';
}


}

/// @nodoc
abstract mixin class $PlanningSemanalCopyWith<$Res>  {
  factory $PlanningSemanalCopyWith(PlanningSemanal value, $Res Function(PlanningSemanal) _then) = _$PlanningSemanalCopyWithImpl;
@useResult
$Res call({
 String id, String clienteId, DateTime fechaInicio, EstadoPlanning estado, DateTime creadoEn, String? nombreObjetivo,@JsonKey(name: 'sesiones_entrenamiento') List<SesionEntrenamiento> sesiones
});




}
/// @nodoc
class _$PlanningSemanalCopyWithImpl<$Res>
    implements $PlanningSemanalCopyWith<$Res> {
  _$PlanningSemanalCopyWithImpl(this._self, this._then);

  final PlanningSemanal _self;
  final $Res Function(PlanningSemanal) _then;

/// Create a copy of PlanningSemanal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clienteId = null,Object? fechaInicio = null,Object? estado = null,Object? creadoEn = null,Object? nombreObjetivo = freezed,Object? sesiones = null,}) {
  return _then(PlanningSemanal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,fechaInicio: null == fechaInicio ? _self.fechaInicio : fechaInicio // ignore: cast_nullable_to_non_nullable
as DateTime,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoPlanning,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,nombreObjetivo: freezed == nombreObjetivo ? _self.nombreObjetivo : nombreObjetivo // ignore: cast_nullable_to_non_nullable
as String?,sesiones: null == sesiones ? _self.sesiones : sesiones // ignore: cast_nullable_to_non_nullable
as List<SesionEntrenamiento>,
  ));
}

}


/// Adds pattern-matching-related methods to [PlanningSemanal].
extension PlanningSemanalPatterns on PlanningSemanal {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PlanningSemanal value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PlanningSemanal() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PlanningSemanal value)  $default,){
final _that = this;
switch (_that) {
case _PlanningSemanal():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PlanningSemanal value)?  $default,){
final _that = this;
switch (_that) {
case _PlanningSemanal() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String clienteId,  DateTime fechaInicio,  EstadoPlanning estado,  DateTime creadoEn,  String? nombreObjetivo, @JsonKey(name: 'sesiones_entrenamiento')  List<SesionEntrenamiento> sesiones)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PlanningSemanal() when $default != null:
return $default(_that.id,_that.clienteId,_that.fechaInicio,_that.estado,_that.creadoEn,_that.nombreObjetivo,_that.sesiones);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String clienteId,  DateTime fechaInicio,  EstadoPlanning estado,  DateTime creadoEn,  String? nombreObjetivo, @JsonKey(name: 'sesiones_entrenamiento')  List<SesionEntrenamiento> sesiones)  $default,) {final _that = this;
switch (_that) {
case _PlanningSemanal():
return $default(_that.id,_that.clienteId,_that.fechaInicio,_that.estado,_that.creadoEn,_that.nombreObjetivo,_that.sesiones);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String clienteId,  DateTime fechaInicio,  EstadoPlanning estado,  DateTime creadoEn,  String? nombreObjetivo, @JsonKey(name: 'sesiones_entrenamiento')  List<SesionEntrenamiento> sesiones)?  $default,) {final _that = this;
switch (_that) {
case _PlanningSemanal() when $default != null:
return $default(_that.id,_that.clienteId,_that.fechaInicio,_that.estado,_that.creadoEn,_that.nombreObjetivo,_that.sesiones);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PlanningSemanal implements PlanningSemanal {
  const _PlanningSemanal({required this.id, required this.clienteId, required this.fechaInicio, required this.estado, required this.creadoEn, this.nombreObjetivo, @JsonKey(name: 'sesiones_entrenamiento')  List<SesionEntrenamiento> sesiones = const []}): _sesiones = sesiones;
  factory _PlanningSemanal.fromJson(Map<String, dynamic> json) => _$PlanningSemanalFromJson(json);

@override final  String id;
@override final  String clienteId;
@override final  DateTime fechaInicio;
@override final  EstadoPlanning estado;
@override final  DateTime creadoEn;
@override final  String? nombreObjetivo;
/// OJO con el `JsonKey`: la consulta incrusta el recurso con el nombre de la
/// tabla (`sesiones_entrenamiento`), no con el del campo. Sin el, la lista
/// llegaba siempre vacia y la semana se veia entera como dias de descanso.
 final  List<SesionEntrenamiento> _sesiones;
/// OJO con el `JsonKey`: la consulta incrusta el recurso con el nombre de la
/// tabla (`sesiones_entrenamiento`), no con el del campo. Sin el, la lista
/// llegaba siempre vacia y la semana se veia entera como dias de descanso.
@override@JsonKey(name: 'sesiones_entrenamiento') List<SesionEntrenamiento> get sesiones {
  if (_sesiones is EqualUnmodifiableListView) return _sesiones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_sesiones);
}


/// Create a copy of PlanningSemanal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PlanningSemanalCopyWith<_PlanningSemanal> get copyWith => __$PlanningSemanalCopyWithImpl<_PlanningSemanal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PlanningSemanalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PlanningSemanal&&(identical(other.id, id) || other.id == id)&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.fechaInicio, fechaInicio) || other.fechaInicio == fechaInicio)&&(identical(other.estado, estado) || other.estado == estado)&&(identical(other.creadoEn, creadoEn) || other.creadoEn == creadoEn)&&(identical(other.nombreObjetivo, nombreObjetivo) || other.nombreObjetivo == nombreObjetivo)&&const DeepCollectionEquality().equals(other.sesiones, _sesiones));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,clienteId,fechaInicio,estado,creadoEn,nombreObjetivo,const DeepCollectionEquality().hash(_sesiones));
}

@override
String toString() {
    return 'PlanningSemanal(id: $id, clienteId: $clienteId, fechaInicio: $fechaInicio, estado: $estado, creadoEn: $creadoEn, nombreObjetivo: $nombreObjetivo, sesiones: $sesiones)';
}


}

/// @nodoc
abstract mixin class _$PlanningSemanalCopyWith<$Res> implements $PlanningSemanalCopyWith<$Res> {
  factory _$PlanningSemanalCopyWith(_PlanningSemanal value, $Res Function(_PlanningSemanal) _then) = __$PlanningSemanalCopyWithImpl;
@override @useResult
$Res call({
 String id, String clienteId, DateTime fechaInicio, EstadoPlanning estado, DateTime creadoEn, String? nombreObjetivo,@JsonKey(name: 'sesiones_entrenamiento') List<SesionEntrenamiento> sesiones
});




}
/// @nodoc
class __$PlanningSemanalCopyWithImpl<$Res>
    implements _$PlanningSemanalCopyWith<$Res> {
  __$PlanningSemanalCopyWithImpl(this._self, this._then);

  final _PlanningSemanal _self;
  final $Res Function(_PlanningSemanal) _then;

/// Create a copy of PlanningSemanal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clienteId = null,Object? fechaInicio = null,Object? estado = null,Object? creadoEn = null,Object? nombreObjetivo = freezed,Object? sesiones = null,}) {
  return _then(_PlanningSemanal(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,fechaInicio: null == fechaInicio ? _self.fechaInicio : fechaInicio // ignore: cast_nullable_to_non_nullable
as DateTime,estado: null == estado ? _self.estado : estado // ignore: cast_nullable_to_non_nullable
as EstadoPlanning,creadoEn: null == creadoEn ? _self.creadoEn : creadoEn // ignore: cast_nullable_to_non_nullable
as DateTime,nombreObjetivo: freezed == nombreObjetivo ? _self.nombreObjetivo : nombreObjetivo // ignore: cast_nullable_to_non_nullable
as String?,sesiones: null == sesiones ? _self._sesiones : sesiones // ignore: cast_nullable_to_non_nullable
as List<SesionEntrenamiento>,
  ));
}


}


/// @nodoc
mixin _$SesionEntrenamiento {

 String get id; String get planningId; DateTime get fecha; String get nombre; bool get resultadoRegistrado;@JsonKey(name: 'bloques_ejercicio') List<BloqueEjercicio> get bloques;
/// Create a copy of SesionEntrenamiento
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SesionEntrenamientoCopyWith<SesionEntrenamiento> get copyWith => _$SesionEntrenamientoCopyWithImpl<SesionEntrenamiento>(this as SesionEntrenamiento, _$identity);

  /// Serializes this SesionEntrenamiento to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SesionEntrenamiento;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SesionEntrenamiento&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.planningId, _this.planningId) || other.planningId == _this.planningId)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.nombre, _this.nombre) || other.nombre == _this.nombre)&&(identical(other.resultadoRegistrado, _this.resultadoRegistrado) || other.resultadoRegistrado == _this.resultadoRegistrado)&&const DeepCollectionEquality().equals(other.bloques, _this.bloques));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SesionEntrenamiento;
  return Object.hash(runtimeType,_this.id,_this.planningId,_this.fecha,_this.nombre,_this.resultadoRegistrado,const DeepCollectionEquality().hash(_this.bloques));
}

@override
String toString() {
  final _this = this as SesionEntrenamiento;
  return 'SesionEntrenamiento(id: ${_this.id}, planningId: ${_this.planningId}, fecha: ${_this.fecha}, nombre: ${_this.nombre}, resultadoRegistrado: ${_this.resultadoRegistrado}, bloques: ${_this.bloques})';
}


}

/// @nodoc
abstract mixin class $SesionEntrenamientoCopyWith<$Res>  {
  factory $SesionEntrenamientoCopyWith(SesionEntrenamiento value, $Res Function(SesionEntrenamiento) _then) = _$SesionEntrenamientoCopyWithImpl;
@useResult
$Res call({
 String id, String planningId, DateTime fecha, String nombre, bool resultadoRegistrado,@JsonKey(name: 'bloques_ejercicio') List<BloqueEjercicio> bloques
});




}
/// @nodoc
class _$SesionEntrenamientoCopyWithImpl<$Res>
    implements $SesionEntrenamientoCopyWith<$Res> {
  _$SesionEntrenamientoCopyWithImpl(this._self, this._then);

  final SesionEntrenamiento _self;
  final $Res Function(SesionEntrenamiento) _then;

/// Create a copy of SesionEntrenamiento
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? planningId = null,Object? fecha = null,Object? nombre = null,Object? resultadoRegistrado = null,Object? bloques = null,}) {
  return _then(SesionEntrenamiento(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planningId: null == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,resultadoRegistrado: null == resultadoRegistrado ? _self.resultadoRegistrado : resultadoRegistrado // ignore: cast_nullable_to_non_nullable
as bool,bloques: null == bloques ? _self.bloques : bloques // ignore: cast_nullable_to_non_nullable
as List<BloqueEjercicio>,
  ));
}

}


/// Adds pattern-matching-related methods to [SesionEntrenamiento].
extension SesionEntrenamientoPatterns on SesionEntrenamiento {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SesionEntrenamiento value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SesionEntrenamiento() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SesionEntrenamiento value)  $default,){
final _that = this;
switch (_that) {
case _SesionEntrenamiento():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SesionEntrenamiento value)?  $default,){
final _that = this;
switch (_that) {
case _SesionEntrenamiento() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String planningId,  DateTime fecha,  String nombre,  bool resultadoRegistrado, @JsonKey(name: 'bloques_ejercicio')  List<BloqueEjercicio> bloques)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SesionEntrenamiento() when $default != null:
return $default(_that.id,_that.planningId,_that.fecha,_that.nombre,_that.resultadoRegistrado,_that.bloques);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String planningId,  DateTime fecha,  String nombre,  bool resultadoRegistrado, @JsonKey(name: 'bloques_ejercicio')  List<BloqueEjercicio> bloques)  $default,) {final _that = this;
switch (_that) {
case _SesionEntrenamiento():
return $default(_that.id,_that.planningId,_that.fecha,_that.nombre,_that.resultadoRegistrado,_that.bloques);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String planningId,  DateTime fecha,  String nombre,  bool resultadoRegistrado, @JsonKey(name: 'bloques_ejercicio')  List<BloqueEjercicio> bloques)?  $default,) {final _that = this;
switch (_that) {
case _SesionEntrenamiento() when $default != null:
return $default(_that.id,_that.planningId,_that.fecha,_that.nombre,_that.resultadoRegistrado,_that.bloques);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SesionEntrenamiento implements SesionEntrenamiento {
  const _SesionEntrenamiento({required this.id, required this.planningId, required this.fecha, required this.nombre, this.resultadoRegistrado = false, @JsonKey(name: 'bloques_ejercicio')  List<BloqueEjercicio> bloques = const []}): _bloques = bloques;
  factory _SesionEntrenamiento.fromJson(Map<String, dynamic> json) => _$SesionEntrenamientoFromJson(json);

@override final  String id;
@override final  String planningId;
@override final  DateTime fecha;
@override final  String nombre;
@override@JsonKey() final  bool resultadoRegistrado;
 final  List<BloqueEjercicio> _bloques;
@override@JsonKey(name: 'bloques_ejercicio') List<BloqueEjercicio> get bloques {
  if (_bloques is EqualUnmodifiableListView) return _bloques;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_bloques);
}


/// Create a copy of SesionEntrenamiento
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SesionEntrenamientoCopyWith<_SesionEntrenamiento> get copyWith => __$SesionEntrenamientoCopyWithImpl<_SesionEntrenamiento>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SesionEntrenamientoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SesionEntrenamiento&&(identical(other.id, id) || other.id == id)&&(identical(other.planningId, planningId) || other.planningId == planningId)&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.nombre, nombre) || other.nombre == nombre)&&(identical(other.resultadoRegistrado, resultadoRegistrado) || other.resultadoRegistrado == resultadoRegistrado)&&const DeepCollectionEquality().equals(other.bloques, _bloques));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,planningId,fecha,nombre,resultadoRegistrado,const DeepCollectionEquality().hash(_bloques));
}

@override
String toString() {
    return 'SesionEntrenamiento(id: $id, planningId: $planningId, fecha: $fecha, nombre: $nombre, resultadoRegistrado: $resultadoRegistrado, bloques: $bloques)';
}


}

/// @nodoc
abstract mixin class _$SesionEntrenamientoCopyWith<$Res> implements $SesionEntrenamientoCopyWith<$Res> {
  factory _$SesionEntrenamientoCopyWith(_SesionEntrenamiento value, $Res Function(_SesionEntrenamiento) _then) = __$SesionEntrenamientoCopyWithImpl;
@override @useResult
$Res call({
 String id, String planningId, DateTime fecha, String nombre, bool resultadoRegistrado,@JsonKey(name: 'bloques_ejercicio') List<BloqueEjercicio> bloques
});




}
/// @nodoc
class __$SesionEntrenamientoCopyWithImpl<$Res>
    implements _$SesionEntrenamientoCopyWith<$Res> {
  __$SesionEntrenamientoCopyWithImpl(this._self, this._then);

  final _SesionEntrenamiento _self;
  final $Res Function(_SesionEntrenamiento) _then;

/// Create a copy of SesionEntrenamiento
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? planningId = null,Object? fecha = null,Object? nombre = null,Object? resultadoRegistrado = null,Object? bloques = null,}) {
  return _then(_SesionEntrenamiento(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,planningId: null == planningId ? _self.planningId : planningId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,nombre: null == nombre ? _self.nombre : nombre // ignore: cast_nullable_to_non_nullable
as String,resultadoRegistrado: null == resultadoRegistrado ? _self.resultadoRegistrado : resultadoRegistrado // ignore: cast_nullable_to_non_nullable
as bool,bloques: null == bloques ? _self._bloques : bloques // ignore: cast_nullable_to_non_nullable
as List<BloqueEjercicio>,
  ));
}


}


/// @nodoc
mixin _$BloqueEjercicio {

 String get id; String get sesionId; TipoBloque get tipo; int get orden; String? get notas;@JsonKey(name: 'ejercicios_planificados') List<EjercicioPlanificado> get ejercicios;
/// Create a copy of BloqueEjercicio
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BloqueEjercicioCopyWith<BloqueEjercicio> get copyWith => _$BloqueEjercicioCopyWithImpl<BloqueEjercicio>(this as BloqueEjercicio, _$identity);

  /// Serializes this BloqueEjercicio to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BloqueEjercicio;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BloqueEjercicio&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.sesionId, _this.sesionId) || other.sesionId == _this.sesionId)&&(identical(other.tipo, _this.tipo) || other.tipo == _this.tipo)&&(identical(other.orden, _this.orden) || other.orden == _this.orden)&&(identical(other.notas, _this.notas) || other.notas == _this.notas)&&const DeepCollectionEquality().equals(other.ejercicios, _this.ejercicios));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BloqueEjercicio;
  return Object.hash(runtimeType,_this.id,_this.sesionId,_this.tipo,_this.orden,_this.notas,const DeepCollectionEquality().hash(_this.ejercicios));
}

@override
String toString() {
  final _this = this as BloqueEjercicio;
  return 'BloqueEjercicio(id: ${_this.id}, sesionId: ${_this.sesionId}, tipo: ${_this.tipo}, orden: ${_this.orden}, notas: ${_this.notas}, ejercicios: ${_this.ejercicios})';
}


}

/// @nodoc
abstract mixin class $BloqueEjercicioCopyWith<$Res>  {
  factory $BloqueEjercicioCopyWith(BloqueEjercicio value, $Res Function(BloqueEjercicio) _then) = _$BloqueEjercicioCopyWithImpl;
@useResult
$Res call({
 String id, String sesionId, TipoBloque tipo, int orden, String? notas,@JsonKey(name: 'ejercicios_planificados') List<EjercicioPlanificado> ejercicios
});




}
/// @nodoc
class _$BloqueEjercicioCopyWithImpl<$Res>
    implements $BloqueEjercicioCopyWith<$Res> {
  _$BloqueEjercicioCopyWithImpl(this._self, this._then);

  final BloqueEjercicio _self;
  final $Res Function(BloqueEjercicio) _then;

/// Create a copy of BloqueEjercicio
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sesionId = null,Object? tipo = null,Object? orden = null,Object? notas = freezed,Object? ejercicios = null,}) {
  return _then(BloqueEjercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoBloque,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,notas: freezed == notas ? _self.notas : notas // ignore: cast_nullable_to_non_nullable
as String?,ejercicios: null == ejercicios ? _self.ejercicios : ejercicios // ignore: cast_nullable_to_non_nullable
as List<EjercicioPlanificado>,
  ));
}

}


/// Adds pattern-matching-related methods to [BloqueEjercicio].
extension BloqueEjercicioPatterns on BloqueEjercicio {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _BloqueEjercicio value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _BloqueEjercicio() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _BloqueEjercicio value)  $default,){
final _that = this;
switch (_that) {
case _BloqueEjercicio():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _BloqueEjercicio value)?  $default,){
final _that = this;
switch (_that) {
case _BloqueEjercicio() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sesionId,  TipoBloque tipo,  int orden,  String? notas, @JsonKey(name: 'ejercicios_planificados')  List<EjercicioPlanificado> ejercicios)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _BloqueEjercicio() when $default != null:
return $default(_that.id,_that.sesionId,_that.tipo,_that.orden,_that.notas,_that.ejercicios);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sesionId,  TipoBloque tipo,  int orden,  String? notas, @JsonKey(name: 'ejercicios_planificados')  List<EjercicioPlanificado> ejercicios)  $default,) {final _that = this;
switch (_that) {
case _BloqueEjercicio():
return $default(_that.id,_that.sesionId,_that.tipo,_that.orden,_that.notas,_that.ejercicios);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sesionId,  TipoBloque tipo,  int orden,  String? notas, @JsonKey(name: 'ejercicios_planificados')  List<EjercicioPlanificado> ejercicios)?  $default,) {final _that = this;
switch (_that) {
case _BloqueEjercicio() when $default != null:
return $default(_that.id,_that.sesionId,_that.tipo,_that.orden,_that.notas,_that.ejercicios);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _BloqueEjercicio implements BloqueEjercicio {
  const _BloqueEjercicio({required this.id, required this.sesionId, required this.tipo, required this.orden, this.notas, @JsonKey(name: 'ejercicios_planificados')  List<EjercicioPlanificado> ejercicios = const []}): _ejercicios = ejercicios;
  factory _BloqueEjercicio.fromJson(Map<String, dynamic> json) => _$BloqueEjercicioFromJson(json);

@override final  String id;
@override final  String sesionId;
@override final  TipoBloque tipo;
@override final  int orden;
@override final  String? notas;
 final  List<EjercicioPlanificado> _ejercicios;
@override@JsonKey(name: 'ejercicios_planificados') List<EjercicioPlanificado> get ejercicios {
  if (_ejercicios is EqualUnmodifiableListView) return _ejercicios;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_ejercicios);
}


/// Create a copy of BloqueEjercicio
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BloqueEjercicioCopyWith<_BloqueEjercicio> get copyWith => __$BloqueEjercicioCopyWithImpl<_BloqueEjercicio>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BloqueEjercicioToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BloqueEjercicio&&(identical(other.id, id) || other.id == id)&&(identical(other.sesionId, sesionId) || other.sesionId == sesionId)&&(identical(other.tipo, tipo) || other.tipo == tipo)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.notas, notas) || other.notas == notas)&&const DeepCollectionEquality().equals(other.ejercicios, _ejercicios));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,sesionId,tipo,orden,notas,const DeepCollectionEquality().hash(_ejercicios));
}

@override
String toString() {
    return 'BloqueEjercicio(id: $id, sesionId: $sesionId, tipo: $tipo, orden: $orden, notas: $notas, ejercicios: $ejercicios)';
}


}

/// @nodoc
abstract mixin class _$BloqueEjercicioCopyWith<$Res> implements $BloqueEjercicioCopyWith<$Res> {
  factory _$BloqueEjercicioCopyWith(_BloqueEjercicio value, $Res Function(_BloqueEjercicio) _then) = __$BloqueEjercicioCopyWithImpl;
@override @useResult
$Res call({
 String id, String sesionId, TipoBloque tipo, int orden, String? notas,@JsonKey(name: 'ejercicios_planificados') List<EjercicioPlanificado> ejercicios
});




}
/// @nodoc
class __$BloqueEjercicioCopyWithImpl<$Res>
    implements _$BloqueEjercicioCopyWith<$Res> {
  __$BloqueEjercicioCopyWithImpl(this._self, this._then);

  final _BloqueEjercicio _self;
  final $Res Function(_BloqueEjercicio) _then;

/// Create a copy of BloqueEjercicio
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sesionId = null,Object? tipo = null,Object? orden = null,Object? notas = freezed,Object? ejercicios = null,}) {
  return _then(_BloqueEjercicio(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sesionId: null == sesionId ? _self.sesionId : sesionId // ignore: cast_nullable_to_non_nullable
as String,tipo: null == tipo ? _self.tipo : tipo // ignore: cast_nullable_to_non_nullable
as TipoBloque,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,notas: freezed == notas ? _self.notas : notas // ignore: cast_nullable_to_non_nullable
as String?,ejercicios: null == ejercicios ? _self._ejercicios : ejercicios // ignore: cast_nullable_to_non_nullable
as List<EjercicioPlanificado>,
  ));
}


}


/// @nodoc
mixin _$EjercicioPlanificado {

 String get id; String get bloqueId; String get ejercicioId; int get orden; EstadoRegistro get estadoRegistro; int? get descansoPlanificadoSeg; double? get minutosPlanificados; double? get minutosRealizados;/// El ejercicio de la biblioteca, incrustado por la consulta. Es quien dice si
/// esto va con series o con minutos.
@JsonKey(name: 'ejercicios') Ejercicio? get ejercicio;@JsonKey(name: 'series_planificadas') List<SeriePlanificada> get series;/// Lo que el cliente registro de verdad (CU-20). Independiente de `series`:
/// puede tener mas, menos o ninguna.
@JsonKey(name: 'series_realizadas') List<SerieRealizada> get seriesRealizadas;
/// Create a copy of EjercicioPlanificado
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$EjercicioPlanificadoCopyWith<EjercicioPlanificado> get copyWith => _$EjercicioPlanificadoCopyWithImpl<EjercicioPlanificado>(this as EjercicioPlanificado, _$identity);

  /// Serializes this EjercicioPlanificado to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as EjercicioPlanificado;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is EjercicioPlanificado&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.bloqueId, _this.bloqueId) || other.bloqueId == _this.bloqueId)&&(identical(other.ejercicioId, _this.ejercicioId) || other.ejercicioId == _this.ejercicioId)&&(identical(other.orden, _this.orden) || other.orden == _this.orden)&&(identical(other.estadoRegistro, _this.estadoRegistro) || other.estadoRegistro == _this.estadoRegistro)&&(identical(other.descansoPlanificadoSeg, _this.descansoPlanificadoSeg) || other.descansoPlanificadoSeg == _this.descansoPlanificadoSeg)&&(identical(other.minutosPlanificados, _this.minutosPlanificados) || other.minutosPlanificados == _this.minutosPlanificados)&&(identical(other.minutosRealizados, _this.minutosRealizados) || other.minutosRealizados == _this.minutosRealizados)&&(identical(other.ejercicio, _this.ejercicio) || other.ejercicio == _this.ejercicio)&&const DeepCollectionEquality().equals(other.series, _this.series)&&const DeepCollectionEquality().equals(other.seriesRealizadas, _this.seriesRealizadas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as EjercicioPlanificado;
  return Object.hash(runtimeType,_this.id,_this.bloqueId,_this.ejercicioId,_this.orden,_this.estadoRegistro,_this.descansoPlanificadoSeg,_this.minutosPlanificados,_this.minutosRealizados,_this.ejercicio,const DeepCollectionEquality().hash(_this.series),const DeepCollectionEquality().hash(_this.seriesRealizadas));
}

@override
String toString() {
  final _this = this as EjercicioPlanificado;
  return 'EjercicioPlanificado(id: ${_this.id}, bloqueId: ${_this.bloqueId}, ejercicioId: ${_this.ejercicioId}, orden: ${_this.orden}, estadoRegistro: ${_this.estadoRegistro}, descansoPlanificadoSeg: ${_this.descansoPlanificadoSeg}, minutosPlanificados: ${_this.minutosPlanificados}, minutosRealizados: ${_this.minutosRealizados}, ejercicio: ${_this.ejercicio}, series: ${_this.series}, seriesRealizadas: ${_this.seriesRealizadas})';
}


}

/// @nodoc
abstract mixin class $EjercicioPlanificadoCopyWith<$Res>  {
  factory $EjercicioPlanificadoCopyWith(EjercicioPlanificado value, $Res Function(EjercicioPlanificado) _then) = _$EjercicioPlanificadoCopyWithImpl;
@useResult
$Res call({
 String id, String bloqueId, String ejercicioId, int orden, EstadoRegistro estadoRegistro, int? descansoPlanificadoSeg, double? minutosPlanificados, double? minutosRealizados,@JsonKey(name: 'ejercicios') Ejercicio? ejercicio,@JsonKey(name: 'series_planificadas') List<SeriePlanificada> series,@JsonKey(name: 'series_realizadas') List<SerieRealizada> seriesRealizadas
});


$EjercicioCopyWith<$Res>? get ejercicio;

}
/// @nodoc
class _$EjercicioPlanificadoCopyWithImpl<$Res>
    implements $EjercicioPlanificadoCopyWith<$Res> {
  _$EjercicioPlanificadoCopyWithImpl(this._self, this._then);

  final EjercicioPlanificado _self;
  final $Res Function(EjercicioPlanificado) _then;

/// Create a copy of EjercicioPlanificado
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? bloqueId = null,Object? ejercicioId = null,Object? orden = null,Object? estadoRegistro = null,Object? descansoPlanificadoSeg = freezed,Object? minutosPlanificados = freezed,Object? minutosRealizados = freezed,Object? ejercicio = freezed,Object? series = null,Object? seriesRealizadas = null,}) {
  return _then(EjercicioPlanificado(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bloqueId: null == bloqueId ? _self.bloqueId : bloqueId // ignore: cast_nullable_to_non_nullable
as String,ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,estadoRegistro: null == estadoRegistro ? _self.estadoRegistro : estadoRegistro // ignore: cast_nullable_to_non_nullable
as EstadoRegistro,descansoPlanificadoSeg: freezed == descansoPlanificadoSeg ? _self.descansoPlanificadoSeg : descansoPlanificadoSeg // ignore: cast_nullable_to_non_nullable
as int?,minutosPlanificados: freezed == minutosPlanificados ? _self.minutosPlanificados : minutosPlanificados // ignore: cast_nullable_to_non_nullable
as double?,minutosRealizados: freezed == minutosRealizados ? _self.minutosRealizados : minutosRealizados // ignore: cast_nullable_to_non_nullable
as double?,ejercicio: freezed == ejercicio ? _self.ejercicio : ejercicio // ignore: cast_nullable_to_non_nullable
as Ejercicio?,series: null == series ? _self.series : series // ignore: cast_nullable_to_non_nullable
as List<SeriePlanificada>,seriesRealizadas: null == seriesRealizadas ? _self.seriesRealizadas : seriesRealizadas // ignore: cast_nullable_to_non_nullable
as List<SerieRealizada>,
  ));
}
/// Create a copy of EjercicioPlanificado
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


/// Adds pattern-matching-related methods to [EjercicioPlanificado].
extension EjercicioPlanificadoPatterns on EjercicioPlanificado {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _EjercicioPlanificado value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _EjercicioPlanificado() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _EjercicioPlanificado value)  $default,){
final _that = this;
switch (_that) {
case _EjercicioPlanificado():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _EjercicioPlanificado value)?  $default,){
final _that = this;
switch (_that) {
case _EjercicioPlanificado() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String bloqueId,  String ejercicioId,  int orden,  EstadoRegistro estadoRegistro,  int? descansoPlanificadoSeg,  double? minutosPlanificados,  double? minutosRealizados, @JsonKey(name: 'ejercicios')  Ejercicio? ejercicio, @JsonKey(name: 'series_planificadas')  List<SeriePlanificada> series, @JsonKey(name: 'series_realizadas')  List<SerieRealizada> seriesRealizadas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _EjercicioPlanificado() when $default != null:
return $default(_that.id,_that.bloqueId,_that.ejercicioId,_that.orden,_that.estadoRegistro,_that.descansoPlanificadoSeg,_that.minutosPlanificados,_that.minutosRealizados,_that.ejercicio,_that.series,_that.seriesRealizadas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String bloqueId,  String ejercicioId,  int orden,  EstadoRegistro estadoRegistro,  int? descansoPlanificadoSeg,  double? minutosPlanificados,  double? minutosRealizados, @JsonKey(name: 'ejercicios')  Ejercicio? ejercicio, @JsonKey(name: 'series_planificadas')  List<SeriePlanificada> series, @JsonKey(name: 'series_realizadas')  List<SerieRealizada> seriesRealizadas)  $default,) {final _that = this;
switch (_that) {
case _EjercicioPlanificado():
return $default(_that.id,_that.bloqueId,_that.ejercicioId,_that.orden,_that.estadoRegistro,_that.descansoPlanificadoSeg,_that.minutosPlanificados,_that.minutosRealizados,_that.ejercicio,_that.series,_that.seriesRealizadas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String bloqueId,  String ejercicioId,  int orden,  EstadoRegistro estadoRegistro,  int? descansoPlanificadoSeg,  double? minutosPlanificados,  double? minutosRealizados, @JsonKey(name: 'ejercicios')  Ejercicio? ejercicio, @JsonKey(name: 'series_planificadas')  List<SeriePlanificada> series, @JsonKey(name: 'series_realizadas')  List<SerieRealizada> seriesRealizadas)?  $default,) {final _that = this;
switch (_that) {
case _EjercicioPlanificado() when $default != null:
return $default(_that.id,_that.bloqueId,_that.ejercicioId,_that.orden,_that.estadoRegistro,_that.descansoPlanificadoSeg,_that.minutosPlanificados,_that.minutosRealizados,_that.ejercicio,_that.series,_that.seriesRealizadas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _EjercicioPlanificado implements EjercicioPlanificado {
  const _EjercicioPlanificado({required this.id, required this.bloqueId, required this.ejercicioId, required this.orden, required this.estadoRegistro, this.descansoPlanificadoSeg, this.minutosPlanificados, this.minutosRealizados, @JsonKey(name: 'ejercicios') this.ejercicio, @JsonKey(name: 'series_planificadas')  List<SeriePlanificada> series = const [], @JsonKey(name: 'series_realizadas')  List<SerieRealizada> seriesRealizadas = const []}): _series = series,_seriesRealizadas = seriesRealizadas;
  factory _EjercicioPlanificado.fromJson(Map<String, dynamic> json) => _$EjercicioPlanificadoFromJson(json);

@override final  String id;
@override final  String bloqueId;
@override final  String ejercicioId;
@override final  int orden;
@override final  EstadoRegistro estadoRegistro;
@override final  int? descansoPlanificadoSeg;
@override final  double? minutosPlanificados;
@override final  double? minutosRealizados;
/// El ejercicio de la biblioteca, incrustado por la consulta. Es quien dice si
/// esto va con series o con minutos.
@override@JsonKey(name: 'ejercicios') final  Ejercicio? ejercicio;
 final  List<SeriePlanificada> _series;
@override@JsonKey(name: 'series_planificadas') List<SeriePlanificada> get series {
  if (_series is EqualUnmodifiableListView) return _series;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_series);
}

/// Lo que el cliente registro de verdad (CU-20). Independiente de `series`:
/// puede tener mas, menos o ninguna.
 final  List<SerieRealizada> _seriesRealizadas;
/// Lo que el cliente registro de verdad (CU-20). Independiente de `series`:
/// puede tener mas, menos o ninguna.
@override@JsonKey(name: 'series_realizadas') List<SerieRealizada> get seriesRealizadas {
  if (_seriesRealizadas is EqualUnmodifiableListView) return _seriesRealizadas;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_seriesRealizadas);
}


/// Create a copy of EjercicioPlanificado
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$EjercicioPlanificadoCopyWith<_EjercicioPlanificado> get copyWith => __$EjercicioPlanificadoCopyWithImpl<_EjercicioPlanificado>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$EjercicioPlanificadoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _EjercicioPlanificado&&(identical(other.id, id) || other.id == id)&&(identical(other.bloqueId, bloqueId) || other.bloqueId == bloqueId)&&(identical(other.ejercicioId, ejercicioId) || other.ejercicioId == ejercicioId)&&(identical(other.orden, orden) || other.orden == orden)&&(identical(other.estadoRegistro, estadoRegistro) || other.estadoRegistro == estadoRegistro)&&(identical(other.descansoPlanificadoSeg, descansoPlanificadoSeg) || other.descansoPlanificadoSeg == descansoPlanificadoSeg)&&(identical(other.minutosPlanificados, minutosPlanificados) || other.minutosPlanificados == minutosPlanificados)&&(identical(other.minutosRealizados, minutosRealizados) || other.minutosRealizados == minutosRealizados)&&(identical(other.ejercicio, ejercicio) || other.ejercicio == ejercicio)&&const DeepCollectionEquality().equals(other.series, _series)&&const DeepCollectionEquality().equals(other.seriesRealizadas, _seriesRealizadas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,bloqueId,ejercicioId,orden,estadoRegistro,descansoPlanificadoSeg,minutosPlanificados,minutosRealizados,ejercicio,const DeepCollectionEquality().hash(_series),const DeepCollectionEquality().hash(_seriesRealizadas));
}

@override
String toString() {
    return 'EjercicioPlanificado(id: $id, bloqueId: $bloqueId, ejercicioId: $ejercicioId, orden: $orden, estadoRegistro: $estadoRegistro, descansoPlanificadoSeg: $descansoPlanificadoSeg, minutosPlanificados: $minutosPlanificados, minutosRealizados: $minutosRealizados, ejercicio: $ejercicio, series: $series, seriesRealizadas: $seriesRealizadas)';
}


}

/// @nodoc
abstract mixin class _$EjercicioPlanificadoCopyWith<$Res> implements $EjercicioPlanificadoCopyWith<$Res> {
  factory _$EjercicioPlanificadoCopyWith(_EjercicioPlanificado value, $Res Function(_EjercicioPlanificado) _then) = __$EjercicioPlanificadoCopyWithImpl;
@override @useResult
$Res call({
 String id, String bloqueId, String ejercicioId, int orden, EstadoRegistro estadoRegistro, int? descansoPlanificadoSeg, double? minutosPlanificados, double? minutosRealizados,@JsonKey(name: 'ejercicios') Ejercicio? ejercicio,@JsonKey(name: 'series_planificadas') List<SeriePlanificada> series,@JsonKey(name: 'series_realizadas') List<SerieRealizada> seriesRealizadas
});


@override $EjercicioCopyWith<$Res>? get ejercicio;

}
/// @nodoc
class __$EjercicioPlanificadoCopyWithImpl<$Res>
    implements _$EjercicioPlanificadoCopyWith<$Res> {
  __$EjercicioPlanificadoCopyWithImpl(this._self, this._then);

  final _EjercicioPlanificado _self;
  final $Res Function(_EjercicioPlanificado) _then;

/// Create a copy of EjercicioPlanificado
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? bloqueId = null,Object? ejercicioId = null,Object? orden = null,Object? estadoRegistro = null,Object? descansoPlanificadoSeg = freezed,Object? minutosPlanificados = freezed,Object? minutosRealizados = freezed,Object? ejercicio = freezed,Object? series = null,Object? seriesRealizadas = null,}) {
  return _then(_EjercicioPlanificado(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,bloqueId: null == bloqueId ? _self.bloqueId : bloqueId // ignore: cast_nullable_to_non_nullable
as String,ejercicioId: null == ejercicioId ? _self.ejercicioId : ejercicioId // ignore: cast_nullable_to_non_nullable
as String,orden: null == orden ? _self.orden : orden // ignore: cast_nullable_to_non_nullable
as int,estadoRegistro: null == estadoRegistro ? _self.estadoRegistro : estadoRegistro // ignore: cast_nullable_to_non_nullable
as EstadoRegistro,descansoPlanificadoSeg: freezed == descansoPlanificadoSeg ? _self.descansoPlanificadoSeg : descansoPlanificadoSeg // ignore: cast_nullable_to_non_nullable
as int?,minutosPlanificados: freezed == minutosPlanificados ? _self.minutosPlanificados : minutosPlanificados // ignore: cast_nullable_to_non_nullable
as double?,minutosRealizados: freezed == minutosRealizados ? _self.minutosRealizados : minutosRealizados // ignore: cast_nullable_to_non_nullable
as double?,ejercicio: freezed == ejercicio ? _self.ejercicio : ejercicio // ignore: cast_nullable_to_non_nullable
as Ejercicio?,series: null == series ? _self._series : series // ignore: cast_nullable_to_non_nullable
as List<SeriePlanificada>,seriesRealizadas: null == seriesRealizadas ? _self._seriesRealizadas : seriesRealizadas // ignore: cast_nullable_to_non_nullable
as List<SerieRealizada>,
  ));
}

/// Create a copy of EjercicioPlanificado
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
mixin _$SerieRealizada {

 String get id; String get ejercicioPlanificadoId; int get numeroSerie; int get repeticionesRealizadas; DateTime get fechaHoraRegistro; double? get pesoReal; int? get rirReal;
/// Create a copy of SerieRealizada
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SerieRealizadaCopyWith<SerieRealizada> get copyWith => _$SerieRealizadaCopyWithImpl<SerieRealizada>(this as SerieRealizada, _$identity);

  /// Serializes this SerieRealizada to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SerieRealizada;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SerieRealizada&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ejercicioPlanificadoId, _this.ejercicioPlanificadoId) || other.ejercicioPlanificadoId == _this.ejercicioPlanificadoId)&&(identical(other.numeroSerie, _this.numeroSerie) || other.numeroSerie == _this.numeroSerie)&&(identical(other.repeticionesRealizadas, _this.repeticionesRealizadas) || other.repeticionesRealizadas == _this.repeticionesRealizadas)&&(identical(other.fechaHoraRegistro, _this.fechaHoraRegistro) || other.fechaHoraRegistro == _this.fechaHoraRegistro)&&(identical(other.pesoReal, _this.pesoReal) || other.pesoReal == _this.pesoReal)&&(identical(other.rirReal, _this.rirReal) || other.rirReal == _this.rirReal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SerieRealizada;
  return Object.hash(runtimeType,_this.id,_this.ejercicioPlanificadoId,_this.numeroSerie,_this.repeticionesRealizadas,_this.fechaHoraRegistro,_this.pesoReal,_this.rirReal);
}

@override
String toString() {
  final _this = this as SerieRealizada;
  return 'SerieRealizada(id: ${_this.id}, ejercicioPlanificadoId: ${_this.ejercicioPlanificadoId}, numeroSerie: ${_this.numeroSerie}, repeticionesRealizadas: ${_this.repeticionesRealizadas}, fechaHoraRegistro: ${_this.fechaHoraRegistro}, pesoReal: ${_this.pesoReal}, rirReal: ${_this.rirReal})';
}


}

/// @nodoc
abstract mixin class $SerieRealizadaCopyWith<$Res>  {
  factory $SerieRealizadaCopyWith(SerieRealizada value, $Res Function(SerieRealizada) _then) = _$SerieRealizadaCopyWithImpl;
@useResult
$Res call({
 String id, String ejercicioPlanificadoId, int numeroSerie, int repeticionesRealizadas, DateTime fechaHoraRegistro, double? pesoReal, int? rirReal
});




}
/// @nodoc
class _$SerieRealizadaCopyWithImpl<$Res>
    implements $SerieRealizadaCopyWith<$Res> {
  _$SerieRealizadaCopyWithImpl(this._self, this._then);

  final SerieRealizada _self;
  final $Res Function(SerieRealizada) _then;

/// Create a copy of SerieRealizada
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ejercicioPlanificadoId = null,Object? numeroSerie = null,Object? repeticionesRealizadas = null,Object? fechaHoraRegistro = null,Object? pesoReal = freezed,Object? rirReal = freezed,}) {
  return _then(SerieRealizada(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ejercicioPlanificadoId: null == ejercicioPlanificadoId ? _self.ejercicioPlanificadoId : ejercicioPlanificadoId // ignore: cast_nullable_to_non_nullable
as String,numeroSerie: null == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int,repeticionesRealizadas: null == repeticionesRealizadas ? _self.repeticionesRealizadas : repeticionesRealizadas // ignore: cast_nullable_to_non_nullable
as int,fechaHoraRegistro: null == fechaHoraRegistro ? _self.fechaHoraRegistro : fechaHoraRegistro // ignore: cast_nullable_to_non_nullable
as DateTime,pesoReal: freezed == pesoReal ? _self.pesoReal : pesoReal // ignore: cast_nullable_to_non_nullable
as double?,rirReal: freezed == rirReal ? _self.rirReal : rirReal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SerieRealizada].
extension SerieRealizadaPatterns on SerieRealizada {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SerieRealizada value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SerieRealizada() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SerieRealizada value)  $default,){
final _that = this;
switch (_that) {
case _SerieRealizada():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SerieRealizada value)?  $default,){
final _that = this;
switch (_that) {
case _SerieRealizada() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ejercicioPlanificadoId,  int numeroSerie,  int repeticionesRealizadas,  DateTime fechaHoraRegistro,  double? pesoReal,  int? rirReal)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SerieRealizada() when $default != null:
return $default(_that.id,_that.ejercicioPlanificadoId,_that.numeroSerie,_that.repeticionesRealizadas,_that.fechaHoraRegistro,_that.pesoReal,_that.rirReal);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ejercicioPlanificadoId,  int numeroSerie,  int repeticionesRealizadas,  DateTime fechaHoraRegistro,  double? pesoReal,  int? rirReal)  $default,) {final _that = this;
switch (_that) {
case _SerieRealizada():
return $default(_that.id,_that.ejercicioPlanificadoId,_that.numeroSerie,_that.repeticionesRealizadas,_that.fechaHoraRegistro,_that.pesoReal,_that.rirReal);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ejercicioPlanificadoId,  int numeroSerie,  int repeticionesRealizadas,  DateTime fechaHoraRegistro,  double? pesoReal,  int? rirReal)?  $default,) {final _that = this;
switch (_that) {
case _SerieRealizada() when $default != null:
return $default(_that.id,_that.ejercicioPlanificadoId,_that.numeroSerie,_that.repeticionesRealizadas,_that.fechaHoraRegistro,_that.pesoReal,_that.rirReal);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SerieRealizada implements SerieRealizada {
  const _SerieRealizada({required this.id, required this.ejercicioPlanificadoId, required this.numeroSerie, required this.repeticionesRealizadas, required this.fechaHoraRegistro, this.pesoReal, this.rirReal});
  factory _SerieRealizada.fromJson(Map<String, dynamic> json) => _$SerieRealizadaFromJson(json);

@override final  String id;
@override final  String ejercicioPlanificadoId;
@override final  int numeroSerie;
@override final  int repeticionesRealizadas;
@override final  DateTime fechaHoraRegistro;
@override final  double? pesoReal;
@override final  int? rirReal;

/// Create a copy of SerieRealizada
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SerieRealizadaCopyWith<_SerieRealizada> get copyWith => __$SerieRealizadaCopyWithImpl<_SerieRealizada>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SerieRealizadaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SerieRealizada&&(identical(other.id, id) || other.id == id)&&(identical(other.ejercicioPlanificadoId, ejercicioPlanificadoId) || other.ejercicioPlanificadoId == ejercicioPlanificadoId)&&(identical(other.numeroSerie, numeroSerie) || other.numeroSerie == numeroSerie)&&(identical(other.repeticionesRealizadas, repeticionesRealizadas) || other.repeticionesRealizadas == repeticionesRealizadas)&&(identical(other.fechaHoraRegistro, fechaHoraRegistro) || other.fechaHoraRegistro == fechaHoraRegistro)&&(identical(other.pesoReal, pesoReal) || other.pesoReal == pesoReal)&&(identical(other.rirReal, rirReal) || other.rirReal == rirReal));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,ejercicioPlanificadoId,numeroSerie,repeticionesRealizadas,fechaHoraRegistro,pesoReal,rirReal);
}

@override
String toString() {
    return 'SerieRealizada(id: $id, ejercicioPlanificadoId: $ejercicioPlanificadoId, numeroSerie: $numeroSerie, repeticionesRealizadas: $repeticionesRealizadas, fechaHoraRegistro: $fechaHoraRegistro, pesoReal: $pesoReal, rirReal: $rirReal)';
}


}

/// @nodoc
abstract mixin class _$SerieRealizadaCopyWith<$Res> implements $SerieRealizadaCopyWith<$Res> {
  factory _$SerieRealizadaCopyWith(_SerieRealizada value, $Res Function(_SerieRealizada) _then) = __$SerieRealizadaCopyWithImpl;
@override @useResult
$Res call({
 String id, String ejercicioPlanificadoId, int numeroSerie, int repeticionesRealizadas, DateTime fechaHoraRegistro, double? pesoReal, int? rirReal
});




}
/// @nodoc
class __$SerieRealizadaCopyWithImpl<$Res>
    implements _$SerieRealizadaCopyWith<$Res> {
  __$SerieRealizadaCopyWithImpl(this._self, this._then);

  final _SerieRealizada _self;
  final $Res Function(_SerieRealizada) _then;

/// Create a copy of SerieRealizada
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ejercicioPlanificadoId = null,Object? numeroSerie = null,Object? repeticionesRealizadas = null,Object? fechaHoraRegistro = null,Object? pesoReal = freezed,Object? rirReal = freezed,}) {
  return _then(_SerieRealizada(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ejercicioPlanificadoId: null == ejercicioPlanificadoId ? _self.ejercicioPlanificadoId : ejercicioPlanificadoId // ignore: cast_nullable_to_non_nullable
as String,numeroSerie: null == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int,repeticionesRealizadas: null == repeticionesRealizadas ? _self.repeticionesRealizadas : repeticionesRealizadas // ignore: cast_nullable_to_non_nullable
as int,fechaHoraRegistro: null == fechaHoraRegistro ? _self.fechaHoraRegistro : fechaHoraRegistro // ignore: cast_nullable_to_non_nullable
as DateTime,pesoReal: freezed == pesoReal ? _self.pesoReal : pesoReal // ignore: cast_nullable_to_non_nullable
as double?,rirReal: freezed == rirReal ? _self.rirReal : rirReal // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$SeriePlanificada {

 String get id; String get ejercicioPlanificadoId; int get numeroSerie; int get repeticionesPlanificadas; double? get pesoPlanificado; int? get rirPlanificado;
/// Create a copy of SeriePlanificada
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SeriePlanificadaCopyWith<SeriePlanificada> get copyWith => _$SeriePlanificadaCopyWithImpl<SeriePlanificada>(this as SeriePlanificada, _$identity);

  /// Serializes this SeriePlanificada to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as SeriePlanificada;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SeriePlanificada&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.ejercicioPlanificadoId, _this.ejercicioPlanificadoId) || other.ejercicioPlanificadoId == _this.ejercicioPlanificadoId)&&(identical(other.numeroSerie, _this.numeroSerie) || other.numeroSerie == _this.numeroSerie)&&(identical(other.repeticionesPlanificadas, _this.repeticionesPlanificadas) || other.repeticionesPlanificadas == _this.repeticionesPlanificadas)&&(identical(other.pesoPlanificado, _this.pesoPlanificado) || other.pesoPlanificado == _this.pesoPlanificado)&&(identical(other.rirPlanificado, _this.rirPlanificado) || other.rirPlanificado == _this.rirPlanificado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as SeriePlanificada;
  return Object.hash(runtimeType,_this.id,_this.ejercicioPlanificadoId,_this.numeroSerie,_this.repeticionesPlanificadas,_this.pesoPlanificado,_this.rirPlanificado);
}

@override
String toString() {
  final _this = this as SeriePlanificada;
  return 'SeriePlanificada(id: ${_this.id}, ejercicioPlanificadoId: ${_this.ejercicioPlanificadoId}, numeroSerie: ${_this.numeroSerie}, repeticionesPlanificadas: ${_this.repeticionesPlanificadas}, pesoPlanificado: ${_this.pesoPlanificado}, rirPlanificado: ${_this.rirPlanificado})';
}


}

/// @nodoc
abstract mixin class $SeriePlanificadaCopyWith<$Res>  {
  factory $SeriePlanificadaCopyWith(SeriePlanificada value, $Res Function(SeriePlanificada) _then) = _$SeriePlanificadaCopyWithImpl;
@useResult
$Res call({
 String id, String ejercicioPlanificadoId, int numeroSerie, int repeticionesPlanificadas, double? pesoPlanificado, int? rirPlanificado
});




}
/// @nodoc
class _$SeriePlanificadaCopyWithImpl<$Res>
    implements $SeriePlanificadaCopyWith<$Res> {
  _$SeriePlanificadaCopyWithImpl(this._self, this._then);

  final SeriePlanificada _self;
  final $Res Function(SeriePlanificada) _then;

/// Create a copy of SeriePlanificada
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? ejercicioPlanificadoId = null,Object? numeroSerie = null,Object? repeticionesPlanificadas = null,Object? pesoPlanificado = freezed,Object? rirPlanificado = freezed,}) {
  return _then(SeriePlanificada(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ejercicioPlanificadoId: null == ejercicioPlanificadoId ? _self.ejercicioPlanificadoId : ejercicioPlanificadoId // ignore: cast_nullable_to_non_nullable
as String,numeroSerie: null == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int,repeticionesPlanificadas: null == repeticionesPlanificadas ? _self.repeticionesPlanificadas : repeticionesPlanificadas // ignore: cast_nullable_to_non_nullable
as int,pesoPlanificado: freezed == pesoPlanificado ? _self.pesoPlanificado : pesoPlanificado // ignore: cast_nullable_to_non_nullable
as double?,rirPlanificado: freezed == rirPlanificado ? _self.rirPlanificado : rirPlanificado // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SeriePlanificada].
extension SeriePlanificadaPatterns on SeriePlanificada {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SeriePlanificada value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SeriePlanificada() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SeriePlanificada value)  $default,){
final _that = this;
switch (_that) {
case _SeriePlanificada():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SeriePlanificada value)?  $default,){
final _that = this;
switch (_that) {
case _SeriePlanificada() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String ejercicioPlanificadoId,  int numeroSerie,  int repeticionesPlanificadas,  double? pesoPlanificado,  int? rirPlanificado)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SeriePlanificada() when $default != null:
return $default(_that.id,_that.ejercicioPlanificadoId,_that.numeroSerie,_that.repeticionesPlanificadas,_that.pesoPlanificado,_that.rirPlanificado);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String ejercicioPlanificadoId,  int numeroSerie,  int repeticionesPlanificadas,  double? pesoPlanificado,  int? rirPlanificado)  $default,) {final _that = this;
switch (_that) {
case _SeriePlanificada():
return $default(_that.id,_that.ejercicioPlanificadoId,_that.numeroSerie,_that.repeticionesPlanificadas,_that.pesoPlanificado,_that.rirPlanificado);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String ejercicioPlanificadoId,  int numeroSerie,  int repeticionesPlanificadas,  double? pesoPlanificado,  int? rirPlanificado)?  $default,) {final _that = this;
switch (_that) {
case _SeriePlanificada() when $default != null:
return $default(_that.id,_that.ejercicioPlanificadoId,_that.numeroSerie,_that.repeticionesPlanificadas,_that.pesoPlanificado,_that.rirPlanificado);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SeriePlanificada implements SeriePlanificada {
  const _SeriePlanificada({required this.id, required this.ejercicioPlanificadoId, required this.numeroSerie, required this.repeticionesPlanificadas, this.pesoPlanificado, this.rirPlanificado});
  factory _SeriePlanificada.fromJson(Map<String, dynamic> json) => _$SeriePlanificadaFromJson(json);

@override final  String id;
@override final  String ejercicioPlanificadoId;
@override final  int numeroSerie;
@override final  int repeticionesPlanificadas;
@override final  double? pesoPlanificado;
@override final  int? rirPlanificado;

/// Create a copy of SeriePlanificada
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SeriePlanificadaCopyWith<_SeriePlanificada> get copyWith => __$SeriePlanificadaCopyWithImpl<_SeriePlanificada>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SeriePlanificadaToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SeriePlanificada&&(identical(other.id, id) || other.id == id)&&(identical(other.ejercicioPlanificadoId, ejercicioPlanificadoId) || other.ejercicioPlanificadoId == ejercicioPlanificadoId)&&(identical(other.numeroSerie, numeroSerie) || other.numeroSerie == numeroSerie)&&(identical(other.repeticionesPlanificadas, repeticionesPlanificadas) || other.repeticionesPlanificadas == repeticionesPlanificadas)&&(identical(other.pesoPlanificado, pesoPlanificado) || other.pesoPlanificado == pesoPlanificado)&&(identical(other.rirPlanificado, rirPlanificado) || other.rirPlanificado == rirPlanificado));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,ejercicioPlanificadoId,numeroSerie,repeticionesPlanificadas,pesoPlanificado,rirPlanificado);
}

@override
String toString() {
    return 'SeriePlanificada(id: $id, ejercicioPlanificadoId: $ejercicioPlanificadoId, numeroSerie: $numeroSerie, repeticionesPlanificadas: $repeticionesPlanificadas, pesoPlanificado: $pesoPlanificado, rirPlanificado: $rirPlanificado)';
}


}

/// @nodoc
abstract mixin class _$SeriePlanificadaCopyWith<$Res> implements $SeriePlanificadaCopyWith<$Res> {
  factory _$SeriePlanificadaCopyWith(_SeriePlanificada value, $Res Function(_SeriePlanificada) _then) = __$SeriePlanificadaCopyWithImpl;
@override @useResult
$Res call({
 String id, String ejercicioPlanificadoId, int numeroSerie, int repeticionesPlanificadas, double? pesoPlanificado, int? rirPlanificado
});




}
/// @nodoc
class __$SeriePlanificadaCopyWithImpl<$Res>
    implements _$SeriePlanificadaCopyWith<$Res> {
  __$SeriePlanificadaCopyWithImpl(this._self, this._then);

  final _SeriePlanificada _self;
  final $Res Function(_SeriePlanificada) _then;

/// Create a copy of SeriePlanificada
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? ejercicioPlanificadoId = null,Object? numeroSerie = null,Object? repeticionesPlanificadas = null,Object? pesoPlanificado = freezed,Object? rirPlanificado = freezed,}) {
  return _then(_SeriePlanificada(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,ejercicioPlanificadoId: null == ejercicioPlanificadoId ? _self.ejercicioPlanificadoId : ejercicioPlanificadoId // ignore: cast_nullable_to_non_nullable
as String,numeroSerie: null == numeroSerie ? _self.numeroSerie : numeroSerie // ignore: cast_nullable_to_non_nullable
as int,repeticionesPlanificadas: null == repeticionesPlanificadas ? _self.repeticionesPlanificadas : repeticionesPlanificadas // ignore: cast_nullable_to_non_nullable
as int,pesoPlanificado: freezed == pesoPlanificado ? _self.pesoPlanificado : pesoPlanificado // ignore: cast_nullable_to_non_nullable
as double?,rirPlanificado: freezed == rirPlanificado ? _self.rirPlanificado : rirPlanificado // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
