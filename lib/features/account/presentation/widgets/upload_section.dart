import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/upload_service.dart';
import 'document_list_item.dart';

class UploadSection extends ConsumerWidget {
  final List<PickedFileData> selectedDocuments;
  final bool uploading;
  final bool uploaded;
  final VoidCallback onPickDocuments;
  final VoidCallback onUploadDocuments;
  final Function(int) onRemoveDocument;

  const UploadSection({
    super.key,
    required this.selectedDocuments,
    required this.uploading,
    required this.uploaded,
    required this.onPickDocuments,
    required this.onUploadDocuments,
    required this.onRemoveDocument,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    final isWholesaler = user?.role == UserRole.wholesaler;
    final isBuyer = user?.role == UserRole.kiosk;

    String documentTypes;
    if (isWholesaler) {
      documentTypes = l10n?.wholesalerDocumentTypes ??
          'Business license, Tax ID, Company registration documents (PNG, JPG, PDF)';
    } else if (isBuyer) {
      documentTypes = l10n?.buyerDocumentTypes ??
          'Identity card, Driver\'s license, or any government-issued ID (PNG, JPG, PDF)';
    } else {
      documentTypes = l10n?.generalDocumentTypes ??
          'Business license, Driver\'s license, Identity card (PNG, JPG, PDF)';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.upload_file,
                  color: colorScheme.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.uploadVerificationDocument ??
                      'Upload Verification Document',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${l10n?.acceptedDocumentTypes ?? 'Accepted document types'}: $documentTypes',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // Selected Documents List
          if (selectedDocuments.isNotEmpty && !uploaded) ...[
            Text(
              '${l10n?.selectedDocuments ?? 'Selected Documents'} (${selectedDocuments.length})',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 12),
            ...selectedDocuments.asMap().entries.map((entry) {
              return DocumentListItem(
                document: entry.value,
                index: entry.key,
                onRemove: () => onRemoveDocument(entry.key),
              );
            }),
            const SizedBox(height: 20),
          ],
          // Upload Success Message
          if (uploaded) ...[
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.9 + (value * 0.1),
                  child: Opacity(
                    opacity: value,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.green.shade50,
                            Colors.green.shade100.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.green.shade200,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              '${selectedDocuments.length} ${l10n?.documentsUploadedSuccessfully ?? 'document(s) uploaded successfully. Our admin will review and update your account status.'}',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: Colors.green.shade900,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
          ],
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.add_circle_outline),
                  label: Text(l10n?.addDocuments ?? 'Add Documents'),
                  onPressed: uploading || uploaded ? null : onPickDocuments,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  icon: uploading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Icon(Icons.cloud_upload),
                  label: Text(
                    uploading
                        ? (l10n?.uploading ?? 'Uploading...')
                        : uploaded
                            ? (l10n?.uploaded ?? 'Uploaded')
                            : selectedDocuments.isEmpty
                                ? (l10n?.selectFirst ?? 'Select First')
                                : '${l10n?.upload ?? 'Upload'} ${selectedDocuments.length}',
                  ),
                  onPressed: uploading || uploaded || selectedDocuments.isEmpty
                      ? null
                      : onUploadDocuments,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
