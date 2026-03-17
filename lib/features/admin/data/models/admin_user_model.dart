import '../../../auth/data/models/auth_models.dart';

class AdminUser {
  const AdminUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.businessName,
    this.phone,
    this.location,
    this.locations,
    this.createdAt,
    this.lastActive,
    this.lastOrderAt,
    this.lastLoginAt,
    this.daysSinceLastLogin,
    this.daysSinceLastOrder,
    this.activeDaysLast14,
    this.isInactiveByOrders,
    this.verificationDocuments,
    this.categorizedDocuments,
    this.gewerbescheinPhotos,
    this.rejectionReason,
  });

  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final UserStatus status;
  final String? businessName;
  final String? phone;
  final UserLocation? location;
  final List<UserLocation>? locations;
  final DateTime? createdAt;
  final DateTime? lastActive;
  final DateTime? lastOrderAt;
  final DateTime? lastLoginAt;
  final int? daysSinceLastLogin;
  final int? daysSinceLastOrder;
  final int? activeDaysLast14;
  final bool? isInactiveByOrders;
  final List<String>? verificationDocuments;
  final List<Map<String, dynamic>>? categorizedDocuments;
  final List<String>? gewerbescheinPhotos;
  final String? rejectionReason;

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: roleFromString(json['role']?.toString() ?? ''),
      status: statusFromString(json['status']?.toString() ?? ''),
      businessName: json['businessName']?.toString(),
      phone: json['phone']?.toString(),
      location: json['location'] != null
          ? UserLocation.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      locations: json['locations'] != null
          ? (json['locations'] as List<dynamic>)
              .map((e) => UserLocation.fromJson(e as Map<String, dynamic>))
              .toList()
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'].toString())
          : null,
      lastActive: json['lastActive'] != null
          ? DateTime.parse(json['lastActive'].toString())
          : null,
      lastOrderAt: json['lastOrderAt'] != null
          ? DateTime.parse(json['lastOrderAt'].toString())
          : null,
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'].toString())
          : null,
      daysSinceLastLogin: json['daysSinceLastLogin'] as int?,
      daysSinceLastOrder: json['daysSinceLastOrder'] as int?,
      activeDaysLast14: json['activeDaysLast14'] as int?,
      isInactiveByOrders: json['isInactiveByOrders'] as bool?,
      verificationDocuments: json['verificationDocuments'] != null
          ? (json['verificationDocuments'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      categorizedDocuments: json['categorizedDocuments'] != null
          ? (json['categorizedDocuments'] as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : null,
      gewerbescheinPhotos: json['gewerbescheinPhotos'] != null
          ? (json['gewerbescheinPhotos'] as List<dynamic>)
              .map((e) => e.toString())
              .toList()
          : null,
      rejectionReason: json['rejectionReason']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'role': role.toString().split('.').last,
        'status': status.toString().split('.').last,
        'businessName': businessName,
        'phone': phone,
        'location': location?.toJson(),
        'locations': locations?.map((e) => e.toJson()).toList(),
        'createdAt': createdAt?.toIso8601String(),
        'lastActive': lastActive?.toIso8601String(),
        'lastOrderAt': lastOrderAt?.toIso8601String(),
        'lastLoginAt': lastLoginAt?.toIso8601String(),
        'daysSinceLastLogin': daysSinceLastLogin,
        'daysSinceLastOrder': daysSinceLastOrder,
        'activeDaysLast14': activeDaysLast14,
        'isInactiveByOrders': isInactiveByOrders,
        'verificationDocuments': verificationDocuments,
        'categorizedDocuments': categorizedDocuments,
        'gewerbescheinPhotos': gewerbescheinPhotos,
        'rejectionReason': rejectionReason,
      };
}
