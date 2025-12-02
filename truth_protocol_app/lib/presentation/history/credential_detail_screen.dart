import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';
import 'package:truth_protocol_app/presentation/history/history_provider.dart';

class CredentialDetailScreen extends ConsumerWidget {
  final String credentialId;

  const CredentialDetailScreen({
    super.key,
    required this.credentialId,
  });

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

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final credentialAsync = ref.watch(credentialDetailProvider(credentialId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Credential Details'),
      ),
      body: credentialAsync.when(
        data: (credential) {
          final metadata = credential.metadata;
          final title = metadata['title'] as String? ?? 'Untitled';
          final description = metadata['description'] as String? ?? '';
          final imageUrl = metadata['image'] as String? ?? '';

          // Generate verification URL or data for QR Code
          final verificationData = 'truthprotocol://verify/${credential.id}';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(credential.status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.circle,
                        size: 12,
                        color: _getStatusColor(credential.status),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _getStatusText(credential.status),
                        style: TextStyle(
                          color: _getStatusColor(credential.status),
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image
                if (imageUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      imageUrl,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey[300],
                          child: const Icon(Icons.broken_image, size: 64),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 24),

                // Title
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),

                // Description
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Colors.grey[700],
                      ),
                ),
                const SizedBox(height: 24),

                // QR Code Card
                if (credential.status == CredentialStatus.confirmed)
                  Card(
                    elevation: 4,
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        children: [
                          Text(
                            'Verification QR Code',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Scan this code to verify the credential',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: QrImageView(
                              data: verificationData,
                              version: QrVersions.auto,
                              size: 200.0,
                              backgroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Credential ID: ${credential.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  fontFamily: 'monospace',
                                  color: Colors.grey[600],
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 24),

                // Blockchain Info Card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Blockchain Information',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          context,
                          'Recipient',
                          credential.recipientAddress,
                          onCopy: () => _copyToClipboard(
                            context,
                            credential.recipientAddress,
                          ),
                        ),
                        if (credential.tokenId != null) ...[
                          const Divider(),
                          _buildInfoRow(context, 'Token ID', credential.tokenId!),
                        ],
                        if (credential.txHash != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Transaction Hash',
                            credential.txHash!,
                            onCopy: () => _copyToClipboard(context, credential.txHash!),
                          ),
                        ],
                        if (credential.arweaveHash != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Arweave Hash',
                            credential.arweaveHash!,
                            onCopy: () => _copyToClipboard(context, credential.arweaveHash!),
                          ),
                        ],
                        if (credential.createdAt != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Created',
                            DateFormat('yyyy-MM-dd HH:mm').format(credential.createdAt!),
                          ),
                        ],
                        if (credential.confirmedAt != null) ...[
                          const Divider(),
                          _buildInfoRow(
                            context,
                            'Confirmed',
                            DateFormat('yyyy-MM-dd HH:mm').format(credential.confirmedAt!),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    String label,
    String value, {
    VoidCallback? onCopy,
  }) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value.length > 20 ? '${value.substring(0, 10)}...${value.substring(value.length - 10)}' : value,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
              if (onCopy != null)
                IconButton(
                  icon: const Icon(Icons.copy, size: 16),
                  onPressed: onCopy,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
