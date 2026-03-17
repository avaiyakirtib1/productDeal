import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../localization/currency_controller.dart';
import '../../features/dashboard/presentation/controllers/story_view_state.dart';

/// Base currency for all backend amounts (prices, shipping, etc.).
const String baseCurrencyCode = 'EUR';

/// Frankfurter API: free FX rates (ECB-backed), no API key, CORS-friendly for web.
/// https://frankfurter.dev/ | https://api.frankfurter.app/latest?from=EUR
const String _fxRatesUrl = 'https://api.frankfurter.app/latest?from=EUR';

/// Cache key and refresh interval for FX rates.
const String _prefRatesKey = 'currency_fx_rates';
const String _prefRatesTimeKey = 'currency_fx_rates_time';
const Duration _ratesRefreshInterval = Duration(hours: 24);

/// Maps locale country/region to ISO 4217 currency code for display.
/// Used when device locale has region (e.g. en_AE → AED). Fallback: EUR.
final Map<String, String> _regionToCurrency = {
  'AE': 'AED',
  'AU': 'AUD',
  'AT': 'EUR',
  'BE': 'EUR',
  'CA': 'CAD',
  'CH': 'CHF',
  'DE': 'EUR',
  'ES': 'EUR',
  'FR': 'EUR',
  'GB': 'GBP',
  'IN': 'INR',
  'IT': 'EUR',
  'JP': 'JPY',
  'NL': 'EUR',
  'SA': 'SAR',
  'US': 'USD',
  'PL': 'PLN',
  'TR': 'TRY',
  'EG': 'EGP',
  'PK': 'PKR',
};

class CurrencyService {
  CurrencyService(this._prefs) {
    _loadCachedRates();
    _scheduleRefresh();
  }

  final SharedPreferences _prefs;

  Map<String, double> _rates = {}; // EUR -> XXX rate (EUR is 1)
  DateTime? _lastFetched;

  static String _getDisplayCurrencyCode(Locale locale) {
    final region = locale.countryCode;
    if (region != null && region.isNotEmpty) {
      final currency = _regionToCurrency[region.toUpperCase()];
      if (currency != null) return currency;
    }
    return baseCurrencyCode;
  }

  /// Returns the display currency code for the given locale (from device region).
  String getDisplayCurrencyCode(Locale locale) =>
      _getDisplayCurrencyCode(locale);

  /// Returns the rate from EUR to the given currency (1 EUR = rate * displayAmount).
  double getRateTo(String currencyCode) {
    if (currencyCode == baseCurrencyCode) return 1.0;
    return _rates[currencyCode] ?? 1.0;
  }

  /// Number of cached FX rates (0 if not yet loaded).
  int get ratesCount => _rates.length;

  /// Formats an amount stored in backend as EUR for display in the user's local currency.
  /// Uses device/platform locale for currency (region) and FX rate from Frankfurter API.
  String formatPrice(num amountEur, Locale locale, {int? decimalDigits}) {
    final currencyCode = _getDisplayCurrencyCode(locale);
    return formatPriceWithCurrency(amountEur, currencyCode,
        decimalDigits: decimalDigits);
  }

  /// Formats an amount in EUR for display in the given [currencyCode].
  String formatPriceWithCurrency(num amountEur, String currencyCode,
      {int? decimalDigits}) {
    final rate = getRateTo(currencyCode);
    final localAmount = amountEur * rate;
    final symbol = _currencySymbol(currencyCode);
    final format = NumberFormat.currency(
      symbol: symbol,
      decimalDigits: decimalDigits ?? 2,
    );
    return format.format(localAmount);
  }

  String _currencySymbol(String code) {
    switch (code) {
      case 'EUR':
        return '€';
      case 'USD':
        return '\$';
      case 'GBP':
        return '£';
      case 'AED':
        return 'AED ';
      case 'SAR':
        return 'SAR ';
      case 'INR':
        return '₹';
      case 'JPY':
        return '¥';
      default:
        return '$code ';
    }
  }

  Future<void> refreshRates() async {
    try {
      final dio = Dio(BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ));
      debugPrint('CurrencyService: Fetching FX rates from $_fxRatesUrl');
      final response = await dio.get<Map<String, dynamic>>(
        _fxRatesUrl,
        options: Options(responseType: ResponseType.json),
      );
      final data = response.data;
      if (data == null) return;
      final ratesJson = data['rates'] as Map<String, dynamic>?;
      if (ratesJson == null || ratesJson.isEmpty) return;
      final parsed = ratesJson.map<String, double>((k, v) {
        final rate = (v is num) ? v.toDouble() : double.tryParse(v.toString());
        return MapEntry(k, rate ?? 0.0);
      });
      parsed.removeWhere((_, rate) => rate <= 0);
      if (parsed.isNotEmpty) {
        _rates = parsed;
        _lastFetched = DateTime.now();
        await _saveCachedRates();
        debugPrint(
            'CurrencyService: loaded ${_rates.length} FX rates from Frankfurter');
      }
    } catch (e, st) {
      debugPrint('CurrencyService: failed to fetch FX rates: $e');
      debugPrint('CurrencyService: $st');
    }
  }

  Future<void> _loadCachedRates() async {
    final json = _prefs.getString(_prefRatesKey);
    final timeMs = _prefs.getInt(_prefRatesTimeKey);
    if (json != null && timeMs != null) {
      try {
        final map = jsonDecode(json) as Map<String, dynamic>;
        _rates = map.map((k, v) => MapEntry(k, (v as num).toDouble()));
        _lastFetched = DateTime.fromMillisecondsSinceEpoch(timeMs);
      } catch (_) {}
    }
    if (_rates.isEmpty) await refreshRates();
  }

  Future<void> _saveCachedRates() async {
    await _prefs.setString(_prefRatesKey, jsonEncode(_rates));
    await _prefs.setInt(
      _prefRatesTimeKey,
      (_lastFetched ?? DateTime.now()).millisecondsSinceEpoch,
    );
  }

  void _scheduleRefresh() {
    Future<void> doRefresh() async {
      final shouldRefresh = _lastFetched == null ||
          DateTime.now().difference(_lastFetched!) > _ratesRefreshInterval;
      if (shouldRefresh) await refreshRates();
    }

    doRefresh();
    Timer.periodic(const Duration(minutes: 60), (_) => doRefresh());
  }
}

final currencyServiceProvider = Provider<CurrencyService>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return CurrencyService(prefs);
});

/// Device locale with region (for currency). Use first platform locale so region is set (e.g. en_AE).
Locale get deviceLocaleWithRegion {
  final locales = WidgetsBinding.instance.platformDispatcher.locales;
  if (locales.isNotEmpty) return locales.first;
  return const Locale('en');
}

/// Extension so widgets can do context.formatPriceEur(amount).
extension FormatPriceEurExtension on BuildContext {
  /// Formats [amountEur] (backend amount in EUR) using the current display currency.
  ///
  /// NOTE: For client requirement \"EUR primary + USD indicator\", prefer
  /// [formatPriceEurOnly] for the main amount plus [formatPriceUsdFromEur]
  /// for the secondary line, instead of this helper.
  String formatPriceEur(num amountEur, {int? decimalDigits}) {
    final container = ProviderScope.containerOf(this, listen: false);
    final service = container.read(currencyServiceProvider);
    final selectedCode = container.read(currencyControllerProvider);
    final effectiveCode = (selectedCode != null && selectedCode.isNotEmpty)
        ? selectedCode
        : service.getDisplayCurrencyCode(deviceLocaleWithRegion);
    return service.formatPriceWithCurrency(
      amountEur,
      effectiveCode,
      decimalDigits: decimalDigits,
    );
  }

  /// Formats [amountEur] in EUR only (base currency).
  ///
  /// Client requirement: EUR is always the primary currency for storage
  /// and display, so this should be used for the main visible amount.
  String formatPriceEurOnly(num amountEur, {int? decimalDigits}) {
    final service = ProviderScope.containerOf(this, listen: false)
        .read(currencyServiceProvider);
    return service.formatPriceWithCurrency(
      amountEur,
      baseCurrencyCode,
      decimalDigits: decimalDigits,
    );
  }

  /// Formats [amountEur] (stored in EUR) as USD using FX rates.
  ///
  /// Used to show the secondary \"USD in brackets\" indicator under the main EUR price.
  String formatPriceUsdFromEur(num amountEur, {int? decimalDigits}) {
    final service = ProviderScope.containerOf(this, listen: false)
        .read(currencyServiceProvider);
    return service.formatPriceWithCurrency(
      amountEur,
      'USD',
      decimalDigits: decimalDigits,
    );
  }

  /// Shows EUR and local currency for clarity on cart/checkout. e.g. "€10.00 (AED 40.00)" or "€10.00" when display is EUR.
  String formatPriceEurWithLocal(num amountEur, {int? decimalDigits}) {
    final container = ProviderScope.containerOf(this, listen: false);
    final service = container.read(currencyServiceProvider);
    final selectedCode = container.read(currencyControllerProvider);
    final effectiveCode = (selectedCode != null && selectedCode.isNotEmpty)
        ? selectedCode
        : service.getDisplayCurrencyCode(deviceLocaleWithRegion);
    final eurStr = service.formatPriceWithCurrency(
      amountEur,
      baseCurrencyCode,
      decimalDigits: decimalDigits,
    );
    if (effectiveCode == baseCurrencyCode) return eurStr;
    final localStr = service.formatPriceWithCurrency(
      amountEur,
      effectiveCode,
      decimalDigits: decimalDigits,
    );
    return '$eurStr ($localStr)';
  }
}
