// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'credential.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CredentialImpl _$$CredentialImplFromJson(Map<String, dynamic> json) =>
    _$CredentialImpl(
      id: json['id'] as String,
      recipientAddress: json['recipientAddress'] as String,
      metadata: json['metadata'] as Map<String, dynamic>,
      status: $enumDecode(_$CredentialStatusEnumMap, json['status']),
      txHash: json['txHash'] as String?,
      tokenId: json['tokenId'] as String?,
      arweaveHash: json['arweaveHash'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      confirmedAt: json['confirmedAt'] == null
          ? null
          : DateTime.parse(json['confirmedAt'] as String),
    );

Map<String, dynamic> _$$CredentialImplToJson(_$CredentialImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'recipientAddress': instance.recipientAddress,
      'metadata': instance.metadata,
      'status': _$CredentialStatusEnumMap[instance.status]!,
      'txHash': instance.txHash,
      'tokenId': instance.tokenId,
      'arweaveHash': instance.arweaveHash,
      'createdAt': instance.createdAt?.toIso8601String(),
      'confirmedAt': instance.confirmedAt?.toIso8601String(),
    };

const _$CredentialStatusEnumMap = {
  CredentialStatus.queued: 'QUEUED',
  CredentialStatus.pending: 'PENDING',
  CredentialStatus.confirmed: 'CONFIRMED',
  CredentialStatus.failed: 'FAILED',
};
