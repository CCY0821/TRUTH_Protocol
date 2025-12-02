import 'package:freezed_annotation/freezed_annotation.dart';

part 'credential.freezed.dart';
part 'credential.g.dart';

enum CredentialStatus {
  @JsonValue('QUEUED')
  queued,
  @JsonValue('PENDING')
  pending,
  @JsonValue('CONFIRMED')
  confirmed,
  @JsonValue('FAILED')
  failed,
}

@freezed
class Credential with _$Credential {
  const factory Credential({
    required String id,
    required String recipientAddress,
    required Map<String, dynamic> metadata,
    required CredentialStatus status,
    String? txHash,
    String? tokenId,
    String? arweaveHash,
    DateTime? createdAt,
    DateTime? confirmedAt,
  }) = _Credential;

  factory Credential.fromJson(Map<String, dynamic> json) => _$CredentialFromJson(json);
}
