import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../data/models/auth_models.dart';

class AuthRoleSelector extends StatelessWidget {
  const AuthRoleSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final UserRole value;
  final ValueChanged<UserRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final options = {
      UserRole.kiosk: ('Kiosk / Shop', Icons.storefront),
      UserRole.wholesaler: ('Wholesaler', Icons.local_shipping_outlined),
    };

    final entries = options.entries.toList();

    return Row(
      children: List.generate(entries.length, (index) {
        final entry = entries[index];
        final isSelected = entry.key == value;
        final isLast = index == entries.length - 1;

        return Expanded(
          child: GestureDetector(
            onTap: () => onChanged(entry.key),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: EdgeInsets.only(right: isLast ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.neutral200,
                  width: 1.2,
                ),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Icon(entry.value.$2,
                      color: isSelected ? Colors.white : AppColors.textPrimary),
                  const SizedBox(height: 12),
                  Text(
                    entry.value.$1,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color:
                              isSelected ? Colors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }
}
