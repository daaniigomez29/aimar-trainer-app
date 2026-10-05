// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'medidas.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RegistroMedidas {

 String get id; String get clienteId; DateTime get fecha; double get pesoKg; double? get pechoCm; double? get cinturaCm; double? get caderaCm; double? get cuadricepsCm; double? get brazosCm;@JsonKey(name: 'fotos_progreso') List<FotoProgreso> get fotos;
/// Create a copy of RegistroMedidas
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RegistroMedidasCopyWith<RegistroMedidas> get copyWith => _$RegistroMedidasCopyWithImpl<RegistroMedidas>(this as RegistroMedidas, _$identity);

  /// Serializes this RegistroMedidas to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as RegistroMedidas;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RegistroMedidas&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.clienteId, _this.clienteId) || other.clienteId == _this.clienteId)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.pesoKg, _this.pesoKg) || other.pesoKg == _this.pesoKg)&&(identical(other.pechoCm, _this.pechoCm) || other.pechoCm == _this.pechoCm)&&(identical(other.cinturaCm, _this.cinturaCm) || other.cinturaCm == _this.cinturaCm)&&(identical(other.caderaCm, _this.caderaCm) || other.caderaCm == _this.caderaCm)&&(identical(other.cuadricepsCm, _this.cuadricepsCm) || other.cuadricepsCm == _this.cuadricepsCm)&&(identical(other.brazosCm, _this.brazosCm) || other.brazosCm == _this.brazosCm)&&const DeepCollectionEquality().equals(other.fotos, _this.fotos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as RegistroMedidas;
  return Object.hash(runtimeType,_this.id,_this.clienteId,_this.fecha,_this.pesoKg,_this.pechoCm,_this.cinturaCm,_this.caderaCm,_this.cuadricepsCm,_this.brazosCm,const DeepCollectionEquality().hash(_this.fotos));
}

@override
String toString() {
  final _this = this as RegistroMedidas;
  return 'RegistroMedidas(id: ${_this.id}, clienteId: ${_this.clienteId}, fecha: ${_this.fecha}, pesoKg: ${_this.pesoKg}, pechoCm: ${_this.pechoCm}, cinturaCm: ${_this.cinturaCm}, caderaCm: ${_this.caderaCm}, cuadricepsCm: ${_this.cuadricepsCm}, brazosCm: ${_this.brazosCm}, fotos: ${_this.fotos})';
}


}

/// @nodoc
abstract mixin class $RegistroMedidasCopyWith<$Res>  {
  factory $RegistroMedidasCopyWith(RegistroMedidas value, $Res Function(RegistroMedidas) _then) = _$RegistroMedidasCopyWithImpl;
@useResult
$Res call({
 String id, String clienteId, DateTime fecha, double pesoKg, double? pechoCm, double? cinturaCm, double? caderaCm, double? cuadricepsCm, double? brazosCm,@JsonKey(name: 'fotos_progreso') List<FotoProgreso> fotos
});




}
/// @nodoc
class _$RegistroMedidasCopyWithImpl<$Res>
    implements $RegistroMedidasCopyWith<$Res> {
  _$RegistroMedidasCopyWithImpl(this._self, this._then);

  final RegistroMedidas _self;
  final $Res Function(RegistroMedidas) _then;

/// Create a copy of RegistroMedidas
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clienteId = null,Object? fecha = null,Object? pesoKg = null,Object? pechoCm = freezed,Object? cinturaCm = freezed,Object? caderaCm = freezed,Object? cuadricepsCm = freezed,Object? brazosCm = freezed,Object? fotos = null,}) {
  return _then(RegistroMedidas(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,pesoKg: null == pesoKg ? _self.pesoKg : pesoKg // ignore: cast_nullable_to_non_nullable
as double,pechoCm: freezed == pechoCm ? _self.pechoCm : pechoCm // ignore: cast_nullable_to_non_nullable
as double?,cinturaCm: freezed == cinturaCm ? _self.cinturaCm : cinturaCm // ignore: cast_nullable_to_non_nullable
as double?,caderaCm: freezed == caderaCm ? _self.caderaCm : caderaCm // ignore: cast_nullable_to_non_nullable
as double?,cuadricepsCm: freezed == cuadricepsCm ? _self.cuadricepsCm : cuadricepsCm // ignore: cast_nullable_to_non_nullable
as double?,brazosCm: freezed == brazosCm ? _self.brazosCm : brazosCm // ignore: cast_nullable_to_non_nullable
as double?,fotos: null == fotos ? _self.fotos : fotos // ignore: cast_nullable_to_non_nullable
as List<FotoProgreso>,
  ));
}

}


/// Adds pattern-matching-related methods to [RegistroMedidas].
extension RegistroMedidasPatterns on RegistroMedidas {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RegistroMedidas value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RegistroMedidas() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RegistroMedidas value)  $default,){
final _that = this;
switch (_that) {
case _RegistroMedidas():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RegistroMedidas value)?  $default,){
final _that = this;
switch (_that) {
case _RegistroMedidas() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String clienteId,  DateTime fecha,  double pesoKg,  double? pechoCm,  double? cinturaCm,  double? caderaCm,  double? cuadricepsCm,  double? brazosCm, @JsonKey(name: 'fotos_progreso')  List<FotoProgreso> fotos)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RegistroMedidas() when $default != null:
return $default(_that.id,_that.clienteId,_that.fecha,_that.pesoKg,_that.pechoCm,_that.cinturaCm,_that.caderaCm,_that.cuadricepsCm,_that.brazosCm,_that.fotos);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String clienteId,  DateTime fecha,  double pesoKg,  double? pechoCm,  double? cinturaCm,  double? caderaCm,  double? cuadricepsCm,  double? brazosCm, @JsonKey(name: 'fotos_progreso')  List<FotoProgreso> fotos)  $default,) {final _that = this;
switch (_that) {
case _RegistroMedidas():
return $default(_that.id,_that.clienteId,_that.fecha,_that.pesoKg,_that.pechoCm,_that.cinturaCm,_that.caderaCm,_that.cuadricepsCm,_that.brazosCm,_that.fotos);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String clienteId,  DateTime fecha,  double pesoKg,  double? pechoCm,  double? cinturaCm,  double? caderaCm,  double? cuadricepsCm,  double? brazosCm, @JsonKey(name: 'fotos_progreso')  List<FotoProgreso> fotos)?  $default,) {final _that = this;
switch (_that) {
case _RegistroMedidas() when $default != null:
return $default(_that.id,_that.clienteId,_that.fecha,_that.pesoKg,_that.pechoCm,_that.cinturaCm,_that.caderaCm,_that.cuadricepsCm,_that.brazosCm,_that.fotos);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RegistroMedidas implements RegistroMedidas {
  const _RegistroMedidas({required this.id, required this.clienteId, required this.fecha, required this.pesoKg, this.pechoCm, this.cinturaCm, this.caderaCm, this.cuadricepsCm, this.brazosCm, @JsonKey(name: 'fotos_progreso')  List<FotoProgreso> fotos = const []}): _fotos = fotos;
  factory _RegistroMedidas.fromJson(Map<String, dynamic> json) => _$RegistroMedidasFromJson(json);

@override final  String id;
@override final  String clienteId;
@override final  DateTime fecha;
@override final  double pesoKg;
@override final  double? pechoCm;
@override final  double? cinturaCm;
@override final  double? caderaCm;
@override final  double? cuadricepsCm;
@override final  double? brazosCm;
 final  List<FotoProgreso> _fotos;
@override@JsonKey(name: 'fotos_progreso') List<FotoProgreso> get fotos {
  if (_fotos is EqualUnmodifiableListView) return _fotos;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_fotos);
}


/// Create a copy of RegistroMedidas
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RegistroMedidasCopyWith<_RegistroMedidas> get copyWith => __$RegistroMedidasCopyWithImpl<_RegistroMedidas>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RegistroMedidasToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _RegistroMedidas&&(identical(other.id, id) || other.id == id)&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.pesoKg, pesoKg) || other.pesoKg == pesoKg)&&(identical(other.pechoCm, pechoCm) || other.pechoCm == pechoCm)&&(identical(other.cinturaCm, cinturaCm) || other.cinturaCm == cinturaCm)&&(identical(other.caderaCm, caderaCm) || other.caderaCm == caderaCm)&&(identical(other.cuadricepsCm, cuadricepsCm) || other.cuadricepsCm == cuadricepsCm)&&(identical(other.brazosCm, brazosCm) || other.brazosCm == brazosCm)&&const DeepCollectionEquality().equals(other.fotos, _fotos));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,clienteId,fecha,pesoKg,pechoCm,cinturaCm,caderaCm,cuadricepsCm,brazosCm,const DeepCollectionEquality().hash(_fotos));
}

@override
String toString() {
    return 'RegistroMedidas(id: $id, clienteId: $clienteId, fecha: $fecha, pesoKg: $pesoKg, pechoCm: $pechoCm, cinturaCm: $cinturaCm, caderaCm: $caderaCm, cuadricepsCm: $cuadricepsCm, brazosCm: $brazosCm, fotos: $fotos)';
}


}

/// @nodoc
abstract mixin class _$RegistroMedidasCopyWith<$Res> implements $RegistroMedidasCopyWith<$Res> {
  factory _$RegistroMedidasCopyWith(_RegistroMedidas value, $Res Function(_RegistroMedidas) _then) = __$RegistroMedidasCopyWithImpl;
@override @useResult
$Res call({
 String id, String clienteId, DateTime fecha, double pesoKg, double? pechoCm, double? cinturaCm, double? caderaCm, double? cuadricepsCm, double? brazosCm,@JsonKey(name: 'fotos_progreso') List<FotoProgreso> fotos
});




}
/// @nodoc
class __$RegistroMedidasCopyWithImpl<$Res>
    implements _$RegistroMedidasCopyWith<$Res> {
  __$RegistroMedidasCopyWithImpl(this._self, this._then);

  final _RegistroMedidas _self;
  final $Res Function(_RegistroMedidas) _then;

/// Create a copy of RegistroMedidas
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clienteId = null,Object? fecha = null,Object? pesoKg = null,Object? pechoCm = freezed,Object? cinturaCm = freezed,Object? caderaCm = freezed,Object? cuadricepsCm = freezed,Object? brazosCm = freezed,Object? fotos = null,}) {
  return _then(_RegistroMedidas(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,pesoKg: null == pesoKg ? _self.pesoKg : pesoKg // ignore: cast_nullable_to_non_nullable
as double,pechoCm: freezed == pechoCm ? _self.pechoCm : pechoCm // ignore: cast_nullable_to_non_nullable
as double?,cinturaCm: freezed == cinturaCm ? _self.cinturaCm : cinturaCm // ignore: cast_nullable_to_non_nullable
as double?,caderaCm: freezed == caderaCm ? _self.caderaCm : caderaCm // ignore: cast_nullable_to_non_nullable
as double?,cuadricepsCm: freezed == cuadricepsCm ? _self.cuadricepsCm : cuadricepsCm // ignore: cast_nullable_to_non_nullable
as double?,brazosCm: freezed == brazosCm ? _self.brazosCm : brazosCm // ignore: cast_nullable_to_non_nullable
as double?,fotos: null == fotos ? _self._fotos : fotos // ignore: cast_nullable_to_non_nullable
as List<FotoProgreso>,
  ));
}


}


/// @nodoc
mixin _$FotoProgreso {

 String get id; String get registroMedidasId; String get rutaStorage; DateTime get subidaEn;
/// Create a copy of FotoProgreso
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FotoProgresoCopyWith<FotoProgreso> get copyWith => _$FotoProgresoCopyWithImpl<FotoProgreso>(this as FotoProgreso, _$identity);

  /// Serializes this FotoProgreso to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as FotoProgreso;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FotoProgreso&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.registroMedidasId, _this.registroMedidasId) || other.registroMedidasId == _this.registroMedidasId)&&(identical(other.rutaStorage, _this.rutaStorage) || other.rutaStorage == _this.rutaStorage)&&(identical(other.subidaEn, _this.subidaEn) || other.subidaEn == _this.subidaEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as FotoProgreso;
  return Object.hash(runtimeType,_this.id,_this.registroMedidasId,_this.rutaStorage,_this.subidaEn);
}

@override
String toString() {
  final _this = this as FotoProgreso;
  return 'FotoProgreso(id: ${_this.id}, registroMedidasId: ${_this.registroMedidasId}, rutaStorage: ${_this.rutaStorage}, subidaEn: ${_this.subidaEn})';
}


}

/// @nodoc
abstract mixin class $FotoProgresoCopyWith<$Res>  {
  factory $FotoProgresoCopyWith(FotoProgreso value, $Res Function(FotoProgreso) _then) = _$FotoProgresoCopyWithImpl;
@useResult
$Res call({
 String id, String registroMedidasId, String rutaStorage, DateTime subidaEn
});




}
/// @nodoc
class _$FotoProgresoCopyWithImpl<$Res>
    implements $FotoProgresoCopyWith<$Res> {
  _$FotoProgresoCopyWithImpl(this._self, this._then);

  final FotoProgreso _self;
  final $Res Function(FotoProgreso) _then;

/// Create a copy of FotoProgreso
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? registroMedidasId = null,Object? rutaStorage = null,Object? subidaEn = null,}) {
  return _then(FotoProgreso(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,registroMedidasId: null == registroMedidasId ? _self.registroMedidasId : registroMedidasId // ignore: cast_nullable_to_non_nullable
as String,rutaStorage: null == rutaStorage ? _self.rutaStorage : rutaStorage // ignore: cast_nullable_to_non_nullable
as String,subidaEn: null == subidaEn ? _self.subidaEn : subidaEn // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [FotoProgreso].
extension FotoProgresoPatterns on FotoProgreso {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FotoProgreso value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FotoProgreso() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FotoProgreso value)  $default,){
final _that = this;
switch (_that) {
case _FotoProgreso():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FotoProgreso value)?  $default,){
final _that = this;
switch (_that) {
case _FotoProgreso() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String registroMedidasId,  String rutaStorage,  DateTime subidaEn)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FotoProgreso() when $default != null:
return $default(_that.id,_that.registroMedidasId,_that.rutaStorage,_that.subidaEn);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String registroMedidasId,  String rutaStorage,  DateTime subidaEn)  $default,) {final _that = this;
switch (_that) {
case _FotoProgreso():
return $default(_that.id,_that.registroMedidasId,_that.rutaStorage,_that.subidaEn);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String registroMedidasId,  String rutaStorage,  DateTime subidaEn)?  $default,) {final _that = this;
switch (_that) {
case _FotoProgreso() when $default != null:
return $default(_that.id,_that.registroMedidasId,_that.rutaStorage,_that.subidaEn);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _FotoProgreso implements FotoProgreso {
  const _FotoProgreso({required this.id, required this.registroMedidasId, required this.rutaStorage, required this.subidaEn});
  factory _FotoProgreso.fromJson(Map<String, dynamic> json) => _$FotoProgresoFromJson(json);

@override final  String id;
@override final  String registroMedidasId;
@override final  String rutaStorage;
@override final  DateTime subidaEn;

/// Create a copy of FotoProgreso
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FotoProgresoCopyWith<_FotoProgreso> get copyWith => __$FotoProgresoCopyWithImpl<_FotoProgreso>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$FotoProgresoToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FotoProgreso&&(identical(other.id, id) || other.id == id)&&(identical(other.registroMedidasId, registroMedidasId) || other.registroMedidasId == registroMedidasId)&&(identical(other.rutaStorage, rutaStorage) || other.rutaStorage == rutaStorage)&&(identical(other.subidaEn, subidaEn) || other.subidaEn == subidaEn));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,registroMedidasId,rutaStorage,subidaEn);
}

@override
String toString() {
    return 'FotoProgreso(id: $id, registroMedidasId: $registroMedidasId, rutaStorage: $rutaStorage, subidaEn: $subidaEn)';
}


}

/// @nodoc
abstract mixin class _$FotoProgresoCopyWith<$Res> implements $FotoProgresoCopyWith<$Res> {
  factory _$FotoProgresoCopyWith(_FotoProgreso value, $Res Function(_FotoProgreso) _then) = __$FotoProgresoCopyWithImpl;
@override @useResult
$Res call({
 String id, String registroMedidasId, String rutaStorage, DateTime subidaEn
});




}
/// @nodoc
class __$FotoProgresoCopyWithImpl<$Res>
    implements _$FotoProgresoCopyWith<$Res> {
  __$FotoProgresoCopyWithImpl(this._self, this._then);

  final _FotoProgreso _self;
  final $Res Function(_FotoProgreso) _then;

/// Create a copy of FotoProgreso
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? registroMedidasId = null,Object? rutaStorage = null,Object? subidaEn = null,}) {
  return _then(_FotoProgreso(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,registroMedidasId: null == registroMedidasId ? _self.registroMedidasId : registroMedidasId // ignore: cast_nullable_to_non_nullable
as String,rutaStorage: null == rutaStorage ? _self.rutaStorage : rutaStorage // ignore: cast_nullable_to_non_nullable
as String,subidaEn: null == subidaEn ? _self.subidaEn : subidaEn // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}


/// @nodoc
mixin _$CheckinRecuperacion {

 String get id; String get clienteId; DateTime get fecha; double get horasSueno; int get estres; int get agujetas; int get fatiga; String? get notas;
/// Create a copy of CheckinRecuperacion
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CheckinRecuperacionCopyWith<CheckinRecuperacion> get copyWith => _$CheckinRecuperacionCopyWithImpl<CheckinRecuperacion>(this as CheckinRecuperacion, _$identity);

  /// Serializes this CheckinRecuperacion to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as CheckinRecuperacion;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CheckinRecuperacion&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.clienteId, _this.clienteId) || other.clienteId == _this.clienteId)&&(identical(other.fecha, _this.fecha) || other.fecha == _this.fecha)&&(identical(other.horasSueno, _this.horasSueno) || other.horasSueno == _this.horasSueno)&&(identical(other.estres, _this.estres) || other.estres == _this.estres)&&(identical(other.agujetas, _this.agujetas) || other.agujetas == _this.agujetas)&&(identical(other.fatiga, _this.fatiga) || other.fatiga == _this.fatiga)&&(identical(other.notas, _this.notas) || other.notas == _this.notas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as CheckinRecuperacion;
  return Object.hash(runtimeType,_this.id,_this.clienteId,_this.fecha,_this.horasSueno,_this.estres,_this.agujetas,_this.fatiga,_this.notas);
}

@override
String toString() {
  final _this = this as CheckinRecuperacion;
  return 'CheckinRecuperacion(id: ${_this.id}, clienteId: ${_this.clienteId}, fecha: ${_this.fecha}, horasSueno: ${_this.horasSueno}, estres: ${_this.estres}, agujetas: ${_this.agujetas}, fatiga: ${_this.fatiga}, notas: ${_this.notas})';
}


}

/// @nodoc
abstract mixin class $CheckinRecuperacionCopyWith<$Res>  {
  factory $CheckinRecuperacionCopyWith(CheckinRecuperacion value, $Res Function(CheckinRecuperacion) _then) = _$CheckinRecuperacionCopyWithImpl;
@useResult
$Res call({
 String id, String clienteId, DateTime fecha, double horasSueno, int estres, int agujetas, int fatiga, String? notas
});




}
/// @nodoc
class _$CheckinRecuperacionCopyWithImpl<$Res>
    implements $CheckinRecuperacionCopyWith<$Res> {
  _$CheckinRecuperacionCopyWithImpl(this._self, this._then);

  final CheckinRecuperacion _self;
  final $Res Function(CheckinRecuperacion) _then;

/// Create a copy of CheckinRecuperacion
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? clienteId = null,Object? fecha = null,Object? horasSueno = null,Object? estres = null,Object? agujetas = null,Object? fatiga = null,Object? notas = freezed,}) {
  return _then(CheckinRecuperacion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,horasSueno: null == horasSueno ? _self.horasSueno : horasSueno // ignore: cast_nullable_to_non_nullable
as double,estres: null == estres ? _self.estres : estres // ignore: cast_nullable_to_non_nullable
as int,agujetas: null == agujetas ? _self.agujetas : agujetas // ignore: cast_nullable_to_non_nullable
as int,fatiga: null == fatiga ? _self.fatiga : fatiga // ignore: cast_nullable_to_non_nullable
as int,notas: freezed == notas ? _self.notas : notas // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CheckinRecuperacion].
extension CheckinRecuperacionPatterns on CheckinRecuperacion {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CheckinRecuperacion value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CheckinRecuperacion() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CheckinRecuperacion value)  $default,){
final _that = this;
switch (_that) {
case _CheckinRecuperacion():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CheckinRecuperacion value)?  $default,){
final _that = this;
switch (_that) {
case _CheckinRecuperacion() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String clienteId,  DateTime fecha,  double horasSueno,  int estres,  int agujetas,  int fatiga,  String? notas)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CheckinRecuperacion() when $default != null:
return $default(_that.id,_that.clienteId,_that.fecha,_that.horasSueno,_that.estres,_that.agujetas,_that.fatiga,_that.notas);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String clienteId,  DateTime fecha,  double horasSueno,  int estres,  int agujetas,  int fatiga,  String? notas)  $default,) {final _that = this;
switch (_that) {
case _CheckinRecuperacion():
return $default(_that.id,_that.clienteId,_that.fecha,_that.horasSueno,_that.estres,_that.agujetas,_that.fatiga,_that.notas);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String clienteId,  DateTime fecha,  double horasSueno,  int estres,  int agujetas,  int fatiga,  String? notas)?  $default,) {final _that = this;
switch (_that) {
case _CheckinRecuperacion() when $default != null:
return $default(_that.id,_that.clienteId,_that.fecha,_that.horasSueno,_that.estres,_that.agujetas,_that.fatiga,_that.notas);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _CheckinRecuperacion implements CheckinRecuperacion {
  const _CheckinRecuperacion({required this.id, required this.clienteId, required this.fecha, required this.horasSueno, required this.estres, required this.agujetas, required this.fatiga, this.notas});
  factory _CheckinRecuperacion.fromJson(Map<String, dynamic> json) => _$CheckinRecuperacionFromJson(json);

@override final  String id;
@override final  String clienteId;
@override final  DateTime fecha;
@override final  double horasSueno;
@override final  int estres;
@override final  int agujetas;
@override final  int fatiga;
@override final  String? notas;

/// Create a copy of CheckinRecuperacion
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CheckinRecuperacionCopyWith<_CheckinRecuperacion> get copyWith => __$CheckinRecuperacionCopyWithImpl<_CheckinRecuperacion>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$CheckinRecuperacionToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CheckinRecuperacion&&(identical(other.id, id) || other.id == id)&&(identical(other.clienteId, clienteId) || other.clienteId == clienteId)&&(identical(other.fecha, fecha) || other.fecha == fecha)&&(identical(other.horasSueno, horasSueno) || other.horasSueno == horasSueno)&&(identical(other.estres, estres) || other.estres == estres)&&(identical(other.agujetas, agujetas) || other.agujetas == agujetas)&&(identical(other.fatiga, fatiga) || other.fatiga == fatiga)&&(identical(other.notas, notas) || other.notas == notas));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,id,clienteId,fecha,horasSueno,estres,agujetas,fatiga,notas);
}

@override
String toString() {
    return 'CheckinRecuperacion(id: $id, clienteId: $clienteId, fecha: $fecha, horasSueno: $horasSueno, estres: $estres, agujetas: $agujetas, fatiga: $fatiga, notas: $notas)';
}


}

/// @nodoc
abstract mixin class _$CheckinRecuperacionCopyWith<$Res> implements $CheckinRecuperacionCopyWith<$Res> {
  factory _$CheckinRecuperacionCopyWith(_CheckinRecuperacion value, $Res Function(_CheckinRecuperacion) _then) = __$CheckinRecuperacionCopyWithImpl;
@override @useResult
$Res call({
 String id, String clienteId, DateTime fecha, double horasSueno, int estres, int agujetas, int fatiga, String? notas
});




}
/// @nodoc
class __$CheckinRecuperacionCopyWithImpl<$Res>
    implements _$CheckinRecuperacionCopyWith<$Res> {
  __$CheckinRecuperacionCopyWithImpl(this._self, this._then);

  final _CheckinRecuperacion _self;
  final $Res Function(_CheckinRecuperacion) _then;

/// Create a copy of CheckinRecuperacion
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? clienteId = null,Object? fecha = null,Object? horasSueno = null,Object? estres = null,Object? agujetas = null,Object? fatiga = null,Object? notas = freezed,}) {
  return _then(_CheckinRecuperacion(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,clienteId: null == clienteId ? _self.clienteId : clienteId // ignore: cast_nullable_to_non_nullable
as String,fecha: null == fecha ? _self.fecha : fecha // ignore: cast_nullable_to_non_nullable
as DateTime,horasSueno: null == horasSueno ? _self.horasSueno : horasSueno // ignore: cast_nullable_to_non_nullable
as double,estres: null == estres ? _self.estres : estres // ignore: cast_nullable_to_non_nullable
as int,agujetas: null == agujetas ? _self.agujetas : agujetas // ignore: cast_nullable_to_non_nullable
as int,fatiga: null == fatiga ? _self.fatiga : fatiga // ignore: cast_nullable_to_non_nullable
as int,notas: freezed == notas ? _self.notas : notas // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
