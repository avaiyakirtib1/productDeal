import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/services/image_picker_helper.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/widgets/image_preview_widget.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/story_repository.dart';
import '../../../manager/presentation/screens/select_product_screen.dart';
import '../../../manager/presentation/screens/select_deal_screen.dart';
import '../../../manager/data/repositories/manager_repository.dart';

class CreateStoryScreen extends ConsumerStatefulWidget {
  const CreateStoryScreen({super.key});

  static const routePath = '/stories/create';
  static const routeName = 'createStory';

  @override
  ConsumerState<CreateStoryScreen> createState() => _CreateStoryScreenState();
}

class _CreateStoryScreenState extends ConsumerState<CreateStoryScreen> {
  final _formKey = GlobalKey<FormState>();

  PickedFileData? _mediaFile;
  bool _isVideo = false;
  String? _selectedProductId;
  String? _selectedProductName; // Store name for display
  String? _selectedDealId;
  String? _selectedDealName; // Store name for display
  DateTime _expiresAt = DateTime.now().add(const Duration(hours: 24));

  bool _isLoading = false;
  bool _isUploading = false;

  Future<void> _pickMedia(bool isVideo) async {
    try {
      final PickedFileData? fileData;

      if (isVideo) {
        fileData = await ImagePickerHelper.pickVideo();
      } else {
        fileData = await ImagePickerHelper.pickImage(
          maxWidth: 1080,
          maxHeight: 1920,
          imageQuality: 85,
        );
      }

      if (fileData != null) {
        setState(() {
          _mediaFile = fileData;
          _isVideo = isVideo;
        });
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToPickMedia ?? 'Failed to pick media'}: $e',
        );
      }
    }
  }

  Future<String> _uploadToSupabase(PickedFileData fileData) async {
    try {
      final dio = ref.read(dioProvider);
      final filename = fileData.filename;
      final contentType = _isVideo ? 'video/mp4' : 'image/jpeg';

      // Step 1: Get presigned upload URL from backend
      final urlResponse =
          await dio.get('/upload/presigned-url', queryParameters: {
        'filename': filename,
        'contentType': contentType,
        'folder': 'stories',
      });

      final uploadUrl = urlResponse.data['data']['uploadUrl'] as String;
      final publicUrl = urlResponse.data['data']['publicUrl'] as String;

      // Step 2: Upload file directly to Supabase
      final fileBytes = fileData.isWeb
          ? Uint8List.fromList(fileData.bytes!)
          : await fileData.fileAsFile.readAsBytes();
      await dio.put(
        uploadUrl,
        data: fileBytes,
        options: Options(
          headers: {
            'Content-Type': contentType,
            'x-upsert': 'false',
          },
        ),
      );

      return publicUrl;
    } catch (e) {
      throw Exception('Upload failed: $e');
    }
  }

  Future<void> _submitStory() async {
    if (!_formKey.currentState!.validate()) return;

    if (_mediaFile == null) {
      SnackbarUtils.showError(
        context,
        AppLocalizations.of(context)?.pleaseSelectImageOrVideo ??
            'Please select an image or video',
      );
      return;
    }

    final authState = ref.read(authControllerProvider);
    final session = authState.valueOrNull;

    if (session == null || session.user.role != UserRole.wholesaler) {
      SnackbarUtils.showError(
        context,
        AppLocalizations.of(context)?.onlyWholesalersCanCreateStories ??
            'Only wholesalers can create stories',
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploading = true;
    });

    try {
      // Step 1: Upload media to Supabase Storage
      final mediaUrl = await _uploadToSupabase(_mediaFile!);

      setState(() => _isUploading = false);

      // Step 2: Create story via API
      final repo = ref.read(storyRepositoryProvider);
      await repo.createStory(
        wholesalerId: session.user.id,
        mediaUrl: mediaUrl,
        thumbnailUrl: mediaUrl,
        // Use same URL for thumbnail
        isVideo: _isVideo,
        expiresAt: _expiresAt.toIso8601String(),
        productId: _selectedProductId,
        dealId: _selectedDealId,
      );

      if (mounted) {
        SnackbarUtils.showSuccess(
          context,
          AppLocalizations.of(context)?.storyCreatedSuccessfully ??
              'Story created successfully! 🎉',
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToCreateStory ?? 'Failed to create story'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.createStory ?? 'Create Story');
          },
        ),
        actions: [
          if (!_isLoading)
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return TextButton(
                  onPressed: _submitStory,
                  child: Text(
                    l10n?.post ?? 'Post',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                );
              },
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Media Picker
            _buildMediaPicker(theme),

            const SizedBox(height: 24),

            // Product Linking (Optional)
            _buildProductSelection(context, theme),

            const SizedBox(height: 16),

            // Deal Linking (Optional)
            _buildDealSelection(context, theme),

            const SizedBox(height: 16),

            // Expiry Time
            _buildExpirySelection(theme),

            const SizedBox(height: 32),

            // Submit Button
            if (_isLoading)
              Center(
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isUploading
                          ? (AppLocalizations.of(context)?.uploadingMedia ??
                              'Uploading media...')
                          : (AppLocalizations.of(context)?.creatingStory ??
                              'Creating story...'),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              )
            else
              FilledButton(
                onPressed: _submitStory,
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  AppLocalizations.of(context)?.createStory ?? 'Create Story',
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMediaPicker(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              AppLocalizations.of(context)?.storyMedia ?? 'Story Media',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_mediaFile != null) ...[
              // Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: AspectRatio(
                  aspectRatio: 9 / 16,
                  child: _isVideo
                      ? Container(
                          color: Colors.black,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_outline,
                                    size: 64, color: Colors.white),
                                const SizedBox(height: 8),
                                Text(
                                  AppLocalizations.of(context)
                                          ?.videoSelected ??
                                      'Video selected',
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ImagePreviewWidget(
                          fileData: _mediaFile!,
                          fit: BoxFit.cover,
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return OutlinedButton.icon(
                    onPressed: () => setState(() => _mediaFile = null),
                    icon: const Icon(Icons.close),
                    label: Text(l10n?.remove ?? 'Remove'),
                  );
                },
              ),
            ] else ...[
              // Picker buttons
              Row(
                children: [
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return OutlinedButton.icon(
                          onPressed: () => _pickMedia(false),
                          icon: const Icon(Icons.image),
                          label: Text(l10n?.pickImage ?? 'Pick Image'),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return OutlinedButton.icon(
                          onPressed: () => _pickMedia(true),
                          icon: const Icon(Icons.videocam),
                          label: Text(l10n?.pickVideo ?? 'Pick Video'),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.selectImageOrVideoForStory ??
                        'Select an image or video for your story',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildProductSelection(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.shopping_bag, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Link Product (Optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: l10n?.productToPromoteHint ?? 'product to promote',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                helperText: 'Tap to select a product (optional)',
              ),
              controller: TextEditingController(
                text: _selectedProductName ?? 'None',
              ),
              onTap: () async {
                final selectedId = await context.push<String>(
                  SelectProductScreen.routePath,
                  extra: {
                    'selectedProductId': _selectedProductId,
                  },
                );
                if (mounted) {
                  if (selectedId != null) {
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
                        _selectedDealId =
                            null; // Clear deal if product selected
                        _selectedDealName = null;
                      });
                    } catch (e) {
                      // If fetch fails, just use the ID
                      setState(() {
                        _selectedProductId = selectedId;
                        _selectedProductName = 'Product $selectedId';
                        _selectedDealId = null;
                        _selectedDealName = null;
                      });
                    }
                  } else {
                    // User selected "None" or cancelled
                    setState(() {
                      _selectedProductId = null;
                      _selectedProductName = null;
                    });
                  }
                }
              },
            ),
            if (_selectedProductId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Users will see a product card in your story',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDealSelection(BuildContext context, ThemeData theme) {
    final l10n = AppLocalizations.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_offer, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Link Deal (Optional)',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                hintText: l10n?.selectDealToPromote ?? 'Select a deal to promote',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                helperText: 'Tap to select a deal (optional)',
              ),
              controller: TextEditingController(
                text: _selectedDealName ?? 'None',
              ),
              onTap: () async {
                final selectedId = await context.push<String>(
                  SelectDealScreen.routePath,
                  extra: {
                    'selectedDealId': _selectedDealId,
                  },
                );
                if (mounted) {
                  if (selectedId != null) {
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
                        _selectedProductId =
                            null; // Clear product if deal selected
                        _selectedProductName = null;
                      });
                    } catch (e) {
                      // If fetch fails, just use the ID
                      setState(() {
                        _selectedDealId = selectedId;
                        _selectedDealName = 'Deal $selectedId';
                        _selectedProductId = null;
                        _selectedProductName = null;
                      });
                    }
                  } else {
                    // User selected "None" or cancelled
                    setState(() {
                      _selectedDealId = null;
                      _selectedDealName = null;
                    });
                  }
                }
              },
            ),
            if (_selectedDealId != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.secondaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Users will see a deal card in your story',
                        style: theme.textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildExpirySelection(ThemeData theme) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Story Duration',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(l10n?.expiresAt ?? 'Expires at'),
                  subtitle: Text(
                    '${_expiresAt.day}/${_expiresAt.month}/${_expiresAt.year} at ${_expiresAt.hour.toString().padLeft(2, '0')}:${_expiresAt.minute.toString().padLeft(2, '0')}',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  trailing: OutlinedButton(
                    onPressed: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: _expiresAt,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 30)),
                      );

                      if (date != null && context.mounted) {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.fromDateTime(_expiresAt),
                        );

                        if (time != null && context.mounted) {
                          setState(() {
                            _expiresAt = DateTime(
                              date.year,
                              date.month,
                              date.day,
                              time.hour,
                              time.minute,
                            );
                          });
                        }
                      }
                    },
                    child: Text(l10n?.change ?? 'Change'),
                  ),
                );
              },
            ),
            const SizedBox(height: 8),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return Wrap(
                  spacing: 8,
                  children: [
                    _DurationChip(
                      label: l10n?.twentyFourHours ?? '24 hours',
                      selected: _isDefaultDuration(24),
                      onTap: () => _setDuration(24),
                    ),
                    _DurationChip(
                      label: l10n?.twelveHours ?? '12 hours',
                      selected: _isDefaultDuration(12),
                      onTap: () => _setDuration(12),
                    ),
                    _DurationChip(
                      label: l10n?.sixHours ?? '6 hours',
                      selected: _isDefaultDuration(6),
                      onTap: () => _setDuration(6),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isDefaultDuration(int hours) {
    final target = DateTime.now().add(Duration(hours: hours));
    return (_expiresAt.difference(target).abs().inMinutes < 5);
  }

  void _setDuration(int hours) {
    setState(() {
      _expiresAt = DateTime.now().add(Duration(hours: hours));
    });
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}
