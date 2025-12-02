import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/data/repositories/credential_repository_impl.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';

part 'history_provider.g.dart';

@riverpod
class CredentialList extends _$CredentialList {
  @override
  Future<List<Credential>> build() async {
    return _fetchCredentials();
  }

  Future<List<Credential>> _fetchCredentials() async {
    final repository = ref.read(credentialRepositoryProvider);
    return await repository.getMyCredentials();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchCredentials());
  }
}

@riverpod
Future<Credential> credentialDetail(CredentialDetailRef ref, String id) async {
  final repository = ref.read(credentialRepositoryProvider);
  return await repository.getCredentialById(id);
}
