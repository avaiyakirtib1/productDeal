import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/services/currency_service.dart';
import '../../data/models/deal_models.dart';
import '../../data/repositories/deal_repository.dart';
import '../../../../shared/utils/snackbar_utils.dart';

/// Predefined carriers with their tracking URL formats
class ShipmentCarrier {
  final String name;
  final String urlFormat;

  const ShipmentCarrier({required this.name, required this.urlFormat});

  String generateTrackingUrl(String trackingNumber) {
    return urlFormat.replaceAll('{tracking}', trackingNumber);
  }
}

const List<ShipmentCarrier> shipmentCarriers = [
  ShipmentCarrier(
    name: 'DHL',
    urlFormat: 'https://www.dhl.com/en/express/tracking.html?AWB={tracking}',
  ),
  ShipmentCarrier(
    name: 'FedEx',
    urlFormat: 'https://www.fedex.com/fedextrack/?trknbr={tracking}',
  ),
  ShipmentCarrier(
    name: 'UPS',
    urlFormat: 'https://www.ups.com/track?tracknum={tracking}',
  ),
  ShipmentCarrier(
    name: 'Aramex',
    urlFormat: 'https://www.aramex.com/track/results?ShipmentNumber={tracking}',
  ),
  ShipmentCarrier(
    name: 'Emirates Post',
    urlFormat: 'https://www.emiratespost.ae/track/{tracking}',
  ),
  ShipmentCarrier(
    name: 'SMSA Express',
    urlFormat: 'https://www.smsaexpress.com/track/{tracking}',
  ),
  ShipmentCarrier(
    name: 'Aramex UAE',
    urlFormat: 'https://www.aramex.com/track/results?ShipmentNumber={tracking}',
  ),
  ShipmentCarrier(
    name: 'DHL Express UAE',
    urlFormat: 'https://www.dhl.com/en/express/tracking.html?AWB={tracking}',
  ),
  ShipmentCarrier(
    name: 'Fetchr',
    urlFormat: 'https://fetchr.us/track/{tracking}',
  ),
  ShipmentCarrier(
    name: 'Other',
    urlFormat: '', // Custom URL
  ),
];

class CreateDealShipmentModal extends ConsumerStatefulWidget {
  const CreateDealShipmentModal({
    super.key,
    required this.order,
    required this.onSuccess,
  });

  final DealOrder order;
  final Future<void> Function()? onSuccess;

  @override
  ConsumerState<CreateDealShipmentModal> createState() =>
      _CreateDealShipmentModalState();
}

class _CreateDealShipmentModalState
    extends ConsumerState<CreateDealShipmentModal> {
  final _formKey = GlobalKey<FormState>();
  final _trackingNumberController = TextEditingController();
  final _customCarrierController = TextEditingController();
  final _trackingUrlController = TextEditingController();
  final _notesController = TextEditingController();

  ShipmentCarrier? _selectedCarrier;
  DateTime? _estimatedDelivery;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Auto-generate tracking URL when carrier and tracking number change
    _trackingNumberController.addListener(_updateTrackingUrl);
  }

  @override
  void dispose() {
    _trackingNumberController.dispose();
    _customCarrierController.dispose();
    _trackingUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _updateTrackingUrl() {
    if (_selectedCarrier != null &&
        _trackingNumberController.text.isNotEmpty &&
        _selectedCarrier!.name != 'Other') {
      final url =
          _selectedCarrier!.generateTrackingUrl(_trackingNumberController.text);
      if (_trackingUrlController.text != url) {
        _trackingUrlController.text = url;
      }
    } else if (_trackingNumberController.text.isEmpty) {
      _trackingUrlController.clear();
    }
  }

  void _onCarrierChanged(ShipmentCarrier? carrier) {
    setState(() {
      _selectedCarrier = carrier;
      if (carrier?.name == 'Other') {
        _customCarrierController.clear();
        _trackingUrlController.clear();
      } else {
        _updateTrackingUrl();
      }
    });
  }

  Future<void> _selectEstimatedDelivery() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 3)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _estimatedDelivery = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCarrier == null) {
      SnackbarUtils.showError(
        context,
        AppLocalizations.of(context)?.pleaseSelectCarrier ??
            'Please select a carrier',
      );
      return;
    }

    if (_selectedCarrier!.name == 'Other' &&
        _customCarrierController.text.isEmpty) {
      SnackbarUtils.showError(
        context,
        AppLocalizations.of(context)?.pleaseEnterCarrierNameForOther ??
            'Please enter carrier name for "Other"',
      );
      return;
    }

    if (_selectedCarrier!.name == 'Other' &&
        _trackingUrlController.text.isEmpty) {
      SnackbarUtils.showError(
        context,
        AppLocalizations.of(context)?.pleaseEnterTrackingUrlForOther ??
            'Please enter tracking URL for "Other" carrier',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final repo = ref.read(dealRepositoryProvider);
      await repo.createDealShipment(
        orderId: widget.order.id,
        trackingNumber: _trackingNumberController.text.trim().isEmpty
            ? null
            : _trackingNumberController.text.trim(),
        carrier: _selectedCarrier!.name == 'Other'
            ? _customCarrierController.text.trim()
            : _selectedCarrier!.name,
        trackingUrl: _trackingUrlController.text.trim().isEmpty
            ? null
            : _trackingUrlController.text.trim(),
        estimatedDelivery: _estimatedDelivery,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        AppLocalizations.of(context)?.shipmentCreatedAndOrderShipped ??
            'Shipment created and order marked as shipped',
      );
      await widget.onSuccess?.call();
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          '${AppLocalizations.of(context)?.failedToCreateShipment ?? 'Failed to create shipment'}: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final order = widget.order;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.createShipment,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Order Info
                      Card(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.orderDetails,
                                style: theme.textTheme.titleSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.quantity,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${order.quantity} ${l10n.units}',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    l10n.totalAmount,
                                    style: theme.textTheme.bodySmall,
                                  ),
                                  Text(
                                    '${context.formatPriceEurOnly(order.totalAmount)} '
                                    '(${context.formatPriceUsdFromEur(order.totalAmount)})',
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Carrier Selection
                      Text(
                        l10n.carrier,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<ShipmentCarrier>(
                        initialValue: _selectedCarrier,
                        decoration: InputDecoration(
                          labelText: l10n.selectCarrier,
                          hintText: l10n.selectCarrierHint,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: shipmentCarriers.map((carrier) {
                          return DropdownMenuItem(
                            value: carrier,
                            child: Text(carrier.name),
                          );
                        }).toList(),
                        onChanged: _isLoading ? null : _onCarrierChanged,
                        validator: (value) =>
                            value == null ? l10n.pleaseSelectCarrier : null,
                      ),
                      if (_selectedCarrier?.name == 'Other') ...[
                        const SizedBox(height: 12),
                        TextFormField(
                          controller: _customCarrierController,
                          decoration: InputDecoration(
                            labelText: l10n.carrierName,
                            hintText: l10n.enterCarrierName,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          enabled: !_isLoading,
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Tracking Number
                      TextFormField(
                        controller: _trackingNumberController,
                        decoration: InputDecoration(
                          labelText: l10n.trackingNumber,
                          hintText: l10n.enterTrackingNumber,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        enabled: !_isLoading,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return l10n.trackingNumberRequired;
                          }
                          return null;
                        },
                      ),
                      if (_selectedCarrier != null &&
                          _trackingNumberController.text.isNotEmpty &&
                          _selectedCarrier!.name != 'Other') ...[
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.check_circle,
                                size: 16, color: Colors.green),
                            const SizedBox(width: 4),
                            Text(
                              l10n.trackingUrlAutoGenerated,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 16),
                      // Tracking URL
                      TextFormField(
                        controller: _trackingUrlController,
                          decoration: InputDecoration(
                            labelText: l10n.trackingUrl,
                            hintText: _selectedCarrier?.name == 'Other'
                                ? 'https://...'
                                : l10n.trackingUrlHintAuto,
                            border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          suffixIcon: _trackingUrlController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.open_in_new),
                                  onPressed: () async {
                                    final uri =
                                        Uri.parse(_trackingUrlController.text);
                                    if (await canLaunchUrl(uri)) {
                                      await launchUrl(uri,
                                          mode: LaunchMode.externalApplication);
                                    }
                                  },
                                )
                              : null,
                        ),
                        enabled: !_isLoading &&
                            (_selectedCarrier?.name == 'Other' ||
                                _trackingNumberController.text.isEmpty),
                        readOnly: _selectedCarrier?.name != 'Other' &&
                            _trackingNumberController.text.isNotEmpty,
                        validator: (value) {
                          if (_selectedCarrier?.name == 'Other' &&
                              (value == null || value.trim().isEmpty)) {
                            return l10n.trackingUrlRequiredForOther;
                          }
                          if (value != null &&
                              value.trim().isNotEmpty &&
                              !Uri.tryParse(value)!.hasScheme) {
                            return l10n.pleaseEnterValidUrl;
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      // Estimated Delivery
                      InkWell(
                        onTap: _isLoading ? null : _selectEstimatedDelivery,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: l10n.estimatedDeliveryDate,
                            hintText: l10n.selectDate,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            suffixIcon: const Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            _estimatedDelivery != null
                                ? DateFormat('d MMM yyyy')
                                    .format(_estimatedDelivery!)
                                : l10n.selectDate,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _estimatedDelivery != null
                                  ? null
                                  : theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notes
                      TextFormField(
                        controller: _notesController,
                          decoration: InputDecoration(
                            labelText: l10n.notesOptional,
                            hintText: l10n.internalNotesShipment,
                            border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        maxLines: 3,
                        enabled: !_isLoading,
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed:
                          _isLoading ? null : () => Navigator.of(context).pop(),
                      child: Text(l10n.cancel),
                    ),
                    const SizedBox(width: 12),
                    FilledButton(
                      onPressed: _isLoading ? null : _submit,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.createShipment),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
