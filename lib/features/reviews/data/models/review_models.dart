class Review {
  const Review({
    required this.id,
    required this.product,
    required this.order,
    required this.reviewer,
    required this.rating,
    this.title,
    this.comment,
    this.images = const [],
    required this.isVerifiedPurchase,
    required this.isHelpful,
    required this.isVisible,
    required this.isEdited,
    this.editedAt,
    this.response,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      product: ReviewProduct.fromJson(json['product'] as Map<String, dynamic>),
      order: ReviewOrder.fromJson(json['order'] as Map<String, dynamic>),
      reviewer:
          ReviewReviewer.fromJson(json['reviewer'] as Map<String, dynamic>),
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      title: json['title'] as String?,
      comment: json['comment'] as String?,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      isVerifiedPurchase: json['isVerifiedPurchase'] as bool? ?? false,
      isHelpful: (json['isHelpful'] as num?)?.toInt() ?? 0,
      isVisible: json['isVisible'] as bool? ?? true,
      isEdited: json['isEdited'] as bool? ?? false,
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'] as String)
          : null,
      response: json['response'] != null
          ? ReviewResponse.fromJson(json['response'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
    );
  }

  final String id;
  final ReviewProduct product;
  final ReviewOrder order;
  final ReviewReviewer reviewer;
  final int rating; // 1-5
  final String? title;
  final String? comment;
  final List<String> images;
  final bool isVerifiedPurchase;
  final int isHelpful;
  final bool isVisible;
  final bool isEdited;
  final DateTime? editedAt;
  final ReviewResponse? response;
  final DateTime createdAt;
  final DateTime updatedAt;
}

class ReviewProduct {
  const ReviewProduct({
    required this.id,
    required this.title,
    this.imageUrl,
  });

  factory ReviewProduct.fromJson(Map<String, dynamic> json) {
    return ReviewProduct(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  final String id;
  final String title;
  final String? imageUrl;
}

class ReviewOrder {
  const ReviewOrder({
    required this.id,
    this.orderNumber,
  });

  factory ReviewOrder.fromJson(Map<String, dynamic> json) {
    return ReviewOrder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      orderNumber: json['orderNumber'] as String?,
    );
  }

  final String id;
  final String? orderNumber;
}

class ReviewReviewer {
  const ReviewReviewer({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  factory ReviewReviewer.fromJson(Map<String, dynamic> json) {
    return ReviewReviewer(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Anonymous',
      avatarUrl: json['avatarUrl'] as String?,
    );
  }

  final String id;
  final String name;
  final String? avatarUrl;
}

class ReviewResponse {
  const ReviewResponse({
    required this.text,
    required this.respondedBy,
    required this.respondedAt,
  });

  factory ReviewResponse.fromJson(Map<String, dynamic> json) {
    return ReviewResponse(
      text: json['text'] as String? ?? '',
      respondedBy: ReviewResponder.fromJson(
        json['respondedBy'] as Map<String, dynamic>,
      ),
      respondedAt: json['respondedAt'] != null
          ? DateTime.parse(json['respondedAt'] as String)
          : DateTime.now(),
    );
  }

  final String text;
  final ReviewResponder respondedBy;
  final DateTime respondedAt;
}

class ReviewResponder {
  const ReviewResponder({
    required this.id,
    required this.name,
  });

  factory ReviewResponder.fromJson(Map<String, dynamic> json) {
    return ReviewResponder(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Admin',
    );
  }

  final String id;
  final String name;
}

class ReviewSummary {
  const ReviewSummary({
    required this.averageRating,
    required this.totalReviews,
    required this.ratingDistribution,
  });

  factory ReviewSummary.fromJson(Map<String, dynamic> json) {
    return ReviewSummary(
      averageRating: (json['averageRating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: (json['totalReviews'] as num?)?.toInt() ?? 0,
      ratingDistribution: (json['ratingDistribution'] as List<dynamic>?)
              ?.map(
                  (e) => RatingDistribution.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  final double averageRating;
  final int totalReviews;
  final List<RatingDistribution> ratingDistribution;
}

class RatingDistribution {
  const RatingDistribution({
    required this.rating,
    required this.count,
    required this.percentage,
  });

  factory RatingDistribution.fromJson(Map<String, dynamic> json) {
    return RatingDistribution(
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      count: (json['count'] as num?)?.toInt() ?? 0,
      percentage: (json['percentage'] as num?)?.toInt() ?? 0,
    );
  }

  final int rating;
  final int count;
  final int percentage;
}

class ProductReviewsPage {
  const ProductReviewsPage({
    required this.reviews,
    required this.pagination,
    required this.summary,
  });

  factory ProductReviewsPage.fromJson(Map<String, dynamic> json) {
    return ProductReviewsPage(
      reviews: (json['data'] as List<dynamic>?)
              ?.map((e) => Review.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      pagination: PaginationMeta.fromJson(
        json['meta'] as Map<String, dynamic>? ?? {},
      ),
      summary: ReviewSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? {},
      ),
    );
  }

  final List<Review> reviews;
  final PaginationMeta pagination;
  final ReviewSummary summary;
}

class PaginationMeta {
  const PaginationMeta({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationMeta.fromJson(Map<String, dynamic> json) {
    return PaginationMeta(
      page: (json['page'] as num?)?.toInt() ?? 1,
      limit: (json['limit'] as num?)?.toInt() ?? 10,
      total: (json['total'] as num?)?.toInt() ?? 0,
      totalPages: (json['totalPages'] as num?)?.toInt() ?? 0,
    );
  }

  final int page;
  final int limit;
  final int total;
  final int totalPages;
}

class EligibleOrder {
  const EligibleOrder({
    required this.orderId,
    this.orderNumber,
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    this.orderItemId,
    required this.deliveredAt,
    required this.hasReview,
  });

  factory EligibleOrder.fromJson(Map<String, dynamic> json) {
    return EligibleOrder(
      orderId: json['orderId']?.toString() ?? '',
      orderNumber: json['orderNumber']?.toString(),
      productId: json['productId']?.toString() ?? '',
      productTitle: json['productTitle']?.toString() ?? '',
      productImageUrl: json['productImageUrl']?.toString(),
      orderItemId: json['orderItemId']?.toString(),
      deliveredAt: json['deliveredAt'] != null
          ? DateTime.parse(json['deliveredAt'] as String)
          : DateTime.now(),
      hasReview: json['hasReview'] as bool? ?? false,
    );
  }

  final String orderId;
  final String? orderNumber;
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final String? orderItemId;
  final DateTime deliveredAt;
  final bool hasReview;
}
