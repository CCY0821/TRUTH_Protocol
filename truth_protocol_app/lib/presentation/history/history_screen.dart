import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';
import 'package:truth_protocol_app/presentation/history/history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  Color _getStatusColor(CredentialStatus status) {
    switch (status) {
      case CredentialStatus.queued:
        return Colors.orange;
      case CredentialStatus.pending:
        return Colors.blue;
      case CredentialStatus.confirmed:
        return Colors.green;
      case CredentialStatus.failed:
        return Colors.red;
    }
  }

  String _getStatusText(CredentialStatus status) {
    switch (status) {
      case CredentialStatus.queued:
        return 'QUEUED';
      case CredentialStatus.pending:
        return 'PENDING';
      case CredentialStatus.confirmed:
        return 'CONFIRMED';
      case CredentialStatus.failed:
        return 'FAILED';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialsAsync = ref.watch(credentialListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Issued Credentials'),
      ),
      body: credentialsAsync.when(
        data: (credentials) {
          if (credentials.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No credentials yet',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 8),
                  const Text('Start by minting your first credential'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await ref.read(credentialListProvider.notifier).refresh();
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: credentials.length,
              itemBuilder: (context, index) {
                final credential = credentials[index];
                final metadata = credential.metadata;
                final title = metadata['title'] as String? ?? 'Untitled';
                final description = metadata['description'] as String? ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: _getStatusColor(credential.status).withOpacity(0.2),
                      child: Icon(
                        Icons.verified_outlined,
                        color: _getStatusColor(credential.status),
                      ),
                    ),
                    title: Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          description.length > 50
                              ? '${description.substring(0, 50)}...'
                              : description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(credential.status).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getStatusText(credential.status),
                            style: TextStyle(
                              color: _getStatusColor(credential.status),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      context.push('/credential/${credential.id}');
                    },
                  ),
                );
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $e'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () {
                  ref.invalidate(credentialListProvider);
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
