import '../../../auth/data/models/auth_models.dart';

class AccountStatus {
  const AccountStatus({
    required this.status,
    this.reason,
  });

  final UserStatus status;
  final String? reason;

  factory AccountStatus.fromJson(Map<String, dynamic> json) {
    return AccountStatus(
      status: statusFromString(json['status'] as String? ?? 'pending'),
      reason: json['reason'] as String?,
    );
  }

  bool get isApproved => status == UserStatus.approved;
  bool get needsApproval => status != UserStatus.approved;
}

class CategorizedDocument {
  const CategorizedDocument({
    required this.type,
    required this.url,
    this.uploadedAt,
  });

  final String type;
  final String url;
  final DateTime? uploadedAt;

  factory CategorizedDocument.fromJson(Map<String, dynamic> json) {
    return CategorizedDocument(
      type: json['type'] as String? ?? '',
      url: json['url'] as String? ?? '',
      uploadedAt: json['uploadedAt'] != null
          ? DateTime.tryParse(json['uploadedAt'] as String)
          : null,
    );
  }

  String get displayName {
    final segments = url.split('/');
    final last = segments.isNotEmpty ? segments.last : '';
    if (last.contains('.')) return last;
    return 'Document';
  }
}

class DocumentUploadResponse {
  const DocumentUploadResponse({
    required this.message,
    required this.documents,
    this.document,
  });

  final String message;
  final List<String> documents;
  final Map<String, dynamic>? document;

  factory DocumentUploadResponse.fromJson(Map<String, dynamic> json) {
    final docs = json['documents'];
    List<String> docUrls = [];
    if (docs is List) {
      for (final d in docs) {
        if (d is Map && d['url'] != null) {
          docUrls.add(d['url'] as String);
        } else if (d is String) {
          docUrls.add(d);
        }
      }
    }
    return DocumentUploadResponse(
      message: json['message'] as String? ?? '',
      documents: docUrls,
      document: json['document'] as Map<String, dynamic>?,
    );
  }
}

class DeletionRequestResponse {
  const DeletionRequestResponse({
    required this.id,
    required this.email,
    required this.status,
    required this.requestedAt,
    this.message,
  });

  final String id;
  final String email;
  final String status;
  final DateTime requestedAt;
  final String? message;

  factory DeletionRequestResponse.fromJson(Map<String, dynamic> json) {
    return DeletionRequestResponse(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      requestedAt: json['requestedAt'] != null
          ? DateTime.parse(json['requestedAt'] as String)
          : DateTime.now(),
      message: json['message'] as String?,
    );
  }
}
