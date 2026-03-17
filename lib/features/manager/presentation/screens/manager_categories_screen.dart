import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/networking/api_client.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/services/upload_service.dart';
import '../../../../core/services/image_picker_helper.dart';
import '../../../../core/widgets/image_preview_widget.dart';
import '../../../../core/constants/app_languages.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/repositories/manager_repository.dart';

final managerCategoriesSearchProvider =
    StateProvider<String>((ref) => '');

final managerCategoriesProvider = AsyncNotifierProvider.autoDispose<
    ManagerCategoriesNotifier,
    ManagerCategoriesState>(ManagerCategoriesNotifier.new);

class ManagerCategoriesState {
  final List<Map<String, dynamic>> items;
  final int total;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final String? search;

  ManagerCategoriesState({
    required this.items,
    required this.total,
    required this.page,
    required this.hasMore,
    this.isLoadingMore = false,
    this.search,
  });

  ManagerCategoriesState copyWith({
    List<Map<String, dynamic>>? items,
    int? total,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    String? search,
  }) {
    return ManagerCategoriesState(
      items: items ?? this.items,
      total: total ?? this.total,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      search: search ?? this.search,
    );
  }
}

class ManagerCategoriesNotifier
    extends AutoDisposeAsyncNotifier<ManagerCategoriesState> {
  static const int _limit = 20;

  @override
  FutureOr<ManagerCategoriesState> build() async {
    final search = ref.watch(managerCategoriesSearchProvider).trim();
    final searchArg = search.isEmpty ? null : search;
    return _fetchPage(1, searchArg);
  }

  Future<ManagerCategoriesState> _fetchPage(int page, [String? search]) async {
    final dio = ref.read(dioProvider);
    final params = <String, dynamic>{'page': page, 'limit': _limit};
    if (search != null && search.trim().isNotEmpty) {
      params['search'] = search.trim();
    }
    final response = await dio.get<Map<String, dynamic>>(
      '/admin/categories',
      queryParameters: params,
    );
    final data = response.data?['data'] as List<dynamic>? ?? [];
    final items = data.cast<Map<String, dynamic>>();
    final meta = response.data?['meta'] as Map<String, dynamic>?;
    final total =
        meta?['totalRows'] as int? ?? items.length; // Fallback if no meta

    return ManagerCategoriesState(
      items: items,
      total: total,
      page: page,
      hasMore: items.length == _limit,
      search: search?.trim().isEmpty == true ? null : search?.trim(),
    );
  }

  Future<void> loadMore(String? search) async {
    final currentState = state.value;
    if (currentState == null ||
        !currentState.hasMore ||
        currentState.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true));

    try {
      final nextPage = currentState.page + 1;
      final dio = ref.read(dioProvider);
      final params = <String, dynamic>{'page': nextPage, 'limit': _limit};
      if (search != null && search.trim().isNotEmpty) {
        params['search'] = search.trim();
      }
      final response = await dio.get<Map<String, dynamic>>(
        '/admin/categories',
        queryParameters: params,
      );

      final data = response.data?['data'] as List<dynamic>? ?? [];
      final newItems = data.cast<Map<String, dynamic>>();

      // Update state with new items appended
      state = AsyncValue.data(currentState.copyWith(
        items: [...currentState.items, ...newItems],
        page: nextPage,
        hasMore: newItems.length == _limit,
        isLoadingMore: false,
      ));
    } catch (e, _) {
      // If load more fails, revert loading flag but keep existing data
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false));
      // Optionally could handle error state specifically for pagination error
    }
  }

  Future<void> refresh() async {
    final search = ref.read(managerCategoriesSearchProvider).trim();
    final searchArg = search.isEmpty ? null : search;
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchPage(1, searchArg));
  }
}

class ManagerCategoriesScreen extends ConsumerStatefulWidget {
  const ManagerCategoriesScreen({super.key});

  static const routePath = '/manager/categories';
  static const routeName = 'managerCategories';

  @override
  ConsumerState<ManagerCategoriesScreen> createState() =>
      _ManagerCategoriesScreenState();
}

class _ManagerCategoriesScreenState
    extends ConsumerState<ManagerCategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = _searchController.text;
    setState(() => _searchQuery = text);
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (mounted) {
        ref.read(managerCategoriesSearchProvider.notifier).state = text;
      }
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final categoriesState = ref.watch(managerCategoriesProvider);
    final l10n = AppLocalizations.of(context)!;

    return authState.when(
      data: (session) {
        final user = session?.user;
        if (user == null || !Permissions.isAdminOrSubAdmin(user.role)) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.accessDenied)),
            body: Center(
              child: Text(l10n.managersSectionOnly),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.manageCategories),
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n.searchCategories,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
              ),
              Expanded(
                child: _buildBody(ref, l10n, categoriesState),
              ),
            ],
          ),
          floatingActionButton: Padding(
            padding: const EdgeInsets.only(
              bottom: kBottomNavigationBarHeight,
            ),
            child: FloatingActionButton(
              onPressed: () => _showCreateCategoryModal(context, ref),
              child: const Icon(Icons.add),
            ),
          ),
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) {
        final l10nErr = AppLocalizations.of(context)!;
        return Scaffold(
          appBar: AppBar(),
          body: Center(
              child: Text(l10nErr.errorWithDetail.replaceAll('{detail}', error.toString()))),
        );
      },
    );
  }

  Widget _buildBody(
    WidgetRef ref,
    AppLocalizations l10n,
    AsyncValue<ManagerCategoriesState> categoriesState,
  ) {
    final searchArg = _searchQuery.trim().isEmpty ? null : _searchQuery.trim();
    final notifier = ref.read(managerCategoriesProvider.notifier);
    return categoriesState.when(
      data: (state) {
        final items = state.items;
        if (items.isEmpty) {
          return Center(
            child: Text(l10n.noCategoriesFound),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            await notifier.refresh();
          },
          child: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scrollInfo) {
              if (!state.isLoadingMore &&
                  state.hasMore &&
                  scrollInfo.metrics.pixels >=
                      scrollInfo.metrics.maxScrollExtent - 200) {
                notifier.loadMore(searchArg);
              }
              return false;
            },
                  child: ListView.builder(
                    itemExtent: 88,
                    cacheExtent: 500,
                    addAutomaticKeepAlives: false,
                    addRepaintBoundaries: true,
                    itemCount: items.length + (state.isLoadingMore ? 1 : 0),
                    padding: EdgeInsets.only(
                      left: 8,
                      right: 8,
                      top: 8,
                      bottom: 8 +
                          MediaQuery.of(context).padding.bottom +
                          140, // Extra space for FAB above bottom nav (65 nav + 56 FAB + 20 margin)
                    ),
                    itemBuilder: (context, index) {
                      if (index == items.length) {
                        return const SizedBox(
                          height: 88,
                          child: Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        );
                      }

                      final category = items[index];
                      return RepaintBoundary(
                        child: SizedBox(
                          height: 80,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: category['imageUrl'] != null
                                ? CircleAvatar(
                                    child: ClipOval(
                                      child: CachedNetworkImage(
                                        imageUrl: category['imageUrl'] as String,
                                        width: 40,
                                        height: 40,
                                        fit: BoxFit.cover,
                                        errorWidget: (_, __, ___) =>
                                            const Icon(Icons.category),
                                      ),
                                    ),
                                  )
                                : const CircleAvatar(
                                    child: Icon(Icons.category),
                                  ),
                          title: Text(
                            () {
                              final name = category['name'];
                              if (name is Map) {
                                return name['en']?.toString() ??
                                    name.values.firstOrNull?.toString() ??
                                    l10n.unknown;
                              }
                              return name?.toString() ?? l10n.unknown;
                            }(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            '${category['productCount'] ?? 0} ${l10n.productsCountSuffix}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showEditCategoryModal(
                                    context, ref, category),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () =>
                                    _showDeleteDialog(context, ref, category),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    );
                    },
                  ),
                ),
              );
            },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(l10n.errorWithDetail.replaceAll('{detail}', error.toString())),
            ElevatedButton(
              onPressed: () => notifier.refresh(),
              child: Text(l10n.retry),
            ),
          ],
        ),
      ),
    );
  }

  static void _showCreateCategoryModal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _CategoryFormModal(
        category: null,
        onSave: (data) async {
          try {
            await ref.read(managerRepositoryProvider).createCategory(data);

            // Refresh the list (invalidate all family instances)
            if (context.mounted) {
              ref.invalidate(managerCategoriesProvider);
            }

            if (modalContext.mounted) {
              final l10nModal = AppLocalizations.of(modalContext)!;
              Navigator.pop(modalContext);
              ScaffoldMessenger.of(modalContext).showSnackBar(
                SnackBar(content: Text(l10nModal.categoryCreatedSuccessfully)),
              );
            }
          } catch (e) {
            if (modalContext.mounted) {
              final l10nModal = AppLocalizations.of(modalContext)!;
              ScaffoldMessenger.of(modalContext).showSnackBar(
                SnackBar(content: Text(l10nModal.errorWithDetail.replaceAll('{detail}', e.toString()))),
              );
            }
          }
        },
      ),
    );
  }

  static void _showEditCategoryModal(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => _CategoryFormModal(
        category: category,
        onSave: (data) async {
          final dio = ref.read(dioProvider);
          try {
            await dio.patch<Map<String, dynamic>>(
              '/admin/categories/${category['id'] ?? category['_id']}',
              data: data,
            );
            if (modalContext.mounted) {
              ref.invalidate(managerCategoriesProvider);
              Navigator.pop(modalContext);
              ScaffoldMessenger.of(modalContext).showSnackBar(
                SnackBar(content: Text(l10n.categoryUpdatedSuccessfully)),
              );
            }
          } catch (e) {
            if (modalContext.mounted) {
              final l10nModal = AppLocalizations.of(modalContext)!;
              ScaffoldMessenger.of(modalContext).showSnackBar(
                SnackBar(content: Text(l10nModal.errorWithDetail.replaceAll('{detail}', e.toString()))),
              );
            }
          }
        },
      ),
    );
  }

  static void _showDeleteDialog(
    BuildContext context,
    WidgetRef ref,
    Map<String, dynamic> category,
  ) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteCategory),
        content: Text(
          l10n.deleteCategoryConfirm.replaceAll(
            '{name}',
            (category['name'] is Map
                    ? (category['name'] as Map)['en'] ?? (category['name'] as Map).values.firstOrNull
                    : category['name'])
                ?.toString() ??
                '',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final dio = ref.read(dioProvider);
              try {
                await dio.delete(
                    '/admin/categories/${category['id'] ?? category['_id']}');
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ref.invalidate(managerCategoriesProvider);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.categoryDeletedSuccessfully)),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  final l10nDlg = AppLocalizations.of(dialogContext)!;
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10nDlg.errorWithDetail.replaceAll('{detail}', e.toString()))),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }
}

class _CategoryFormModal extends ConsumerStatefulWidget {
  const _CategoryFormModal({
    required this.category,
    required this.onSave,
  });

  final Map<String, dynamic>? category;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  ConsumerState<_CategoryFormModal> createState() => _CategoryFormModalState();
}

class _CategoryFormModalState extends ConsumerState<_CategoryFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _imageUrlController = TextEditingController();
  PickedFileData? _selectedImage;
  bool _isUploading = false;
  bool _isLoading = false;

  String _currentLanguage = 'en';
  final Map<String, String> _nameMap = {};
  final Map<String, String> _descriptionMap = {};
  final List<String> _supportedLanguages = AppLanguages.contentSourceLanguages;

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      // Initialize multilingual Name
      final nameRaw = widget.category!['name'];
      if (nameRaw is Map) {
        final map = Map<String, dynamic>.from(nameRaw);
        map.forEach((key, value) => _nameMap[key] = value?.toString() ?? '');
      } else {
        _nameMap['en'] = nameRaw?.toString() ?? '';
      }

      // Initialize multilingual Description
      final descRaw = widget.category!['description'];
      if (descRaw is Map) {
        final map = Map<String, dynamic>.from(descRaw);
        map.forEach(
            (key, value) => _descriptionMap[key] = value?.toString() ?? '');
      } else {
        _descriptionMap['en'] = descRaw?.toString() ?? '';
      }

      _imageUrlController.text = widget.category!['imageUrl']?.toString() ?? '';
    }

    _updateControllers();

    // Listeners
    _nameController.addListener(() {
      _nameMap[_currentLanguage] = _nameController.text;
    });
    _descriptionController.addListener(() {
      _descriptionMap[_currentLanguage] = _descriptionController.text;
    });
  }

  void _updateControllers() {
    // Temporarily remove listeners to avoid loops/overwrites (though map update is safe)
    _nameController.text = _nameMap[_currentLanguage] ?? '';
    _descriptionController.text = _descriptionMap[_currentLanguage] ?? '';
  }

  void _changeLanguage(String lang) {
    setState(() {
      _currentLanguage = lang;
      _updateControllers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  Future<void> _generateWithAI() async {
    final l10n = AppLocalizations.of(context)!;
    final prompt = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final controller = TextEditingController();
        final l10nD = AppLocalizations.of(dialogContext)!;
        return AlertDialog(
          title: Text(l10nD.generateWithAI),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10nD.enterCategoryDescriptionToGenerate),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: l10nD.categoryDescriptionHint,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10nD.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(controller.text),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.auto_awesome, size: 16),
                  const SizedBox(width: 8),
                  Text(l10nD.generate),
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
      final data = await repo.generateCategoryContent(
        prompt,
        language: _currentLanguage,
      );

      if (!mounted) return;

      setState(() {
        // AI returns simple strings usually, put them in current language or English
        if (data['name'] != null) {
          _nameMap['en'] = data['name'];
          if (_currentLanguage == 'en') _nameController.text = data['name'];
        }
        if (data['description'] != null) {
          _descriptionMap['en'] = data['description'];
          if (_currentLanguage == 'en') {
            _descriptionController.text = data['description'];
          }
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.contentGeneratedSuccessfullyEnglish)),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.generationFailedWithError.replaceAll('{error}', e.toString()))),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickAndUploadImage() async {
    try {
      final uploadService = ref.read(uploadServiceProvider);
      final imageData = await ImagePickerHelper.pickImage();
      if (imageData == null) return;

      setState(() {
        _selectedImage = imageData;
        _isUploading = true;
      });

      final url = await uploadService.uploadFile(
        fileData: imageData,
        folder: 'categories',
      );

      setState(() {
        _imageUrlController.text = url;
        _isUploading = false;
      });
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  '${AppLocalizations.of(context)?.uploadFailed ?? 'Upload failed'}: $e')),
        );
      }
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    // Ensure current text is saved to map
    _nameMap[_currentLanguage] = _nameController.text.trim();
    _descriptionMap[_currentLanguage] = _descriptionController.text.trim();

    final data = <String, dynamic>{
      'name': _nameMap, // Send map
      'description': _descriptionMap, // Send map
    };

    if (_imageUrlController.text.trim().isNotEmpty) {
      data['imageUrl'] = _imageUrlController.text.trim();
    }

    await widget.onSave(data);
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
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    widget.category == null
                        ? l10n.createCategory
                        : l10n.editCategory,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Image preview and upload
                    if (_imageUrlController.text.isNotEmpty ||
                        _selectedImage != null)
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
                              onSelected: (_) => _changeLanguage(lang),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText:
                            '${l10n.categoryName} (${_currentLanguage.toUpperCase()})',
                        border: const OutlineInputBorder(),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.auto_awesome,
                              color: Colors.amber),
                          tooltip: l10n.generateWithAI,
                          onPressed: _isLoading ? null : _generateWithAI,
                        ),
                      ),
                      validator: (value) {
                        // Only validate if it's the primary language or if we enforce all langs
                        if (_currentLanguage == 'en' &&
                            (value == null || value.trim().isEmpty)) {
                          return l10n.pleaseEnterCategoryName;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: InputDecoration(
                        labelText:
                            '${l10n.categoryDescription} (${_currentLanguage.toUpperCase()})',
                        border: const OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _imageUrlController,
                      decoration: InputDecoration(
                        labelText: l10n.imageUrl,
                        border: const OutlineInputBorder(),
                        suffixIcon: _isUploading
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child:
                                    CircularProgressIndicator(strokeWidth: 2),
                              )
                            : IconButton(
                                icon: const Icon(Icons.upload),
                                onPressed: _pickAndUploadImage,
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: (_isUploading || _isLoading) ? null : _save,
                        child: Text(l10n.save),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
