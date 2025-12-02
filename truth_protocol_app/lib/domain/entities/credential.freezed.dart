// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'credential.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Credential _$CredentialFromJson(Map<String, dynamic> json) {
  return _Credential.fromJson(json);
}

/// @nodoc
mixin _$Credential {
  String get id => throw _privateConstructorUsedError;
  String get recipientAddress => throw _privateConstructorUsedError;
  Map<String, dynamic> get metadata => throw _privateConstructorUsedError;
  CredentialStatus get status => throw _privateConstructorUsedError;
  String? get txHash => throw _privateConstructorUsedError;
  String? get tokenId => throw _privateConstructorUsedError;
  String? get arweaveHash => throw _privateConstructorUsedError;
  DateTime? get createdAt => throw _privateConstructorUsedError;
  DateTime? get confirmedAt => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $CredentialCopyWith<Credential> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $CredentialCopyWith<$Res> {
  factory $CredentialCopyWith(
          Credential value, $Res Function(Credential) then) =
      _$CredentialCopyWithImpl<$Res, Credential>;
  @useResult
  $Res call(
      {String id,
      String recipientAddress,
      Map<String, dynamic> metadata,
      CredentialStatus status,
      String? txHash,
      String? tokenId,
      String? arweaveHash,
      DateTime? createdAt,
      DateTime? confirmedAt});
}

/// @nodoc
class _$CredentialCopyWithImpl<$Res, $Val extends Credential>
    implements $CredentialCopyWith<$Res> {
  _$CredentialCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipientAddress = null,
    Object? metadata = null,
    Object? status = null,
    Object? txHash = freezed,
    Object? tokenId = freezed,
    Object? arweaveHash = freezed,
    Object? createdAt = freezed,
    Object? confirmedAt = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipientAddress: null == recipientAddress
          ? _value.recipientAddress
          : recipientAddress // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value.metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CredentialStatus,
      txHash: freezed == txHash
          ? _value.txHash
          : txHash // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenId: freezed == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String?,
      arweaveHash: freezed == arweaveHash
          ? _value.arweaveHash
          : arweaveHash // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$CredentialImplCopyWith<$Res>
    implements $CredentialCopyWith<$Res> {
  factory _$$CredentialImplCopyWith(
          _$CredentialImpl value, $Res Function(_$CredentialImpl) then) =
      __$$CredentialImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String recipientAddress,
      Map<String, dynamic> metadata,
      CredentialStatus status,
      String? txHash,
      String? tokenId,
      String? arweaveHash,
      DateTime? createdAt,
      DateTime? confirmedAt});
}

/// @nodoc
class __$$CredentialImplCopyWithImpl<$Res>
    extends _$CredentialCopyWithImpl<$Res, _$CredentialImpl>
    implements _$$CredentialImplCopyWith<$Res> {
  __$$CredentialImplCopyWithImpl(
      _$CredentialImpl _value, $Res Function(_$CredentialImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? recipientAddress = null,
    Object? metadata = null,
    Object? status = null,
    Object? txHash = freezed,
    Object? tokenId = freezed,
    Object? arweaveHash = freezed,
    Object? createdAt = freezed,
    Object? confirmedAt = freezed,
  }) {
    return _then(_$CredentialImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      recipientAddress: null == recipientAddress
          ? _value.recipientAddress
          : recipientAddress // ignore: cast_nullable_to_non_nullable
              as String,
      metadata: null == metadata
          ? _value._metadata
          : metadata // ignore: cast_nullable_to_non_nullable
              as Map<String, dynamic>,
      status: null == status
          ? _value.status
          : status // ignore: cast_nullable_to_non_nullable
              as CredentialStatus,
      txHash: freezed == txHash
          ? _value.txHash
          : txHash // ignore: cast_nullable_to_non_nullable
              as String?,
      tokenId: freezed == tokenId
          ? _value.tokenId
          : tokenId // ignore: cast_nullable_to_non_nullable
              as String?,
      arweaveHash: freezed == arweaveHash
          ? _value.arweaveHash
          : arweaveHash // ignore: cast_nullable_to_non_nullable
              as String?,
      createdAt: freezed == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      confirmedAt: freezed == confirmedAt
          ? _value.confirmedAt
          : confirmedAt // ignore: cast_nullable_to_non_nullable
              as DateTime?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$CredentialImpl implements _Credential {
  const _$CredentialImpl(
      {required this.id,
      required this.recipientAddress,
      required final Map<String, dynamic> metadata,
      required this.status,
      this.txHash,
      this.tokenId,
      this.arweaveHash,
      this.createdAt,
      this.confirmedAt})
      : _metadata = metadata;

  factory _$CredentialImpl.fromJson(Map<String, dynamic> json) =>
      _$$CredentialImplFromJson(json);

  @override
  final String id;
  @override
  final String recipientAddress;
  final Map<String, dynamic> _metadata;
  @override
  Map<String, dynamic> get metadata {
    if (_metadata is EqualUnmodifiableMapView) return _metadata;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_metadata);
  }

  @override
  final CredentialStatus status;
  @override
  final String? txHash;
  @override
  final String? tokenId;
  @override
  final String? arweaveHash;
  @override
  final DateTime? createdAt;
  @override
  final DateTime? confirmedAt;

  @override
  String toString() {
    return 'Credential(id: $id, recipientAddress: $recipientAddress, metadata: $metadata, status: $status, txHash: $txHash, tokenId: $tokenId, arweaveHash: $arweaveHash, createdAt: $createdAt, confirmedAt: $confirmedAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$CredentialImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.recipientAddress, recipientAddress) ||
                other.recipientAddress == recipientAddress) &&
            const DeepCollectionEquality().equals(other._metadata, _metadata) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.txHash, txHash) || other.txHash == txHash) &&
            (identical(other.tokenId, tokenId) || other.tokenId == tokenId) &&
            (identical(other.arweaveHash, arweaveHash) ||
                other.arweaveHash == arweaveHash) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      recipientAddress,
      const DeepCollectionEquality().hash(_metadata),
      status,
      txHash,
      tokenId,
      arweaveHash,
      createdAt,
      confirmedAt);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$CredentialImplCopyWith<_$CredentialImpl> get copyWith =>
      __$$CredentialImplCopyWithImpl<_$CredentialImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$CredentialImplToJson(
      this,
    );
  }
}

abstract class _Credential implements Credential {
  const factory _Credential(
      {required final String id,
      required final String recipientAddress,
      required final Map<String, dynamic> metadata,
      required final CredentialStatus status,
      final String? txHash,
      final String? tokenId,
      final String? arweaveHash,
      final DateTime? createdAt,
      final DateTime? confirmedAt}) = _$CredentialImpl;

  factory _Credential.fromJson(Map<String, dynamic> json) =
      _$CredentialImpl.fromJson;

  @override
  String get id;
  @override
  String get recipientAddress;
  @override
  Map<String, dynamic> get metadata;
  @override
  CredentialStatus get status;
  @override
  String? get txHash;
  @override
  String? get tokenId;
  @override
  String? get arweaveHash;
  @override
  DateTime? get createdAt;
  @override
  DateTime? get confirmedAt;
  @override
  @JsonKey(ignore: true)
  _$$CredentialImplCopyWith<_$CredentialImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
