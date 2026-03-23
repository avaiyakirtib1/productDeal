import 'dart:convert';
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// One row from Place Autocomplete predictions.
class PlacePrediction {
  const PlacePrediction({
    required this.placeId,
    required this.description,
  });

  final String placeId;
  final String description;
}

/// Parsed address for registration / profile payloads.
class StructuredPlaceAddress {
  const StructuredPlaceAddress({
    required this.formattedAddress,
    required this.streetLine,
    this.city,
    this.country,
  });

  /// Full line shown in the text field (Google formatted address).
  final String formattedAddress;

  /// Street number + route when available.
  final String streetLine;

  final String? city;
  final String? country;
}

/// Result of an autocomplete request (predictions + diagnostics for UI/logs).
class PlacesAutocompleteOutcome {
  const PlacesAutocompleteOutcome({
    required this.predictions,
    this.httpStatus,
    this.googleStatus,
    this.googleErrorMessage,
  });

  final List<PlacePrediction> predictions;
  final int? httpStatus;
  final String? googleStatus;
  final String? googleErrorMessage;

  /// Show inline hint when Google had no suggestions.
  bool get showNoResultsHint =>
      googleStatus == 'ZERO_RESULTS' ||
      (googleStatus == 'OK' && predictions.isEmpty);

  /// Show SnackBar for denied / quota / invalid request, etc.
  bool get showApiErrorSnack =>
      googleStatus != null &&
      googleStatus != 'OK' &&
      googleStatus != 'ZERO_RESULTS';
}

void _placesVerboseLog(
  String operation,
  String url,
  int? httpStatus,
  String body,
) {
  final header = '[PlacesService][$operation]';
  debugPrint('$header REQUEST: $url');
  if (httpStatus != null) {
    debugPrint('$header HTTP: $httpStatus');
  }
  debugPrint('$header BODY: $body');
  developer.log(
    '$operation http=$httpStatus body=$body',
    name: 'PlacesService',
  );
}

String _trimTrailingSlash(String s) {
  var out = s.trim();
  while (out.endsWith('/')) {
    out = out.substring(0, out.length - 1);
  }
  return out;
}

/// Address autocomplete via **backend proxy** only (`/api/v1/places/*`).
///
/// The Google API key stays on the server. [sessionToken] is passed through
/// for session-based billing.
class PlacesService {
  PlacesService({
    required this.apiBaseUrl,
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

  /// Same base as Dio (`…/api/v1`), e.g. [AppConfig.defaultBaseUrl].
  final String apiBaseUrl;
  final http.Client _client;

  static const _minQueryLength = 2;
  static const Duration debounceDelay = Duration(milliseconds: 400);

  String get _apiBaseNormalized => _trimTrailingSlash(apiBaseUrl);

  bool get isConfigured => _apiBaseNormalized.isNotEmpty;

  Uri _autocompleteUri(String input, String sessionToken) {
    final st = sessionToken.trim();
    return Uri.parse('$_apiBaseNormalized/places/autocomplete').replace(
      queryParameters: {
        'input': input,
        'sessiontoken': st,
      },
    );
  }

  Uri _detailsUri(String placeId, String sessionToken) {
    final st = sessionToken.trim();
    return Uri.parse('$_apiBaseNormalized/places/details').replace(
      queryParameters: {
        'place_id': placeId,
        'sessiontoken': st,
      },
    );
  }

  /// Autocomplete with full logging and structured outcome for the UI.
  Future<PlacesAutocompleteOutcome> fetchAutocompleteOutcome({
    required String input,
    required String sessionToken,
  }) async {
    final trimmed = input.trim();
    if (trimmed.length < _minQueryLength) {
      return const PlacesAutocompleteOutcome(predictions: []);
    }
    if (_apiBaseNormalized.isEmpty) {
      return const PlacesAutocompleteOutcome(
        predictions: [],
        googleStatus: 'INVALID_CONFIG',
        googleErrorMessage:
            'API base URL is empty. Set API_BASE_URL / apiBaseUrl.',
      );
    }

    final uri = _autocompleteUri(trimmed, sessionToken);

    try {
      final response = await _client.get(uri);
      final body = response.body;
      _placesVerboseLog(
        'Autocomplete',
        uri.toString(),
        response.statusCode,
        body,
      );

      if (response.statusCode != 200) {
        final parsed = _tryParseErrorMessage(body);
        return PlacesAutocompleteOutcome(
          predictions: const [],
          httpStatus: response.statusCode,
          googleStatus: 'HTTP_ERROR',
          googleErrorMessage: parsed ??
              'HTTP ${response.statusCode}: '
              '${body.length > 200 ? '${body.substring(0, 200)}…' : body}',
        );
      }

      final json = jsonDecode(body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';
      final errMsg = json['error_message'] as String?;

      if (status != 'OK' && status != 'ZERO_RESULTS') {
        return PlacesAutocompleteOutcome(
          predictions: const [],
          httpStatus: response.statusCode,
          googleStatus: status,
          googleErrorMessage: errMsg ?? status,
        );
      }

      final list = json['predictions'] as List<dynamic>? ?? const [];
      final predictions = list
          .map((e) => e as Map<String, dynamic>)
          .map(
            (m) => PlacePrediction(
              placeId: m['place_id'] as String? ?? '',
              description: m['description'] as String? ?? '',
            ),
          )
          .where((p) => p.placeId.isNotEmpty && p.description.isNotEmpty)
          .toList();

      return PlacesAutocompleteOutcome(
        predictions: predictions,
        httpStatus: response.statusCode,
        googleStatus: status,
        googleErrorMessage: errMsg,
      );
    } on Object catch (e, st) {
      final msg = '$e\n$st';
      _placesVerboseLog('Autocomplete', uri.toString(), null, 'EXCEPTION: $msg');
      return PlacesAutocompleteOutcome(
        predictions: const [],
        googleStatus: 'EXCEPTION',
        googleErrorMessage: e.toString(),
      );
    }
  }

  /// Place Details for structured address. Use the same [sessionToken] as
  /// autocomplete for session billing, then start a new session.
  Future<StructuredPlaceAddress?> fetchPlaceDetails({
    required String placeId,
    required String sessionToken,
  }) async {
    if (placeId.isEmpty || _apiBaseNormalized.isEmpty) {
      return null;
    }

    final uri = _detailsUri(placeId, sessionToken);

    try {
      final response = await _client.get(uri);
      final body = response.body;
      _placesVerboseLog(
        'PlaceDetails',
        uri.toString(),
        response.statusCode,
        body,
      );

      if (response.statusCode != 200) {
        return null;
      }
      final json = jsonDecode(body) as Map<String, dynamic>;
      final status = json['status'] as String? ?? '';
      if (status != 'OK') {
        return null;
      }
      final result = json['result'] as Map<String, dynamic>?;
      if (result == null) {
        return null;
      }
      return _parseDetails(result);
    } on Object catch (e, st) {
      _placesVerboseLog(
        'PlaceDetails',
        uri.toString(),
        null,
        'EXCEPTION: $e\n$st',
      );
      return null;
    }
  }

  String? _tryParseErrorMessage(String body) {
    try {
      final j = jsonDecode(body);
      if (j is Map<String, dynamic>) {
        return j['error_message'] as String? ??
            j['error'] as String? ??
            j['message'] as String?;
      }
    } on Object {
      // ignore
    }
    return null;
  }

  StructuredPlaceAddress? _parseDetails(Map<String, dynamic> result) {
    final formatted =
        result['formatted_address'] as String? ?? '';
    final raw = result['address_components'] as List<dynamic>? ?? const [];
    final components = raw.map((e) => e as Map<String, dynamic>).toList();

    String? streetNumber;
    String? routeName;
    String? city;
    String? country;

    for (final c in components) {
      final types = (c['types'] as List<dynamic>? ?? const [])
          .map((t) => t as String)
          .toList();
      final long = c['long_name'] as String? ?? '';
      if (types.contains('street_number')) {
        streetNumber = long;
      }
      if (types.contains('route')) {
        routeName = long;
      }
      if (types.contains('locality')) {
        city = long;
      }
      if (city == null && types.contains('postal_town')) {
        city = long;
      }
      if (city == null && types.contains('sublocality')) {
        city = long;
      }
      if (types.contains('country')) {
        country = long;
      }
    }

    final parts = <String>[
      if (streetNumber != null && streetNumber.isNotEmpty) streetNumber,
      if (routeName != null && routeName.isNotEmpty) routeName,
    ];
    final streetLine = parts.join(' ').trim();
    final display = formatted.isNotEmpty
        ? formatted
        : (streetLine.isNotEmpty ? streetLine : '');

    if (display.isEmpty) {
      return null;
    }

    return StructuredPlaceAddress(
      formattedAddress: display,
      streetLine: streetLine.isNotEmpty ? streetLine : display,
      city: city,
      country: country,
    );
  }

  void dispose() {
    _client.close();
  }
}
