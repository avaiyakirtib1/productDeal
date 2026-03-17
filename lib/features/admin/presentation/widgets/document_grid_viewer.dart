import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';

class DocumentGridItem {
  final String url;
  final String? type;
  final String? label;

  DocumentGridItem({
    required this.url,
    this.type,
    this.label,
  });
}

class DocumentGridViewer extends StatefulWidget {
  final List<DocumentGridItem> documents;
  final String? selectedUrl;

  const DocumentGridViewer({
    super.key,
    required this.documents,
    this.selectedUrl,
  });

  @override
  State<DocumentGridViewer> createState() => _DocumentGridViewerState();
}

class _DocumentGridViewerState extends State<DocumentGridViewer> {
  String? _selectedUrl;

  @override
  void initState() {
    super.initState();
    _selectedUrl = widget.selectedUrl ??
        (widget.documents.isNotEmpty ? widget.documents.first.url : null);
  }

  bool _isImage(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.gif');
  }

  String _getDocumentLabel(BuildContext context, DocumentGridItem doc) {
    final l10n = AppLocalizations.of(context);
    if (doc.label != null) return doc.label!;
    if (doc.type != null) {
      switch (doc.type) {
        case 'passport':
          return l10n?.passport ?? 'Passport';
        case 'gewerbeschein':
          return l10n?.gewerbeschein ?? 'Gewerbeschein';
        case 'businessLicense':
          return l10n?.businessLicense ?? 'Business License';
        case 'idCard':
          return l10n?.idCard ?? 'ID Card';
        case 'taxId':
          return l10n?.taxId ?? 'Tax ID';
        case 'companyRegistration':
          return l10n?.companyRegistration ?? 'Company Registration';
        default:
          return l10n?.document ?? 'Document';
      }
    }
    return l10n?.document ?? 'Document';
  }

  @override
  Widget build(BuildContext context) {
    if (widget.documents.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            AppLocalizations.of(context)?.noDocumentsAvailable ??
                'No documents available',
          ),
        ),
      );
    }

    final selectedDoc = widget.documents.firstWhere(
      (doc) => doc.url == _selectedUrl,
      orElse: () => widget.documents.first,
    );

    final isImage = _isImage(selectedDoc.url);

    return Column(
      children: [
        // Main document viewer
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: isImage
                  ? InteractiveViewer(
                      child: CachedNetworkImage(
                        imageUrl: selectedDoc.url,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => const Center(
                          child: CircularProgressIndicator(),
                        ),
                        errorWidget: (context, url, error) => const Center(
                          child: Icon(Icons.error, size: 48),
                        ),
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.picture_as_pdf,
                            size: 64,
                            color: Colors.red.shade700,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            AppLocalizations.of(context)?.pdfDocument ??
                                'PDF Document',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _getDocumentLabel(context, selectedDoc),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey.shade600,
                                    ),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: const Icon(Icons.open_in_new),
                            label: Text(
                              AppLocalizations.of(context)?.openInBrowser ??
                                  'Open in Browser',
                            ),
                            onPressed: () async {
                              final uri = Uri.parse(selectedDoc.url);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        // Document grid selector
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.documents.length,
            itemBuilder: (context, index) {
              final doc = widget.documents[index];
              final isSelected = doc.url == _selectedUrl;
              final docIsImage = _isImage(doc.url);

              return GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedUrl = doc.url;
                  });
                },
                child: Container(
                  width: 100,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                      width: isSelected ? 3 : 1.5,
                    ),
                    borderRadius: BorderRadius.circular(8),
                    color: isSelected
                        ? Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withValues(alpha: 0.3)
                        : Colors.white,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(7),
                          ),
                          child: docIsImage
                              ? CachedNetworkImage(
                                  imageUrl: doc.url,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey.shade200,
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) =>
                                      Container(
                                    color: Colors.grey.shade200,
                                    child: const Icon(Icons.error),
                                  ),
                                )
                              : Container(
                                  color: Colors.red.shade50,
                                  child: Center(
                                    child: Icon(
                                      Icons.picture_as_pdf,
                                      color: Colors.red.shade700,
                                      size: 32,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade200,
                          borderRadius: const BorderRadius.vertical(
                            bottom: Radius.circular(7),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getDocumentLabel(context, doc),
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
