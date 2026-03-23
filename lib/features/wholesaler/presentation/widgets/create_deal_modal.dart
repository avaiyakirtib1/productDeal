import 'dart:typed_data';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../manager/data/providers/manager_data_providers.dart'
    as manager_providers;
import '../../../manager/data/repositories/manager_repository.dart';
import '../../../manager/presentation/screens/select_product_screen.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../core/services/deal_image_preprocess.dart';
import '../../../../core/services/image_picker_helper.dart';
import '../../../../core/services/upload_io.dart'
    if (dart.library.html) '../../../../core/services/upload_io_stub.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/widgets/image_preview_widget.dart';
import '../../data/payment_email_defaults.dart';
import '../../../../shared/widgets/payment_mode_selector.dart';

class CreateDealData {
  CreateDealData({
    required this.title,
    required this.productId,
    required this.wholesalerId,
    required this.type,
    required this.startAt,
    required this.endAt,
    required this.dealPrice,
    required this.targetQuantity,
    required this.minOrderQuantity,
    this.description,
    this.variantId,
    this.status = 'draft',
    this.originalPrice,
    this.highlighted = false,
    this.imageUrl,
    this.images = const [],
    this.shippingBaseCost,
    this.shippingFreeThreshold,
    this.shippingPerUnitCost,
    this.allowedPaymentMethods,
    this.paymentIban,
    this.paymentBankAccountOwner,
    this.paymentReferenceTemplate,
    this.paymentInstructions,
    this.paymentEmailSubjectTemplate,
    this.paymentEmailBodyTemplate,
    this.allowOnlinePayment = true,
    this.language = 'en',
    this.end24hNotificationBodyTemplate,
    this.end7dNotificationBodyTemplate,
  });

  final dynamic title; // String or Map<String, String>
  final dynamic description; // String or Map<String, String>
  final String productId;
  final String? variantId;
  final String wholesalerId;
  final String type;
  final String status;
  final String startAt;
  final String endAt;
  final double dealPrice;
  final double? originalPrice;
  final int targetQuantity;
  final int minOrderQuantity;
  final bool highlighted;
  final String? imageUrl;
  final List<String> images;
  final double? shippingBaseCost;
  final int? shippingFreeThreshold;
  final double? shippingPerUnitCost;
  final List<String>? allowedPaymentMethods;
  final String? paymentIban;
  final String? paymentBankAccountOwner;
  final String? paymentReferenceTemplate;
  final String? paymentInstructions;
  final String? paymentEmailSubjectTemplate;
  final String? paymentEmailBodyTemplate;
  final bool allowOnlinePayment;
  final String language;
  final String? end24hNotificationBodyTemplate;
  final String? end7dNotificationBodyTemplate;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'wholesalerId': wholesalerId,
      'type': type,
      'status': status,
      'startAt': startAt,
      'endAt': endAt,
      'dealPrice': dealPrice,
      'targetQuantity': targetQuantity,
      'minOrderQuantity': minOrderQuantity,
      'highlighted': highlighted,
    };

    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }
    if (variantId != null && variantId!.isNotEmpty) {
      json['variantId'] = variantId;
    } else {
      json['productId'] = productId;
    }
    if (originalPrice != null) {
      json['originalPrice'] = originalPrice;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      json['imageUrl'] = imageUrl;
    }
    if (images.isNotEmpty) {
      json['images'] = images;
    }
    if (shippingBaseCost != null) {
      json['shippingBaseCost'] = shippingBaseCost;
    }
    if (shippingFreeThreshold != null) {
      json['shippingFreeThreshold'] = shippingFreeThreshold;
    }
    if (shippingPerUnitCost != null) {
      json['shippingPerUnitCost'] = shippingPerUnitCost;
    }
    if (allowedPaymentMethods != null && allowedPaymentMethods!.isNotEmpty) {
      json['allowedPaymentMethods'] = allowedPaymentMethods;
    }
    if (paymentIban != null && paymentIban!.isNotEmpty) {
      json['paymentIban'] = paymentIban;
    }
    if (paymentBankAccountOwner != null && paymentBankAccountOwner!.isNotEmpty) {
      json['paymentBankAccountOwner'] = paymentBankAccountOwner;
    }
    if (paymentReferenceTemplate != null && paymentReferenceTemplate!.isNotEmpty) {
      json['paymentReferenceTemplate'] = paymentReferenceTemplate;
    }
    if (paymentInstructions != null && paymentInstructions!.isNotEmpty) {
      json['paymentInstructions'] = paymentInstructions;
    }
    if (paymentEmailSubjectTemplate != null && paymentEmailSubjectTemplate!.isNotEmpty) {
      json['paymentEmailSubjectTemplate'] = paymentEmailSubjectTemplate;
    }
    if (paymentEmailBodyTemplate != null && paymentEmailBodyTemplate!.isNotEmpty) {
      json['paymentEmailBodyTemplate'] = paymentEmailBodyTemplate;
    }
    if (end24hNotificationBodyTemplate != null &&
        end24hNotificationBodyTemplate!.trim().isNotEmpty) {
      json['end24hNotificationBodyTemplate'] =
          end24hNotificationBodyTemplate!.trim();
    }
    if (end7dNotificationBodyTemplate != null &&
        end7dNotificationBodyTemplate!.trim().isNotEmpty) {
      json['end7dNotificationBodyTemplate'] =
          end7dNotificationBodyTemplate!.trim();
    }
    json['allowOnlinePayment'] = allowOnlinePayment;
    json['language'] = language;

    return json;
  }
}

class CreateDealModal extends ConsumerStatefulWidget {
  const CreateDealModal({
    super.key,
    required this.onSave,
    this.currentUserId,
    this.wholesalers = const [],
    this.initialUser,
  });

  final Future<void> Function(CreateDealData) onSave;
  final String? currentUserId;
  final List<Map<String, String>> wholesalers; // For admin to select wholesaler
  /// Current user for default payment mode and pre-fill (from profile)
  final UserModel? initialUser;

  @override
  ConsumerState<CreateDealModal> createState() => _CreateDealModalState();
}

class _CreateDealModalState extends ConsumerState<CreateDealModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dealPriceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _targetQuantityController = TextEditingController(text: '100');
  final _minOrderQuantityController = TextEditingController(text: '1');
  final _imageUrlController = TextEditingController();
  final _shippingBaseCostController = TextEditingController();
  final _shippingFreeThresholdController = TextEditingController();
  final _shippingPerUnitCostController = TextEditingController();
  final _paymentIbanController = TextEditingController();
  final _paymentBankAccountOwnerController = TextEditingController();
  final _paymentReferenceTemplateController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();
  final _paymentEmailSubjectController = TextEditingController();
  final _paymentEmailBodyController = TextEditingController();
  final _end24hNotificationController = TextEditingController();
  final _end7dNotificationController = TextEditingController();

  // Removed wholesaler selection - admins create deals on their own products
  String? _selectedProductId;
  String? _selectedProductName; // Store name for display
  String? _selectedVariantId;
  String _selectedType = 'auction';
  String _selectedStatus = 'draft';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _highlighted = false;
  bool _isLoading = false;
  String? _error;
  bool _productHasVariants = false; // Track if selected product has variants
  bool _loadingProductDetail = false; // Track product detail loading
  // ignore: unused_field - reserved for price auto-fill
  Map<String, dynamic>? _selectedProductData;
  // ignore: unused_field - reserved for price auto-fill
  Map<String, dynamic>? _selectedVariantData;
  PickedFileData? _selectedImage;
  bool _uploadingImage = false;
  bool _generatingPaymentEmail = false;
  /// Allowed payment methods for this deal.
  List<String> _allowedPaymentMethods = ['cash_on_delivery'];
  bool _paymentInitFromUser = false;

  String _selectedSourceLanguage = 'en';
  final Map<String, String> _titleMap = {};
  final Map<String, String> _descriptionMap = {};

  @override
  void initState() {
    super.initState();
    // Admin creates deals on their own products (use currentUserId)
    // No wholesaler selection needed

    // Initialize multilingual maps with selected source language
    _titleMap[_selectedSourceLanguage] = '';
    _descriptionMap[_selectedSourceLanguage] = '';

    // Initialize default notification templates so admin sees current defaults
    if (_end24hNotificationController.text.trim().isEmpty) {
      _end24hNotificationController.text =
          'Last 24 hours! "{dealTitle}" – only {remainingQuantity} orders left to close this deal.';
    }
    if (_end7dNotificationController.text.trim().isEmpty) {
      _end7dNotificationController.text =
          '"{dealTitle}" – only {remainingQuantity} orders left to close this deal.';
    }

    // Listeners to update the map as user types
    _titleController.addListener(() {
      _titleMap[_selectedSourceLanguage] = _titleController.text;
    });
    _descriptionController.addListener(() {
      _descriptionMap[_selectedSourceLanguage] = _descriptionController.text;
    });
  }

  bool get _needsPaymentFields =>
      _allowedPaymentMethods.contains('invoice') ||
      _allowedPaymentMethods.contains('bank_transfer');

  void _initFromUser(UserModel? user) {
    if (user == null || _paymentInitFromUser) return;
    _paymentInitFromUser = true;
    final modes = user.defaultPaymentModes != null &&
            user.defaultPaymentModes!.isNotEmpty
        ? List<String>.from(user.defaultPaymentModes!)
        : <String>[
            user.defaultPaymentMode ??
                ((user.effectiveIban ?? '').trim().isNotEmpty ||
                        (user.effectiveAccountHolder ?? '').trim().isNotEmpty
                    ? 'bank_transfer'
                    : 'cash_on_delivery')
          ];
    _allowedPaymentMethods = modes;
    if (_needsPaymentFields) {
      if ((user.effectiveIban ?? '').trim().isNotEmpty) {
        _paymentIbanController.text = user.effectiveIban ?? '';
      }
      if ((user.effectiveAccountHolder ?? '').trim().isNotEmpty) {
        _paymentBankAccountOwnerController.text = user.effectiveAccountHolder ?? '';
      }
      final inst = user.paymentConfig?.paymentInstructions ?? user.paymentInstructions ?? '';
      if (inst.isNotEmpty) _paymentInstructionsController.text = inst;
      final ref = user.paymentConfig?.paymentReferenceTemplate ?? user.paymentReferenceTemplate ?? '';
      if (ref.isNotEmpty) _paymentReferenceTemplateController.text = ref;
      // Prefill email subject/body from user or use defaults (so user sees how emails are sent)
      if (_paymentEmailSubjectController.text.trim().isEmpty) {
        _paymentEmailSubjectController.text = user.paymentEmailSubjectTemplate ??
            user.paymentConfig?.paymentEmailSubjectTemplate ??
            defaultPaymentEmailSubject;
      }
      if (_paymentEmailBodyController.text.trim().isEmpty) {
        _paymentEmailBodyController.text = user.paymentEmailBodyTemplate ??
            user.paymentConfig?.paymentEmailBodyTemplate ??
            defaultPaymentEmailBody;
      }
    }
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dealPriceController.dispose();
    _originalPriceController.dispose();
    _targetQuantityController.dispose();
    _minOrderQuantityController.dispose();
    _imageUrlController.dispose();
    _shippingBaseCostController.dispose();
    _shippingFreeThresholdController.dispose();
    _shippingPerUnitCostController.dispose();
    _paymentIbanController.dispose();
    _paymentBankAccountOwnerController.dispose();
    _paymentReferenceTemplateController.dispose();
    _paymentInstructionsController.dispose();
    _paymentEmailSubjectController.dispose();
    _paymentEmailBodyController.dispose();
    _end24hNotificationController.dispose();
    _end7dNotificationController.dispose();
    super.dispose();
  }

  Future<void> _generatePaymentEmailWithAI() async {
    final l10n = AppLocalizations.of(context)!;
    setState(() => _generatingPaymentEmail = true);
    try {
      final repo = ref.read(managerRepositoryProvider);
      final dealTitle = _titleController.text.trim().isEmpty ? null : _titleController.text.trim();
      final result = await repo.generateDealPaymentEmail(
        dealTitle: dealTitle,
        dealType: _selectedType,
      );
      final subject = result['subject']?.toString();
      final body = result['body']?.toString();
      if (subject != null || body != null) {
        setState(() {
          if (subject != null) _paymentEmailSubjectController.text = subject;
          if (body != null) _paymentEmailBodyController.text = body;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
            content: Text(l10n.paymentEmailTemplateGenerated),
          ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.aiGenerationFailed ?? 'AI generation failed'}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _generatingPaymentEmail = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      setState(() => _uploadingImage = true);
      final uploadService = ref.read(uploadServiceProvider);
      final imageData = await ImagePickerHelper.pickImage(
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );
      if (imageData == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      setState(() => _selectedImage = imageData);

      final Uint8List rawBytes;
      if (imageData.isWeb) {
        rawBytes = Uint8List.fromList(imageData.bytes!);
      } else {
        rawBytes = await readUploadBytesFromIoFile(imageData.fileAsFile);
      }

      final processed = await compute(preprocessDealImageForUpload, rawBytes);
      final baseName =
          imageData.filename.replaceAll(RegExp(r'\.[^.]+$'), '');
      final outName = '${baseName.isEmpty ? 'deal' : baseName}.jpg';
      final uploadPayload = PickedFileData(
        bytes: processed,
        filename: outName,
      );

      final url = await uploadService.uploadFile(
        fileData: uploadPayload,
        folder: 'deals',
      );

      setState(() {
        _imageUrlController.text = url;
        _uploadingImage = false;
      });
    } catch (e) {
      setState(() => _uploadingImage = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(
            '${AppLocalizations.of(context)?.uploadFailed ?? 'Upload failed'}: $e',
          ),
        ),
        );
      }
    }
  }

  void _loadVariants(String productId) {
    // Variants will be loaded via provider when product is selected
    setState(() {
      _selectedVariantId = null;
    });
  }

  Future<void> _generateWithAI() async {
    final l10n = AppLocalizations.of(context)!;
    String? prompt;

    await showDialog(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(l10n.generateWithAI),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterDealDescriptionPrompt),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: l10n.dealDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 16),
                  const SizedBox(width: 8),
                  Text(l10n.generate),
                ],
              ),
            ),
          ],
        );
      },
    ).then((value) => prompt = value);

    if (prompt == null || prompt!.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(managerRepositoryProvider);
      final data = await repo.generateDealContent(
        prompt!,
        language: _selectedSourceLanguage,
        productId: _selectedProductId,
        variantId: _selectedVariantId,
      );

      if (!mounted) return;

      setState(() {
        if (data['title'] != null) {
          _titleMap[_selectedSourceLanguage] = data['title'].toString();
          _titleController.text = data['title'].toString();
        }
        if (data['description'] != null) {
          _descriptionMap[_selectedSourceLanguage] = data['description'].toString();
          _descriptionController.text = data['description'].toString();
        }
        if (data['dealPrice'] != null) {
          _dealPriceController.text = data['dealPrice'].toString();
        }
        if (data['targetQuantity'] != null) {
          _targetQuantityController.text = data['targetQuantity'].toString();
        }
        if (data['minOrderQuantity'] != null) {
          _minOrderQuantityController.text =
              data['minOrderQuantity'].toString();
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(l10n
                .dealCreatedSuccessfully)), // Reusing success message or generic "Content generated"
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.generationFailed ?? 'Generation failed'}: $e',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Format DateTime to ISO 8601 format
  /// Backend expects: YYYY-MM-DDTHH:mm (without seconds) or full ISO with timezone
  /// Using YYYY-MM-DDTHH:mm format to match backend regex validation
  String _formatDateTime(DateTime dateTime) {
    // Convert to UTC before formatting to ensure consistent storage
    final utcDateTime = dateTime.toUtc();
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(utcDateTime);
  }

  Future<void> _handleSubmit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    // Admin creates deals on their own products (use currentUserId)
    final wholesalerId = widget.currentUserId;
    if (wholesalerId == null || wholesalerId.isEmpty) {
      setState(() => _error = l10n.userIdRequired);
      return;
    }

    if (_selectedProductId == null) {
      setState(() => _error = l10n.pleaseSelectProduct);
      return;
    }

    // Validate variant selection if product has variants
    if (_productHasVariants &&
        (_selectedVariantId == null || _selectedVariantId!.isEmpty)) {
      setState(() => _error = l10n.selectVariantHelper);
      return;
    }

    if (_endDate.isBefore(_startDate) ||
        _endDate.isAtSameMomentAs(_startDate)) {
      setState(() => _error = l10n.endDateMustBeAfterStartDate);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });
    // Let the frame paint loading/disabled submit before heavy work + network.
    await Future<void>.delayed(Duration.zero);

    try {
      final images = _imageUrlController.text.trim().isNotEmpty
          ? [_imageUrlController.text.trim()]
          : <String>[];

      final data = CreateDealData(
        title: _titleMap,
        description: _descriptionMap.isNotEmpty ? _descriptionMap : null,
        language: _selectedSourceLanguage,
        productId: _selectedProductId!,
        variantId: _selectedVariantId,
        wholesalerId: widget.currentUserId ?? '',
        type: _selectedType,
        status: _selectedStatus,
        startAt: _formatDateTime(_startDate),
        endAt: _formatDateTime(_endDate),
        dealPrice: double.tryParse(_dealPriceController.text) ?? 0,
        originalPrice: _originalPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_originalPriceController.text),
        targetQuantity: int.tryParse(_targetQuantityController.text) ?? 100,
        minOrderQuantity: int.tryParse(_minOrderQuantityController.text) ?? 1,
        highlighted: _highlighted,
        imageUrl: _imageUrlController.text.trim().isEmpty
            ? null
            : _imageUrlController.text.trim(),
        images: images,
        shippingBaseCost: _shippingBaseCostController.text.trim().isEmpty
            ? null
            : double.tryParse(_shippingBaseCostController.text),
        shippingFreeThreshold:
            _shippingFreeThresholdController.text.trim().isEmpty
                ? null
                : int.tryParse(_shippingFreeThresholdController.text),
        shippingPerUnitCost: _shippingPerUnitCostController.text.trim().isEmpty
            ? null
            : double.tryParse(_shippingPerUnitCostController.text),
        allowedPaymentMethods: _allowedPaymentMethods,
        paymentIban: _needsPaymentFields &&
                _paymentIbanController.text.trim().isNotEmpty
            ? _paymentIbanController.text.trim()
            : null,
        paymentBankAccountOwner: _needsPaymentFields &&
                _paymentBankAccountOwnerController.text.trim().isNotEmpty
            ? _paymentBankAccountOwnerController.text.trim()
            : null,
        paymentReferenceTemplate: _needsPaymentFields &&
                _paymentReferenceTemplateController.text.trim().isNotEmpty
            ? _paymentReferenceTemplateController.text.trim()
            : null,
        paymentInstructions: _needsPaymentFields &&
                _paymentInstructionsController.text.trim().isNotEmpty
            ? _paymentInstructionsController.text.trim()
            : null,
        paymentEmailSubjectTemplate: _needsPaymentFields &&
                _paymentEmailSubjectController.text.trim().isNotEmpty
            ? _paymentEmailSubjectController.text.trim()
            : null,
        paymentEmailBodyTemplate: _needsPaymentFields &&
                _paymentEmailBodyController.text.trim().isNotEmpty
            ? _paymentEmailBodyController.text.trim()
            : null,
        end24hNotificationBodyTemplate:
            _end24hNotificationController.text.trim().isEmpty
                ? null
                : _end24hNotificationController.text.trim(),
        end7dNotificationBodyTemplate: _end7dNotificationController.text.trim().isEmpty
            ? null
            : _end7dNotificationController.text.trim(),
        allowOnlinePayment: false, // Payment Mode (Cash/Bank Transfer/Invoice) only – no card
      );

      await widget.onSave(data);
      // Caller (e.g. manager screen) closes the route and shows success.
    } catch (e, stackTrace) {
      // Keep modal open on error so user doesn't lose data
      debugPrint('CreateDeal error caught - keeping modal open: $e');
      debugPrint('Stack trace: $stackTrace');

      String errorMessage = l10n.failedToCreateDeal;
      if (e.toString().contains('Validation failed')) {
        // Try to extract field-specific errors
        try {
          final errorStr = e.toString();
          if (errorStr.contains('fieldErrors')) {
            // Parse error details if available
            if (errorStr.contains('startAt') || errorStr.contains('endAt')) {
              errorMessage = l10n.invalidDateTimeFormat;
            } else {
              errorMessage = '${l10n.validationError}: ${l10n.checkAllFields}';
            }
          } else {
            errorMessage = '${l10n.validationError}: ${e.toString()}';
          }
        } catch (_) {
          errorMessage = e.toString();
        }
      } else {
        errorMessage = e.toString();
      }

      // IMPORTANT: Don't close modal - keep it open so user can fix and retry
      // Only update state if widget is still mounted
      if (mounted) {
        debugPrint(
            'Modal still mounted - updating error state, NOT closing modal');
        setState(() {
          _error = errorMessage;
          _isLoading = false; // Stop loading so user can retry
        });
      } else {
        debugPrint('WARNING: Modal was unmounted during error handling');
      }
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null && context.mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(isStartDate ? _startDate : _endDate),
      );
      if (time != null && context.mounted) {
        setState(() {
          final dateTime = DateTime(
            picked.year,
            picked.month,
            picked.day,
            time.hour,
            time.minute,
          );
          if (isStartDate) {
            _startDate = dateTime;
          } else {
            _endDate = dateTime;
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    l10n.createDeal,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isLoading ? null : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              DropdownButtonFormField<String>(
                key: ValueKey(_selectedSourceLanguage),
                initialValue: _selectedSourceLanguage,
                decoration: InputDecoration(
                  labelText: l10n.sourceLanguageLabel,
                  helperText: l10n.sourceLanguageHint,
                  border: const OutlineInputBorder(),
                ),
                items: AppLanguages.contentSourceLanguages
                    .map((code) => DropdownMenuItem(
                          value: code,
                          child: Text(AppLanguages.contentLanguageNames[code] ?? code),
                        ))
                    .toList(),
                onChanged: (v) {
                  if (v != null && v != _selectedSourceLanguage) {
                    setState(() {
                      _titleMap[_selectedSourceLanguage] = _titleController.text;
                      _descriptionMap[_selectedSourceLanguage] = _descriptionController.text;
                      _selectedSourceLanguage = v;
                      _titleController.text = _titleMap[v] ?? '';
                      _descriptionController.text = _descriptionMap[v] ?? '';
                    });
                  }
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '${l10n.dealTitle} *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                    tooltip: l10n.generateWithAI,
                    onPressed: _isLoading ? null : _generateWithAI,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterDealTitle;
                  }
                  if (value.trim().length < 3) {
                    return l10n.titleMinLength;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.description,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
              // Removed wholesaler selection - admins create deals on their own products
              const SizedBox(height: 16),
              // Product selection button
              Consumer(
                builder: (context, ref, child) {
                  return TextFormField(
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: '${l10n.product} *',
                      border: const OutlineInputBorder(),
                      suffixIcon: _loadingProductDetail
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              ),
                            )
                          : const Icon(Icons.arrow_drop_down),
                      helperText: _loadingProductDetail
                          ? (l10n.loadingProductDetails)
                          : l10n.tapToSelectProduct,
                    ),
                    controller: TextEditingController(
                      text: _loadingProductDetail
                          ? l10n.loading
                          : (_selectedProductName ?? ''),
                    ),
                    onTap: () async {
                      // Admin creates deals on their own products
                      final wholesalerIdForProducts = widget.currentUserId;

                      if (wholesalerIdForProducts == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(l10n.userIdRequired),
                          ),
                        );
                        return;
                      }

                      final selectedId = await context.push<String>(
                        SelectProductScreen.routePath,
                        extra: {
                          'selectedProductId': _selectedProductId,
                          'wholesalerId': wholesalerIdForProducts,
                        },
                      );
                      if (selectedId != null && mounted) {
                        // Show loading immediately
                        setState(() {
                          _loadingProductDetail = true;
                          _selectedProductId = selectedId;
                          _selectedProductName =
                              null; // Clear name while loading
                          _selectedVariantId = null;
                          _productHasVariants = false;
                          _selectedProductData = null;
                          _selectedVariantData = null;
                        });

                        // Fetch product detail from repository
                        try {
                          final repo = ref.read(managerRepositoryProvider);
                          final productDetail =
                              await repo.fetchProductDetail(selectedId);

                          if (!mounted) return;

                          // Handle multilingual title
                          String productTitle = '';
                          if (productDetail['title'] is Map) {
                            final titleMap = Map<String, dynamic>.from(
                                productDetail['title'] as Map);
                            productTitle = titleMap['en']?.toString() ??
                                titleMap.values.first.toString();
                          } else {
                            productTitle = productDetail['title']?.toString() ??
                                l10n.unknownProduct;
                          }

                          setState(() {
                            _selectedProductId = selectedId;
                            _selectedProductName = productTitle;
                            _selectedVariantId = null;
                            _productHasVariants = false;
                            _selectedProductData = productDetail;
                            _loadingProductDetail = false;
                          });

                          // Auto-fill original price from product
                          final productPrice = productDetail['price'] as num?;
                          final basePrice = productDetail['basePrice'] as num?;
                          if (productPrice != null || basePrice != null) {
                            final price =
                                (productPrice ?? basePrice ?? 0).toDouble();
                            if (_originalPriceController.text.isEmpty) {
                              _originalPriceController.text =
                                  price.toStringAsFixed(2);
                            }
                            // Auto-fill deal price if empty (suggest 10% discount)
                            if (_dealPriceController.text.isEmpty) {
                              _dealPriceController.text =
                                  (price * 0.9).toStringAsFixed(2);
                            }
                          }

                          // Auto-fill deal image from product primary image (user can override)
                          final imgUrl = productDetail['imageUrl'] as String?;
                          final images = productDetail['images'] as List?;
                          final primaryImage = imgUrl ??
                              (images != null && images.isNotEmpty
                                  ? (images[0] is String
                                      ? images[0] as String
                                      : (images[0] as Map?)?['url']?.toString())
                                  : null);
                          if (primaryImage != null &&
                              _imageUrlController.text.trim().isEmpty) {
                            _imageUrlController.text = primaryImage;
                          }

                          _loadVariants(selectedId);
                        } catch (e) {
                          if (!mounted) return;
                          // If fetch fails, just use the ID
                          setState(() {
                            _selectedProductId = selectedId;
                            _selectedProductName = 'Product $selectedId';
                            _selectedVariantId = null;
                            _productHasVariants = false;
                            _loadingProductDetail = false;
                          });
                          _loadVariants(selectedId);
                        }
                      }
                    },
                    validator: (value) {
                      if (_selectedProductId == null) {
                        return l10n.pleaseSelectProduct;
                      }
                      return null;
                    },
                  );
                },
              ),
              if (_selectedProductId != null) ...[
                const SizedBox(height: 16),
                _ProductVariantsSelector(
                  productId: _selectedProductId!,
                  selectedVariantId: _selectedVariantId,
                  onVariantSelected: (variantId) {
                    setState(() {
                      _selectedVariantId = variantId;
                      // Clear error when variant is selected
                      if (_error != null && _error!.contains('variant')) {
                        _error = null;
                      }
                    });
                  },
                  onVariantDataSelected: (variant) {
                    // Auto-fill prices when variant is selected
                    final variantPrice = (variant['price'] as num?)?.toDouble();
                    if (variantPrice != null) {
                      setState(() {
                        if (_originalPriceController.text.isEmpty) {
                          _originalPriceController.text =
                              variantPrice.toStringAsFixed(2);
                        }
                        // Auto-fill deal price if empty (suggest 10% discount)
                        if (_dealPriceController.text.isEmpty) {
                          _dealPriceController.text =
                              (variantPrice * 0.9).toStringAsFixed(2);
                        }
                      });
                    }
                  },
                  onVariantsLoaded: (hasVariants) {
                    setState(() {
                      _productHasVariants = hasVariants;
                      // If product has variants but no variant selected, clear variant selection
                      if (hasVariants && _selectedVariantId == null) {
                        _selectedVariantId = null;
                      }
                      // If product has no variants, clear variant selection
                      if (!hasVariants) {
                        _selectedVariantId = null;
                      }
                    });
                  },
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      isExpanded: true,
                      initialValue: _selectedType,
                      decoration: InputDecoration(
                        labelText: '${l10n.dealType} *',
                        border: const OutlineInputBorder(),
                      ),
                      items: [
                        DropdownMenuItem(
                            value: 'auction', child: Text(l10n.auction)),
                        DropdownMenuItem(
                            value: 'price_drop', child: Text(l10n.priceDrop)),
                        DropdownMenuItem(
                            value: 'limited_stock',
                            child: Text(l10n.limitedStock)),
                      ],
                      selectedItemBuilder: (context) => [
                        Text(l10n.auction,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(l10n.priceDrop,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text(l10n.limitedStock,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                      onChanged: (value) =>
                          setState(() => _selectedType = value ?? 'auction'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.status,
                        border: const OutlineInputBorder(),
                      ),
                      initialValue: _selectedStatus,
                      items: [
                        DropdownMenuItem(
                            value: 'draft', child: Text(l10n.draft)),
                        DropdownMenuItem(
                            value: 'scheduled', child: Text(l10n.scheduled)),
                        DropdownMenuItem(value: 'live', child: Text(l10n.live)),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value ?? 'draft');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '${l10n.startDate} *',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_startDate.year}-${_startDate.month.toString().padLeft(2, '0')}-${_startDate.day.toString().padLeft(2, '0')} ${_startDate.hour.toString().padLeft(2, '0')}:${_startDate.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: '${l10n.endDate} *',
                          border: const OutlineInputBorder(),
                          suffixIcon: const Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          '${_endDate.year}-${_endDate.month.toString().padLeft(2, '0')}-${_endDate.day.toString().padLeft(2, '0')} ${_endDate.hour.toString().padLeft(2, '0')}:${_endDate.minute.toString().padLeft(2, '0')}',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _dealPriceController,
                      decoration: InputDecoration(
                        labelText: l10n.dealPriceRequired,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter deal price';
                        }
                        final price = double.tryParse(value);
                        if (price == null || price <= 0) {
                          return 'Price must be greater than 0';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _originalPriceController,
                      decoration: InputDecoration(
                        labelText: l10n.originalPrice,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetQuantityController,
                      decoration: InputDecoration(
                        labelText: l10n.targetQuantityRequired,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter target quantity';
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 1) {
                          return 'Target quantity must be at least 1';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _minOrderQuantityController,
                      decoration: InputDecoration(
                        labelText: l10n.minOrderQtyRequired,
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter min order quantity';
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 1) {
                          return 'Min order quantity must be at least 1';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const SizedBox(height: 20),
              Text(
                l10n.paymentAndEmail,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Builder(
                builder: (context) {
                  final user = widget.initialUser ??
                      ref
                          .watch(authControllerProvider)
                          .valueOrNull
                          ?.user;
                  if (user != null) _initFromUser(user);
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.paymentMode,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l10n.paymentModeSubtitleMulti,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                      const SizedBox(height: 12),
                      PaymentModeSelectorMulti(
                        value: _allowedPaymentMethods,
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(
                                  () => _allowedPaymentMethods = v,
                                ),
                        l10n: l10n,
                      ),
                      if (_needsPaymentFields) ...[
                        const SizedBox(height: 24),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                                TextFormField(
                                  controller: _paymentIbanController,
                                  decoration: InputDecoration(
                                    labelText: l10n.ibanBankAccount,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _paymentBankAccountOwnerController,
                                  decoration: InputDecoration(
                                    labelText: l10n.accountOwner,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller:
                                      _paymentReferenceTemplateController,
                                  decoration: InputDecoration(
                                    labelText: l10n.referenceTemplate,
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _paymentInstructionsController,
                                  decoration: InputDecoration(
                                    labelText: l10n.paymentInstructions,
                                    border: const OutlineInputBorder(),
                                  ),
                                  maxLines: 2,
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _paymentEmailSubjectController,
                                  decoration: InputDecoration(
                                    labelText: l10n.paymentEmailSubject,
                                    helperText:
                                        'Placeholders: {dealTitle}, {amount}, {reference}',
                                    border: const OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                TextFormField(
                                  controller: _paymentEmailBodyController,
                                  decoration: InputDecoration(
                                    labelText: l10n.paymentEmailBody,
                                    helperText:
                                        'Placeholders: {dealTitle}, {amount}, {accountOwner}, {iban}, {reference}, {additionalInstructions}',
                                    border: const OutlineInputBorder(),
                                  ),
                                  maxLines: 8,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: _generatingPaymentEmail
                                      ? null
                                      : _generatePaymentEmailWithAI,
                                  icon: _generatingPaymentEmail
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.auto_awesome),
                                  label: Text(_generatingPaymentEmail
                                      ? l10n.generating
                                      : l10n.generateWithAI),
                                ),
                              ],
                            ),
                      ],
                    ],
                  );
                },
              ),
              const SizedBox(height: 16),
              // Image preview
              if (_imageUrlController.text.isNotEmpty || _selectedImage != null)
                Container(
                  height: 150,
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _selectedImage != null
                        ? ImagePreviewWidget(
                            fileData: _selectedImage!, fit: BoxFit.cover)
                        : Image.network(
                            _imageUrlController.text,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.error),
                          ),
                  ),
                ),
              TextFormField(
                controller: _imageUrlController,
                decoration: InputDecoration(
                  labelText: l10n.imageUrl,
                  border: const OutlineInputBorder(),
                  suffixIcon: _uploadingImage
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : IconButton(
                          icon: const Icon(Icons.upload),
                          onPressed:
                              _uploadingImage ? null : _pickAndUploadImage,
                        ),
                ),
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _end24hNotificationController,
                decoration: InputDecoration(
                  labelText: l10n.dealNotification24hLabel,
                  helperText: l10n.dealNotification24hHint,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final hasBraces = text.contains('{') || text.contains('}');
                  if (!hasBraces) return null;
                  final hasTitle = text.contains('{dealTitle}');
                  final hasQty = text.contains('{remainingQuantity}');
                  if (!hasTitle || !hasQty) {
                    return l10n.notificationTemplatePlaceholdersError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _end7dNotificationController,
                decoration: InputDecoration(
                  labelText: l10n.dealNotification7dLabel,
                  helperText: l10n.dealNotification7dHint,
                  helperMaxLines: 3,
                  border: const OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) return null;
                  final hasBraces = text.contains('{') || text.contains('}');
                  if (!hasBraces) return null;
                  final hasTitle = text.contains('{dealTitle}');
                  final hasQty = text.contains('{remainingQuantity}');
                  if (!hasTitle || !hasQty) {
                    return l10n.notificationTemplatePlaceholdersError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Shipping Cost Section
              Text(
                'Shipping Cost (Optional)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _shippingBaseCostController,
                decoration: InputDecoration(
                  labelText: l10n.baseShippingCostEur,
                  border: const OutlineInputBorder(),
                  helperText: 'Base shipping cost in EUR (e.g. 50 €)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shippingFreeThresholdController,
                decoration: InputDecoration(
                  labelText: l10n.freeShippingThresholdQuantity,
                  border: const OutlineInputBorder(),
                  helperText:
                      'Free shipping for orders of this quantity or more (e.g., 10)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _shippingPerUnitCostController,
                decoration: InputDecoration(
                  labelText: l10n.perUnitShippingCostEur,
                  border: const OutlineInputBorder(),
                  helperText:
                      'Additional cost per unit in EUR (e.g. 5 € per unit)',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(l10n.highlightedDeal),
                value: _highlighted,
                onChanged: (value) {
                  setState(() => _highlighted = value ?? false);
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleSubmit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.createDeal),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductVariantsSelector extends ConsumerStatefulWidget {
  const _ProductVariantsSelector({
    required this.productId,
    required this.selectedVariantId,
    required this.onVariantSelected,
    required this.onVariantsLoaded,
    this.onVariantDataSelected,
  });

  final String productId;
  final String? selectedVariantId;
  final void Function(String?) onVariantSelected;
  final void Function(bool hasVariants) onVariantsLoaded;
  final void Function(Map<String, dynamic>)? onVariantDataSelected;

  @override
  ConsumerState<_ProductVariantsSelector> createState() =>
      _ProductVariantsSelectorState();
}

class _ProductVariantsSelectorState
    extends ConsumerState<_ProductVariantsSelector> {
  bool? _lastVariantStatus;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final variantsAsync =
        ref.watch(manager_providers.productVariantsProvider(widget.productId));

    return variantsAsync.when(
      data: (variants) {
        final hasVariants = variants.isNotEmpty;
        // Notify parent about variant status when it changes
        if (_lastVariantStatus != hasVariants) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              widget.onVariantsLoaded(hasVariants);
              _lastVariantStatus = hasVariants;
            }
          });
        }

        // Always show variant selector section when product is selected
        // If no variants, show message that deal will be on product
        if (variants.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, size: 20, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    l10n.noVariantsMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        // Product has variants - show selector
        return DropdownButtonFormField<String>(
          decoration: InputDecoration(
            labelText: '${l10n.variant} *',
            border: const OutlineInputBorder(),
            helperText: l10n.selectVariantHelper,
          ),
          initialValue: widget.selectedVariantId,
          isExpanded: true,
          items: variants.map((variant) {
            final attrs = variant['attributes'] as Map<String, dynamic>? ?? {};
            final attrStr =
                attrs.entries.map((e) => '${e.key}: ${e.value}').join(', ');
            final sku = variant['sku']?.toString() ?? 'N/A';
            final price = variant['price'] != null
                ? ' - ${context.formatPriceEurOnly((variant['price'] as num))} '
                    '(${context.formatPriceUsdFromEur((variant['price'] as num))})'
                : '';

            return DropdownMenuItem<String>(
              value: variant['id']?.toString(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    sku,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (attrStr.isNotEmpty)
                    Text(
                      attrStr,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (price.isNotEmpty)
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green.shade700,
                      ),
                    ),
                ],
              ),
            );
          }).toList(),
          selectedItemBuilder: (context) {
            return variants.map((variant) {
              final attrs =
                  variant['attributes'] as Map<String, dynamic>? ?? {};
              final attrStr =
                  attrs.entries.map((e) => '${e.key}: ${e.value}').join(', ');
              final sku = variant['sku']?.toString() ?? 'N/A';
              return Text(
                '$sku${attrStr.isNotEmpty ? ' ($attrStr)' : ''}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          onChanged: (value) {
            widget.onVariantSelected(value);
            // Also pass variant data if available
            if (value != null && widget.onVariantDataSelected != null) {
              final variant = variants.firstWhere(
                (v) => v['id']?.toString() == value,
                orElse: () => {},
              );
              if (variant.isNotEmpty) {
                widget.onVariantDataSelected!(variant);
              }
            }
          },
          validator: (value) {
            // Variants exist, so variant selection is required
            if (value == null || value.isEmpty) {
              return l10n
                  .selectVariantHelper; // reusing helper text or new key? "Please select a variant"? I'll use selectVariantHelper for now as it makes sense roughly, or 'addAtLeastOneVariant'? No.
            }
            return null;
          },
        );
      },
      loading: () => const SizedBox(
        height: 56,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) {
        debugPrint('Error loading variants: $error');
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber,
                  size: 20, color: Colors.orange.shade700),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.unableToLoadVariantsMessage,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
