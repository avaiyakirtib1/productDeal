enum DocumentType {
  passport('passport', 'Passport'),
  gewerbeschein('gewerbeschein', 'Gewerbeschein'),
  businessLicense('businessLicense', 'Business License / Gewerbeschein'),
  idCard('idCard', 'Government ID Card'),
  taxId('taxId', 'Tax ID'),
  companyRegistration('companyRegistration', 'Company Registration'),
  other('other', 'Other');

  final String value;
  final String label;

  const DocumentType(this.value, this.label);

  static DocumentType? fromString(String? value) {
    if (value == null) return null;
    return DocumentType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => DocumentType.other,
    );
  }
}

class DocumentCategory {
  final DocumentType type;
  final String? url;
  final String? alternativeMessage;

  const DocumentCategory({
    required this.type,
    this.url,
    this.alternativeMessage,
  });

  Map<String, dynamic> toJson() {
    return {
      'type': type.value,
      'url': url,
      if (alternativeMessage != null) 'alternativeMessage': alternativeMessage,
    };
  }

  factory DocumentCategory.fromJson(Map<String, dynamic> json) {
    return DocumentCategory(
      type: DocumentType.fromString(json['type'] as String?) ??
          DocumentType.other,
      url: json['url'] as String?,
      alternativeMessage: json['alternativeMessage'] as String?,
    );
  }
}
