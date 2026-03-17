import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/custom_switch_tile.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  static const routePath = '/options/notification-settings';
  static const routeName = 'notificationSettings';

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  bool _saving = false;
  late bool _pushEnabled;
  late bool _emailEnabled;
  late Map<String, ModuleNotificationPrefs> _modules;

  void _loadFromUser(UserModel? user) {
    final prefs = user?.notificationPreferences;
    _pushEnabled = prefs?.pushEnabled ?? true;
    _emailEnabled = prefs?.emailEnabled ?? true;
    _modules = {};
    for (final k in notificationModuleKeys) {
      final m = prefs?.modules?[k];
      _modules[k] = ModuleNotificationPrefs(
        push: m?.push ?? true,
        email: m?.email ?? true,
      );
    }
  }

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    _loadFromUser(user);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user != null && _modules.isEmpty) {
      _loadFromUser(user);
    }
  }

  String _moduleLabel(String key) {
    final l10n = AppLocalizations.of(context);
    switch (key) {
      case 'products':
        return l10n?.notificationModuleProducts ?? 'Products';
      case 'product_orders':
        return l10n?.notificationModuleProductOrders ?? 'Product Orders';
      case 'deals':
        return l10n?.notificationModuleDeals ?? 'Deals';
      case 'deal_orders':
        return l10n?.notificationModuleDealOrders ?? 'Deal Orders';
      case 'banners':
        return l10n?.notificationModuleBanners ?? 'Banners';
      case 'admin':
        return l10n?.notificationModuleAdmin ?? 'Admin';
      case 'engagement':
        return l10n?.notificationModuleEngagement ?? 'Engagement';
      case 'payment':
        return l10n?.notificationModulePayment ?? 'Payment';
      default:
        return key;
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final payload = UpdateProfilePayload(
      notificationPreferences: NotificationPreferences(
        pushEnabled: _pushEnabled,
        emailEnabled: _emailEnabled,
        modules: Map.fromEntries(
          _modules.entries.map((e) => MapEntry(e.key, e.value)),
        ),
      ),
    );
    try {
      await ref.read(authControllerProvider.notifier).updateProfile(payload);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showSnackBar(
            context, l10n?.notificationSettingsSaved ?? 'Notification settings saved');
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showSnackBar(context,
            l10n?.failedToUpdateProfile ?? 'Failed to update profile',
            isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.notificationSettings ?? 'Notification Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            l10n?.notificationSettingsSubtitle ??
                'Choose which notifications you want to receive.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: l10n?.notificationChannels ?? 'Channels',
          ),
          CustomSwitchTile(
            title: Text(l10n?.pushNotifications ?? 'Push Notifications'),
            subtitle: Text(
              l10n?.pushNotificationsSubtitle ??
                  'Receive push notifications on your device',
            ),
            value: _pushEnabled,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          CustomSwitchTile(
            title: Text(l10n?.emailNotifications ?? 'Email Notifications'),
            subtitle: Text(
              l10n?.emailNotificationsSubtitle ??
                  'Receive notifications via email',
            ),
            value: _emailEnabled,
            onChanged: (v) => setState(() => _emailEnabled = v),
          ),
          const SizedBox(height: 24),
          _SectionHeader(
            title: l10n?.notificationModules ?? 'By Category',
          ),
          ...notificationModuleKeys.map((key) {
            final m = _modules[key] ?? const ModuleNotificationPrefs();
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _moduleLabel(key),
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.notifications_outlined,
                                  size: 18, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                l10n?.push ?? 'Push',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              CustomSwitch(
                                value: m.push ?? true,
                                onChanged: (v) => setState(() {
                                  _modules[key] = ModuleNotificationPrefs(
                                    push: v,
                                    email: m.email,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 18, color: theme.colorScheme.onSurfaceVariant),
                              const SizedBox(width: 4),
                              Text(
                                l10n?.email ?? 'Email',
                                style: theme.textTheme.bodySmall,
                              ),
                              const SizedBox(width: 8),
                              CustomSwitch(
                                value: m.email ?? true,
                                onChanged: (v) => setState(() {
                                  _modules[key] = ModuleNotificationPrefs(
                                    push: m.push,
                                    email: v,
                                  );
                                }),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 24),
          PrimaryButton(
            label: l10n?.save ?? 'Save',
            onPressed: _save,
            isLoading: _saving,
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
      ),
    );
  }
}
