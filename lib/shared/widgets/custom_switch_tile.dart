import 'package:flutter/material.dart';

/// A compact, theme-aware switch tile with customizable size and colors.
/// Use for settings screens where the default Switch/SwitchListTile is too large.
class CustomSwitchTile extends StatelessWidget {
  const CustomSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.leading,
    this.switchWidth = 33,
    this.switchHeight = 18,
    this.thumbSize = 12,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.contentPadding,
    this.enabled = true,
  });

  final Widget title;
  final Widget? subtitle;
  final Widget? leading;

  final bool value;
  final ValueChanged<bool> onChanged;

  final double switchWidth;
  final double switchHeight;
  final double thumbSize;

  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;

  final EdgeInsetsGeometry? contentPadding;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListTile(
      leading: leading,
      title: title,
      subtitle: subtitle,
      contentPadding: contentPadding,
      enabled: enabled,
      onTap: enabled ? () => onChanged(!value) : null,
      trailing: _CustomSwitch(
        value: value,
        onChanged: enabled ? onChanged : (_) {},
        width: switchWidth,
        height: switchHeight,
        thumbSize: thumbSize,
        activeColor: activeColor ?? colorScheme.primary,
        inactiveColor: inactiveColor ?? colorScheme.surfaceContainerHighest,
        thumbColor: thumbColor ?? colorScheme.onPrimary,
        enabled: enabled,
      ),
    );
  }
}

/// Compact inline switch for use in rows (e.g. Push / Email toggles).
class CustomSwitch extends StatelessWidget {
  const CustomSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.width = 33,
    this.height = 18,
    this.thumbSize = 12,
    this.activeColor,
    this.inactiveColor,
    this.thumbColor,
    this.enabled = true,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  final double width;
  final double height;
  final double thumbSize;

  final Color? activeColor;
  final Color? inactiveColor;
  final Color? thumbColor;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return _CustomSwitch(
      value: value,
      onChanged: enabled ? onChanged : (_) {},
      width: width,
      height: height,
      thumbSize: thumbSize,
      activeColor: activeColor ?? colorScheme.primary,
      inactiveColor: inactiveColor ?? colorScheme.surfaceContainerHighest,
      thumbColor: thumbColor ?? colorScheme.onPrimary,
      enabled: enabled,
    );
  }
}

class _CustomSwitch extends StatelessWidget {
  const _CustomSwitch({
    required this.value,
    required this.onChanged,
    required this.width,
    required this.height,
    required this.thumbSize,
    required this.activeColor,
    required this.inactiveColor,
    required this.thumbColor,
    required this.enabled,
  });

  final bool value;
  final ValueChanged<bool> onChanged;

  final double width;
  final double height;
  final double thumbSize;

  final Color activeColor;
  final Color inactiveColor;
  final Color thumbColor;

  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final trackColor = enabled
        ? (value ? activeColor : inactiveColor)
        : inactiveColor.withValues(alpha: 0.5);

    return Semantics(
      toggled: value,
      enabled: enabled,
      child: GestureDetector(
        onTap: enabled ? () => onChanged(!value) : null,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeInOut,
          width: width,
          height: height,
          padding: EdgeInsets.all((height - thumbSize) / 2),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: trackColor,
          ),
          child: AnimatedAlign(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            alignment: value ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: thumbSize,
              height: thumbSize,
              decoration: BoxDecoration(
                color: enabled ? thumbColor : thumbColor.withValues(alpha: 0.6),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 2,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
