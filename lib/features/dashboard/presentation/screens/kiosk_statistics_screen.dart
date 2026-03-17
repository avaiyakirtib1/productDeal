import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../widgets/kiosk_stats_section.dart' show kioskStatsProvider, KioskStatsSection;

/// Statistics screen for kiosk users – shows deal participation stats.
/// Accessed from Options > Statistics.
class KioskStatisticsScreen extends ConsumerWidget {
  const KioskStatisticsScreen({super.key});

  static const routePath = '/options/statistics';
  static const routeName = 'kiosk_statistics';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.statistics ?? 'Statistics'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(kioskStatsProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
          child: const KioskStatsSection(),
        ),
      ),
    );
  }
}
