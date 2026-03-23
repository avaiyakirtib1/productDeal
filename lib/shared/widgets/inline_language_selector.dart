import 'package:flutter/material.dart';

import '../../core/constants/app_languages.dart';

/// Horizontal, card-based language chooser for onboarding-style flows.
class InlineLanguageSelector extends StatelessWidget {
  const InlineLanguageSelector({
    super.key,
    required this.currentValue,
    required this.availableLanguages,
    required this.onChanged,
  });

  final String currentValue;
  final List<String> availableLanguages;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    if (availableLanguages.isEmpty) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final gap = isMobile ? 8.0 : 12.0;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < availableLanguages.length; i++) ...[
            if (i > 0) SizedBox(width: gap),
            _LanguageCard(
              label: AppLanguages.contentLanguageNames[
                      availableLanguages[i]] ??
                  availableLanguages[i],
              selected: availableLanguages[i] == currentValue,
              primaryColor: primary,
              isMobile: isMobile,
              onTap: () => onChanged(availableLanguages[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.label,
    required this.selected,
    required this.primaryColor,
    required this.isMobile,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final Color primaryColor;
  final bool isMobile;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.colorScheme.onSurfaceVariant;
    final borderColor =
        selected ? primaryColor : theme.colorScheme.outlineVariant;
    final bgColor = selected
        ? primaryColor.withValues(alpha: 0.1)
        : Colors.transparent;

    final baseText = isMobile
        ? theme.textTheme.bodyMedium
        : theme.textTheme.titleSmall;
    final textStyle = baseText?.copyWith(
      color: selected ? theme.colorScheme.onSurface : muted,
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
    );

    final contentPadding = isMobile
        ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
        : const EdgeInsets.fromLTRB(12, 14, 12, 12);
    final iconSize = isMobile ? 18.0 : 28.0;
    final checkSize = isMobile ? 18.0 : 20.0;
    final iconTextGap = isMobile ? 6.0 : 10.0;
    final cardWidth = isMobile ? 128.0 : 152.0;
    final checkInset = isMobile ? 6.0 : 8.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: cardWidth,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderColor,
          width: selected ? 2 : 1,
        ),
        color: bgColor,
        boxShadow: selected
            ? [
                BoxShadow(
                  color: primaryColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Stack(
            children: [
              Padding(
                padding: contentPadding,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.language,
                      size: iconSize,
                      color: selected ? primaryColor : muted,
                    ),
                    SizedBox(height: iconTextGap),
                    Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: textStyle,
                    ),
                  ],
                ),
              ),
              if (selected)
                Positioned(
                  top: checkInset,
                  right: checkInset,
                  child: Icon(
                    Icons.check_circle,
                    size: checkSize,
                    color: primaryColor,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
