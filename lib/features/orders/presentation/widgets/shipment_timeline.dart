import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/order_models.dart';

class ShipmentTimeline extends StatelessWidget {
  const ShipmentTimeline({
    super.key,
    required this.shipments,
  });

  final List<Shipment> shipments;

  @override
  Widget build(BuildContext context) {
    if (shipments.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.shipments,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...shipments.map((shipment) => _ShipmentCard(
                  shipment: shipment,
                  l10n: l10n,
                )),
          ],
        ),
      ),
    );
  }
}

class _ShipmentCard extends StatelessWidget {
  const _ShipmentCard({
    required this.shipment,
    required this.l10n,
  });

  final Shipment shipment;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('d MMM yyyy, HH:mm');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.shipmentId.replaceAll('{id}', shipment.id.substring(0, 8)),
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              _StatusChip(status: shipment.status),
            ],
          ),
          if (shipment.trackingNumber != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.local_shipping,
                  size: 16,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.trackingLabel.replaceAll('{number}', shipment.trackingNumber!),
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                if (shipment.trackingUrl != null)
                  TextButton(
                    onPressed: () async {
                      final uri = Uri.parse(shipment.trackingUrl!);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      } else {
                        if (context.mounted) {
                          final l10nCtx = AppLocalizations.of(context)!;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(l10nCtx.couldNotOpenTrackingUrl),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(l10n.track),
                  ),
              ],
            ),
          ],
          if (shipment.carrier != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.carrierLabel.replaceAll('{name}', shipment.carrier!),
              style: theme.textTheme.bodySmall,
            ),
          ],
          if (shipment.estimatedDelivery != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.estDelivery.replaceAll('{date}', dateFormat.format(shipment.estimatedDelivery!.toLocal())),
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
          if (shipment.shippedAt != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.shippedAt.replaceAll('{date}', dateFormat.format(shipment.shippedAt!.toLocal())),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
          ],
          if (shipment.deliveredAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  size: 16,
                  color: Colors.green,
                ),
                const SizedBox(width: 4),
                Text(
                  l10n.deliveredAt.replaceAll('{date}', dateFormat.format(shipment.deliveredAt!.toLocal())),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (shipment.deliveryNotes != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                shipment.deliveryNotes!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
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
