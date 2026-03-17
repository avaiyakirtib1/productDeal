import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

/// Amazon-style gallery: Stack with main image + top-left thumbnails (max 3).
/// If >3 images, "Show more" card reveals full list.
class ProductImageGallery extends StatefulWidget {
  const ProductImageGallery({
    super.key,
    required this.imageUrls,
    this.height = 320,
  });

  final List<String> imageUrls;
  final double height;

  @override
  State<ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<ProductImageGallery> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  List<String> get _urls =>
      widget.imageUrls.isNotEmpty ? widget.imageUrls : const [];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_urls.isEmpty) {
      return _buildPlaceholder(theme);
    }

    const maxThumbnails = 3;
    final showMoreCount = _urls.length > maxThumbnails ? _urls.length - maxThumbnails : 0;
    final visibleUrls = _urls.length > maxThumbnails
        ? _urls.take(maxThumbnails).toList()
        : List<String>.from(_urls);

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
        // Main image – full size, swipeable
        Positioned.fill(
          child: PageView.builder(
            controller: _pageController,
            onPageChanged: (i) => setState(() => _currentIndex = i),
            itemCount: _urls.length,
            itemBuilder: (context, index) => CachedNetworkImage(
              imageUrl: _urls[index],
              fit: BoxFit.contain,
              placeholder: (_, __) => Container(
                color: theme.colorScheme.surfaceContainerHighest,
                child: const Center(child: CircularProgressIndicator()),
              ),
              errorWidget: (_, __, ___) => _buildPlaceholder(theme),
            ),
          ),
        ),
        // Top-left: thumbnails (max 3) + Show more card
        if (_urls.length > 1)
          Positioned(
            top: 12,
            left: 12,
            child: Material(
              elevation: 2,
              borderRadius: BorderRadius.circular(8),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...List.generate(visibleUrls.length, (i) {
                    final index = _urls.indexOf(visibleUrls[i]);
                    final isSelected = index == _currentIndex;
                    return _ThumbnailTile(
                      imageUrl: visibleUrls[i],
                      isSelected: isSelected,
                      theme: theme,
                      onTap: () => _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                      ),
                    );
                  }),
                  if (showMoreCount > 0)
                    _ShowMoreCard(
                      count: showMoreCount,
                      theme: theme,
                      onTap: () => _showFullGallery(context, theme),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showFullGallery(BuildContext context, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    AppLocalizations.of(context)?.allImages ?? 'All images',
                    style: theme.textTheme.titleMedium,
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: GridView.builder(
                controller: scrollController,
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 1,
                ),
                itemCount: _urls.length,
                itemBuilder: (context, index) {
                  final isSelected = index == _currentIndex;
                  return GestureDetector(
                    onTap: () {
                      _pageController.animateToPage(
                        index,
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                      );
                      Navigator.pop(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: CachedNetworkImage(
                          imageUrl: _urls[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Icon(
                            Icons.broken_image_outlined,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder(ThemeData theme) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.primaryContainer,
            theme.colorScheme.secondaryContainer,
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.inventory_2_outlined,
          size: 80,
          color: theme.colorScheme.onPrimaryContainer,
        ),
      ),
    );
  }
}

class _ThumbnailTile extends StatelessWidget {
  const _ThumbnailTile({
    required this.imageUrl,
    required this.isSelected,
    required this.theme,
    required this.onTap,
  });

  final String imageUrl;
  final bool isSelected;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 56,
        height: 56,
        margin: const EdgeInsets.fromLTRB(4, 4, 4, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.transparent,
            width: 2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            placeholder: (_, __) => Container(
              color: theme.colorScheme.surfaceContainerHighest,
              child: const Center(
                child: SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Icon(
              Icons.broken_image_outlined,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _ShowMoreCard extends StatelessWidget {
  const _ShowMoreCard({
    required this.count,
    required this.theme,
    required this.onTap,
  });

  final int count;
  final ThemeData theme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: theme.colorScheme.outlineVariant,
          ),
        ),
        child: Center(
          child: Text(
            '+$count',
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ),
    );
  }
}
