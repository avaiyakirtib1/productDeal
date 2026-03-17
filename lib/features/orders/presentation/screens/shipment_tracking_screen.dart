import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_models.dart';
import '../../data/repositories/order_repository.dart';

final shipmentTrackingProvider =
    FutureProvider.autoDispose.family<Shipment?, String>(
  (ref, trackingNumber) async {
    final repo = ref.watch(orderRepositoryProvider);
    try {
      return await repo.trackShipment(trackingNumber);
    } catch (e) {
      return null;
    }
  },
);

class ShipmentTrackingScreen extends ConsumerStatefulWidget {
  const ShipmentTrackingScreen({super.key});

  static const routePath = '/track/:trackingNumber';
  static const routeName = 'shipmentTracking';

  @override
  ConsumerState<ShipmentTrackingScreen> createState() =>
      _ShipmentTrackingScreenState();
}

class _ShipmentTrackingScreenState
    extends ConsumerState<ShipmentTrackingScreen> {
  final _trackingNumberController = TextEditingController();

  @override
  void dispose() {
    _trackingNumberController.dispose();
    super.dispose();
  }

  void _trackShipment() {
    final trackingNumber = _trackingNumberController.text.trim();
    if (trackingNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context)?.pleaseEnterTrackingNumber ??
                'Please enter a tracking number',
          ),
        ),
      );
      return;
    }

    // Navigate to tracking result
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _ShipmentTrackingResultScreen(
          trackingNumber: trackingNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trackShipment),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.enterTrackingNumber,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              l10n.trackShipmentHint,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _trackingNumberController,
              decoration: InputDecoration(
                labelText: l10n.trackingNumber,
                hintText: l10n.enterTrackingNumber,
                prefixIcon: const Icon(Icons.local_shipping),
                border: const OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              onSubmitted: (_) => _trackShipment(),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _trackShipment,
              icon: const Icon(Icons.search),
              label: Text(l10n.trackShipment),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShipmentTrackingResultScreen extends ConsumerWidget {
  const _ShipmentTrackingResultScreen({
    required this.trackingNumber,
  });

  final String trackingNumber;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final shipmentAsync = ref.watch(shipmentTrackingProvider(trackingNumber));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.trackingDetails),
      ),
      body: shipmentAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(l10n.shipmentNotFound),
              const SizedBox(height: 8),
              Text(
                l10n.pleaseCheckTrackingNumber,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(
                  shipmentTrackingProvider(trackingNumber),
                ),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
        data: (shipment) {
          if (shipment == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(l10n.shipmentNotFound),
                  const SizedBox(height: 8),
                  Text(
                    l10n.pleaseCheckTrackingNumber,
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return _ShipmentDetailsView(shipment: shipment);
        },
      ),
    );
  }
}

class _ShipmentDetailsView extends StatelessWidget {
  const _ShipmentDetailsView({
    required this.shipment,
  });

  final Shipment shipment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.trackingNumber,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    _StatusChip(status: shipment.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  shipment.trackingNumber ?? shipment.id,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
                if (shipment.carrier != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    '${l10n.carrier}: ${shipment.carrier}',
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.statusTimeline ?? 'Status Timeline',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 16),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _TimelineItem(
                      icon: Icons.shopping_cart,
                      title: l10n?.orderPlaced ?? 'Order Placed',
                      date: shipment.createdAt,
                      dateFormat: dateFormat,
                      isActive: true,
                    );
                  },
                ),
                if (shipment.packedAt != null)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _TimelineItem(
                        icon: Icons.inventory,
                        title: l10n?.packed ?? 'Packed',
                        date: shipment.packedAt!,
                        dateFormat: dateFormat,
                        isActive: shipment.status.index >=
                            ShipmentStatus.packed.index,
                      );
                    },
                  ),
                if (shipment.shippedAt != null)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _TimelineItem(
                        icon: Icons.local_shipping,
                        title: l10n?.shipped ?? 'Shipped',
                        date: shipment.shippedAt!,
                        dateFormat: dateFormat,
                        isActive: shipment.status.index >=
                            ShipmentStatus.shipped.index,
                      );
                    },
                  ),
                if (shipment.deliveredAt != null)
                  Builder(
                    builder: (context) {
                      final l10n = AppLocalizations.of(context);
                      return _TimelineItem(
                        icon: Icons.check_circle,
                        title: l10n?.delivered ?? 'Delivered',
                        date: shipment.deliveredAt!,
                        dateFormat: dateFormat,
                        isActive: shipment.status == ShipmentStatus.delivered,
                        isCompleted: true,
                      );
                    },
                  ),
                if (shipment.estimatedDelivery != null &&
                    shipment.status != ShipmentStatus.delivered) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Estimated Delivery',
                                style: theme.textTheme.labelSmall,
                              ),
                              Text(
                                dateFormat.format(
                                  shipment.estimatedDelivery!.toLocal(),
                                ),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (shipment.deliveryNotes != null) ...[
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Delivery Notes',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    shipment.deliveryNotes!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
        if (shipment.trackingUrl != null) ...[
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              // TODO: Open tracking URL
            },
            icon: const Icon(Icons.open_in_new),
            label: Text(l10n.trackOnCarrierWebsite),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ],
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  const _TimelineItem({
    required this.icon,
    required this.title,
    required this.date,
    required this.dateFormat,
    required this.isActive,
    this.isCompleted = false,
  });

  final IconData icon;
  final String title;
  final DateTime date;
  final DateFormat dateFormat;
  final bool isActive;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isCompleted
        ? Colors.green
        : isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? color.withValues(alpha: 0.1)
                  : theme.colorScheme.surfaceContainerHighest,
              border: Border.all(
                color: isActive ? color : theme.colorScheme.outline,
                width: 2,
              ),
            ),
            child: Icon(
              icon,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                Text(
                  dateFormat.format(date.toLocal()),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.status,
  });

  final ShipmentStatus status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Color backgroundColor;
    Color textColor;

    switch (status) {
      case ShipmentStatus.delivered:
        backgroundColor = Colors.green.withValues(alpha: 0.1);
        textColor = Colors.green;
        break;
      case ShipmentStatus.shipped:
      case ShipmentStatus.inTransit:
      case ShipmentStatus.outForDelivery:
        backgroundColor = theme.colorScheme.primaryContainer;
        textColor = theme.colorScheme.onPrimaryContainer;
        break;
      case ShipmentStatus.failedDelivery:
      case ShipmentStatus.returned:
      case ShipmentStatus.cancelled:
        backgroundColor = Colors.red.withValues(alpha: 0.1);
        textColor = Colors.red;
        break;
      default:
        backgroundColor = theme.colorScheme.surfaceContainerHighest;
        textColor = theme.colorScheme.onSurfaceVariant;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
