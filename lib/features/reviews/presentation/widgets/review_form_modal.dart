import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/review_models.dart';
import '../../data/repositories/review_repository.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/services/image_picker_helper.dart';
import '../../../../core/widgets/image_preview_widget.dart';
import 'rating_widget.dart';

class ReviewFormModal extends ConsumerStatefulWidget {
  const ReviewFormModal({
    super.key,
    required this.productId,
    required this.orderId,
    this.orderItemId,
    this.existingReview,
  });

  final String productId;
  final String orderId;
  final String? orderItemId;
  final Review? existingReview;

  @override
  ConsumerState<ReviewFormModal> createState() => _ReviewFormModalState();
}

class _ReviewFormModalState extends ConsumerState<ReviewFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _commentController = TextEditingController();
  int? _selectedRating;
  bool _isSubmitting = false;
  final List<PickedFileData> _selectedImages = [];
  List<String> _uploadedImageUrls = [];
  bool _isUploadingImages = false;

  @override
  void initState() {
    super.initState();
    if (widget.existingReview != null) {
      _selectedRating = widget.existingReview!.rating;
      _titleController.text = widget.existingReview!.title ?? '';
      _commentController.text = widget.existingReview!.comment ?? '';
      _uploadedImageUrls = List<String>.from(widget.existingReview!.images);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    try {
      final imageData = await ImagePickerHelper.pickImage();
      if (imageData != null && _selectedImages.length < 5) {
        setState(() {
          _selectedImages.add(imageData);
        });
      } else if (_selectedImages.length >= 5) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                AppLocalizations.of(context)?.maximum5ImagesAllowed ??
                    'Maximum 5 images allowed',
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)?.failedToPickImage ?? 'Failed to pick image'}: $e',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _removeImage(int index) async {
    setState(() {
      if (index < _selectedImages.length) {
        _selectedImages.removeAt(index);
      } else {
        final urlIndex = index - _selectedImages.length;
        if (urlIndex < _uploadedImageUrls.length) {
          _uploadedImageUrls.removeAt(urlIndex);
        }
      }
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() => _isUploadingImages = true);

    try {
      final uploadService = ref.read(uploadServiceProvider);
      final uploadedUrls = <String>[];

      for (final imageData in _selectedImages) {
        try {
          final url = await uploadService.uploadFile(
            fileData: imageData,
            folder: 'reviews',
          );
          uploadedUrls.add(url);
        } catch (e) {
          debugPrint('Failed to upload image: $e');
          // Continue with other images
        }
      }

      setState(() {
        _uploadedImageUrls.addAll(uploadedUrls);
        _selectedImages.clear();
        _isUploadingImages = false;
      });
    } catch (e) {
      setState(() => _isUploadingImages = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '${l10n?.failedToUploadImages ?? 'Failed to upload images'}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRating == null) {
      final l10n = AppLocalizations.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text(l10n?.pleaseSelectRating ?? 'Please select a rating')),
      );
      return;
    }

    // Upload any pending images first
    if (_selectedImages.isNotEmpty) {
      await _uploadImages();
    }

    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(reviewRepositoryProvider);

      if (widget.existingReview != null) {
        // Update existing review
        await repo.updateReview(
          reviewId: widget.existingReview!.id,
          rating: _selectedRating,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          images: _uploadedImageUrls.isNotEmpty ? _uploadedImageUrls : null,
        );
      } else {
        // Create new review
        await repo.createReview(
          productId: widget.productId,
          orderId: widget.orderId,
          orderItemId: widget.orderItemId,
          rating: _selectedRating!,
          title: _titleController.text.trim().isEmpty
              ? null
              : _titleController.text.trim(),
          comment: _commentController.text.trim().isEmpty
              ? null
              : _commentController.text.trim(),
          images: _uploadedImageUrls.isNotEmpty ? _uploadedImageUrls : null,
        );
      }

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        Navigator.of(context).pop(true); // Return true to indicate success
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingReview != null
                ? (l10n?.reviewUpdatedSuccessfully ??
                    'Review updated successfully')
                : (l10n?.reviewSubmittedSuccessfully ??
                    'Review submitted successfully')),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${l10n?.error ?? 'Error'}: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final isEditing = widget.existingReview != null;

    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      isEditing ? 'Edit Review' : 'Write a Review',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(),
            // Form
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Rating selector
                      Text(
                        'Rating *',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: RatingSelector(
                          initialRating: _selectedRating,
                          onRatingChanged: (rating) {
                            setState(() {
                              _selectedRating = rating;
                            });
                          },
                        ),
                      ),
                      const SizedBox(height: 24),
                      // Title
                      TextFormField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          labelText: l10n?.titleOptional,
                          hintText: l10n?.giveReviewTitle,
                          border: const OutlineInputBorder(),
                        ),
                        maxLength: 200,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      // Comment
                      TextFormField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          labelText: l10n?.yourReviewOptional,
                          hintText: l10n?.shareExperienceWithProduct,
                          border: const OutlineInputBorder(),
                          alignLabelWithHint: true,
                        ),
                        maxLines: 5,
                        maxLength: 2000,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      const SizedBox(height: 16),
                      // Images section
                      Text(
                        'Images (Optional)',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Selected images preview
                      if (_selectedImages.isNotEmpty ||
                          _uploadedImageUrls.isNotEmpty)
                        SizedBox(
                          height: 100,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _selectedImages.length +
                                _uploadedImageUrls.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, index) {
                              if (index < _selectedImages.length) {
                                // Local file preview
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: ImagePreviewWidget(
                                        fileData: _selectedImages[index],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        color: Colors.white,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                          padding: const EdgeInsets.all(4),
                                        ),
                                        onPressed: () => _removeImage(index),
                                      ),
                                    ),
                                  ],
                                );
                              } else {
                                // Uploaded URL preview
                                final urlIndex = index - _selectedImages.length;
                                return Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: CachedNetworkImage(
                                        imageUrl: _uploadedImageUrls[urlIndex],
                                        width: 100,
                                        height: 100,
                                        fit: BoxFit.cover,
                                        placeholder: (_, __) => Container(
                                          width: 100,
                                          height: 100,
                                          color:
                                              theme.colorScheme.surfaceContainerHighest,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        ),
                                        errorWidget: (_, __, ___) => Container(
                                          width: 100,
                                          height: 100,
                                          color:
                                              theme.colorScheme.surfaceContainerHighest,
                                          child: const Icon(Icons.broken_image),
                                        ),
                                      ),
                                    ),
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: IconButton(
                                        icon: const Icon(Icons.close, size: 20),
                                        color: Colors.white,
                                        style: IconButton.styleFrom(
                                          backgroundColor: Colors.black54,
                                          padding: const EdgeInsets.all(4),
                                        ),
                                        onPressed: () => _removeImage(index),
                                      ),
                                    ),
                                  ],
                                );
                              }
                            },
                          ),
                        ),
                      // Add image button
                      if ((_selectedImages.length + _uploadedImageUrls.length) <
                          5)
                        OutlinedButton.icon(
                          onPressed: _isUploadingImages ? null : _pickImages,
                          icon: _isUploadingImages
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Icon(Icons.add_photo_alternate),
                          label: Text(
                            _isUploadingImages
                                ? 'Uploading...'
                                : 'Add Image (${_selectedImages.length + _uploadedImageUrls.length}/5)',
                          ),
                        ),
                      if (_selectedImages.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: FilledButton.icon(
                            onPressed:
                                _isUploadingImages ? null : _uploadImages,
                            icon: _isUploadingImages
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  )
                                : const Icon(Icons.cloud_upload),
                            label: Builder(
                              builder: (context) {
                                final l10n = AppLocalizations.of(context);
                                return Text(
                                    l10n?.uploadImages ?? 'Upload Images');
                              },
                            ),
                          ),
                        ),
                      const SizedBox(height: 24),
                      // Submit button
                      FilledButton(
                        onPressed: _isSubmitting ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                isEditing ? 'Update Review' : 'Submit Review'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
