enum UserRole { admin, subAdmin, wholesaler, kiosk }

enum UserStatus { pending, approved, rejected, suspended, needMoreInfo }

UserRole roleFromString(String value) {
  switch (value) {
    case 'admin':
      return UserRole.admin;
    case 'sub_admin':
      return UserRole.subAdmin;
    case 'wholesaler':
      return UserRole.wholesaler;
    default:
      return UserRole.kiosk;
  }
}

UserStatus statusFromString(String value) {
  switch (value) {
    case 'approved':
      return UserStatus.approved;
    case 'rejected':
      return UserStatus.rejected;
    case 'suspended':
      return UserStatus.suspended;
    case 'need_more_info':
      return UserStatus.needMoreInfo;
    default:
      return UserStatus.pending;
  }
}

/// Module keys for notification preferences (matches backend)
const notificationModuleKeys = [
  'products',
  'product_orders',
  'deals',
  'deal_orders',
  'banners',
  'admin',
  'engagement',
  'payment',
];

/// Per-module push/email toggles. undefined/null = true (enabled).
class ModuleNotificationPrefs {
  const ModuleNotificationPrefs({this.push, this.email});
  final bool? push;
  final bool? email;
  Map<String, dynamic> toJson() => {
        if (push != null) 'push': push,
        if (email != null) 'email': email,
      };
}

/// User notification preferences. All default to true when undefined.
class NotificationPreferences {
  const NotificationPreferences({
    this.pushEnabled,
    this.emailEnabled,
    this.modules,
  });
  final bool? pushEnabled;
  final bool? emailEnabled;
  final Map<String, ModuleNotificationPrefs>? modules;

  factory NotificationPreferences.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const NotificationPreferences();
    final modulesRaw = json['modules'] as Map<String, dynamic>?;
    Map<String, ModuleNotificationPrefs>? modules;
    if (modulesRaw != null) {
      modules = {};
      for (final e in modulesRaw.entries) {
        final v = e.value;
        if (v is Map<String, dynamic>) {
          modules[e.key] = ModuleNotificationPrefs(
            push: v['push'] as bool?,
            email: v['email'] as bool?,
          );
        }
      }
    }
    return NotificationPreferences(
      pushEnabled: json['pushEnabled'] as bool?,
      emailEnabled: json['emailEnabled'] as bool?,
      modules: modules,
    );
  }

  Map<String, dynamic> toJson() => {
        if (pushEnabled != null) 'pushEnabled': pushEnabled,
        if (emailEnabled != null) 'emailEnabled': emailEnabled,
        if (modules != null && modules!.isNotEmpty)
          'modules': Map.fromEntries(
            modules!.entries.map((e) => MapEntry(e.key, e.value.toJson())),
          ),
      };
}

class UserLocation {
  const UserLocation({
    this.label,
    this.address,
    this.country,
    this.city,
    this.latitude,
    this.longitude,
  });

  final String? label;
  final String? address;
  final String? country;
  final String? city;
  final double? latitude;
  final double? longitude;

  factory UserLocation.fromJson(Map<String, dynamic> json) {
    final coords = _extractCoordinates(json);
    final lng =
        (coords?.isNotEmpty ?? false) ? (coords![0] as num?)?.toDouble() : null;
    final lat = (coords != null && coords.length > 1)
        ? (coords[1] as num?)?.toDouble()
        : null;
    return UserLocation(
      label: json['label'] as String?,
      address: json['address'] as String?,
      country: json['country'] as String?,
      city: json['city'] as String?,
      latitude: lat ?? (json['latitude'] as num?)?.toDouble(),
      longitude: lng ?? (json['longitude'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'label': label,
        'address': address,
        'country': country,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
      };

  static List<dynamic>? _extractCoordinates(Map<String, dynamic> json) {
    final loc = json['location'];
    if (loc is Map<String, dynamic>) {
      final values = loc['coordinates'];
      if (values is List<dynamic>) return values;
    }
    final coordinates = json['coordinates'];
    if (coordinates is Map<String, dynamic>) {
      final values = coordinates['coordinates'];
      if (values is List<dynamic>) return values;
    }
    if (coordinates is List<dynamic>) {
      return coordinates;
    }
    return null;
  }
}

/// Wholesaler bank details – flexible for country-specific requirements.
/// Currently: IBAN only. Future: India (Account+IFSC), Russia (Account+BIK), etc.
class PaymentConfig {
  const PaymentConfig({
    this.country,
    this.currency,
    this.accountHolderName,
    this.bankName,
    this.bankAddress,
    this.iban,
    this.accountNumber,
    this.routingCode,
    this.swiftBic,
    this.paymentInstructions,
    this.paymentReferenceTemplate,
    this.paymentEmailSubjectTemplate,
    this.paymentEmailBodyTemplate,
  });

  final String? country;
  final String? currency;
  final String? accountHolderName;
  final String? bankName;
  final String? bankAddress;
  final String? iban;
  final String? accountNumber;
  final String? routingCode;
  final String? swiftBic;
  final String? paymentInstructions;
  final String? paymentReferenceTemplate;
  final String? paymentEmailSubjectTemplate;
  final String? paymentEmailBodyTemplate;

  factory PaymentConfig.fromJson(Map<String, dynamic>? json) {
    if (json == null || json.isEmpty) return const PaymentConfig();
    return PaymentConfig(
      country: json['country'] as String?,
      currency: json['currency'] as String?,
      accountHolderName: json['accountHolderName'] as String?,
      bankName: json['bankName'] as String?,
      bankAddress: json['bankAddress'] as String?,
      iban: json['iban'] as String?,
      accountNumber: json['accountNumber'] as String?,
      routingCode: json['routingCode'] as String?,
      swiftBic: json['swiftBic'] as String?,
      paymentInstructions: json['paymentInstructions'] as String?,
      paymentReferenceTemplate: json['paymentReferenceTemplate'] as String?,
      paymentEmailSubjectTemplate: json['paymentEmailSubjectTemplate'] as String?,
      paymentEmailBodyTemplate: json['paymentEmailBodyTemplate'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        if (country != null && country!.isNotEmpty) 'country': country,
        if (currency != null && currency!.isNotEmpty) 'currency': currency,
        if (accountHolderName != null && accountHolderName!.isNotEmpty)
          'accountHolderName': accountHolderName,
        if (bankName != null && bankName!.isNotEmpty) 'bankName': bankName,
        if (bankAddress != null && bankAddress!.isNotEmpty) 'bankAddress': bankAddress,
        if (iban != null && iban!.isNotEmpty) 'iban': iban,
        if (accountNumber != null && accountNumber!.isNotEmpty) 'accountNumber': accountNumber,
        if (routingCode != null && routingCode!.isNotEmpty) 'routingCode': routingCode,
        if (swiftBic != null && swiftBic!.isNotEmpty) 'swiftBic': swiftBic,
        if (paymentInstructions != null && paymentInstructions!.isNotEmpty)
          'paymentInstructions': paymentInstructions,
        if (paymentReferenceTemplate != null && paymentReferenceTemplate!.isNotEmpty)
          'paymentReferenceTemplate': paymentReferenceTemplate,
        if (paymentEmailSubjectTemplate != null && paymentEmailSubjectTemplate!.isNotEmpty)
          'paymentEmailSubjectTemplate': paymentEmailSubjectTemplate,
        if (paymentEmailBodyTemplate != null && paymentEmailBodyTemplate!.isNotEmpty)
          'paymentEmailBodyTemplate': paymentEmailBodyTemplate,
      };
}

class UserModel {
  const UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.status,
    this.businessName,
    this.phone,
    this.avatarUrl,
    this.coverImageUrl,
    this.tagline,
    this.location,
    this.locations = const [],
    this.termsAccepted = false,
    this.privacyAccepted = false,
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
    this.paymentConfig,
    this.defaultPaymentMode,
    this.defaultPaymentModes,
    this.paymentIban,
    this.paymentBankAccountOwner,
    this.paymentInstructions,
    this.paymentReferenceTemplate,
    this.paymentEmailSubjectTemplate,
    this.paymentEmailBodyTemplate,
    this.notificationPreferences,
  });

  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final UserRole role;
  final UserStatus status;
  final String? businessName;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? tagline;
  final UserLocation? location;
  final List<UserLocation> locations;
  final bool termsAccepted;
  final bool privacyAccepted;
  final DateTime? termsAcceptedAt;
  final DateTime? privacyAcceptedAt;
  final PaymentConfig? paymentConfig;
  final String? defaultPaymentMode;
  /// Accepted payment modes (multiple). Prefer over [defaultPaymentMode].
  final List<String>? defaultPaymentModes;
  final String? paymentIban;
  final String? paymentBankAccountOwner;
  final String? paymentInstructions;
  final String? paymentReferenceTemplate;
  final String? paymentEmailSubjectTemplate;
  final String? paymentEmailBodyTemplate;
  final NotificationPreferences? notificationPreferences;

  /// Effective IBAN (paymentConfig.iban or legacy paymentIban)
  String? get effectiveIban => paymentConfig?.iban ?? paymentIban;
  /// Effective account holder (paymentConfig.accountHolderName or legacy paymentBankAccountOwner)
  String? get effectiveAccountHolder => paymentConfig?.accountHolderName ?? paymentBankAccountOwner;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final parsedLocations = (json['locations'] as List<dynamic>? ?? [])
        .map((entry) => UserLocation.fromJson(entry as Map<String, dynamic>))
        .toList(growable: false);
    final legacyLocation = json['location'] != null
        ? UserLocation.fromJson(json['location'] as Map<String, dynamic>)
        : (parsedLocations.isNotEmpty ? parsedLocations.first : null);

    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      role: roleFromString(json['role'] as String? ?? 'kiosk'),
      status: statusFromString(json['status'] as String? ?? 'pending'),
      businessName: json['businessName'] as String?,
      avatarUrl: json['avatarUrl'] as String?,
      coverImageUrl: json['coverImageUrl'] as String?,
      tagline: json['tagline'] as String?,
      location: legacyLocation,
      locations: parsedLocations,
      termsAccepted: json['termsAccepted'] as bool? ?? false,
      privacyAccepted: json['privacyAccepted'] as bool? ?? false,
      termsAcceptedAt: json['termsAcceptedAt'] != null
          ? DateTime.tryParse(json['termsAcceptedAt'] as String? ??
                  json['termsAcceptedAt'].toString())
          : null,
      privacyAcceptedAt: json['privacyAcceptedAt'] != null
          ? DateTime.tryParse(json['privacyAcceptedAt'] as String? ??
                  json['privacyAcceptedAt'].toString())
          : null,
      paymentConfig: json['paymentConfig'] != null
          ? PaymentConfig.fromJson(json['paymentConfig'] as Map<String, dynamic>)
          : null,
      defaultPaymentMode: _parseDefaultPaymentModes(json)?.first ?? json['defaultPaymentMode'] as String?,
      defaultPaymentModes: _parseDefaultPaymentModes(json),
      paymentIban: json['paymentIban'] as String?,
      paymentBankAccountOwner: json['paymentBankAccountOwner'] as String?,
      paymentInstructions: json['paymentInstructions'] as String?,
      paymentReferenceTemplate: json['paymentReferenceTemplate'] as String?,
      paymentEmailSubjectTemplate: json['paymentEmailSubjectTemplate'] as String?,
      paymentEmailBodyTemplate: json['paymentEmailBodyTemplate'] as String?,
      notificationPreferences: json['notificationPreferences'] != null
          ? NotificationPreferences.fromJson(
              json['notificationPreferences'] as Map<String, dynamic>)
          : null,
    );
  }

  static List<String>? _parseDefaultPaymentModes(Map<String, dynamic> json) {
    final list = json['defaultPaymentModes'] as List<dynamic>?;
    if (list != null && list.isNotEmpty) {
      return list.map((e) => e as String).toList();
    }
    final single = json['defaultPaymentMode'] as String?;
    if (single != null && single.isNotEmpty) return [single];
    return null;
  }

  Map<String, dynamic> toJson() => {
        '_id': id,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'role': role.name,
        'status': status.name,
        'businessName': businessName,
        'avatarUrl': avatarUrl,
        'coverImageUrl': coverImageUrl,
        'tagline': tagline,
        'location': location?.toJson(),
        'locations': locations.map((loc) => loc.toJson()).toList(),
      'termsAccepted': termsAccepted,
      'privacyAccepted': privacyAccepted,
      'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
      'privacyAcceptedAt': privacyAcceptedAt?.toIso8601String(),
      };

  UserLocation? get primaryLocation =>
      location ?? (locations.isNotEmpty ? locations.first : null);
}

class AuthTokens {
  const AuthTokens({required this.accessToken, required this.refreshToken});

  final String accessToken;
  final String refreshToken;

  factory AuthTokens.fromJson(Map<String, dynamic> json) => AuthTokens(
        accessToken: json['accessToken'] as String? ?? '',
        refreshToken: json['refreshToken'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
      };
}

class AuthSession {
  const AuthSession({required this.user, required this.tokens});

  final UserModel user;
  final AuthTokens tokens;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
        tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
      );

  Map<String, dynamic> toJson() => {
        'user': user.toJson(),
        'tokens': tokens.toJson(),
      };
}

class LoginPayload {
  LoginPayload({required this.email, required this.password});

  final String email;
  final String password;

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterPayload {
  RegisterPayload({
    required this.fullName,
    required this.email,
    required this.password,
    required this.role,
    this.phone,
    this.businessName,
    this.country,
    this.city,
    this.address,
    this.defaultPaymentMode,
    this.defaultPaymentModes,
    this.paymentConfig,
    required this.termsAccepted,
    required this.privacyAccepted,
    this.agbAccepted,
    this.complianceAccepted,
    this.privacyLegalAccepted,
    this.frameworkContractAccepted,
  });

  final String fullName;
  final String email;
  final String password;
  final UserRole role;
  final String? phone;
  final String? businessName;
  final String? country;
  final String? city;
  final String? address;
  /// Default payment mode (wholesalers only; legacy single)
  final String? defaultPaymentMode;
  /// Accepted payment modes (wholesalers only; preferred)
  final List<String>? defaultPaymentModes;
  /// Payment config (wholesalers only; can be updated later in profile)
  final PaymentConfig? paymentConfig;
  /// Legal compliance flags (required for backend)
  final bool termsAccepted;
  final bool privacyAccepted;
  /// Wholesaler-specific legal flags (optional; sent when role is wholesaler)
  final bool? agbAccepted;
  final bool? complianceAccepted;
  final bool? privacyLegalAccepted;
  final bool? frameworkContractAccepted;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'email': email,
      if (phone != null && phone!.isNotEmpty) 'phone': phone,
      'password': password,
      'role': role == UserRole.wholesaler ? 'wholesaler' : 'kiosk',
      if (businessName != null && businessName!.isNotEmpty)
        'businessName': businessName,
      if ((country?.isNotEmpty ?? false) ||
          (city?.isNotEmpty ?? false) ||
          (address?.isNotEmpty ?? false))
        'location': {
          if (country != null && country!.isNotEmpty) 'country': country,
          if (city != null && city!.isNotEmpty) 'city': city,
          if (address != null && address!.isNotEmpty) 'address': address,
        },
      'termsAccepted': termsAccepted,
      'privacyAccepted': privacyAccepted,
      if (defaultPaymentModes != null && defaultPaymentModes!.isNotEmpty) 'defaultPaymentModes': defaultPaymentModes,
      if (defaultPaymentMode != null && defaultPaymentMode!.isNotEmpty) 'defaultPaymentMode': defaultPaymentMode,
      if (paymentConfig != null && paymentConfig!.toJson().isNotEmpty) 'paymentConfig': paymentConfig!.toJson(),
      if (agbAccepted != null) 'agbAccepted': agbAccepted,
      if (complianceAccepted != null) 'complianceAccepted': complianceAccepted,
      if (privacyLegalAccepted != null) 'privacyLegalAccepted': privacyLegalAccepted,
      if (frameworkContractAccepted != null) 'frameworkContractAccepted': frameworkContractAccepted,
    }..removeWhere((key, value) => value == null);
  }
}

class UpdateProfilePayload {
  UpdateProfilePayload({
    this.fullName,
    this.businessName,
    this.phone,
    this.avatarUrl,
    this.coverImageUrl,
    this.tagline,
    this.preferredLanguage,
    this.country,
    this.city,
    this.address,
    this.latitude,
    this.longitude,
    this.locations,
    this.termsAccepted,
    this.privacyAccepted,
    this.termsAcceptedAt,
    this.privacyAcceptedAt,
    this.paymentConfig,
    this.defaultPaymentMode,
    this.defaultPaymentModes,
    this.paymentIban,
    this.paymentBankAccountOwner,
    this.paymentInstructions,
    this.paymentReferenceTemplate,
    this.paymentEmailSubjectTemplate,
    this.paymentEmailBodyTemplate,
    this.notificationPreferences,
  });

  final String? fullName;
  final String? businessName;
  final String? phone;
  final String? avatarUrl;
  final String? coverImageUrl;
  final String? tagline;
  final String? preferredLanguage;
  final String? country;
  final String? city;
  final String? address;
  final double? latitude;
  final double? longitude;
  final List<UserLocation>? locations;
  final bool? termsAccepted;
  final bool? privacyAccepted;
  final DateTime? termsAcceptedAt;
  final DateTime? privacyAcceptedAt;
  final PaymentConfig? paymentConfig;
  final String? defaultPaymentMode;
  final List<String>? defaultPaymentModes;
  final String? paymentIban;
  final String? paymentBankAccountOwner;
  final String? paymentInstructions;
  final String? paymentReferenceTemplate;
  final String? paymentEmailSubjectTemplate;
  final String? paymentEmailBodyTemplate;
  final NotificationPreferences? notificationPreferences;

  Map<String, dynamic> toJson() {
    return {
      'fullName': fullName,
      'businessName': businessName,
      'phone': phone,
      'avatarUrl': avatarUrl,
      'coverImageUrl': coverImageUrl,
      'tagline': tagline,
      'preferredLanguage': preferredLanguage,
      'location': {
        'country': country,
        'city': city,
        'address': address,
        'latitude': latitude,
        'longitude': longitude,
      },
      'termsAccepted': termsAccepted,
      'privacyAccepted': privacyAccepted,
      'termsAcceptedAt': termsAcceptedAt?.toIso8601String(),
      'privacyAcceptedAt': privacyAcceptedAt?.toIso8601String(),
      if (paymentConfig != null) 'paymentConfig': paymentConfig!.toJson(),
      if (defaultPaymentModes != null && defaultPaymentModes!.isNotEmpty)
        'defaultPaymentModes': defaultPaymentModes,
      'defaultPaymentMode': defaultPaymentMode,
      'paymentIban': paymentIban,
      'paymentBankAccountOwner': paymentBankAccountOwner,
      'paymentInstructions': paymentInstructions,
      'paymentReferenceTemplate': paymentReferenceTemplate,
      'paymentEmailSubjectTemplate': paymentEmailSubjectTemplate,
      'paymentEmailBodyTemplate': paymentEmailBodyTemplate,
      if (notificationPreferences != null)
        'notificationPreferences': notificationPreferences!.toJson(),
      if (locations != null)
        'locations': locations!
            .map((loc) => {
                  'label': loc.label,
                  'address': loc.address,
                  'country': loc.country,
                  'city': loc.city,
                  'latitude': loc.latitude,
                  'longitude': loc.longitude,
                })
            .toList(),
    }..removeWhere((key, value) =>
        value == null ||
        (value is Map && value.values.every((entry) => entry == null)));
  }
}
