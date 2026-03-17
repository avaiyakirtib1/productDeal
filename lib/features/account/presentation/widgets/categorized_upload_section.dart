import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/upload_service.dart';
import '../../data/models/account_models.dart';
import '../../data/models/document_type.dart';
import '../../data/repositories/account_repository.dart';
import 'document_upload_card.dart';

class CategorizedUploadSection extends ConsumerStatefulWidget {
  const CategorizedUploadSection({super.key});

  @override
  ConsumerState<CategorizedUploadSection> createState() =>
      _CategorizedUploadSectionState();
}

class _CategorizedUploadSectionState
    extends ConsumerState<CategorizedUploadSection> {
  List<CategorizedDocument> _passportServerDocs = [];
  final List<PickedFileData> _passportFiles = [];
  int _passportUploadedCount = 0;
  bool _uploadingPassport = false;
  List<CategorizedDocument> _gewerbescheinServerDocs = [];
  final List<PickedFileData> _gewerbescheinFiles = [];
  int _gewerbescheinUploadedCount = 0;
  bool _uploadingGewerbeschein = false;
  List<CategorizedDocument> _businessServerDocs = [];
  final List<PickedFileData> _businessLicenseFiles = [];
  int _businessUploadedCount = 0;
  bool _uploadingBusiness = false;
  bool _loadingDocs = true;
  String? _removingUrl;

  @override
  void initState() {
    super.initState();
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final repo = ref.read(accountRepositoryProvider);
      final docs = await repo.getDocuments();
      if (!mounted) return;
      setState(() {
        _passportServerDocs = docs.where((d) => d.type == DocumentType.passport.value).toList();
        _gewerbescheinServerDocs =
            docs.where((d) => d.type == DocumentType.gewerbeschein.value).toList();
        _businessServerDocs =
            docs.where((d) => d.type == DocumentType.businessLicense.value).toList();
        _loadingDocs = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingDocs = false);
      }
    }
  }

  Future<void> _removeServerDocument(DocumentType type, String url) async {
    if (!mounted) return;
    setState(() => _removingUrl = url);
    try {
      await ref.read(accountRepositoryProvider).removeDocument(url);
      if (!mounted) return;
      setState(() {
        _removingUrl = null;
        if (type == DocumentType.passport) {
          _passportServerDocs = _passportServerDocs.where((d) => d.url != url).toList();
        } else if (type == DocumentType.gewerbeschein) {
          _gewerbescheinServerDocs =
              _gewerbescheinServerDocs.where((d) => d.url != url).toList();
        } else {
          _businessServerDocs = _businessServerDocs.where((d) => d.url != url).toList();
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)?.documentRemoved ?? 'Document removed'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _removingUrl = null);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${AppLocalizations.of(context)?.uploadFailed ?? AppLocalizations.of(context)?.failed}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Pick multiple documents and upload each immediately (append, don't replace).
  Future<void> _pickAndUploadDocuments(DocumentType type) async {
    try {
      final uploadService = ref.read(uploadServiceProvider);
      final documents = await uploadService.pickMultipleDocuments(limit: 5);
      if (documents.isEmpty) return;

      final isPassport = type == DocumentType.passport;
      final isGewerbeschein = type == DocumentType.gewerbeschein;
      setState(() {
        if (isPassport) {
          _passportFiles.addAll(documents);
          _uploadingPassport = true;
        } else if (isGewerbeschein) {
          _gewerbescheinFiles.addAll(documents);
          _uploadingGewerbeschein = true;
        } else {
          _businessLicenseFiles.addAll(documents);
          _uploadingBusiness = true;
        }
      });

      final repository = ref.read(accountRepositoryProvider);
      final list = isPassport
          ? _passportFiles
          : isGewerbeschein
              ? _gewerbescheinFiles
              : _businessLicenseFiles;
      var uploadedCount = isPassport
          ? _passportUploadedCount
          : isGewerbeschein
              ? _gewerbescheinUploadedCount
              : _businessUploadedCount;
      final startIndex = list.length - documents.length;
      var successCount = 0;

      for (var i = startIndex; i < list.length; i++) {
        if (!mounted) return;
        try {
          final url = await uploadService.uploadFile(
            fileData: list[i],
            folder: 'verification-documents',
          );
          await repository.uploadCategorizedDocument(
            documentUrl: url,
            documentType: type.value,
          );
          uploadedCount = i + 1;
          successCount++;
          if (mounted) {
            setState(() {
              if (isPassport) {
                _passportUploadedCount = uploadedCount;
              } else if (isGewerbeschein) {
                _gewerbescheinUploadedCount = uploadedCount;
              } else {
                _businessUploadedCount = uploadedCount;
              }
            });
          }
        } catch (e) {
          if (mounted) {
            final l10n = AppLocalizations.of(context);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('${l10n?.uploadFailed ?? 'Upload failed'}: $e'),
                backgroundColor: Colors.red,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            );
          }
        }
      }

      if (mounted) {
        setState(() {
          if (isPassport) {
            _uploadingPassport = false;
            _passportFiles.clear();
            _passportUploadedCount = 0;
          } else if (isGewerbeschein) {
            _uploadingGewerbeschein = false;
            _gewerbescheinFiles.clear();
            _gewerbescheinUploadedCount = 0;
          } else {
            _uploadingBusiness = false;
            _businessLicenseFiles.clear();
            _businessUploadedCount = 0;
          }
        });
        if (successCount > 0) {
          _loadDocuments();
          final l10n = AppLocalizations.of(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                l10n?.documentsUploadedSuccessfully ??
                    'document(s) uploaded successfully. Our admin will review and update your account status.',
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              duration: const Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _uploadingPassport = false;
          _uploadingGewerbeschein = false;
          _uploadingBusiness = false;
        });
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${l10n?.failedToPickDocuments ?? 'Failed to pick documents'}: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  void _removeDocument(DocumentType type, int index) {
    setState(() {
      if (type == DocumentType.passport) {
        _passportFiles.removeAt(index);
        _passportUploadedCount =
            _passportUploadedCount.clamp(0, _passportFiles.length);
      } else if (type == DocumentType.gewerbeschein) {
        _gewerbescheinFiles.removeAt(index);
        _gewerbescheinUploadedCount =
            _gewerbescheinUploadedCount.clamp(0, _gewerbescheinFiles.length);
      } else {
        _businessLicenseFiles.removeAt(index);
        _businessUploadedCount =
            _businessUploadedCount.clamp(0, _businessLicenseFiles.length);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    final isWholesaler = user?.role == UserRole.wholesaler;

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
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.upload_file,
                  color: theme.colorScheme.primary,
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
          const SizedBox(height: 24),
          if (_loadingDocs)
            const Center(child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ))
          else ...[
          DocumentUploadCard(
            documentType: DocumentType.passport,
            title: l10n?.passport ?? 'Passport',
            description: l10n?.passportDescription ??
                'Upload your passport for identity verification',
            alternativeMessage: l10n?.passportAlternative ??
                'If you don\'t have a passport, you can upload a government-approved ID card with address (e.g., Aadhar in India, National ID, etc.)',
            selectedFiles: _passportFiles,
            serverDocuments: _passportServerDocs,
            uploadedCount: _passportUploadedCount,
            uploading: _uploadingPassport,
            removingUrl: _removingUrl,
            onPickDocument: () =>
                _pickAndUploadDocuments(DocumentType.passport),
            onRemoveDocument: (index) =>
                _removeDocument(DocumentType.passport, index),
            onRemoveServerDocument: (url) =>
                _removeServerDocument(DocumentType.passport, url),
          ),
          const SizedBox(height: 16),
          DocumentUploadCard(
            documentType: DocumentType.gewerbeschein,
            title: l10n?.gewerbeschein ?? 'Gewerbeschein',
            description: l10n?.gewerbescheinDescription ??
                'Upload your Gewerbeschein (Trade License) for business verification',
            alternativeMessage: l10n?.gewerbescheinAlternative ??
                'Upload your official trade license document issued by the authorities',
            selectedFiles: _gewerbescheinFiles,
            serverDocuments: _gewerbescheinServerDocs,
            uploadedCount: _gewerbescheinUploadedCount,
            uploading: _uploadingGewerbeschein,
            removingUrl: _removingUrl,
            onPickDocument: () =>
                _pickAndUploadDocuments(DocumentType.gewerbeschein),
            onRemoveDocument: (index) =>
                _removeDocument(DocumentType.gewerbeschein, index),
            onRemoveServerDocument: (url) =>
                _removeServerDocument(DocumentType.gewerbeschein, url),
          ),
          if (isWholesaler) ...[
            const SizedBox(height: 16),
            DocumentUploadCard(
              documentType: DocumentType.businessLicense,
              title:
                  l10n?.businessLicense ?? 'Business License / Gewerbeschein',
              description: l10n?.businessLicenseDescription ??
                  'Upload your business license or Gewerbeschein for business verification',
              alternativeMessage: l10n?.businessLicenseAlternative ??
                  'If you don\'t have a business license, you can upload company registration documents, tax ID, or any official business verification document',
              selectedFiles: _businessLicenseFiles,
              serverDocuments: _businessServerDocs,
              uploadedCount: _businessUploadedCount,
              uploading: _uploadingBusiness,
              removingUrl: _removingUrl,
              onPickDocument: () =>
                  _pickAndUploadDocuments(DocumentType.businessLicense),
              onRemoveDocument: (index) =>
                  _removeDocument(DocumentType.businessLicense, index),
              onRemoveServerDocument: (url) =>
                  _removeServerDocument(DocumentType.businessLicense, url),
            ),
          ],
          ],
        ],
      ),
    );
  }
}
