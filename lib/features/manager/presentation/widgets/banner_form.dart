import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/services/image_picker_helper.dart';
import '../../../../core/widgets/image_preview_widget.dart';
import '../../../admin/data/repositories/admin_repository.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/manager_repository.dart';
import '../../../dashboard/domain/models/banner_model.dart';
import '../../../dashboard/presentation/controllers/banner_controller.dart';
import '../screens/select_product_screen.dart';
import '../screens/select_deal_screen.dart';

/// Device mode for the banner preview modal (Mobile frame vs Web frame).
enum PreviewDevice { mobile, web }

final _previewDeviceProvider =
    StateProvider<PreviewDevice>((ref) => PreviewDevice.mobile);

class BannerForm extends ConsumerStatefulWidget {
  const BannerForm({
    super.key,
    this.isAdminCreate = false,
    this.initialBanner,
    this.onSaved,
    this.canEditStatus = false,
  });

  /// When true (admin creating), show "Banner submitted" vs "Banner request submitted"
  final bool isAdminCreate;
  /// When provided, form is in edit mode
  final BannerModel? initialBanner;
  /// Callback when save succeeds (for edit mode)
  final VoidCallback? onSaved;
  /// When true (admin/sub-admin), show status dropdown in edit mode
  final bool canEditStatus;

  @override
  ConsumerState<BannerForm> createState() => _BannerFormState();
}

class _BannerFormState extends ConsumerState<BannerForm> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetUrlController = TextEditingController();
  final _productDisplayController = TextEditingController();
  final _dealDisplayController = TextEditingController();

  BannerType _selectedType = BannerType.promotion;
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    final b = widget.initialBanner;
    if (b != null) {
      _titleController.text = b.title;
      _webImageUrl = b.webImageUrl ?? b.imageUrl;
      _mobileImageUrl = b.mobileImageUrl ?? b.imageUrl;
      _descriptionController.text = b.description ?? '';
      _selectedType = b.type;
      _targetUrlController.text = b.targetUrl ?? '';
      if (b.type == BannerType.product) {
        _selectedProductId = b.targetId;
        _selectedProductName = b.targetProductTitle ?? b.targetId;
        _productDisplayController.text = _selectedProductName ?? '';
      }
      if (b.type == BannerType.deal) {
        _selectedDealId = b.targetId;
        _selectedDealName = b.targetDealTitle ?? b.targetId;
        _dealDisplayController.text = _selectedDealName ?? '';
      }
      _startDate = b.startDate;
      _endDate = b.endDate;
      _selectedStatus = b.status;
    }
  }
  bool _uploadingWebImage = false;
  bool _uploadingMobileImage = false;
  bool _isSubmitting = false;
  String? _webImageUrl;
  String? _mobileImageUrl;
  PickedFileData? _selectedWebImageData;
  PickedFileData? _selectedMobileImageData;
  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedDealId;
  String? _selectedDealName;
  BannerStatus _selectedStatus = BannerStatus.pending;
  String _selectedSourceLanguage = 'en';
  bool _isGenerating = false;

  /// Build context string for AI prompt from selected product/deal/type.
  /// Includes product/deal data when selected for more realistic AI output.
  String _getBannerContextForPrompt() {
    if (_selectedType == BannerType.product &&
        _selectedProductName != null &&
        _selectedProductName!.isNotEmpty) {
      return 'Product: $_selectedProductName';
    }
    if (_selectedType == BannerType.deal &&
        _selectedDealName != null &&
        _selectedDealName!.isNotEmpty) {
      return 'Deal: $_selectedDealName';
    }
    if (_selectedType == BannerType.external) return 'External link banner';
    // Promotion: include product/deal if selected for more realistic output
    if (_selectedProductName != null && _selectedProductName!.isNotEmpty) {
      return 'Promotional banner. Product: $_selectedProductName';
    }
    if (_selectedDealName != null && _selectedDealName!.isNotEmpty) {
      return 'Promotional banner. Deal: $_selectedDealName';
    }
    return 'Promotional banner';
  }

  Future<void> _generateWithAI() async {
    final l10n = AppLocalizations.of(context);
    final contextPart = _getBannerContextForPrompt();

    final userPrompt = await showDialog<String>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(l10n?.generateWithAI ?? 'Generate with AI'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Context: $contextPart',
                style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade700,
                      fontStyle: FontStyle.italic,
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                l10n?.generateNotificationPrompt ??
                    'Add optional details (e.g. flash sale, discount) to generate title and description.',
                style: Theme.of(ctx).textTheme.bodySmall,
              ),
              if (_selectedProductId == null &&
                  _selectedDealId == null &&
                  (_selectedType == BannerType.product ||
                      _selectedType == BannerType.deal))
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Tip: Select a product or deal first for more realistic AI output.',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                          color: Theme.of(ctx).colorScheme.primary,
                          fontStyle: FontStyle.italic,
                        ),
                  ),
                ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: (_selectedProductId != null || _selectedDealId != null)
                      ? 'e.g., Flash sale this weekend'
                      : 'e.g., Flash sale. Or select product/deal above first.',
                  border: const OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(l10n?.cancel ?? 'Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.auto_awesome,
                      size: 18, color: Theme.of(ctx).colorScheme.onPrimary),
                  const SizedBox(width: 8),
                  Text(l10n?.generate ?? 'Generate'),
                ],
              ),
            ),
          ],
        );
      },
    );

    // null = user cancelled; otherwise optional extra prompt text (may be empty)
    if (userPrompt == null) return;
    final prompt =
        'Create a short promotional banner title and message (for app banner carousel) for: $contextPart. ${userPrompt.isNotEmpty ? userPrompt : ""}'
            .trim();
    if (prompt.isEmpty) return;

    if (!mounted) return;
    setState(() => _isGenerating = true);

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      final data = await adminRepo.generateNotificationContent(
        prompt,
        language: _selectedSourceLanguage,
      );
      if (!mounted) return;
      setState(() {
        _titleController.text = data['title'] ?? '';
        _descriptionController.text = data['body'] ?? '';
        _isGenerating = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGenerating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.error ?? 'Error'}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 16,
          right: 16,
          top: 16),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 900),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.initialBanner != null
                            ? 'Edit Banner'
                            : l10n.createNewBanner,
                        style: Theme.of(context)
                            .textTheme
                            .headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: _isSubmitting
                          ? null
                          : () => Navigator.pop(context),
                    ),
                  ],
                ),
              const SizedBox(height: 24),
              DropdownButtonFormField<String>(
                initialValue: _selectedSourceLanguage,
                decoration: InputDecoration(
                  labelText: l10n.sourceLanguageLabel,
                  helperText: l10n.sourceLanguageHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: AppLanguages.contentSourceLanguages
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(AppLanguages.contentLanguageNames[code] ?? code),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedSourceLanguage = v);
                },
              ),
              const SizedBox(height: 20),
              // Title Field
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.bannerTitle,
                  hintText: l10n.enterBannerTitle,
                  prefixIcon: const Icon(Icons.title),
                  suffixIcon: IconButton(
                    icon: _isGenerating
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome, color: Colors.amber),
                    tooltip: AppLocalizations.of(context)?.generateWithAI ??
                        'Generate with AI',
                    onPressed: _isGenerating ? null : _generateWithAI,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (v) => v?.isEmpty == true ? l10n.required : null,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),

              // Web Image (upload only) — 16:9 desktop banner
              FormField<String>(
                validator: (_) => null,
                builder: (formState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.web, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.webBannerImage,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            if (l10n.webBannerImageHint.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  l10n.webBannerImageHint,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            _ImageUploadZone(
                              aspectRatio: 21 / 9,
                              imageUrl: _webImageUrl,
                              imageData: _selectedWebImageData,
                              uploading: _uploadingWebImage,
                              onTap: _pickAndUploadWebImage,
                              errorMessage: l10n.invalidImageUrl,
                              emptyStateLabel: l10n.tapToUploadWebImage,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Mobile Image (upload only, required) — 16:9 wide banner (top of phone)
              FormField<String>(
                validator: (_) {
                  final hasMobile =
                      _selectedMobileImageData != null ||
                      (_mobileImageUrl != null && _mobileImageUrl!.isNotEmpty);
                  if (!hasMobile) return l10n.pleaseTapChooseImage;
                  return null;
                },
                builder: (formState) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: formState.hasError
                            ? BorderSide(
                                color: Theme.of(context).colorScheme.error,
                                width: 2,
                              )
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.smartphone,
                                    color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  l10n.mobileBannerImage,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ],
                            ),
                            if (l10n.mobileBannerImageHint.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  l10n.mobileBannerImageHint,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: Colors.grey.shade600,
                                      ),
                                ),
                              ),
                            const SizedBox(height: 12),
                            _ImageUploadZone(
                              aspectRatio: 16 / 9,
                              imageUrl: _mobileImageUrl,
                              imageData: _selectedMobileImageData,
                              uploading: _uploadingMobileImage,
                              onTap: _pickAndUploadMobileImage,
                              errorMessage: l10n.invalidImageUrl,
                              emptyStateLabel: l10n.tapToUploadMobileImage,
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (formState.hasError) ...[
                      const SizedBox(height: 8),
                      Text(
                        formState.errorText!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Description Field
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n?.descriptionOptional,
                  hintText: l10n?.enterBannerDescription,
                  prefixIcon: const Icon(Icons.description),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                maxLines: 3,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              // Banner Type
              DropdownButtonFormField<BannerType>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  labelText: l10n?.bannerType,
                  prefixIcon: const Icon(Icons.category),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                items: BannerType.values
                    .map((e) => DropdownMenuItem(
                          value: e,
                          child: Text(e.name.toUpperCase()),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _selectedType = v!;
                    // Clear product/deal when switching to non-product/deal types
                    if (v != BannerType.product) {
                      _selectedProductId = null;
                      _selectedProductName = null;
                      _productDisplayController.clear();
                    }
                    if (v != BannerType.deal) {
                      _selectedDealId = null;
                      _selectedDealName = null;
                      _dealDisplayController.clear();
                    }
                  });
                },
              ),
              const SizedBox(height: 20),
              if (_selectedType == BannerType.external) ...[
                TextFormField(
                  controller: _targetUrlController,
                  decoration: InputDecoration(labelText: l10n?.targetUrl),
                  validator: (v) => v?.isEmpty == true ? l10n.required : null,
                ),
                const SizedBox(height: 20),
              ],
              if (_selectedType == BannerType.product) ...[
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n?.selectProduct,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    helperText: 'Tap to select a product',
                  ),
                  controller: _productDisplayController,
                  onTap: () async {
                    final selectedId = await context.push<String>(
                      SelectProductScreen.routePath,
                      extra: {
                        'selectedProductId': _selectedProductId,
                      },
                    );
                    if (selectedId != null && mounted) {
                      // Fetch product name from repository
                      try {
                        final repo = ref.read(managerRepositoryProvider);
                        final productDetail =
                            await repo.fetchProductDetail(selectedId);
                        setState(() {
                          _selectedProductId = selectedId;
                          _selectedProductName =
                              productDetail['title'] as String? ??
                                  'Unknown Product';
                          _productDisplayController.text =
                              _selectedProductName ?? '';
                        });
                      } catch (e) {
                        // If fetch fails, just use the ID
                        setState(() {
                          _selectedProductId = selectedId;
                          _selectedProductName = 'Product $selectedId';
                          _productDisplayController.text =
                              _selectedProductName ?? '';
                        });
                      }
                    }
                  },
                  validator: (value) {
                    if (_selectedProductId == null) {
                      return 'Please select a product';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              if (_selectedType == BannerType.deal) ...[
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n?.selectDeal,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    helperText: 'Tap to select a deal',
                  ),
                  controller: _dealDisplayController,
                  onTap: () async {
                    final selectedId = await context.push<String>(
                      SelectDealScreen.routePath,
                      extra: {
                        'selectedDealId': _selectedDealId,
                      },
                    );
                    if (selectedId != null && mounted) {
                      // Fetch deal name from repository
                      try {
                        final repo = ref.read(managerRepositoryProvider);
                        final dealsPage =
                            await repo.fetchDeals(page: 1, limit: 1000);
                        final deal = dealsPage.items.firstWhere(
                          (d) => d.id == selectedId,
                          orElse: () => dealsPage.items.first,
                        );
                        setState(() {
                          _selectedDealId = selectedId;
                          _selectedDealName = deal.title;
                          _dealDisplayController.text =
                              _selectedDealName ?? '';
                        });
                      } catch (e) {
                        // If fetch fails, just use the ID
                        setState(() {
                          _selectedDealId = selectedId;
                          _selectedDealName = 'Deal $selectedId';
                          _dealDisplayController.text =
                              _selectedDealName ?? '';
                        });
                      }
                    }
                  },
                  validator: (value) {
                    if (_selectedDealId == null) {
                      return 'Please select a deal';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Status dropdown (admin/sub-admin in edit mode)
              if (widget.canEditStatus && widget.initialBanner != null) ...[
                DropdownButtonFormField<BannerStatus>(
                  // ignore: deprecated_member_use - value needed for controlled dropdown
                  value: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n?.status,
                    prefixIcon: const Icon(Icons.flag),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                  ),
                  items: BannerStatus.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.name.toUpperCase()),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedStatus = v);
                  },
                ),
                const SizedBox(height: 20),
              ],

              // Date Selection
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _startDate = picked);
                        }
                      },
                      icon: const Icon(Icons.calendar_today),
                      label: Text(
                        _startDate == null
                            ? 'Start Date'
                            : DateFormat('MM/dd/yyyy').format(_startDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          firstDate: _startDate ?? DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _endDate = picked);
                        }
                      },
                      icon: const Icon(Icons.event),
                      label: Text(
                        _endDate == null
                            ? 'End Date'
                            : DateFormat('MM/dd/yyyy').format(_endDate!),
                      ),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Preview Mobile + Submit
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _showPreviewModal(context),
                    icon: const Icon(Icons.visibility_outlined),
                    label: Text(l10n.preview),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            )
                          : Text(
                              widget.initialBanner != null
                                  ? l10n.saveChanges
                                  : 'Create Banner',
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    ),
    );
  }

  void _showPreviewModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _BannerPreviewDialog(
        title: _titleController.text,
        description: _descriptionController.text,
        webImageUrl: _webImageUrl,
        webImageData: _selectedWebImageData,
        mobileImageUrl: _mobileImageUrl,
        mobileImageData: _selectedMobileImageData,
      ),
    );
  }

  Future<void> _pickAndUploadWebImage() async {
    try {
      setState(() => _uploadingWebImage = true);
      final uploadService = ref.read(uploadServiceProvider);
      final imageData = await ImagePickerHelper.pickImage();
      if (imageData == null) {
        setState(() => _uploadingWebImage = false);
        return;
      }
      setState(() => _selectedWebImageData = imageData);
      final url = await uploadService.uploadFile(
        fileData: imageData,
        folder: 'banners',
      );
      setState(() {
        _webImageUrl = url;
        _uploadingWebImage = false;
      });
    } catch (e) {
      setState(() => _uploadingWebImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.uploadFailed ?? 'Upload failed'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAndUploadMobileImage() async {
    try {
      setState(() => _uploadingMobileImage = true);
      final uploadService = ref.read(uploadServiceProvider);
      final imageData = await ImagePickerHelper.pickImage();
      if (imageData == null) {
        setState(() => _uploadingMobileImage = false);
        return;
      }
      setState(() => _selectedMobileImageData = imageData);
      final url = await uploadService.uploadFile(
        fileData: imageData,
        folder: 'banners',
      );
      setState(() {
        _mobileImageUrl = url;
        _uploadingMobileImage = false;
      });
    } catch (e) {
      setState(() => _uploadingMobileImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.uploadFailed ?? 'Upload failed'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate() && !_isSubmitting) {
      setState(() {
        _isSubmitting = true;
      });

      try {
        final titleMap = <String, String>{
          _selectedSourceLanguage: _titleController.text.trim(),
        };

        final descriptionMap = _descriptionController.text.trim().isNotEmpty
            ? <String, String>{
                _selectedSourceLanguage: _descriptionController.text.trim(),
              }
            : null;

        final data = {
          'title': titleMap,
          'language': _selectedSourceLanguage,
          if (_webImageUrl != null && _webImageUrl!.isNotEmpty) 'webImageUrl': _webImageUrl,
          if (_mobileImageUrl != null && _mobileImageUrl!.isNotEmpty) 'mobileImageUrl': _mobileImageUrl,
          if (descriptionMap != null) 'description': descriptionMap,
          'type': _selectedType.name,
          'targetId': _selectedType == BannerType.product
              ? _selectedProductId
              : _selectedType == BannerType.deal
                  ? _selectedDealId
                  : null,
          'targetUrl': _targetUrlController.text.isNotEmpty
              ? _targetUrlController.text
              : null,
          'startDate': _startDate?.toIso8601String(),
          'endDate': _endDate?.toIso8601String(),
          if (widget.canEditStatus && widget.initialBanner != null)
            'status': _selectedStatus.name,
        };

        final isEdit = widget.initialBanner != null;
        final l10n = AppLocalizations.of(context)!;

        if (isEdit) {
          final updated = await ref
              .read(bannerActionsControllerProvider.notifier)
              .updateBanner(widget.initialBanner!.id, data);

          if (mounted) {
            setState(() => _isSubmitting = false);
            if (updated != null) {
              widget.onSaved?.call();
              ref.invalidate(manageBannersProvider);
              Navigator.pop(context);
              final isWholesaler = ref.read(authControllerProvider).valueOrNull
                      ?.user.role ==
                  UserRole.wholesaler;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    isWholesaler
                        ? l10n.translate('bannerEditSubmittedForApproval')
                        : l10n.translate('bannerUpdated'),
                  ),
                ),
              );
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(l10n.translate('failedToUpdateBanner')),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        } else {
          final success = await ref
              .read(bannerActionsControllerProvider.notifier)
              .createBanner(data);

          if (mounted) {
            if (success) {
              ref.invalidate(manageBannersProvider);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.isAdminCreate
                        ? l10n.translate('bannerSubmittedSuccessfully')
                        : l10n.translate('bannerRequestSubmitted'),
                  ),
                ),
              );
            } else {
              setState(() => _isSubmitting = false);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    widget.isAdminCreate
                        ? l10n.translate('failedToCreateBanner')
                        : l10n.translate('failedToSubmitBannerRequest'),
                  ),
                  backgroundColor: Theme.of(context).colorScheme.error,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${AppLocalizations.of(context)!.error}: ${e.toString()}',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _targetUrlController.dispose();
    _productDisplayController.dispose();
    _dealDisplayController.dispose();
    super.dispose();
  }
}

/// Reusable upload zone: empty state (dashed-style dropzone) or filled state
/// (image with "Replace Image" overlay). Uses AspectRatio for correct proportions.
class _ImageUploadZone extends StatelessWidget {
  const _ImageUploadZone({
    required this.aspectRatio,
    this.imageUrl,
    this.imageData,
    required this.uploading,
    required this.onTap,
    this.errorMessage,
    required this.emptyStateLabel,
  });

  final double aspectRatio;
  final String? imageUrl;
  final PickedFileData? imageData;
  final bool uploading;
  final VoidCallback onTap;
  final String? errorMessage;
  /// Short label for empty state, e.g. "Tap to upload Web Image".
  final String emptyStateLabel;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasImage = imageData != null ||
        (imageUrl != null && imageUrl!.isNotEmpty);
    final content = hasImage
        ? _buildFilledZone(context, l10n)
        : _buildEmptyZone(context, l10n);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: content,
    );
  }

  Widget _buildEmptyZone(BuildContext context, AppLocalizations l10n) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: uploading ? null : onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.shade400,
              width: 2,
              strokeAlign: BorderSide.strokeAlignInside,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
            child: uploading
                ? Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 40,
                        color: Colors.grey.shade600,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        emptyStateLabel,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey.shade700,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildFilledZone(BuildContext context, AppLocalizations l10n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _buildImage(context),
          Positioned(
            bottom: 8,
            right: 8,
            child: Material(
              color: Colors.black54,
              borderRadius: BorderRadius.circular(8),
              child: InkWell(
                onTap: uploading ? null : onTap,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.refresh, size: 18, color: Colors.white),
                      const SizedBox(width: 6),
                      Text(
                        l10n.replaceImage,
                        style: TextStyle(color: Colors.white, fontSize: 12),
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

  Widget _buildImage(BuildContext context) {
    if (imageData != null) {
      return ImagePreviewWidget(
        fileData: imageData!,
        fit: BoxFit.cover,
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        errorWidget: (_, __, ___) => _errorPlaceholder(context),
      );
    }
    return _errorPlaceholder(context);
  }

  Widget _errorPlaceholder(BuildContext context) {
    return Container(
      color: Colors.grey.shade200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey.shade600),
            if (errorMessage != null) ...[
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Dialog that shows Mobile/Web preview with device toggle. Uses Riverpod for
/// device state; preview content matches the home page banner carousel.
class _BannerPreviewDialog extends ConsumerStatefulWidget {
  const _BannerPreviewDialog({
    required this.title,
    required this.description,
    this.webImageUrl,
    this.webImageData,
    this.mobileImageUrl,
    this.mobileImageData,
  });

  final String title;
  final String description;
  final String? webImageUrl;
  final PickedFileData? webImageData;
  final String? mobileImageUrl;
  final PickedFileData? mobileImageData;

  @override
  ConsumerState<_BannerPreviewDialog> createState() =>
      _BannerPreviewDialogState();
}

class _BannerPreviewDialogState extends ConsumerState<_BannerPreviewDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(_previewDeviceProvider.notifier).state = PreviewDevice.mobile;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final device = ref.watch(_previewDeviceProvider);
    final isMobile = device == PreviewDevice.mobile;
    final imageUrl = isMobile ? widget.mobileImageUrl : widget.webImageUrl;
    final imageData = isMobile ? widget.mobileImageData : widget.webImageData;

    return AlertDialog(
      title: Text(l10n.mobilePreview),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Device toggle
            SegmentedButton<PreviewDevice>(
              segments: [
                ButtonSegment<PreviewDevice>(
                  value: PreviewDevice.mobile,
                  icon: const Icon(Icons.smartphone),
                  label: Text(l10n.platformMobile),
                ),
                ButtonSegment<PreviewDevice>(
                  value: PreviewDevice.web,
                  icon: const Icon(Icons.web),
                  label: Text(l10n.platformWeb),
                ),
              ],
              selected: {device},
              onSelectionChanged: (Set<PreviewDevice> selected) {
                if (selected.isEmpty) return;
                ref.read(_previewDeviceProvider.notifier).state =
                    selected.first;
                setState(() {});
              },
            ),
            const SizedBox(height: 20),
            // Frame: mobile ~375px or web ~1000px
            Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: isMobile ? 375 : 1000,
                ),
                child: _BannerPreviewContent(
                  isMobilePreview: isMobile,
                  title: widget.title,
                  description: widget.description,
                  imageUrl: imageUrl,
                  imageData: imageData,
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.close),
        ),
      ],
    );
  }
}

/// Banner preview content matching the home page carousel: same borderRadius,
/// gradient overlay, title/description styling, and 16:9 image area.
class _BannerPreviewContent extends StatelessWidget {
  const _BannerPreviewContent({
    required this.isMobilePreview,
    required this.title,
    required this.description,
    this.imageUrl,
    this.imageData,
  });

  final bool isMobilePreview;
  final String title;
  final String description;
  final String? imageUrl;
  final PickedFileData? imageData;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final aspectRatio = isMobilePreview ? 1.0 : (16 / 9);

    return AspectRatio(
      aspectRatio: aspectRatio,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: _PreviewBannerImage(
                imageUrl: imageUrl,
                imageData: imageData,
                placeholderBuilder: () => _imagePlaceholder(context, l10n),
              ),
            ),
            // Gradient overlay (same as banner_carousel)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.0),
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Title and description (same styles as banner_carousel)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Align(
                alignment: Alignment.bottomLeft,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isEmpty ? l10n.enterBannerTitle : title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 13.0,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(BuildContext context, AppLocalizations l10n) {
    return Container(
      color: Colors.grey.shade300,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_not_supported_outlined,
                size: 48, color: Colors.grey.shade600),
            const SizedBox(height: 8),
            Text(
              l10n.previewWillAppearHere,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders banner image from network URL or local file with error handling.
class _PreviewBannerImage extends StatelessWidget {
  const _PreviewBannerImage({
    this.imageUrl,
    this.imageData,
    required this.placeholderBuilder,
  });

  final String? imageUrl;
  final PickedFileData? imageData;
  final Widget Function() placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    if (imageData != null) {
      return _LocalPreviewImage(
        fileData: imageData!,
        placeholderBuilder: placeholderBuilder,
      );
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: imageUrl!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorWidget: (_, __, ___) => placeholderBuilder(),
      );
    }
    return placeholderBuilder();
  }
}

/// Local file/bytes image with errorBuilder.
class _LocalPreviewImage extends StatelessWidget {
  const _LocalPreviewImage({
    required this.fileData,
    required this.placeholderBuilder,
  });

  final PickedFileData fileData;
  final Widget Function() placeholderBuilder;

  @override
  Widget build(BuildContext context) {
    if (fileData.bytes != null) {
      return Image.memory(
        Uint8List.fromList(fileData.bytes!),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => placeholderBuilder(),
      );
    }
    if (!kIsWeb) {
      try {
        final file = fileData.fileAsFile;
        return Image.file(
          file,
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, __, ___) => placeholderBuilder(),
        );
      } catch (_) {
        return placeholderBuilder();
      }
    }
    return placeholderBuilder();
  }
}
