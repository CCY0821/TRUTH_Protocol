import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:truth_protocol_app/domain/entities/credential.dart';
import 'package:truth_protocol_app/presentation/verifier/verifier_provider.dart';

class VerifierScreen extends ConsumerStatefulWidget {
  const VerifierScreen({super.key});

  @override
  ConsumerState<VerifierScreen> createState() => _VerifierScreenState();
}

class _VerifierScreenState extends ConsumerState<VerifierScreen> {
  MobileScannerController? _cameraController;
  bool _isScanning = true;

  @override
  void initState() {
    super.initState();
    _cameraController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    final List<Barcode> barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        setState(() {
          _isScanning = false;
        });
        _cameraController?.stop();

        // Extract tokenId from QR code
        final tokenId = barcode.rawValue!;
        ref.read(verifierNotifierProvider.notifier).verifyCredential(tokenId);
        break;
      }
    }
  }

  void _resetScanner() {
    setState(() {
      _isScanning = true;
    });
    ref.read(verifierNotifierProvider.notifier).reset();
    _cameraController?.start();
  }

  @override
  Widget build(BuildContext context) {
    final verificationState = ref.watch(verifierNotifierProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Credential'),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Camera Scanner
          if (_isScanning)
            MobileScanner(
              controller: _cameraController,
              onDetect: _onDetect,
            ),

          // Scanning Overlay
          if (_isScanning)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
              child: Column(
                children: [
                  Expanded(
                    flex: 1,
                    child: Container(color: Colors.black.withOpacity(0.7)),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Container(color: Colors.black.withOpacity(0.7)),
                        ),
                        Expanded(
                          flex: 3,
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: Colors.white,
                                width: 3,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Container(color: Colors.black.withOpacity(0.7)),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 1,
                    child: Container(
                      color: Colors.black.withOpacity(0.7),
                      child: Center(
                        child: Text(
                          'Align QR Code within the frame',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Verification Result
          if (!_isScanning)
            Container(
              color: Colors.white,
              child: verificationState.when(
                data: (credential) {
                  if (credential == null) {
                    return const Center(child: Text('No credential'));
                  }
                  return _buildVerificationResult(context, credential);
                },
                loading: () => const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text('Verifying credential...'),
                    ],
                  ),
                ),
                error: (error, stack) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[400],
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Verification Failed',
                          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: Colors.red[700],
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'This credential could not be verified',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Error: $error',
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Colors.grey[600],
                              ),
                        ),
                        const SizedBox(height: 32),
                        FilledButton.icon(
                          onPressed: _resetScanner,
                          icon: const Icon(Icons.qr_code_scanner),
                          label: const Text('Scan Again'),
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                              vertical: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildVerificationResult(BuildContext context, Credential credential) {
    final metadata = credential.metadata;
    final title = metadata['title'] as String? ?? 'Untitled';
    final description = metadata['description'] as String? ?? '';
    final imageUrl = metadata['image'] as String? ?? '';
    final isVerified = credential.status == CredentialStatus.confirmed;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Verification Status
          Container(
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              color: isVerified ? Colors.green[50] : Colors.orange[50],
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isVerified ? Colors.green : Colors.orange,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                Icon(
                  isVerified ? Icons.verified : Icons.pending,
                  size: 64,
                  color: isVerified ? Colors.green : Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  isVerified ? 'VERIFIED' : 'PENDING',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: isVerified ? Colors.green[700] : Colors.orange[700],
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  isVerified
                      ? 'This credential is authentic and verified on blockchain'
                      : 'This credential is pending blockchain confirmation',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Credential Image
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
                    color: Colors.grey[200],
                    child: const Icon(
                      Icons.image_not_supported,
                      size: 64,
                      color: Colors.grey,
                    ),
                  );
                },
              ),
            ),
          if (imageUrl.isNotEmpty) const SizedBox(height: 24),

          // Credential Details Card
          Card(
            elevation: 0,
            color: Colors.grey[50],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey[300]!),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Credential Details',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Divider(height: 24),
                  _buildDetailRow(context, 'Title', title),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Description', description),
                  const SizedBox(height: 12),
                  _buildDetailRow(context, 'Recipient', credential.recipientAddress),
                  if (credential.tokenId != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Token ID', credential.tokenId!),
                  ],
                  if (credential.txHash != null) ...[
                    const SizedBox(height: 12),
                    _buildDetailRow(context, 'Transaction', '${credential.txHash!.substring(0, 10)}...${credential.txHash!.substring(credential.txHash!.length - 8)}'),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          FilledButton.icon(
            onPressed: _resetScanner,
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('Scan Another'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ),
      ],
    );
  }
}
