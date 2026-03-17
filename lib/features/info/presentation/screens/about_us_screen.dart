import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  static const routePath = '/about-us';
  static const routeName = 'aboutUs';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.aboutUs ?? 'About Us'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.business_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.welcomeToProductDeal ?? 'Welcome to Product Deal',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            l10n?.trustedMarketplace ??
                'Your trusted marketplace for wholesale products and deals',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          _Section(
            title: l10n?.ourMission ?? 'Our Mission',
            content: l10n?.ourMissionContent ??
                'To connect wholesalers and retailers, making bulk purchasing accessible and efficient for businesses of all sizes.',
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n?.whatWeOffer ?? 'What We Offer',
            content: l10n?.whatWeOfferContent ??
                '• Access to verified wholesalers\n• Exclusive bulk deals and discounts\n• Real-time inventory tracking\n• Secure order management\n• Location-based product discovery',
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n?.forWholesalers ?? 'For Wholesalers',
            content: l10n?.forWholesalersContent ??
                'Showcase your products, create exclusive deals, manage orders, and reach a wider network of retailers.',
          ),
          const SizedBox(height: 24),
          _Section(
            title: l10n?.forRetailers ?? 'For Retailers',
            content: l10n?.forRetailersContent ??
                'Discover products from nearby wholesalers, participate in bulk deals, and manage your orders efficiently.',
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.content});

  final String title;
  final String content;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}
