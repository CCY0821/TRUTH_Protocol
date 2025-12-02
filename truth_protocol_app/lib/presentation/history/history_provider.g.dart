// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$credentialDetailHash() => r'ea960044e287071873789702252e71949f8349d7';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [credentialDetail].
@ProviderFor(credentialDetail)
const credentialDetailProvider = CredentialDetailFamily();

/// See also [credentialDetail].
class CredentialDetailFamily extends Family<AsyncValue<Credential>> {
  /// See also [credentialDetail].
  const CredentialDetailFamily();

  /// See also [credentialDetail].
  CredentialDetailProvider call(
    String id,
  ) {
    return CredentialDetailProvider(
      id,
    );
  }

  @override
  CredentialDetailProvider getProviderOverride(
    covariant CredentialDetailProvider provider,
  ) {
    return call(
      provider.id,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'credentialDetailProvider';
}

/// See also [credentialDetail].
class CredentialDetailProvider extends AutoDisposeFutureProvider<Credential> {
  /// See also [credentialDetail].
  CredentialDetailProvider(
    String id,
  ) : this._internal(
          (ref) => credentialDetail(
            ref as CredentialDetailRef,
            id,
          ),
          from: credentialDetailProvider,
          name: r'credentialDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$credentialDetailHash,
          dependencies: CredentialDetailFamily._dependencies,
          allTransitiveDependencies:
              CredentialDetailFamily._allTransitiveDependencies,
          id: id,
        );

  CredentialDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<Credential> Function(CredentialDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: CredentialDetailProvider._internal(
        (ref) => create(ref as CredentialDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<Credential> createElement() {
    return _CredentialDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is CredentialDetailProvider && other.id == id;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, id.hashCode);

    return _SystemHash.finish(hash);
  }
}

mixin CredentialDetailRef on AutoDisposeFutureProviderRef<Credential> {
  /// The parameter `id` of this provider.
  String get id;
}

class _CredentialDetailProviderElement
    extends AutoDisposeFutureProviderElement<Credential>
    with CredentialDetailRef {
  _CredentialDetailProviderElement(super.provider);

  @override
  String get id => (origin as CredentialDetailProvider).id;
}

String _$credentialListHash() => r'9a126b52003925b8516216b4dc9487204719e89c';

/// See also [CredentialList].
@ProviderFor(CredentialList)
final credentialListProvider =
    AutoDisposeAsyncNotifierProvider<CredentialList, List<Credential>>.internal(
  CredentialList.new,
  name: r'credentialListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$credentialListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$CredentialList = AutoDisposeAsyncNotifier<List<Credential>>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member
