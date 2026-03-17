import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/services/image_picker_helper.dart';
import '../../../../core/widgets/image_preview_widget.dart';
import '../../../manager/presentation/screens/select_category_screen.dart';
import '../../../manager/presentation/screens/select_wholesaler_screen.dart';
import '../../../manager/data/repositories/manager_repository.dart';

/// Single image slot: either uploaded (url) or pending (fileData, auto-uploading)
class ProductImageSlot {
  ProductImageSlot({required this.id, this.url, this.fileData})
      : assert(url != null || fileData != null);
  final String id;
  final String? url;
  final PickedFileData? fileData;
  bool get isUploaded => url != null;
}

class ProductVariantData {
  ProductVariantData({
    this.sku,
    this.attributes = const {},
    this.price = 0,
    this.costPrice,
    this.stock = 0,
    this.reservedStock = 0,
    this.images = const [],
    this.isDefault = false,
  });

  final String? sku;
  final Map<String, dynamic> attributes;
  final double price;
  final double? costPrice;
  final int stock;
  final int reservedStock;
  final List<String> images;
  final bool isDefault;

  ProductVariantData copyWith({
    String? sku,
    Map<String, dynamic>? attributes,
    double? price,
    double? costPrice,
    int? stock,
    int? reservedStock,
    List<String>? images,
    bool? isDefault,
  }) {
    return ProductVariantData(
      sku: sku ?? this.sku,
      attributes: attributes ?? this.attributes,
      price: price ?? this.price,
      costPrice: costPrice ?? this.costPrice,
      stock: stock ?? this.stock,
      reservedStock: reservedStock ?? this.reservedStock,
      images: images ?? this.images,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}

class CreateProductData {
  CreateProductData({
    required this.title,
    this.categoryId,
    this.categoryIds = const [],
    required this.wholesalerId,
    this.description,
    this.price,
    this.stock,
    this.unit = 'unit',
    this.sku,
    this.costPrice,
    this.status = 'pending',
    this.imageUrl,
    this.images = const [],
    this.isFeatured = false,
    this.variants = const [],
    this.language = 'en',
  });

  final String title;
  final String? description;
  final String? categoryId; // Legacy, use categoryIds
  final List<String> categoryIds;
  final String wholesalerId;
  final double? price;
  final int? stock;
  final String unit;
  final String? sku;
  final double? costPrice;
  final String status;
  final String? imageUrl;
  final List<String> images;
  final bool isFeatured;
  final List<ProductVariantData> variants;
  final String language;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'title': title,
      'wholesalerId': wholesalerId,
      'unit': unit,
      'status': status,
      'isFeatured': isFeatured,
    };

    if (categoryIds.isNotEmpty) {
      json['categoryIds'] = categoryIds;
    } else if (categoryId != null && categoryId!.isNotEmpty) {
      json['categoryId'] = categoryId;
    }
    if (description != null && description!.isNotEmpty) {
      json['description'] = description;
    }
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      json['imageUrl'] = imageUrl;
    }
    if (images.isNotEmpty) {
      json['images'] = images;
    }

    if (variants.isNotEmpty) {
      json['variants'] = variants.map((v) {
        final variantJson = <String, dynamic>{
          'sku': v.sku?.toUpperCase() ?? '',
          'attributes': v.attributes,
          'price': v.price,
          'stock': v.stock,
          'reservedStock': v.reservedStock,
          'isDefault': v.isDefault,
        };
        if (v.costPrice != null) variantJson['costPrice'] = v.costPrice;
        if (v.images.isNotEmpty) variantJson['images'] = v.images;
        return variantJson;
      }).toList();
    } else {
      if (price != null) json['price'] = price;
      if (stock != null) json['stock'] = stock;
      if (sku != null && sku!.isNotEmpty) json['sku'] = sku;
      if (costPrice != null) json['costPrice'] = costPrice;
    }
    json['language'] = language;

    return json;
  }
}

class CreateProductModal extends ConsumerStatefulWidget {
  const CreateProductModal({
    super.key,
    required this.onSave,
    this.categories = const [],
    this.wholesalers = const [],
    this.currentUserId,
  });

  final Future<void> Function(CreateProductData) onSave;
  final List<Map<String, String>> categories;
  final List<Map<String, String>> wholesalers;
  final String? currentUserId;

  @override
  ConsumerState<CreateProductModal> createState() => _CreateProductModalState();
}

class _CreateProductModalState extends ConsumerState<CreateProductModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _skuController = TextEditingController();
  final _costPriceController = TextEditingController();

  List<String> _selectedCategoryIds = [];
  List<Map<String, dynamic>> _selectedCategories = []; // For display (id, name)
  String? _selectedWholesalerId;
  String? _selectedWholesalerName; // Store name for display
  String _selectedSourceLanguage = 'en';
  String _selectedUnit = 'unit';
  String _selectedStatus = 'pending';
  bool _isFeatured = false;
  bool _useVariants = false;
  bool _isLoading = false;
  String? _error;
  // Unified image list: url = uploaded, fileData = pending (auto-upload on pick)
  final List<ProductImageSlot> _imageSlots = [];
  final List<Future<void>> _uploadFutures = []; // Track in-flight uploads for save
  bool _pickingImages = false;
  final _urlInputController = TextEditingController();

  final List<ProductVariantData> _variants = [];
  final List<String> _attributeKeys = [];

  @override
  void initState() {
    super.initState();
    debugPrint('Current User ID: ${widget.currentUserId}');
    // Pre-select wholesaler logic
    // Default to current user (admin creates products for themselves by default)
    if (widget.currentUserId != null) {
      _selectedWholesalerId = widget.currentUserId;

      // If wholesalers list is provided, try to find the name for display
      if (widget.wholesalers.isNotEmpty) {
        final wholesaler = widget.wholesalers.firstWhere(
          (wh) => wh['id'] == widget.currentUserId,
          orElse: () => <String, String>{
            'id': widget.currentUserId!,
            'name': 'Current User'
          },
        );
        _selectedWholesalerName = wholesaler['name'] ?? 'Current User';
      } else {
        // Wholesaler view: list is empty, just set the ID
        _selectedWholesalerName =
            null; // Will show "Current User" in read-only field
      }
    }
  }

  @override
  void didUpdateWidget(CreateProductModal oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If wholesalers list changed, validate that selected value still exists
    if (widget.wholesalers != oldWidget.wholesalers &&
        _selectedWholesalerId != null) {
      final wholesalerIds = widget.wholesalers.map((wh) => wh['id']).toSet();
      if (!wholesalerIds.contains(_selectedWholesalerId)) {
        // Selected wholesaler no longer exists in the list, reset it
        _selectedWholesalerId = null;
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _skuController.dispose();
    _costPriceController.dispose();
    _urlInputController.dispose();
    super.dispose();
  }

  void _addAttributeKey(String key) {
    if (key.trim().isEmpty) return;
    if (_attributeKeys.contains(key.trim())) return;
    setState(() {
      _attributeKeys.add(key.trim());
    });
  }

  void _removeAttributeKey(String key) {
    setState(() {
      _attributeKeys.remove(key);
      // Clean up attributes from variants
      for (var i = 0; i < _variants.length; i++) {
        final newAttributes =
            Map<String, dynamic>.from(_variants[i].attributes);
        newAttributes.remove(key);
        _variants[i] = _variants[i].copyWith(attributes: newAttributes);
      }
    });
  }

  void _addVariant() {
    setState(() {
      _variants.add(ProductVariantData(
        price: double.tryParse(_priceController.text) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        isDefault: _variants.isEmpty,
      ));
    });
  }

  void _removeVariant(int index) {
    setState(() {
      _variants.removeAt(index);
      if (_variants.isNotEmpty && !_variants.any((v) => v.isDefault)) {
        _variants[0] = _variants[0].copyWith(isDefault: true);
      }
    });
  }

  void _updateVariant(int index, ProductVariantData variant) {
    setState(() {
      _variants[index] = variant;
    });
  }

  static const int _maxProductImages = 5;

  Future<void> _pickAndUploadImages() async {
    final l10n = AppLocalizations.of(context)!;
    if (_imageSlots.length >= _maxProductImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.maximum5ImagesAllowed)),
      );
      return;
    }
    try {
      setState(() => _pickingImages = true);
      final files = await ImagePickerHelper.pickMultipleImages(
        limit: _maxProductImages - _imageSlots.length,
      );
      setState(() => _pickingImages = false);
      if (files.isEmpty || !mounted) return;

      for (final imageData in files) {
        final slotId = 'img_${DateTime.now().millisecondsSinceEpoch}_${_imageSlots.length}';
        final slot = ProductImageSlot(id: slotId, fileData: imageData);
        setState(() => _imageSlots.add(slot));

        final future = _uploadSlot(slot);
        _uploadFutures.add(future);
        future.whenComplete(() {
          _uploadFutures.remove(future);
        });
      }
    } catch (e) {
      setState(() => _pickingImages = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.uploadFailed}: $e')),
        );
      }
    }
  }

  Future<void> _uploadSlot(ProductImageSlot slot) async {
    if (slot.url != null) return;
    final uploadService = ref.read(uploadServiceProvider);
    try {
      final url = await uploadService.uploadFile(
        fileData: slot.fileData!,
        folder: 'products',
      );
      if (!mounted) return;
      setState(() {
        final i = _imageSlots.indexWhere((s) => s.id == slot.id);
        if (i >= 0) _imageSlots[i] = ProductImageSlot(id: slot.id, url: url);
      });
    } catch (e) {
      debugPrint('Failed to upload image: $e');
      if (mounted) {
        setState(() => _imageSlots.removeWhere((s) => s.id == slot.id));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.uploadFailed}: $e')),
        );
      }
    }
  }

  void _removeImage(int index) {
    setState(() {
      if (index >= 0 && index < _imageSlots.length) _imageSlots.removeAt(index);
    });
  }

  void _reorderImages(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) newIndex -= 1;
    setState(() {
      final item = _imageSlots.removeAt(oldIndex);
      _imageSlots.insert(newIndex, item);
    });
  }

  void _addImageFromUrl() {
    final url = _urlInputController.text.trim();
    if (url.isEmpty) return;
    final l10n = AppLocalizations.of(context)!;
    if (_imageSlots.length >= _maxProductImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.maximum5ImagesAllowed)),
      );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || (!uri.scheme.startsWith('http'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.invalidImageUrl)),
      );
      return;
    }
    setState(() {
      _imageSlots.add(ProductImageSlot(id: 'url_${DateTime.now().millisecondsSinceEpoch}', url: url));
      _urlInputController.clear();
    });
  }

  Future<void> _generateWithAI() async {
    final l10n = AppLocalizations.of(context)!;
    final prompt = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        return AlertDialog(
          title: Text(l10n.generateWithAI),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.enterProductDescriptionPrompt),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: l10n.productDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
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
    );

    if (prompt == null || prompt.trim().isEmpty) return;

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(managerRepositoryProvider);
      final data = await repo.generateProductContent(
        prompt,
        language: _selectedSourceLanguage,
      );

      if (!mounted) return;

      setState(() {
        if (data['title'] != null) {
          _titleController.text = data['title'];
        }
        if (data['description'] != null) {
          _descriptionController.text = data['description'];
        }
        if (data['price'] != null) {
          _priceController.text = data['price'].toString();
        }
        if (data['stock'] != null) {
          _stockController.text = data['stock'].toString();
        }
        if (data['unit'] != null) {
          final raw = data['unit'].toString().toLowerCase();
          const canonicalUnits = ['unit', 'kg', 'g', 'L', 'mL', 'piece', 'box', 'pack'];
          final match = canonicalUnits.where((u) => u.toLowerCase() == raw).firstOrNull;
          _selectedUnit = match ?? 'unit';
        }
        if (data['sku'] != null) {
          _skuController.text = data['sku'];
        }

        // Try to match category by name if returned
        if (data['categoryName'] != null) {
          try {
            final catName = data['categoryName'].toString().toLowerCase();
            final cat = widget.categories.firstWhere(
              (c) => c['name'].toString().toLowerCase() == catName,
              orElse: () => {'id': '', 'name': ''},
            );
            if (cat['id'] != null && cat['id']!.toString().isNotEmpty) {
              _selectedCategoryIds = [cat['id']!.toString()];
              _selectedCategories = [
                {'id': cat['id'], 'name': cat['name'] ?? catName}
              ];
            }
          } catch (e) {
            debugPrint('Category match failed: $e');
          }
        }

        // Handle variants from AI
        if (data['variants'] != null && data['variants'] is List) {
          final variantsList = data['variants'] as List;
          if (variantsList.isNotEmpty) {
            _useVariants = true;
            _variants.clear();
            for (var i = 0; i < variantsList.length; i++) {
              final v = variantsList[i];
              _variants.add(ProductVariantData(
                sku: v['sku']?.toString(),
                price: (v['price'] as num?)?.toDouble() ??
                    double.tryParse(_priceController.text) ??
                    0,
                stock: (v['stock'] as num?)?.toInt() ??
                    int.tryParse(_stockController.text) ??
                    0,
                attributes: v['attributes'] is Map
                    ? Map<String, dynamic>.from(v['attributes'])
                    : {},
                isDefault: i == 0,
              ));
            }
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contentGeneratedSuccessfully)),
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

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    final l10n = AppLocalizations.of(context)!;

    // Category is optional; backend will auto-assign via AI if none selected

    // Use currentUserId as fallback if wholesalerId is not set
    final wholesalerId = _selectedWholesalerId ?? widget.currentUserId;
    if (wholesalerId == null || wholesalerId.isEmpty) {
      setState(() => _error = l10n.pleaseSelectWholesaler);
      return;
    }

    if (_useVariants) {
      if (_variants.isEmpty) {
        setState(() => _error = l10n.addAtLeastOneVariant);
        return;
      }
      for (var i = 0; i < _variants.length; i++) {
        final variant = _variants[i];
        if (variant.sku == null || variant.sku!.isEmpty) {
          setState(
              () => _error = 'Variant ${i + 1}: ${l10n.variantSkuRequired}');
          return;
        }
        if (variant.price <= 0) {
          setState(() => _error = 'Variant ${i + 1}: ${l10n.pricePositive}');
          return;
        }
        if (variant.stock < 0) {
          setState(() => _error = 'Variant ${i + 1}: ${l10n.stockNegative}');
          return;
        }
      }
    } else {
      final price = double.tryParse(_priceController.text);
      final stock = int.tryParse(_stockController.text);
      if (price == null || price <= 0) {
        setState(() => _error = l10n.pricePositive);
        return;
      }
      if (stock == null || stock < 0) {
        setState(() => _error = l10n.stockNegative);
        return;
      }
    }

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Wait for any in-flight image uploads before submit
      if (_uploadFutures.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(_uploadFutures));
      }
      // Upload any slots still with fileData (e.g. retries)
      final uploadService = ref.read(uploadServiceProvider);
      for (final slot in List<ProductImageSlot>.from(_imageSlots)) {
        if (slot.fileData != null) {
          try {
            final url = await uploadService.uploadFile(
              fileData: slot.fileData!,
              folder: 'products',
            );
            if (!mounted) return;
            setState(() {
              final i = _imageSlots.indexWhere((s) => s.id == slot.id);
              if (i >= 0) _imageSlots[i] = ProductImageSlot(id: slot.id, url: url);
            });
          } catch (e) {
            debugPrint('Failed to upload pending image: $e');
          }
        }
      }
      // First image = primary; order preserved from _imageSlots
      final images = _imageSlots
          .where((s) => s.url != null)
          .map((s) => s.url!)
          .toList();
      final firstUrl = images.isNotEmpty ? images.first : null;

      final data = CreateProductData(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim().isEmpty
            ? null
            : _descriptionController.text.trim(),
        categoryIds: _selectedCategoryIds,
        wholesalerId: wholesalerId,
        language: _selectedSourceLanguage,
        price: _useVariants ? null : double.tryParse(_priceController.text),
        stock: _useVariants ? null : int.tryParse(_stockController.text),
        unit: _selectedUnit,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        costPrice: _costPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_costPriceController.text),
        status: _selectedStatus,
        imageUrl: firstUrl,
        images: images,
        isFeatured: _isFeatured,
        variants: _useVariants ? _variants : const [],
      );

      await widget.onSave(data);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  AppLocalizations.of(context)!.productCreatedSuccessfully)),
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
                    l10n.createProduct,
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
                  if (v != null) setState(() => _selectedSourceLanguage = v);
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: '${l10n.productTitle} *',
                  border: const OutlineInputBorder(),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.auto_awesome, color: Colors.amber),
                    tooltip: l10n.generateWithAI,
                    onPressed: _isLoading ? null : _generateWithAI,
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return l10n.productTitleRequired;
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
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final result = await context.push<Object>(
                    SelectCategoryScreen.routePath,
                    extra: {
                      'multiSelect': true,
                      'selectedCategoryIds': _selectedCategoryIds,
                    },
                  );

                  if (result != null && mounted && result is List) {
                    final selected = result
                        .map((e) => e as Map<String, dynamic>)
                        .where((m) => m['id'] != null)
                        .toList();
                    setState(() {
                      _selectedCategoryIds =
                          selected.map((m) => m['id'].toString()).toList();
                      _selectedCategories = selected;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.category,
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    helperText: _selectedCategories.isEmpty
                        ? l10n.optionalAutoAssigned
                        : l10n.tapToSelectCategory,
                  ),
                  child: Text(
                    _selectedCategories.isEmpty
                        ? ''
                        : _selectedCategories
                            .map((c) => c['name']?.toString() ?? '')
                            .join(', '),
                    style: TextStyle(
                      color: _selectedCategories.isEmpty
                          ? Theme.of(context).hintColor
                          : null,
                    ),
                  ),
                ),
              ),
              if (_selectedCategories.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: _selectedCategories.map((c) {
                    final name = c['name']?.toString() ?? 'Unknown';
                    final id = c['id']?.toString() ?? '';
                    return Chip(
                      label: Text(name),
                      onDeleted: () {
                        setState(() {
                          _selectedCategoryIds.remove(id);
                          _selectedCategories
                              .removeWhere((x) => x['id']?.toString() == id);
                        });
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 16),
              // Wholesaler selection button (for admin)
              if (widget.wholesalers.isNotEmpty) ...[
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: '${l10n.wholesaler} *',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    helperText: _selectedWholesalerId == widget.currentUserId
                        ? l10n.defaultYourAccount
                        : l10n.tapToSelectWholesaler,
                  ),
                  controller: TextEditingController(
                    text: _selectedWholesalerName ??
                        (_selectedWholesalerId == widget.currentUserId
                            ? l10n.currentUserYou
                            : ''),
                  ),
                  onTap: () async {
                    final selectedId = await context.push<String>(
                      SelectWholesalerScreen.routePath,
                      extra: {
                        'selectedWholesalerId': _selectedWholesalerId,
                      },
                    );
                    if (selectedId != null && mounted) {
                      // Find the wholesaler name from the list
                      final wholesaler = widget.wholesalers.firstWhere(
                        (wh) => wh['id'] == selectedId,
                        orElse: () => {'id': selectedId, 'name': 'Unknown'},
                      );
                      setState(() {
                        _selectedWholesalerId = selectedId;
                        _selectedWholesalerName =
                            wholesaler['name'] ?? 'Unknown';
                      });
                    }
                  },
                  validator: (value) {
                    if (_selectedWholesalerId == null) {
                      return l10n.pleaseSelectWholesaler;
                    }
                    return null;
                  },
                ),
              ] else if (widget.currentUserId != null) ...[
                // For non-admin users, show current user (read-only)
                TextFormField(
                  readOnly: true,
                  decoration: InputDecoration(
                    labelText: l10n.wholesaler,
                    border: const OutlineInputBorder(),
                    helperText: l10n.yourAccount,
                  ),
                  controller: TextEditingController(
                    text: l10n.currentUser,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: l10n.unit,
                        border: const OutlineInputBorder(),
                      ),
                      initialValue: _selectedUnit,
                      items: [
                        DropdownMenuItem(value: 'unit', child: Text(l10n.unit)),
                        DropdownMenuItem(value: 'kg', child: Text(l10n.kilogram)),
                        DropdownMenuItem(value: 'g', child: Text(l10n.gram)),
                        DropdownMenuItem(value: 'L', child: Text(l10n.liter)),
                        DropdownMenuItem(
                            value: 'mL', child: Text(l10n.milliliter)),
                        DropdownMenuItem(value: 'piece', child: Text(l10n.piece)),
                        DropdownMenuItem(value: 'box', child: Text(l10n.box)),
                        DropdownMenuItem(value: 'pack', child: Text(l10n.pack)),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedUnit = value ?? 'unit');
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
                            value: 'pending', child: Text(l10n.pending)),
                        DropdownMenuItem(value: 'draft', child: Text(l10n.draft)),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value ?? 'pending');
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(l10n.useVariants),
                value: _useVariants,
                onChanged: (value) {
                  setState(() => _useVariants = value ?? false);
                },
              ),
              if (!_useVariants) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        decoration: InputDecoration(
                          labelText: l10n.priceRequired,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          // Auto-copy to cost price if cost price is empty
                          if (value.isNotEmpty &&
                              _costPriceController.text.isEmpty) {
                            _costPriceController.text = value;
                          }
                        },
                        validator: (value) {
                          if (!_useVariants) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.priceRequired;
                            }
                            final price = double.tryParse(value);
                            if (price == null || price <= 0) {
                              return l10n.pricePositive;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: InputDecoration(
                          labelText: l10n.stockRequired,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (!_useVariants) {
                            if (value == null || value.trim().isEmpty) {
                              return l10n.stockRequired;
                            }
                            final stock = int.tryParse(value);
                            if (stock == null || stock < 0) {
                              return l10n.stockNegative;
                            }
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        decoration: InputDecoration(
                          labelText: l10n.sku,
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _costPriceController,
                        decoration: InputDecoration(
                          labelText: l10n.costPrice,
                          border: const OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          // Auto-copy to price if price is empty
                          if (value.isNotEmpty &&
                              _priceController.text.isEmpty) {
                            _priceController.text = value;
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
              if (_useVariants) ...[
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      l10n.variants,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ElevatedButton.icon(
                      onPressed: _addVariant,
                      icon: const Icon(Icons.add),
                      label: Text(l10n.addVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Attribute Keys Management
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.globalAttributes,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.globalAttributesDescription,
                        style: TextStyle(
                            color: Colors.grey.shade600, fontSize: 13),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ..._attributeKeys.map((key) => Chip(
                                label: Text(key),
                                onDeleted: () => _removeAttributeKey(key),
                              )),
                          ActionChip(
                            label: Text(l10n.addAttribute),
                            avatar: const Icon(Icons.add, size: 16),
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) {
                                  final controller = TextEditingController();
                                  return AlertDialog(
                                    title: Text(l10n.addAttribute),
                                    content: TextField(
                                      controller: controller,
                                      autofocus: true,
                                      decoration: InputDecoration(
                                        labelText: l10n.attributeName,
                                        hintText: l10n.attributeNameHint,
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context),
                                        child: Text(l10n.cancel),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          _addAttributeKey(controller.text);
                                          Navigator.pop(context);
                                        },
                                        child: Text(l10n.add),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                ...List.generate(_variants.length, (index) {
                  return _VariantCard(
                    variant: _variants[index],
                    index: index,
                    attributeKeys: _attributeKeys,
                    onUpdate: (variant) => _updateVariant(index, variant),
                    onRemove: () => _removeVariant(index),
                  );
                }),
              ],
              const SizedBox(height: 16),
              // Product images (Amazon/Flipkart: first = primary, max 5, drag to reorder)
              Text(
                '${l10n.productImages} (${l10n.firstImagePrimary})',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              if (_imageSlots.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ReorderableListView.builder(
                    scrollDirection: Axis.horizontal,
                    buildDefaultDragHandles: false,
                    proxyDecorator: (child, index, animation) =>
                        Material(elevation: 4, color: Colors.transparent, child: child),
                    itemCount: _imageSlots.length + 1,
                    onReorder: (oldIndex, newIndex) {
                      if (oldIndex >= _imageSlots.length) return;
                      _reorderImages(oldIndex, newIndex);
                    },
                    itemBuilder: (context, index) {
                      if (index == _imageSlots.length) {
                        if (_imageSlots.length >= _maxProductImages) {
                          return const SizedBox(width: 0, key: ValueKey('add_hidden'));
                        }
                        return Padding(
                          key: const ValueKey('add_tile'),
                          padding: const EdgeInsets.only(right: 8),
                          child: _AddImageTile(
                            onTap: _pickingImages ? null : _pickAndUploadImages,
                            isLoading: _pickingImages,
                          ),
                        );
                      }
                      final slot = _imageSlots[index];
                      return Padding(
                        key: ValueKey(slot.id),
                        padding: const EdgeInsets.only(right: 8),
                        child: ReorderableDelayedDragStartListener(
                          index: index,
                          child: _ProductImageTile(
                            imageUrl: slot.url,
                            fileData: slot.fileData,
                            isPrimary: index == 0,
                            onRemove: () => _removeImage(index),
                          ),
                        ),
                      );
                    },
                  ),
                )
              else
                _AddImageTile(
                  key: const ValueKey('add_tile_empty'),
                  onTap: _pickingImages ? null : _pickAndUploadImages,
                  isLoading: _pickingImages,
                ),
              if (_imageSlots.length < _maxProductImages) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _urlInputController,
                        decoration: InputDecoration(
                          hintText: l10n.pasteImageUrlHint,
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        keyboardType: TextInputType.url,
                        onFieldSubmitted: (_) => _addImageFromUrl(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: _addImageFromUrl,
                      icon: const Icon(Icons.add_link, size: 18),
                      label: Text(l10n.addImageUrl),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              CheckboxListTile(
                title: Text(l10n.featuredProduct),
                value: _isFeatured,
                onChanged: (value) {
                  setState(() => _isFeatured = value ?? false);
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
                    : Text(l10n.createProduct),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AddImageTile extends StatelessWidget {
  const _AddImageTile({super.key, required this.onTap, required this.isLoading});

  final VoidCallback? onTap;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade400),
            color: Colors.grey.shade100,
          ),
          child: isLoading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.add_photo_alternate, size: 40),
        ),
      ),
    );
  }
}

class _ProductImageTile extends StatelessWidget {
  const _ProductImageTile({
    this.imageUrl,
    this.fileData,
    required this.isPrimary,
    required this.onRemove,
  }) : assert(imageUrl != null || fileData != null);

  final String? imageUrl;
  final PickedFileData? fileData;
  final bool isPrimary;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: SizedBox(
            width: 100,
            height: 100,
            child: imageUrl != null
                ? CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => Container(
                      color: Colors.grey.shade200,
                      child: const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
                  )
                : ImagePreviewWidget(
                    fileData: fileData!,
                    fit: BoxFit.cover,
                  ),
          ),
        ),
        if (isPrimary)
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 2),
              color: Colors.black54,
              child: Text(
                'Primary',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        Positioned(
          top: 4,
          right: 4,
          child: IconButton(
            icon: const Icon(Icons.close, size: 18, color: Colors.white),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black54,
              padding: const EdgeInsets.all(4),
              minimumSize: Size.zero,
            ),
            onPressed: onRemove,
          ),
        ),
        Positioned(
          bottom: 4,
          left: 4,
          child: Icon(Icons.drag_handle, color: Colors.white70, size: 20),
        ),
      ],
    );
  }
}

class _VariantCard extends StatefulWidget {
  const _VariantCard({
    required this.variant,
    required this.index,
    required this.attributeKeys,
    required this.onUpdate,
    required this.onRemove,
  });

  final ProductVariantData variant;
  final int index;
  final List<String> attributeKeys;
  final void Function(ProductVariantData) onUpdate;
  final VoidCallback onRemove;

  @override
  State<_VariantCard> createState() => _VariantCardState();
}

class _VariantCardState extends State<_VariantCard> {
  late final TextEditingController _skuController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _costPriceController;
  final Map<String, TextEditingController> _attributeControllers = {};

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.variant.sku ?? '');
    _priceController =
        TextEditingController(text: widget.variant.price.toString());
    _stockController =
        TextEditingController(text: widget.variant.stock.toString());
    _costPriceController = TextEditingController(
      text: widget.variant.costPrice?.toString() ?? '',
    );

    // Initialize attribute controllers
    for (final key in widget.attributeKeys) {
      _attributeControllers[key] = TextEditingController(
        text: widget.variant.attributes[key]?.toString() ?? '',
      );
    }
  }

  @override
  void didUpdateWidget(_VariantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Handle added/removed keys
    if (widget.attributeKeys != oldWidget.attributeKeys) {
      // Add missing controllers
      for (final key in widget.attributeKeys) {
        if (!_attributeControllers.containsKey(key)) {
          _attributeControllers[key] = TextEditingController(
            text: widget.variant.attributes[key]?.toString() ?? '',
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _skuController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _costPriceController.dispose();
    for (var controller in _attributeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateVariant() {
    final attributes = <String, dynamic>{...widget.variant.attributes};

    // Update attributes from controllers
    for (final key in widget.attributeKeys) {
      if (_attributeControllers.containsKey(key)) {
        final value = _attributeControllers[key]!.text.trim();
        if (value.isNotEmpty) {
          attributes[key] = value;
        } else {
          attributes.remove(key);
        }
      }
    }

    widget.onUpdate(
      widget.variant.copyWith(
        sku: _skuController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0,
        stock: int.tryParse(_stockController.text) ?? 0,
        costPrice: _costPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_costPriceController.text),
        attributes: attributes,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${l10n.variant} ${widget.index + 1}${widget.variant.isDefault ? ' (${l10n.default_})' : ''}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: [
                    Checkbox(
                      value: widget.variant.isDefault,
                      onChanged: (value) {
                        widget.onUpdate(
                          widget.variant.copyWith(isDefault: value ?? false),
                        );
                      },
                    ),
                    Text(l10n.default_),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: widget.onRemove,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Attribute Inputs
            if (widget.attributeKeys.isNotEmpty) ...[
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: widget.attributeKeys.map((key) {
                  return SizedBox(
                    width: (MediaQuery.of(context).size.width - 80) /
                        2, // 2 columns approx
                    child: TextFormField(
                      controller: _attributeControllers[key],
                      decoration: InputDecoration(
                        labelText: key,
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (_) => _updateVariant(),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Divider(),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _skuController,
              decoration: InputDecoration(
                labelText: l10n.skuRequired,
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => _updateVariant(),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _priceController,
                    decoration: InputDecoration(
                      labelText: l10n.priceRequired,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateVariant(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _stockController,
                    decoration: InputDecoration(
                      labelText: l10n.stockRequired,
                      border: const OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    onChanged: (_) => _updateVariant(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _costPriceController,
              decoration: InputDecoration(
                labelText: l10n.costPrice,
                border: const OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              onChanged: (_) => _updateVariant(),
            ),
          ],
        ),
      ),
    );
  }
}
