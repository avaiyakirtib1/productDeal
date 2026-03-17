import 'package:flutter/material.dart';

import '../../data/legal_document_content.dart';

/// Full-screen scrollable viewer for legal document text.
/// Uses [SelectableText] for accessibility and copy.
class LegalDocumentViewer extends StatelessWidget {
  const LegalDocumentViewer({
    super.key,
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  /// Predefined viewers for the three main documents + Rahmenvertrag
  static void showAgb(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) => _LegalDocumentScaffold(
          title: 'Allgemeine Geschäftsbedingungen (AGB)',
          body: legalDocumentAgb,
          scrollController: scrollController,
        ),
      ),
    );
  }

  static void showCompliance(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) => _LegalDocumentScaffold(
          title: 'Compliance-Richtlinie (Markenrecht & Produktintegrität)',
          body: legalDocumentCompliance,
          scrollController: scrollController,
        ),
      ),
    );
  }

  static void showPrivacy(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) => _LegalDocumentScaffold(
          title: 'Datenschutzerklärung und Datenübermittlung',
          body: legalDocumentPrivacy,
          scrollController: scrollController,
        ),
      ),
    );
  }

  static void showRahmenvertrag(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      isDismissible: true,
      enableDrag: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.95,
        minChildSize: 0.5,
        maxChildSize: 1,
        expand: false,
        builder: (_, scrollController) => _LegalDocumentScaffold(
          title: 'Rahmenvertrag zur Nutzung der App',
          body: legalDocumentRahmenvertrag,
          scrollController: scrollController,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _LegalDocumentScaffold(title: title, body: body);
  }
}

class _LegalDocumentScaffold extends StatelessWidget {
  const _LegalDocumentScaffold({
    required this.title,
    required this.body,
    ScrollController? scrollController,
  }) : _scrollController = scrollController;

  final String title;
  final String body;
  final ScrollController? _scrollController;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final controller = _scrollController ?? ScrollController();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            controller: controller,
            padding: const EdgeInsets.all(16),
            child: SelectableText(
              body,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
