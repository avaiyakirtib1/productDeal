import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../data/models/deal_models.dart';

class DealTimer extends StatefulWidget {
  const DealTimer({super.key, required this.deal});

  final Deal deal;

  @override
  State<DealTimer> createState() => _DealTimerState();
}

class _DealTimerState extends State<DealTimer> {
  @override
  Widget build(BuildContext context) {
    final deal = widget.deal;
    final theme = Theme.of(context);
    final timeRemaining = deal.timeRemaining;

    final l10n = AppLocalizations.of(context)!;
    if (deal.isEnded) {
      return Card(
        color: theme.colorScheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.event_busy,
                color: theme.colorScheme.onErrorContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.dealEnded,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (timeRemaining.isNegative) {
      return Card(
        color: theme.colorScheme.surfaceContainerHighest,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.schedule,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n.dealHasEnded,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Show countdown if <= 1 hour, else show text
    if (deal.hasLessThanOneHour) {
      return _CountdownTimer(deal: deal);
    } else {
      return _TimeRemainingText(deal: deal);
    }
  }
}

class _CountdownTimer extends StatefulWidget {
  const _CountdownTimer({required this.deal});

  final Deal deal;

  @override
  State<_CountdownTimer> createState() => _CountdownTimerState();
}

class _CountdownTimerState extends State<_CountdownTimer> {
  late Duration _remaining;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _endTime = widget.deal.endAt;
    _remaining = _endTime.difference(DateTime.now());
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      final now = DateTime.now();
      final remaining = _endTime.difference(now);
      if (remaining.isNegative) {
        setState(() {
          _remaining = Duration.zero;
        });
        return;
      }
      setState(() {
        _remaining = remaining;
      });
      if (_remaining.inSeconds > 0) {
        _startTimer();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final hours = _remaining.inHours;
    final minutes = _remaining.inMinutes.remainder(60);
    final seconds = _remaining.inSeconds.remainder(60);

    return Card(
      color: theme.colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.timer,
                  color: theme.colorScheme.onErrorContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n.endingSoon,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _TimeUnit(
                      value: hours.toString().padLeft(2, '0'),
                      label: l10n?.hours ?? 'Hours',
                      color: theme.colorScheme.onErrorContainer,
                    );
                  },
                ),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _TimeUnit(
                      value: minutes.toString().padLeft(2, '0'),
                      label: l10n?.minutes ?? 'Minutes',
                      color: theme.colorScheme.onErrorContainer,
                    );
                  },
                ),
                Text(
                  ':',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _TimeUnit(
                      value: seconds.toString().padLeft(2, '0'),
                      label: l10n?.seconds ?? 'Seconds',
                      color: theme.colorScheme.onErrorContainer,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  const _TimeUnit({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _TimeRemainingText extends StatelessWidget {
  const _TimeRemainingText({required this.deal});

  final Deal deal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final timeRemaining = deal.timeRemaining;
    final days = timeRemaining.inDays;
    final hours = timeRemaining.inHours.remainder(24);

    String text;
    if (days > 0) {
      text = days == 1 ? l10n.endsIn1Day : l10n.endsInDays.replaceAll('{n}', '$days');
    } else if (hours > 0) {
      text = hours == 1 ? l10n.endsIn1Hour : l10n.endsInHours.replaceAll('{n}', '$hours');
    } else {
      text = l10n.endsSoon;
    }

    return Card(
      color: theme.colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: theme.colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            Text(
              DateFormat('MMM d, HH:mm').format(deal.endAt.toLocal()),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
