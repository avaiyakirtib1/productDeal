import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/account_models.dart';

class DocumentListItem extends StatelessWidget {
  final PickedFileData? document;
  final CategorizedDocument? serverDoc;
  final int index;
  final VoidCallback? onRemove;
  /// True when removing a server document via API (show loader)
  final bool isRemoving;
  /// True when this local file is currently uploading (disable remove)
  final bool disableRemove;

  const DocumentListItem({
    super.key,
    this.document,
    this.serverDoc,
    required this.index,
    this.onRemove,
    this.isRemoving = false,
    this.disableRemove = false,
  }) : assert(document != null || serverDoc != null, 'Either document or serverDoc must be provided');

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final fileName = document?.filename ??
        serverDoc?.displayName ??
        (l10n?.document ?? 'Document');
    final isImage = fileName.toLowerCase().endsWith('.jpg') ||
        fileName.toLowerCase().endsWith('.jpeg') ||
        fileName.toLowerCase().endsWith('.png');
    final isPdf = fileName.toLowerCase().endsWith('.pdf');

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + (index * 50)),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.grey.shade200,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isImage
                        ? Colors.blue.shade50
                        : isPdf
                            ? Colors.red.shade50
                            : Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    isImage
                        ? Icons.image
                        : isPdf
                            ? Icons.picture_as_pdf
                            : Icons.description,
                    color: isImage
                        ? Colors.blue
                        : isPdf
                            ? Colors.red
                            : Colors.grey,
                    size: 24,
                  ),
                ),
                title: Text(
                  fileName.length > 35
                      ? '${fileName.substring(0, 35)}...'
                      : fileName,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: isRemoving
                    ? SizedBox(
                        width: 40,
                        height: 40,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.red.shade700,
                            ),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: disableRemove
                                ? Colors.grey.shade200
                                : Colors.red.shade50,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.close,
                            color: disableRemove
                                ? Colors.grey.shade500
                                : Colors.red.shade700,
                            size: 18,
                          ),
                        ),
                        onPressed: disableRemove ? null : onRemove,
                        tooltip: disableRemove
                            ? (l10n?.uploading ?? 'Uploading...')
                            : (l10n?.remove ?? 'Remove'),
                      ),
              ),
            ),
          ),
        );
      },
    );
  }
}
