import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/data/datasources/credential_remote_data_source.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';

part 'verifier_provider.g.dart';

@riverpod
class VerifierNotifier extends _$VerifierNotifier {
  @override
  FutureOr<Credential?> build() {
    return null;
  }

  Future<void> verifyCredential(String tokenId) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final dataSource = ref.read(credentialRemoteDataSourceProvider);
      return await dataSource.verifyCredentialByTokenId(tokenId);
    });
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}
