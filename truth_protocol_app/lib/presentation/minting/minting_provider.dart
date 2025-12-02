import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:truth_protocol_app/data/repositories/credential_repository_impl.dart';
import 'package:truth_protocol_app/data/dtos/mint_request.dart';

part 'minting_provider.g.dart';

@riverpod
class MintingNotifier extends _$MintingNotifier {
  @override
  FutureOr<void> build() {
    // Initial state
  }

  Future<void> mintCredential({
    required String recipientAddress,
    required String title,
    required String description,
    required String imageUrl,
    Map<String, String>? attributes,
  }) async {
    state = const AsyncValue.loading();

    try {
      final metadata = {
        'title': title,
        'description': description,
        'image': imageUrl,
        if (attributes != null && attributes.isNotEmpty) 'attributes': attributes,
      };

      final request = MintRequest(
        recipientWalletAddress: recipientAddress,
        metadata: metadata,
      );

      final repository = ref.read(credentialRepositoryProvider);
      await repository.mintCredential(request);

      state = const AsyncValue.data(null);
    } catch (e, s) {
      state = AsyncValue.error(e, s);
    }
  }
}
