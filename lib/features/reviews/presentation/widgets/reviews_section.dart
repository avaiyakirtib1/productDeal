import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/review_models.dart';
import '../../data/repositories/review_repository.dart';
import 'rating_widget.dart';
import 'review_item.dart';

/// Provider for product reviews
final productReviewsProvider = FutureProvider.autoDispose
    .family<ProductReviewsPage, ProductReviewsParams>((ref, params) async {
  final repo = ref.watch(reviewRepositoryProvider);
  return repo.getProductReviews(
    params.productId,
    page: params.page,
    limit: params.limit,
    rating: params.rating,
    sortBy: params.sortBy,
  );
});

class ProductReviewsParams {
  const ProductReviewsParams({
    required this.productId,
    this.page = 1,
    this.limit = 10,
    this.rating,
    this.sortBy,
  });

  final String productId;
  final int page;
  final int limit;
  final int? rating;
  final String? sortBy;

  ProductReviewsParams copyWith({
    String? productId,
    int? page,
    int? limit,
    int? rating,
    String? sortBy,
  }) {
    return ProductReviewsParams(
      productId: productId ?? this.productId,
      page: page ?? this.page,
      limit: limit ?? this.limit,
      rating: rating ?? this.rating,
      sortBy: sortBy ?? this.sortBy,
    );
  }
}

class ReviewsSection extends ConsumerStatefulWidget {
  const ReviewsSection({
    super.key,
    required this.productId,
    this.onWriteReview,
    this.isLoading = false,
  });

  final String productId;
  final VoidCallback? onWriteReview;
  final bool isLoading;

  @override
  ConsumerState<ReviewsSection> createState() => _ReviewsSectionState();
}

/// Formats a number to a compact string (e.g., 1000 -> "1k", 1500 -> "1.5k", 2000 -> "2k")
String _formatReviewCount(int count) {
  if (count < 1000) {
    return count.toString();
  } else if (count < 10000) {
    final thousands = count / 1000;
    if (thousands == thousands.toInt()) {
      return '${thousands.toInt()}k';
    } else {
      return '${thousands.toStringAsFixed(1)}k';
    }
  } else if (count < 1000000) {
    final thousands = count / 1000;
    if (thousands == thousands.toInt()) {
      return '${thousands.toInt()}k';
    } else {
      return '${thousands.toStringAsFixed(1)}k';
    }
  } else {
    final millions = count / 1000000;
    if (millions == millions.toInt()) {
      return '${millions.toInt()}M';
    } else {
      return '${millions.toStringAsFixed(1)}M';
    }
  }
}

class _ReviewsSectionState extends ConsumerState<ReviewsSection> {
  late final ProductReviewsParams _params;

  @override
  void initState() {
    super.initState();
    // Create stable params object once in initState to prevent rebuilds
    _params = ProductReviewsParams(productId: widget.productId);
  }

  @override
  void didUpdateWidget(ReviewsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only update params if productId actually changed
    if (oldWidget.productId != widget.productId) {
      _params = ProductReviewsParams(productId: widget.productId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reviewsAsync = ref.watch(productReviewsProvider(_params));

    return reviewsAsync.when(
      data: (page) {
        final summary = page.summary;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with summary
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Customer Reviews',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (summary.totalReviews > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            RatingWidget(
                              rating: summary.averageRating,
                              size: 20,
                              showNumber: true,
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                '(${_formatReviewCount(summary.totalReviews)} ${summary.totalReviews == 1 ? 'review' : 'reviews'})',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.onWriteReview != null)
                  TextButton.icon(
                    onPressed: widget.isLoading ? null : widget.onWriteReview,
                    icon: widget.isLoading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.edit),
                    label:
                        Text(widget.isLoading ? 'Loading...' : 'Write Review'),
                  ),
              ],
            ),
            // Rating distribution
            if (summary.totalReviews > 0) ...[
              const SizedBox(height: 16),
              _RatingDistribution(distribution: summary.ratingDistribution),
              const SizedBox(height: 24),
            ],
            // Reviews list
            if (page.reviews.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.reviews_outlined,
                        size: 64,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No reviews yet',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Be the first to review this product!',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              ...page.reviews.map((review) => ReviewItem(review: review)),
            // Pagination
            if (page.pagination.totalPages > 1) ...[
              const SizedBox(height: 16),
              _ReviewsPagination(
                pagination: page.pagination,
                onPageChanged: (newPage) {
                  // Invalidate with new page params to trigger refresh
                  ref.invalidate(
                    productReviewsProvider(_params.copyWith(page: newPage)),
                  );
                },
              ),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 8),
              Text(
                'Error loading reviews',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 4),
              Text(
                error.toString(),
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingDistribution extends StatelessWidget {
  const _RatingDistribution({required this.distribution});

  final List<RatingDistribution> distribution;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Rating Distribution',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ...distribution.reversed.map((dist) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    child: Text(
                      '${dist.rating}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ),
                  const Icon(Icons.star, size: 16, color: Colors.amber),
                  const SizedBox(width: 8),
                  Expanded(
                    child: LinearProgressIndicator(
                      value: dist.percentage / 100,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${dist.count} (${dist.percentage}%)',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _ReviewsPagination extends StatelessWidget {
  const _ReviewsPagination({
    required this.pagination,
    required this.onPageChanged,
  });

  final PaginationMeta pagination;
  final Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: pagination.page > 1
              ? () => onPageChanged(pagination.page - 1)
              : null,
        ),
        Text(
          'Page ${pagination.page} of ${pagination.totalPages}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: pagination.page < pagination.totalPages
              ? () => onPageChanged(pagination.page + 1)
              : null,
        ),
      ],
    );
  }
}
