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

import '../widgets/create_product_modal.dart' show ProductVariantData, ProductImageSlot;
import '../../../manager/presentation/screens/select_category_screen.dart';
import 'dart:convert';

class EditProductData {
  EditProductData({
    this.title,
    this.description,
    this.categoryId,
    this.categoryIds,
    this.price,
    this.stock,
    this.unit,
    this.sku,
    this.costPrice,
    this.status,
    this.imageUrl,
    this.images = const [],
    this.isFeatured,
    this.variants = const [],
  });

  final dynamic title; // String or Map<String, String>
  final dynamic description; // String or Map<String, String>
  final String? categoryId; // Legacy
  final List<String>? categoryIds;
  final double? price;
  final int? stock;
  final String? unit;
  final String? sku;
  final double? costPrice;
  final String? status;
  final String? imageUrl;
  final List<String> images;
  final bool? isFeatured;
  final List<ProductVariantData>? variants;

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};

    if (title != null) {
      json['title'] = title;
    }
    if (description != null) {
      json['description'] = description;
    }
    if (categoryIds != null && categoryIds!.isNotEmpty) {
      json['categoryIds'] = categoryIds;
    } else if (categoryId != null) {
      json['categoryId'] = categoryId;
    }
    if (unit != null) json['unit'] = unit;
    if (status != null) json['status'] = status;
    if (imageUrl != null) json['imageUrl'] = imageUrl;
    if (images.isNotEmpty) json['images'] = images;
    if (isFeatured != null) json['isFeatured'] = isFeatured;

    if (variants != null && variants!.isNotEmpty) {
      json['variants'] = variants!.map((v) {
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
      if (sku != null) json['sku'] = sku;
      if (costPrice != null) json['costPrice'] = costPrice;
    }

    return json;
  }
}

class EditProductModal extends ConsumerStatefulWidget {
  const EditProductModal({
    super.key,
    required this.product,
    required this.onSave,
    this.categories = const [],
    this.canChangeStatus = false,
  });

  final Map<String, dynamic> product;
  final Future<void> Function(EditProductData) onSave;
  final List<Map<String, String>> categories;
  final bool canChangeStatus; // Only admin can change status

  @override
  ConsumerState<EditProductModal> createState() => _EditProductModalState();
}

class _EditProductModalState extends ConsumerState<EditProductModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;
  late final TextEditingController _skuController;
  late final TextEditingController _costPriceController;
  late final TextEditingController _urlInputController;

  List<String> _selectedCategoryIds = [];
  List<Map<String, dynamic>> _selectedCategories = [];
  String _selectedUnit = 'unit';
  String _selectedStatus = 'pending';
  bool _isFeatured = false;
  bool _useVariants = false;
  bool _isLoading = false;
  String? _error;
  final List<ProductImageSlot> _imageSlots = [];
  final List<Future<void>> _uploadFutures = [];
  bool _pickingImages = false;
  static const int _maxProductImages = 5;

  List<ProductVariantData> _variants = [];
  final List<String> _attributeKeys = [];

  String _currentLanguage = 'en';
  final Map<String, String> _titleMap = {};
  final Map<String, String> _descriptionMap = {};
  final List<String> _supportedLanguages = AppLanguages.contentSourceLanguages;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    debugPrint('Edit Product: ${jsonEncode(product)}');

    // Initialize multilingual Title
    if (product['title'] is Map) {
      final map = Map<String, dynamic>.from(product['title'] as Map);
      map.forEach((key, value) => _titleMap[key] = value?.toString() ?? '');
    } else {
      String raw = product['title']?.toString() ?? '';
      // Recovery for malformed string maps "{en: Text, de: Text}"
      if (raw.startsWith('{') && raw.contains('en:')) {
        final enMatch =
            RegExp(r'en:\s*(.*?)(?:,\s*[a-z]{2}:|}$)').firstMatch(raw);
        if (enMatch != null) {
          _titleMap['en'] = enMatch.group(1)?.trim() ?? raw;
          // Try to extract others if possible, or just accept we losing some data on edit
          final deMatch =
              RegExp(r'de:\s*(.*?)(?:,\s*[a-z]{2}:|}$)').firstMatch(raw);
          if (deMatch != null) _titleMap['de'] = deMatch.group(1)?.trim() ?? '';
        } else {
          _titleMap['en'] = raw;
        }
      } else {
        _titleMap['en'] = raw;
      }
    }

    // Initialize multilingual Description
    if (product['description'] is Map) {
      final map = Map<String, dynamic>.from(product['description'] as Map);
      map.forEach(
          (key, value) => _descriptionMap[key] = value?.toString() ?? '');
    } else {
      String raw = product['description']?.toString() ?? '';
      if (raw.startsWith('{') && raw.contains('en:')) {
        final enMatch =
            RegExp(r'en:\s*(.*?)(?:,\s*[a-z]{2}:|}$)').firstMatch(raw);
        if (enMatch != null) {
          _descriptionMap['en'] = enMatch.group(1)?.trim() ?? raw;
          final deMatch =
              RegExp(r'de:\s*(.*?)(?:,\s*[a-z]{2}:|}$)').firstMatch(raw);
          if (deMatch != null) {
            _descriptionMap['de'] = deMatch.group(1)?.trim() ?? '';
          }
        } else {
          _descriptionMap['en'] = raw;
        }
      } else {
        _descriptionMap['en'] = raw;
      }
    }

    _titleController = TextEditingController(text: _titleMap[_currentLanguage]);
    _descriptionController =
        TextEditingController(text: _descriptionMap[_currentLanguage]);

    // Listeners to update the map as user types
    _titleController.addListener(() {
      _titleMap[_currentLanguage] = _titleController.text;
    });
    _descriptionController.addListener(() {
      _descriptionMap[_currentLanguage] = _descriptionController.text;
    });

    _priceController =
        TextEditingController(text: product['price']?.toString() ?? '');
    _stockController =
        TextEditingController(text: product['stock']?.toString() ?? '');
    _skuController =
        TextEditingController(text: product['sku']?.toString() ?? '');
    _costPriceController =
        TextEditingController(text: product['costPrice']?.toString() ?? '');
    _urlInputController = TextEditingController();

    // Initialize images: prefer images[] array, fallback to imageUrl
    List<String> initialUrls = [];
    if (product['images'] is List && (product['images'] as List).isNotEmpty) {
      initialUrls = (product['images'] as List)
          .map((e) => e?.toString() ?? '')
          .where((s) => s.isNotEmpty)
          .toList();
    } else if (product['imageUrl']?.toString().trim().isNotEmpty == true) {
      initialUrls = [product['imageUrl'].toString().trim()];
    }
    for (var i = 0; i < initialUrls.length; i++) {
      _imageSlots.add(ProductImageSlot(id: 'edit_${i}_${initialUrls[i].hashCode}', url: initialUrls[i]));
    }

    // Support both categoryIds (multi) and categoryId/category (single)
    final ids = product['categoryIds'];
    if (ids is List && ids.isNotEmpty) {
      _selectedCategoryIds =
          ids.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList();
      for (final id in _selectedCategoryIds) {
        final cat = widget.categories.cast<Map<String, dynamic>>().firstWhere(
              (c) => c['id']?.toString() == id,
              orElse: () => {'id': id, 'name': 'Unknown'},
            );
        _selectedCategories.add(cat);
      }
    } else {
      final catVal = product['category'];
      String? catId = product['categoryId']?.toString();
      if (catId == null && catVal is Map) {
        catId = catVal['_id']?.toString() ?? catVal['id']?.toString();
      }
      catId ??= product['category']?.toString();
      if (catId != null && catId.isNotEmpty) {
        _selectedCategoryIds = [catId];
        final category = widget.categories.cast<Map<String, dynamic>>().firstWhere(
              (cat) => cat['id'] == catId,
              orElse: () => {'id': catId, 'name': 'Unknown Category'},
            );
        _selectedCategories = [category];
      }
    }
    _selectedUnit = product['unit']?.toString() ?? 'unit';
    _selectedStatus = product['status']?.toString() ?? 'pending';
    _isFeatured = product['isFeatured'] == true;

    // Check if product has variants - only set _useVariants if variants actually exist and are not empty
    final variantsList = product['variants'];
    if (variantsList is List && variantsList.isNotEmpty) {
      _useVariants = true;
      _variants = variantsList.map((v) {
        return ProductVariantData(
          sku: v['sku']?.toString(),
          attributes: Map<String, dynamic>.from(v['attributes'] ?? {}),
          price: (v['price'] as num?)?.toDouble() ?? 0,
          costPrice: (v['costPrice'] as num?)?.toDouble(),
          stock: (v['stock'] as num?)?.toInt() ?? 0,
          reservedStock: (v['reservedStock'] as num?)?.toInt() ?? 0,
          images: (v['images'] as List<dynamic>?)
                  ?.map((e) => e.toString())
                  .toList() ??
              [],
          isDefault: v['isDefault'] == true,
        );
      }).toList();

      // Extract attribute keys from variants
      if (_variants.isNotEmpty) {
        final keys = <String>{};
        for (var variant in _variants) {
          keys.addAll(variant.attributes.keys);
        }
        _attributeKeys.addAll(keys);
      }
    } else {
      // Explicitly set to false if no variants exist
      _useVariants = false;
      _variants = [];
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
        final slotId = 'edit_img_${DateTime.now().millisecondsSinceEpoch}_${_imageSlots.length}';
        final slot = ProductImageSlot(id: slotId, fileData: imageData);
        setState(() => _imageSlots.add(slot));

        final future = _uploadSlot(slot);
        _uploadFutures.add(future);
        future.whenComplete(() => _uploadFutures.remove(future));
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
      _imageSlots.add(ProductImageSlot(id: 'edit_url_${DateTime.now().millisecondsSinceEpoch}', url: url));
      _urlInputController.clear();
    });
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Wait for any in-flight image uploads before submit
      if (_uploadFutures.isNotEmpty) {
        await Future.wait(List<Future<void>>.from(_uploadFutures));
      }
      // Upload any slots still with fileData
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
      final images = _imageSlots
          .where((s) => s.url != null)
          .map((s) => s.url!)
          .toList();
      final firstUrl = images.isNotEmpty ? images.first : null;

      final data = EditProductData(
        title: _titleMap,
        description: _descriptionMap,
        categoryIds: _selectedCategoryIds.isNotEmpty ? _selectedCategoryIds : null,
        price: _useVariants ? null : double.tryParse(_priceController.text),
        stock: _useVariants ? null : int.tryParse(_stockController.text),
        unit: _selectedUnit,
        sku: _skuController.text.trim().isEmpty
            ? null
            : _skuController.text.trim(),
        costPrice: _costPriceController.text.trim().isEmpty
            ? null
            : double.tryParse(_costPriceController.text),
        status: widget.canChangeStatus
            ? _selectedStatus
            : null, // Only send status if admin
        imageUrl: firstUrl,
        images: images,
        isFeatured: _isFeatured,
        variants: _useVariants ? _variants : null,
      );

      try {
        await widget.onSave(data);
        // Only close modal on success
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(
                    AppLocalizations.of(context)!.productUpdatedSuccessfully)),
          );
        }
      } catch (saveError) {
        // Re-throw to outer catch block
        rethrow;
      }
    } catch (e, stackTrace) {
      // Keep modal open on error so user doesn't lose data
      debugPrint('EditProduct error caught - keeping modal open: $e');
      debugPrint('Stack trace: $stackTrace');

      // Use localized error handling if possible, for now keeping generic or context-aware if possible
      // But since we are in a catch block without easy access to context for translation in pure logic,
      // we might need to rely on the error message itself or generic errors.
      // However, below we set _error which is displayed in UI.
      String errorMessage =
          'Failed to update product'; // Fallback if no context
      if (mounted) {
        errorMessage = AppLocalizations.of(context)!.validationError;
      }
      if (e.toString().contains('Validation failed')) {
        try {
          final errorStr = e.toString();
          if (errorStr.contains('fieldErrors')) {
            if (mounted) {
              errorMessage =
                  '${AppLocalizations.of(context)!.validationError}: ${AppLocalizations.of(context)!.checkAllFields}';
            }
          } else {
            if (mounted) {
              errorMessage =
                  '${AppLocalizations.of(context)!.validationError}: ${e.toString()}';
            }
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
                    l10n.editProduct,
                    style: TextStyle(
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
                const SizedBox(height: 16),
              ],
              // Language Selector
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _supportedLanguages.map((lang) {
                    final isSelected = lang == _currentLanguage;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
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
                  labelText: '${l10n.productTitle} *',
                  border: const OutlineInputBorder(),
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
                    helperText: l10n.tapToSelectCategory,
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
                  // Only show status field if user can change it (admin only)
                  if (widget.canChangeStatus) ...[
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
                          DropdownMenuItem(
                              value: 'approved', child: Text(l10n.approved)),
                          DropdownMenuItem(
                              value: 'rejected', child: Text(l10n.rejected)),
                          DropdownMenuItem(
                              value: 'draft', child: Text(l10n.draft)),
                        ],
                        onChanged: (value) {
                          setState(() => _selectedStatus = value ?? 'pending');
                        },
                      ),
                    ),
                  ],
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
                          labelText: l10n.price,
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
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        decoration: InputDecoration(
                          labelText: l10n.stock,
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
                      style: TextStyle(
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
                          return const SizedBox(width: 0, key: ValueKey('edit_add_hidden'));
                        }
                        return Padding(
                          key: const ValueKey('edit_add_tile'),
                          padding: const EdgeInsets.only(right: 8),
                          child: _EditAddImageTile(
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
                          child: _EditProductImageTile(
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
                _EditAddImageTile(
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
                    : Text(l10n.updateProduct),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditAddImageTile extends StatelessWidget {
  const _EditAddImageTile({required this.onTap, required this.isLoading});

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

class _EditProductImageTile extends StatelessWidget {
  const _EditProductImageTile({
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
                  'Variant ${widget.index + 1}${widget.variant.isDefault ? ' (Default)' : ''}',
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
                    Text(l10n.defaultVariant),
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
                    onChanged: (value) {
                      _updateVariant();
                      // Auto-copy to cost price if cost price is empty
                      if (value.isNotEmpty &&
                          _costPriceController.text.isEmpty) {
                        _costPriceController.text = value;
                        _updateVariant();
                      }
                    },
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
              onChanged: (value) {
                _updateVariant();
                // Auto-copy to price if price is empty
                if (value.isNotEmpty && _priceController.text.isEmpty) {
                  _priceController.text = value;
                  _updateVariant();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
