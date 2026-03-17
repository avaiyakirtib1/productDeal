import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../manager/data/repositories/manager_repository.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../shared/widgets/payment_mode_selector.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/services/image_picker_helper.dart';
import '../../../../core/widgets/image_preview_widget.dart';
import '../../data/payment_email_defaults.dart';
import 'create_deal_modal.dart' show CreateDealData;

class EditDealModal extends ConsumerStatefulWidget {
  const EditDealModal({
    super.key,
    required this.deal,
    required this.onSave,
  });

  final Map<String, dynamic> deal;
  final Future<void> Function(CreateDealData) onSave;

  @override
  ConsumerState<EditDealModal> createState() => _EditDealModalState();
}

class _EditDealModalState extends ConsumerState<EditDealModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dealPriceController = TextEditingController();
  final _originalPriceController = TextEditingController();
  final _targetQuantityController = TextEditingController();
  final _minOrderQuantityController = TextEditingController();
  final _imageUrlController = TextEditingController();
  final _paymentIbanController = TextEditingController();
  final _paymentBankAccountOwnerController = TextEditingController();
  final _paymentReferenceTemplateController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();
  final _paymentEmailSubjectController = TextEditingController();
  final _paymentEmailBodyController = TextEditingController();
  final _end24hNotificationController = TextEditingController();
  final _end7dNotificationController = TextEditingController();

  String? _selectedProductId;
  String? _selectedProductName;
  String? _selectedVariantId;
  String _selectedType = 'auction';
  String _selectedStatus = 'draft';
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now().add(const Duration(days: 1));
  bool _highlighted = false;
  bool _isLoading = false;
  String? _error;
  PickedFileData? _selectedImage;
  bool _uploadingImage = false;
  bool _generatingPaymentEmail = false;
  /// Allowed payment methods for this deal.
  List<String> _allowedPaymentMethods = ['cash_on_delivery'];
  bool _paymentFieldsPrefilled = false;

  String _currentLanguage = 'en';
  final Map<String, String> _titleMap = {};
  final Map<String, String> _descriptionMap = {};
  final List<String> _supportedLanguages = AppLanguages.contentSourceLanguages;

  @override
  void initState() {
    super.initState();
    _initializeFromDeal();
  }

  void _initializeFromDeal() {
    final deal = widget.deal;

    // Initialize title map - handle both Map<String, dynamic> and Map<String, String>
    final titleRaw = deal['title'];
    if (titleRaw is Map) {
      // Convert Map<String, dynamic> to Map<String, String>
      _titleMap.clear();
      titleRaw.forEach((key, value) {
        if (key is String && value != null) {
          _titleMap[key] = value.toString();
        }
      });
    } else if (titleRaw is String) {
      _titleMap['en'] = titleRaw;
    } else {
      _titleMap['en'] = '';
    }

    // Initialize description map - handle both Map<String, dynamic> and Map<String, String>
    final descriptionRaw = deal['description'];
    if (descriptionRaw is Map) {
      // Convert Map<String, dynamic> to Map<String, String>
      _descriptionMap.clear();
      descriptionRaw.forEach((key, value) {
        if (key is String && value != null) {
          _descriptionMap[key] = value.toString();
        }
      });
    } else if (descriptionRaw is String && descriptionRaw.isNotEmpty) {
      _descriptionMap['en'] = descriptionRaw;
    }

    // Set initial values based on current language
    _titleController.text = _titleMap[_currentLanguage] ?? '';
    _descriptionController.text = _descriptionMap[_currentLanguage] ?? '';

    // Listeners to update the map as user types
    _titleController.addListener(() {
      _titleMap[_currentLanguage] = _titleController.text;
    });
    _descriptionController.addListener(() {
      _descriptionMap[_currentLanguage] = _descriptionController.text;
    });

    _dealPriceController.text = (deal['dealPrice'] as num?)?.toString() ?? '';
    _originalPriceController.text =
        (deal['originalPrice'] as num?)?.toString() ?? '';
    _targetQuantityController.text =
        (deal['targetQuantity'] as num?)?.toString() ?? '100';
    _minOrderQuantityController.text =
        (deal['minOrderQuantity'] as num?)?.toString() ?? '1';

    _selectedProductId = deal['product']?['id']?.toString() ??
        deal['product']?['_id']?.toString();
    _selectedProductName = deal['product']?['title']?.toString() ??
        deal['product']?['name']?.toString();
    _selectedVariantId = deal['variant']?['id']?.toString() ??
        deal['variant']?['_id']?.toString();

    // Normalize type/status to valid dropdown values to avoid DropdownButton assertion
    const validTypes = ['auction', 'price_drop', 'limited_stock'];
    const validStatuses = ['draft', 'scheduled', 'live', 'ended', 'cancelled'];
    final rawType = (deal['type']?.toString() ?? 'auction').toLowerCase();
    final rawStatus = (deal['status']?.toString() ?? 'draft').toLowerCase();
    _selectedType = validTypes.contains(rawType) ? rawType : (rawType.replaceAll('_', '') == 'pricedrop' ? 'price_drop' : rawType.replaceAll('_', '') == 'limitedstock' ? 'limited_stock' : 'auction');
    _selectedStatus = validStatuses.contains(rawStatus) ? rawStatus : 'draft';
    _highlighted = deal['highlighted'] == true;

    // Parse dates as UTC and convert to local for display
    if (deal['startAt'] != null) {
      final parsed = DateTime.tryParse(deal['startAt'].toString());
      _startDate = parsed != null ? parsed.toLocal() : DateTime.now();
    }
    if (deal['endAt'] != null) {
      final parsed = DateTime.tryParse(deal['endAt'].toString());
      _endDate = parsed != null
          ? parsed.toLocal()
          : DateTime.now().add(const Duration(days: 1));
    }

    final imageUrl = deal['imageUrl']?.toString() ??
        (deal['images'] is List && (deal['images'] as List).isNotEmpty
            ? (deal['images'] as List).first.toString()
            : '');
    _imageUrlController.text = imageUrl;

    _paymentIbanController.text = deal['paymentIban']?.toString() ?? '';
    _paymentBankAccountOwnerController.text = deal['paymentBankAccountOwner']?.toString() ?? '';
    _paymentReferenceTemplateController.text = deal['paymentReferenceTemplate']?.toString() ?? '';
    _paymentInstructionsController.text = deal['paymentInstructions']?.toString() ?? '';
    _paymentEmailSubjectController.text = deal['paymentEmailSubjectTemplate']?.toString() ?? '';
    _paymentEmailBodyController.text = deal['paymentEmailBodyTemplate']?.toString() ?? '';
    _end24hNotificationController.text =
        deal['end24hNotificationBodyTemplate']?.toString() ??
            'Last 24 hours! "{dealTitle}" – only {remainingQuantity} orders left to close this deal.';
    _end7dNotificationController.text =
        deal['end7dNotificationBodyTemplate']?.toString() ??
            '"{dealTitle}" – only {remainingQuantity} orders left to close this deal.';
    // Allowed payment methods from deal, or infer: has bank details = cash + bank_transfer, else cash only
    final rawAllowed = deal['allowedPaymentMethods'];
    if (rawAllowed is List && rawAllowed.isNotEmpty) {
      _allowedPaymentMethods =
          rawAllowed.map((e) => e.toString()).toSet().toList();
    } else {
      final hasBankDetails =
          ((deal['paymentIban']?.toString() ?? '').trim().isNotEmpty ||
              (deal['paymentBankAccountOwner']?.toString() ?? '')
                  .trim()
                  .isNotEmpty);
      _allowedPaymentMethods = hasBankDetails
          ? ['cash_on_delivery', 'bank_transfer']
          : ['cash_on_delivery'];
    }
  }

  void _prefillPaymentFieldsFromUser(UserModel? user) {
    final needsPaymentFields =
        _allowedPaymentMethods.contains('invoice') ||
        _allowedPaymentMethods.contains('bank_transfer');
    if (user == null || _paymentFieldsPrefilled || !needsPaymentFields) return;
    _paymentFieldsPrefilled = true;
    // Prefill bank details when deal has empty values and user has them
    if (_paymentIbanController.text.trim().isEmpty && (user.effectiveIban ?? '').trim().isNotEmpty) {
      _paymentIbanController.text = user.effectiveIban ?? '';
    }
    if (_paymentBankAccountOwnerController.text.trim().isEmpty && (user.effectiveAccountHolder ?? '').trim().isNotEmpty) {
      _paymentBankAccountOwnerController.text = user.effectiveAccountHolder ?? '';
    }
    if (_paymentReferenceTemplateController.text.trim().isEmpty) {
      final ref = user.paymentConfig?.paymentReferenceTemplate ?? user.paymentReferenceTemplate ?? '';
      if (ref.isNotEmpty) _paymentReferenceTemplateController.text = ref;
    }
    if (_paymentInstructionsController.text.trim().isEmpty) {
      final inst = user.paymentConfig?.paymentInstructions ?? user.paymentInstructions ?? '';
      if (inst.isNotEmpty) _paymentInstructionsController.text = inst;
    }
    // Prefill email templates when deal has empty values and user has them
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
      final dealId = widget.deal['id']?.toString() ?? widget.deal['_id']?.toString();
      final titleRaw = widget.deal['title'];
      String? dealTitle;
      if (titleRaw is Map) {
        dealTitle = titleRaw['en']?.toString() ?? titleRaw[titleRaw.keys.isNotEmpty ? titleRaw.keys.first : 'en']?.toString();
      } else if (titleRaw != null) {
        dealTitle = titleRaw.toString();
      }
      final result = await repo.generateDealPaymentEmail(
        dealId: dealId,
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
      final imageData = await ImagePickerHelper.pickImage();
      if (imageData == null) {
        setState(() => _uploadingImage = false);
        return;
      }

      setState(() => _selectedImage = imageData);

      final url = await uploadService.uploadFile(
        fileData: imageData,
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(dateTime.toUtc());
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProductId == null) {
      setState(() => _error = l10n.pleaseSelectProduct);
      return;
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final images = _imageUrlController.text.trim().isNotEmpty
          ? [_imageUrlController.text.trim()]
          : <String>[];

      final data = CreateDealData(
        title: _titleMap,
        description: _descriptionMap.isNotEmpty ? _descriptionMap : null,
        productId: _selectedProductId!,
        variantId: _selectedVariantId,
        wholesalerId: widget.deal['wholesaler']?['id']?.toString() ??
            widget.deal['wholesaler']?['_id']?.toString() ??
            '',
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
        allowedPaymentMethods: _allowedPaymentMethods,
        paymentIban: (_allowedPaymentMethods.contains('invoice') ||
                _allowedPaymentMethods.contains('bank_transfer')) &&
                _paymentIbanController.text.trim().isNotEmpty
            ? _paymentIbanController.text.trim()
            : null,
        paymentBankAccountOwner:
            (_allowedPaymentMethods.contains('invoice') ||
                    _allowedPaymentMethods.contains('bank_transfer')) &&
                    _paymentBankAccountOwnerController.text.trim().isNotEmpty
                ? _paymentBankAccountOwnerController.text.trim()
                : null,
        paymentReferenceTemplate:
            (_allowedPaymentMethods.contains('invoice') ||
                    _allowedPaymentMethods.contains('bank_transfer')) &&
                    _paymentReferenceTemplateController.text
                        .trim()
                        .isNotEmpty
                ? _paymentReferenceTemplateController.text.trim()
                : null,
        paymentInstructions:
            (_allowedPaymentMethods.contains('invoice') ||
                    _allowedPaymentMethods.contains('bank_transfer')) &&
                    _paymentInstructionsController.text.trim().isNotEmpty
                ? _paymentInstructionsController.text.trim()
                : null,
        paymentEmailSubjectTemplate:
            (_allowedPaymentMethods.contains('invoice') ||
                    _allowedPaymentMethods.contains('bank_transfer')) &&
                    _paymentEmailSubjectController.text.trim().isNotEmpty
                ? _paymentEmailSubjectController.text.trim()
                : null,
        paymentEmailBodyTemplate:
            (_allowedPaymentMethods.contains('invoice') ||
                    _allowedPaymentMethods.contains('bank_transfer')) &&
                    _paymentEmailBodyController.text.trim().isNotEmpty
                ? _paymentEmailBodyController.text.trim()
                : null,
        end24hNotificationBodyTemplate:
            _end24hNotificationController.text.trim().isEmpty
                ? null
                : _end24hNotificationController.text.trim(),
        end7dNotificationBodyTemplate:
            _end7dNotificationController.text.trim().isEmpty
                ? null
                : _end7dNotificationController.text.trim(),
        allowOnlinePayment: false, // Payment Mode only – no card
      );

      await widget.onSave(data);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
          content: Text(l10n.dealUpdatedSuccessfully),
        ),
        );
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editDeal),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Language selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _supportedLanguages.map((lang) {
                    final isSelected = _currentLanguage == lang;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(AppLanguages.contentLanguageNames[lang] ?? lang.toUpperCase()),
                        selected: isSelected,
                        onSelected: (selected) {
                          if (selected) {
                            setState(() {
                              _currentLanguage = lang;
                              _titleController.text = _titleMap[lang] ?? '';
                              _descriptionController.text =
                                  _descriptionMap[lang] ?? '';
                            });
                          }
                        },
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '${l10n.dealTitle} *',
                  border: const OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterDealTitle;
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
              const SizedBox(height: 16),
              // Product selection (read-only for edit)
              TextFormField(
                initialValue: _selectedProductName ?? l10n.pleaseSelectProduct,
                decoration: InputDecoration(
                  labelText: '${l10n.product} *',
                  border: const OutlineInputBorder(),
                  enabled: false,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.type,
                        border: const OutlineInputBorder(),
                      ),
                      initialValue: _selectedType,
                      items: [
                        DropdownMenuItem(
                            value: 'auction', child: Text(l10n.auction)),
                        DropdownMenuItem(
                            value: 'price_drop', child: Text(l10n.priceDrop)),
                        DropdownMenuItem(
                            value: 'limited_stock',
                            child: Text(l10n.limitedStock)),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedType = value ?? 'auction');
                      },
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
                        DropdownMenuItem(
                            value: 'ended', child: Text(l10n.ended)),
                        DropdownMenuItem(
                            value: 'cancelled', child: Text(l10n.cancelled)),
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
              TextFormField(
                controller: _dealPriceController,
                decoration: InputDecoration(
                  labelText: '${l10n.dealPrice} *',
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.pleaseEnterDealPrice;
                  }
                  final price = double.tryParse(value);
                  if (price == null || price < 0) {
                    return l10n.dealPriceMustBeValidNumber;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _originalPriceController,
                decoration: InputDecoration(
                  labelText: l10n.originalPrice,
                  border: const OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetQuantityController,
                      decoration: InputDecoration(
                        labelText: '${l10n.targetQuantity} *',
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return l10n.pleaseEnterTargetQuantity;
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 1) {
                          return l10n.targetQuantityMin;
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
                          return l10n.pleaseEnterMinOrderQuantity;
                        }
                        final qty = int.tryParse(value);
                        if (qty == null || qty < 1) {
                          return l10n.minOrderQtyMin;
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
                  final user = ref.watch(authControllerProvider).valueOrNull?.user;
                  _prefillPaymentFieldsFromUser(user);
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
                            : (v) {
                                setState(() {
                                  _allowedPaymentMethods = v;
                                  _paymentFieldsPrefilled = false;
                                  _prefillPaymentFieldsFromUser(user);
                                });
                              },
                        l10n: l10n,
                      ),
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
                          controller: _paymentReferenceTemplateController,
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
                                l10n.paymentEmailPlaceholdersSubject,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _paymentEmailBodyController,
                          decoration: InputDecoration(
                            labelText: l10n.paymentEmailBody,
                            helperText:
                                l10n.paymentEmailPlaceholdersBody,
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
                          label: Text(
                            _generatingPaymentEmail
                                ? l10n.generating
                                : l10n.generateWithAI,
                          ),
                        ),
                      ],
                    ),
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
              CheckboxListTile(
                title: Text(l10n.highlightedDeal),
                value: _highlighted,
                onChanged: (value) {
                  setState(() => _highlighted = value ?? false);
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _isLoading ? null : _save,
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.save),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
