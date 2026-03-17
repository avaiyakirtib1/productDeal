import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';

/// Display currency option. Code is ISO 4217; label is for UI.
class DisplayCurrency {
  const DisplayCurrency({required this.code, required this.label, this.symbol});

  final String code;
  final String label;
  final String? symbol;

  String get displayLabel =>
      symbol != null ? '$symbol $label ($code)' : '$label ($code)';
}

/// Common currencies for selection. Order: system, then EUR, then alphabetical by code.
const List<DisplayCurrency> displayCurrencies = [
  DisplayCurrency(code: 'EUR', label: 'Euro', symbol: '€'),
  DisplayCurrency(code: 'USD', label: 'US Dollar', symbol: '\$'),
  DisplayCurrency(code: 'GBP', label: 'British Pound', symbol: '£'),
  DisplayCurrency(code: 'AED', label: 'UAE Dirham', symbol: 'AED'),
  DisplayCurrency(code: 'SAR', label: 'Saudi Riyal', symbol: 'SAR'),
  DisplayCurrency(code: 'INR', label: 'Indian Rupee', symbol: '₹'),
  DisplayCurrency(code: 'CHF', label: 'Swiss Franc', symbol: 'CHF'),
  DisplayCurrency(code: 'JPY', label: 'Japanese Yen', symbol: '¥'),
  DisplayCurrency(code: 'AUD', label: 'Australian Dollar', symbol: 'A\$'),
  DisplayCurrency(code: 'CAD', label: 'Canadian Dollar', symbol: 'C\$'),
  DisplayCurrency(code: 'PLN', label: 'Polish Złoty', symbol: 'zł'),
  DisplayCurrency(code: 'TRY', label: 'Turkish Lira', symbol: '₺'),
  DisplayCurrency(code: 'EGP', label: 'Egyptian Pound', symbol: 'E£'),
  DisplayCurrency(code: 'PKR', label: 'Pakistani Rupee', symbol: 'Rs'),
];

class CurrencySelectionScreen extends ConsumerWidget {
  const CurrencySelectionScreen({super.key});

  static const routePath = '/options/currency';
  static const routeName = 'currencySelection';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final selectedCode = ref.watch(currencyControllerProvider);
    final deviceLocale = _deviceLocaleWithRegion();
    final currencyService = ref.read(currencyServiceProvider);
    final systemDefaultCode =
        currencyService.getDisplayCurrencyCode(deviceLocale);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.currency ?? 'Currency'),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              l10n?.currencySubtitle ??
                  'Choose display currency for prices. Default follows device.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          _CurrencyTile(
            isSystemDefault: true,
            label: l10n?.systemDefault ?? 'System default',
            subtitle: _systemSubtitle(systemDefaultCode),
            isSelected: selectedCode == null || selectedCode.isEmpty,
            onTap: () async {
              await ref.read(currencyServiceProvider).refreshRates();
              if (!context.mounted) return;
              ref.read(currencyControllerProvider.notifier).setCurrency(null);
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          const Divider(height: 1),
          ...displayCurrencies.map(
            (c) => _CurrencyTile(
              code: c.code,
              label: c.displayLabel,
              isSelected: selectedCode == c.code,
              onTap: () async {
                await ref.read(currencyServiceProvider).refreshRates();
                if (!context.mounted) return;
                ref
                    .read(currencyControllerProvider.notifier)
                    .setCurrency(c.code);
                if (context.mounted) Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
    );
  }

  Locale _deviceLocaleWithRegion() {
    final locales = WidgetsBinding.instance.platformDispatcher.locales;
    if (locales.isNotEmpty) return locales.first;
    return const Locale('en');
  }

  String _systemSubtitle(String code) {
    try {
      final c = displayCurrencies.firstWhere((e) => e.code == code);
      return '${c.label} (${c.symbol ?? c.code})';
    } catch (_) {
      return code;
    }
  }
}

class _CurrencyTile extends StatelessWidget {
  const _CurrencyTile({
    this.code,
    required this.label,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
    this.isSystemDefault = false,
  });

  final String? code;
  final String label;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isSystemDefault;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        isSystemDefault ? Icons.settings_suggest : Icons.attach_money,
        color: isSelected
            ? Theme.of(context).colorScheme.primary
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(label),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      trailing: isSelected
          ? Icon(Icons.check_circle,
              color: Theme.of(context).colorScheme.primary)
          : null,
      onTap: onTap,
    );
  }
}
