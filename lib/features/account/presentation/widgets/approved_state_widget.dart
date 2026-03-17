import 'package:flutter/material.dart';
import '../../../../core/localization/app_localizations.dart';

class ApprovedStateWidget extends StatelessWidget {
  const ApprovedStateWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.check_circle,
              size: 64,
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.accountApproved ?? 'Account approved!',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.green.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n?.redirecting ?? 'Redirecting...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}
