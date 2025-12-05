import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';

class CredentialQRDialog extends StatelessWidget {
  final Credential credential;

  const CredentialQRDialog({
    super.key,
    required this.credential,
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
        return 'VERIFIED';
      case CredentialStatus.failed:
        return 'FAILED';
    }
  }

  @override
  Widget build(BuildContext context) {
    final metadata = credential.metadata;
    final title = metadata['title'] as String? ?? 'Untitled';
    final description = metadata['description'] as String? ?? '';
    final imageUrl = metadata['image'] as String? ?? '';
    final isVerified = credential.status == CredentialStatus.confirmed;

    // Use tokenId for QR code if available, otherwise use credential ID
    final qrData = credential.tokenId ?? credential.id;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with close button
              Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _getStatusColor(credential.status).withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isVerified ? Icons.verified : Icons.pending,
                      color: _getStatusColor(credential.status),
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Status Badge
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: _getStatusColor(credential.status),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getStatusText(credential.status),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // QR Code
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: QrImageView(
                        data: qrData,
                        version: QrVersions.auto,
                        size: 250,
                        backgroundColor: Colors.white,
                        errorCorrectionLevel: QrErrorCorrectLevel.H,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // QR Code Info
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: Colors.blue[700],
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Scan this QR code to verify this credential',
                              style: TextStyle(
                                color: Colors.blue[700],
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Image
                    if (imageUrl.isNotEmpty) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          imageUrl,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: 150,
                              color: Colors.grey[200],
                              child: const Icon(
                                Icons.image_not_supported,
                                size: 48,
                                color: Colors.grey,
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Description
                    if (description.isNotEmpty) ...[
                      Text(
                        'Description',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[700],
                            ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Credential Details
                    _buildDetailRow(
                      context,
                      'Recipient',
                      '${credential.recipientAddress.substring(0, 6)}...${credential.recipientAddress.substring(credential.recipientAddress.length - 4)}',
                      Icons.account_circle,
                      onTap: () {
                        Clipboard.setData(ClipboardData(text: credential.recipientAddress));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Address copied!')),
                        );
                      },
                    ),
                    if (credential.tokenId != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        'Token ID',
                        credential.tokenId!.length > 16
                            ? '${credential.tokenId!.substring(0, 16)}...'
                            : credential.tokenId!,
                        Icons.tag,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: credential.tokenId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Token ID copied!')),
                          );
                        },
                      ),
                    ],
                    if (credential.txHash != null) ...[
                      const SizedBox(height: 8),
                      _buildDetailRow(
                        context,
                        'Transaction',
                        '${credential.txHash!.substring(0, 10)}...${credential.txHash!.substring(credential.txHash!.length - 8)}',
                        Icons.link,
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: credential.txHash!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Transaction hash copied!')),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: Colors.grey[600]),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              Icon(
                Icons.content_copy,
                size: 16,
                color: Colors.grey[400],
              ),
          ],
        ),
      ),
    );
  }
}
