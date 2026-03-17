enum BannerType { deal, product, external, promotion }

enum BannerStatus { pending, approved, rejected, active, inactive }

class BannerModel {
  final String id;
  final String title;
  final String imageUrl;
  final String? webImageUrl;
  final String? mobileImageUrl;
  final String? description;
  final BannerType type;
  final String? targetId;
  final String? targetUrl;
  /// Resolved product title when type is product (from API)
  final String? targetProductTitle;
  /// Resolved deal title when type is deal (from API)
  final String? targetDealTitle;
  final BannerStatus status;
  final String createdBy; // User ID
  final DateTime? startDate;
  final DateTime? endDate;
  final int clickCount;
  final int viewCount;

  BannerModel({
    required this.id,
    required this.title,
    required this.imageUrl,
    this.webImageUrl,
    this.mobileImageUrl,
    this.description,
    required this.type,
    this.targetId,
    this.targetUrl,
    this.targetProductTitle,
    this.targetDealTitle,
    required this.status,
    required this.createdBy,
    this.startDate,
    this.endDate,
    this.clickCount = 0,
    this.viewCount = 0,
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    // Handle title: can be String (from resolved API) or Map (for backward compatibility)
    String titleString = '';
    final titleValue = json['title'];
    if (titleValue is String) {
      titleString = titleValue;
    } else if (titleValue is Map<String, dynamic>) {
      // If it's a Map, try to get the current language or fallback to 'en'
      titleString = titleValue['en'] as String? ??
          (titleValue.values.isNotEmpty
              ? titleValue.values.first.toString()
              : null) ??
          'Banner';
    } else if (titleValue != null) {
      titleString = titleValue.toString();
    }

    // Handle description: can be String (from resolved API) or Map
    String? descriptionString;
    final descriptionValue = json['description'];
    if (descriptionValue is String) {
      descriptionString = descriptionValue.isEmpty ? null : descriptionValue;
    } else if (descriptionValue is Map<String, dynamic>) {
      descriptionString = descriptionValue['en'] as String? ??
          (descriptionValue.values.isNotEmpty
              ? descriptionValue.values.first.toString()
              : null);
      if (descriptionString != null && descriptionString.isEmpty) {
        descriptionString = null;
      }
    }

    final rawImageUrl = json['imageUrl'] as String?;
    final webImageUrl = json['webImageUrl'] as String?;
    final mobileImageUrl = json['mobileImageUrl'] as String?;
    final imageUrl = rawImageUrl?.isNotEmpty == true
        ? rawImageUrl!
        : (webImageUrl?.isNotEmpty == true
            ? webImageUrl!
            : mobileImageUrl ?? '');

    return BannerModel(
      id: json['_id'] ?? '',
      title: titleString,
      imageUrl: imageUrl,
      webImageUrl: webImageUrl?.isNotEmpty == true ? webImageUrl : null,
      mobileImageUrl: mobileImageUrl?.isNotEmpty == true ? mobileImageUrl : null,
      description: descriptionString,
      type: BannerType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => BannerType.promotion,
      ),
      targetId: json['targetId'],
      targetUrl: json['targetUrl'],
      targetProductTitle: json['targetProductTitle'] as String?,
      targetDealTitle: json['targetDealTitle'] as String?,
      status: BannerStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => BannerStatus.pending,
      ),
      createdBy: json['createdBy'] is Map
          ? json['createdBy']['_id']
          : json['createdBy'] ?? '',
      startDate:
          json['startDate'] != null ? DateTime.parse(json['startDate']) : null,
      endDate: json['endDate'] != null ? DateTime.parse(json['endDate']) : null,
      clickCount: json['clickCount'] ?? 0,
      viewCount: json['viewCount'] ?? 0,
    );
  }

  /// Image URL for display: prefers mobile on mobile platforms, else web, else imageUrl.
  String get displayImageUrl {
    if (mobileImageUrl != null && mobileImageUrl!.isNotEmpty) return mobileImageUrl!;
    if (webImageUrl != null && webImageUrl!.isNotEmpty) return webImageUrl!;
    return imageUrl;
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'imageUrl': imageUrl,
      if (webImageUrl != null) 'webImageUrl': webImageUrl,
      if (mobileImageUrl != null) 'mobileImageUrl': mobileImageUrl,
      'description': description,
      'type': type.toString().split('.').last,
      'targetId': targetId,
      'targetUrl': targetUrl,
      'startDate': startDate?.toIso8601String(),
      'endDate': endDate?.toIso8601String(),
    };
  }
}
