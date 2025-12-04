import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/core/network/api_client.dart';
import 'package:truth_protocol_app/data/dtos/mint_request.dart';
import 'package:truth_protocol_app/data/dtos/mint_response.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';

part 'credential_remote_data_source.g.dart';

@Riverpod(keepAlive: true)
CredentialRemoteDataSource credentialRemoteDataSource(CredentialRemoteDataSourceRef ref) {
  return CredentialRemoteDataSource(ref.watch(apiClientProvider));
}

class CredentialRemoteDataSource {
  final Dio _dio;

  CredentialRemoteDataSource(this._dio);

  Future<MintResponse> mintCredential(MintRequest request) async {
    try {
      final response = await _dio.post(
        '/credentials/mint',
        data: request.toJson(),
      );
      return MintResponse.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Credential>> getMyCredentials() async {
    try {
      final response = await _dio.get('/credentials');
      final List<dynamic> data = response.data;
      return data.map((json) => Credential.fromJson(json)).toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<Credential> getCredentialById(String id) async {
    try {
      final response = await _dio.get('/credentials/$id');
      return Credential.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }

  Future<Credential> verifyCredentialByTokenId(String tokenId) async {
    try {
      final response = await _dio.get('/credentials/verify/$tokenId');
      return Credential.fromJson(response.data);
    } catch (e) {
      rethrow;
    }
  }
}
