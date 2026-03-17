class NotificationModel {
  final String id;
  final String title;
  final String body;
  final String? titleKey;
  final String? bodyKey;
  final List<String>? titleArgs;
  final List<String>? bodyArgs;
  final String type;
  final Map<String, dynamic>? data;
  final String status; // 'unread', 'read', 'deleted'
  final DateTime? readAt;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.title,
    required this.body,
    this.titleKey,
    this.bodyKey,
    this.titleArgs,
    this.bodyArgs,
    required this.type,
    this.data,
    required this.status,
    this.readAt,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      titleKey: json['titleKey'] as String?,
      bodyKey: json['bodyKey'] as String?,
      titleArgs: (json['titleArgs'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      bodyArgs: (json['bodyArgs'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>?,
      status: json['status'] as String,
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'body': body,
      'titleKey': titleKey,
      'bodyKey': bodyKey,
      'titleArgs': titleArgs,
      'bodyArgs': bodyArgs,
      'type': type,
      'data': data,
      'status': status,
      'readAt': readAt?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isUnread => status == 'unread';
  bool get isRead => status == 'read';

  NotificationModel copyWith({
    String? id,
    String? title,
    String? body,
    String? titleKey,
    String? bodyKey,
    List<String>? titleArgs,
    List<String>? bodyArgs,
    String? type,
    Map<String, dynamic>? data,
    String? status,
    DateTime? readAt,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      titleKey: titleKey ?? this.titleKey,
      bodyKey: bodyKey ?? this.bodyKey,
      titleArgs: titleArgs ?? this.titleArgs,
      bodyArgs: bodyArgs ?? this.bodyArgs,
      type: type ?? this.type,
      data: data ?? this.data,
      status: status ?? this.status,
      readAt: readAt ?? this.readAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class NotificationListResponse {
  final List<NotificationModel> notifications;
  final int unreadCount;
  final PaginationInfo pagination;

  NotificationListResponse({
    required this.notifications,
    required this.unreadCount,
    required this.pagination,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    return NotificationListResponse(
      notifications: (json['notifications'] as List<dynamic>)
          .map((item) =>
              NotificationModel.fromJson(item as Map<String, dynamic>))
          .toList(),
      unreadCount: json['unreadCount'] as int,
      pagination: PaginationInfo.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasMore => page < totalPages;
}
