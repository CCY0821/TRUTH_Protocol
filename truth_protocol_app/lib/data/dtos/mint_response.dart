import 'package:freezed_annotation/freezed_annotation.dart';

part 'mint_response.freezed.dart';
part 'mint_response.g.dart';

@freezed
class MintResponse with _$MintResponse {
  const factory MintResponse({
    required String credentialId,
    required String status,
    String? message,
  }) = _MintResponse;

  factory MintResponse.fromJson(Map<String, dynamic> json) => _$MintResponseFromJson(json);
}
