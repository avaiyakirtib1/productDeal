import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/localization/app_localizations.dart';

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  static const routePath = '/help-support';
  static const routeName = 'helpSupport';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.helpSupport ?? 'Help & Support');
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.support_agent_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.wereHereToHelp ?? 'We\'re Here to Help',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              );
            },
          ),
          const SizedBox(height: 32),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _SupportCard(
                icon: Icons.email_outlined,
                title: l10n?.emailSupport ?? 'Email Support',
                subtitle: l10n?.getHelpViaEmail ?? 'Get help via email',
                onTap: () => _launchEmail(context),
              );
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _SupportCard(
                icon: Icons.phone_outlined,
                title: l10n?.phoneSupport ?? 'Phone Support',
                subtitle: l10n?.callUsDuringBusinessHours ??
                    'Call us during business hours',
                onTap: () => _launchPhone(context),
              );
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _SupportCard(
                icon: Icons.chat_bubble_outline,
                title: l10n?.liveChat ?? 'Live Chat',
                subtitle:
                    l10n?.chatWithSupportTeam ?? 'Chat with our support team',
                onTap: () => _showComingSoon(context),
              );
            },
          ),
          const SizedBox(height: 32),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return Text(
                l10n?.commonIssues ?? 'Common Issues',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              );
            },
          ),
          const SizedBox(height: 16),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _IssueCard(
                title: l10n?.orderNotShowingUp ?? 'Order not showing up',
                solution: l10n?.orderNotShowingUpSolution ??
                    'Refresh the dashboard or check your order history in "My Orders"',
              );
            },
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _IssueCard(
                title: l10n?.locationNotUpdating ?? 'Location not updating',
                solution: l10n?.locationNotUpdatingSolution ??
                    'Go to Profile > Addresses and ensure your location coordinates are correct',
              );
            },
          ),
          const SizedBox(height: 12),
          Builder(
            builder: (context) {
              final l10n = AppLocalizations.of(context);
              return _IssueCard(
                title: l10n?.dealProgressNotUpdating ??
                    'Deal progress not updating',
                solution: l10n?.dealProgressNotUpdatingSolution ??
                    'Deal progress updates automatically. If it seems stuck, refresh the page',
              );
            },
          ),
        ],
      ),
    );
  }

  void _launchEmail(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final email = 'support@productdeal.com';
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Support Request',
    );
    launchUrl(uri).catchError((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.emailLabel} $email')),
        );
      }
      return false;
    });
  }

  void _launchPhone(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final phone = '+1-800-PRODUCT';
    final uri = Uri(scheme: 'tel', path: phone);
    launchUrl(uri).catchError((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.phoneLabel} $phone')),
        );
      }
      return false;
    });
  }

  void _showComingSoon(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text(l10n?.liveChatComingSoon ?? 'Live chat coming soon!')),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(icon, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

class _IssueCard extends StatelessWidget {
  const _IssueCard({required this.title, required this.solution});

  final String title;
  final String solution;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              solution,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
