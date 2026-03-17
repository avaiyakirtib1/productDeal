import 'package:flutter/material.dart';

import '../../../../core/localization/app_localizations.dart';

class FAQScreen extends StatelessWidget {
  const FAQScreen({super.key});

  static const routePath = '/faq';
  static const routeName = 'faq';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
            l10n?.frequentlyAskedQuestions ?? 'Frequently Asked Questions'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Icon(
            Icons.help_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            l10n?.commonQuestions ?? 'Common Questions',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ..._getFaqItems(l10n).map((item) => _FAQItem(
                question: item['question']!,
                answer: item['answer']!,
              )),
        ],
      ),
    );
  }

  static List<Map<String, String>> _getFaqItems(AppLocalizations? l10n) {
    return [
      {
        'question': l10n?.faqQuestion1 ?? 'How do I place an order?',
        'answer': l10n?.faqAnswer1 ??
            'Browse active deals or products, select the quantity you need, and click "Place Order". Your order will be reviewed by the wholesaler.',
      },
      {
        'question': l10n?.faqQuestion2 ?? 'What are deal orders?',
        'answer': l10n?.faqAnswer2 ??
            'Deal orders are bulk purchasing opportunities where wholesalers offer discounted prices when a target quantity is reached. You can place multiple orders on the same deal.',
      },
      {
        'question': l10n?.faqQuestion3 ?? 'How is shipping handled?',
        'answer': l10n?.faqAnswer3 ??
            'Shipping details are arranged directly with the wholesaler after your order is confirmed. Contact information will be provided upon order confirmation.',
      },
      {
        'question': l10n?.faqQuestion4 ?? 'Can I cancel an order?',
        'answer': l10n?.faqAnswer4 ??
            'You can cancel pending orders. Once an order is confirmed by the wholesaler, cancellation policies apply as per the wholesaler\'s terms.',
      },
      {
        'question':
            l10n?.faqQuestion5 ?? 'How do I become a verified wholesaler?',
        'answer': l10n?.faqAnswer5 ??
            'Contact our support team to get verified. You\'ll need to provide business documentation and complete the verification process.',
      },
      {
        'question':
            l10n?.faqQuestion6 ?? 'How are products sorted by distance?',
        'answer': l10n?.faqAnswer6 ??
            'Products are automatically sorted by proximity to your location. Make sure to add your location in your profile for accurate distance-based sorting.',
      },
      {
        'question': l10n?.faqQuestion7 ?? 'What payment methods are accepted?',
        'answer': l10n?.faqAnswer7 ??
            'Payment methods vary by wholesaler. Payment details are discussed after order confirmation.',
      },
      {
        'question': l10n?.faqQuestion8 ?? 'How do I update my profile?',
        'answer': l10n?.faqAnswer8 ??
            'Go to your profile page from the dashboard, update your information, and save. You can add multiple addresses for different locations.',
      },
    ];
  }
}

class _FAQItem extends StatefulWidget {
  const _FAQItem({required this.question, required this.answer});

  final String question;
  final String answer;

  @override
  State<_FAQItem> createState() => _FAQItemState();
}

class _FAQItemState extends State<_FAQItem> {
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        title: Text(
          widget.question,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Text(
              widget.answer,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
