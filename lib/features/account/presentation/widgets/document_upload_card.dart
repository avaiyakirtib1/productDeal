import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/account_models.dart';
import '../../data/models/document_type.dart';
import 'document_list_item.dart';

class DocumentUploadCard extends StatelessWidget {
  final DocumentType documentType;
  final String title;
  final String description;
  final String alternativeMessage;
  final List<PickedFileData> selectedFiles;
  final List<CategorizedDocument> serverDocuments;
  final int uploadedCount;
  final bool uploading;
  final String? removingUrl;
  final VoidCallback onPickDocument;
  final void Function(int index) onRemoveDocument;
  final void Function(String url)? onRemoveServerDocument;

  const DocumentUploadCard({
    super.key,
    required this.documentType,
    required this.title,
    required this.description,
    required this.alternativeMessage,
    this.selectedFiles = const [],
    this.serverDocuments = const [],
    this.uploadedCount = 0,
    required this.uploading,
    this.removingUrl,
    required this.onPickDocument,
    required this.onRemoveDocument,
    this.onRemoveServerDocument,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: (serverDocuments.isNotEmpty || selectedFiles.isNotEmpty)
              ? Colors.green.shade300
              : Colors.grey.shade300,
          width: selectedFiles.isNotEmpty ? 2 : 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      (serverDocuments.isNotEmpty || selectedFiles.isNotEmpty)
                          ? Colors.green.shade50
                          : Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  selectedFiles.isNotEmpty
                      ? Icons.check_circle
                      : Icons.description,
                  color:
                      (serverDocuments.isNotEmpty || selectedFiles.isNotEmpty)
                          ? Colors.green.shade700
                          : Colors.blue.shade700,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.blue.shade200,
                width: 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline,
                  size: 18,
                  color: Colors.blue.shade700,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    alternativeMessage,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.blue.shade900,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (serverDocuments.isNotEmpty || selectedFiles.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...serverDocuments.asMap().entries.map((entry) {
              final idx = entry.key;
              final doc = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DocumentListItem(
                        serverDoc: doc,
                        index: idx,
                        onRemove: () => onRemoveServerDocument?.call(doc.url),
                        isRemoving: removingUrl == doc.url,
                      ),
                    )
                  ],
                ),
              );
            }),
            ...selectedFiles.asMap().entries.map((entry) {
              final idx = entry.key;
              final doc = entry.value;
              final isUploaded = idx < uploadedCount;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: DocumentListItem(
                        document: doc,
                        index: serverDocuments.length + idx,
                        onRemove: () => onRemoveDocument(idx),
                        disableRemove: uploading && idx == uploadedCount,
                      ),
                    ),
                    SizedBox(
                      width: 30,
                      height: 30,
                      child: Center(
                          child: (isUploaded)
                              ? Icon(Icons.check_circle,
                                  color: Colors.green.shade700, size: 20)
                              : (uploading && idx == uploadedCount)
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: Center(
                                          child: CircularProgressIndicator(strokeWidth: 2)),
                                    )
                                  : null),
                    ),
                  ],
                ),
              );
            }),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              icon: uploading
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.upload_file),
              label: Text(
                uploading
                    ? (l10n?.uploading ?? 'Uploading...')
                    : (serverDocuments.isEmpty && selectedFiles.isEmpty)
                        ? (l10n?.selectDocument ?? 'Select Document')
                        : (l10n?.addDocuments ?? 'Add Documents'),
              ),
              onPressed: uploading ? null : onPickDocument,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                side: BorderSide(
                  color:
                      (serverDocuments.isNotEmpty || selectedFiles.isNotEmpty)
                          ? Colors.green.shade300
                          : Colors.blue.shade300,
                  width: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
