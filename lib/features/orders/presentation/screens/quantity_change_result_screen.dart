import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_localizations.dart';
import 'my_orders_screen.dart';

/// Screen shown when user lands from email link after accepting/declining a quantity change.
/// Handles query params: quantity_change (accepted|declined|error), type (deal|product), message (optional).
class QuantityChangeResultScreen extends StatelessWidget {
  const QuantityChangeResultScreen({
    super.key,
    required this.quantityChange,
    this.type,
    this.message,
  });

  static const routePath = '/quantity-change-result';
  static const routeName = 'quantity-change-result';

  final String quantityChange; // accepted, declined, error
  final String? type; // deal, product
  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.orderUpdate ?? 'Order Update'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildIcon(quantityChange, theme),
              const SizedBox(height: 24),
              Text(
                _buildTitle(quantityChange, l10n),
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _buildMessage(quantityChange, message, l10n),
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: () => context.go(MyOrdersScreen.routePath),
                child: Text(l10n?.viewMyOrders ?? 'View My Orders'),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/'),
                child: Text(l10n?.goToHome ?? 'Go to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(String status, ThemeData theme) {
    IconData icon;
    Color color;
    switch (status) {
      case 'accepted':
        icon = Icons.check_circle_outline;
        color = theme.colorScheme.primary;
        break;
      case 'declined':
        icon = Icons.undo;
        color = theme.colorScheme.tertiary;
        break;
      default:
        icon = Icons.error_outline;
        color = theme.colorScheme.error;
    }
    return Center(
      child: Icon(icon, size: 80, color: color),
    );
  }

  String _buildTitle(String status, AppLocalizations? l10n) {
    switch (status) {
      case 'accepted':
        return l10n?.quantityChangeAccepted ?? 'Quantity change accepted';
      case 'declined':
        return l10n?.quantityChangeDeclined ?? 'Quantity change declined';
      default:
        return l10n?.somethingWentWrong ?? 'Something went wrong';
    }
  }

  String _buildMessage(String status, String? message, AppLocalizations? l10n) {
    switch (status) {
      case 'accepted':
        return l10n?.orderUpdatedMessage ?? 'Your order has been updated.';
      case 'declined':
        return l10n?.orderRevertedMessage ??
            'Your order has been reverted to the previous quantity.';
      default:
        return message ?? (l10n?.pleaseTryAgainLater ?? 'Please try again later.');
    }
  }
}
