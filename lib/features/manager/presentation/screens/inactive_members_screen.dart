import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/language_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../admin/data/models/admin_user_model.dart';
import '../../../admin/data/repositories/admin_repository.dart';
import '../../data/repositories/manager_repository.dart';

final inactiveMembersProvider = FutureProvider.autoDispose
    .family<InactiveMembersPage, ({int page, String? search})>(
        (ref, params) async {
  final repo = ref.watch(managerRepositoryProvider);
  return repo.fetchInactiveMembers(
    page: params.page,
    limit: 25,
    search: params.search?.isEmpty == true ? null : params.search,
  );
});

class InactiveMembersScreen extends ConsumerStatefulWidget {
  const InactiveMembersScreen({super.key});

  static const routePath = '/manager/inactive-members';
  static const routeName = 'inactiveMembers';

  @override
  ConsumerState<InactiveMembersScreen> createState() =>
      _InactiveMembersScreenState();
}

class _InactiveMembersScreenState extends ConsumerState<InactiveMembersScreen> {
  int _page = 1;
  String? _search;
  final Set<String> _selectedIds = {};
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSelectAll(List<AdminUser> items) {
    setState(() {
      if (_selectedIds.length >= items.length) {
        _selectedIds.clear();
      } else {
        _selectedIds.addAll(items.map((e) => e.id));
      }
    });
  }

  void _toggleSelection(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _showUserDetails(AdminUser user) {
    final l10n = AppLocalizations.of(context);
    final lastOrder = user.lastOrderAt != null
        ? DateFormat.yMMMd().format(user.lastOrderAt!)
        : (l10n?.never ?? 'Never');
    final created = user.createdAt != null
        ? DateFormat.yMMMd().format(user.createdAt!)
        : '—';

    showModalBottomSheet(
      context: context,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              user.fullName,
              style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(user.email, style: Theme.of(ctx).textTheme.bodyMedium),
            if (user.phone != null && user.phone!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(user.phone!, style: Theme.of(ctx).textTheme.bodyMedium),
            ],
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(Icons.receipt_long_outlined,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${l10n?.lastOrder ?? 'Last order'}: $lastOrder',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 18, color: Colors.grey[600]),
                const SizedBox(width: 8),
                Text(
                  '${l10n?.joined ?? 'Joined'}: $created',
                  style: Theme.of(ctx)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey[700]),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  _toggleSelection(user.id);
                },
                icon: const Icon(Icons.notifications_outlined, size: 20),
                label: Text(_selectedIds.contains(user.id)
                    ? (l10n?.deselect ?? 'Deselect')
                    : (l10n?.selectToNotify ?? 'Select to send notification')),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendNotification() async {
    if (_selectedIds.isEmpty) return;
    final l10n = AppLocalizations.of(context);
    final adminRepo = ref.read(adminRepositoryProvider);
    final titleController = TextEditingController(text: l10n?.weMissYou ?? 'We miss you!');
    final bodyController = TextEditingController(
      text: l10n?.reEngagementDefaultBody ??
          'You haven\'t placed an order in a while. Browse our latest deals and products.',
    );

    final sent = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(l10n?.sendNotification ?? 'Send notification'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '${l10n?.recipients ?? 'Recipients'}: ${_selectedIds.length}',
                style: Theme.of(ctx).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: l10n?.title ?? 'Title',
                  border: const OutlineInputBorder(),
                ),
                maxLength: 200,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: bodyController,
                decoration: InputDecoration(
                  labelText: l10n?.body ?? 'Message',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
                maxLines: 4,
                maxLength: 1000,
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  final prompt = await showDialog<String>(
                    context: ctx,
                    builder: (promptCtx) {
                      final controller = TextEditingController();
                      return AlertDialog(
                        title: Text(l10n?.generateWithAI ?? 'Generate with AI'),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              l10n?.generateNotificationPrompt ??
                                  'Describe the notification (e.g. re-engagement, flash sale, new products) to generate title and message.',
                              style: Theme.of(promptCtx).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            TextField(
                              controller: controller,
                              decoration: InputDecoration(
                                hintText: l10n?.notificationRemindHint ??
                                    'e.g., Remind inactive shops about our winter sale',
                                border: const OutlineInputBorder(),
                              ),
                              maxLines: 3,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(promptCtx).pop(),
                            child: Text(l10n?.cancel ?? 'Cancel'),
                          ),
                          FilledButton(
                            onPressed: () =>
                                Navigator.of(promptCtx).pop(controller.text),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.auto_awesome,
                                    size: 18,
                                    color: Theme.of(promptCtx)
                                        .colorScheme
                                        .onPrimary),
                                const SizedBox(width: 8),
                                Text(l10n?.generate ?? 'Generate'),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                  if (prompt == null || prompt.trim().isEmpty) return;
                  try {
                    final locale = ref.read(languageControllerProvider);
                    final data = await adminRepo.generateNotificationContent(
                      prompt.trim(),
                      language: locale.languageCode,
                    );
                    if (!ctx.mounted) return;
                    titleController.text = data['title'] ?? '';
                    bodyController.text = data['body'] ?? '';
                  } catch (e) {
                    if (!ctx.mounted) return;
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text('${l10n?.error ?? 'Error'}: $e'),
                        backgroundColor: Theme.of(ctx).colorScheme.error,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.auto_awesome,
                    color: Colors.amber, size: 20),
                label: Text(l10n?.generateWithAI ?? 'Generate with AI'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(l10n?.cancel ?? 'Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(l10n?.send ?? 'Send'),
          ),
        ],
      ),
    );

    if (sent != true || !mounted) return;

    try {
      final adminRepo = ref.read(adminRepositoryProvider);
      final result = await adminRepo.sendNotificationToUsers(
        userIds: _selectedIds.toList(),
        title: titleController.text.trim(),
        body: bodyController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${l10n?.notificationSent ?? 'Notification sent'} to ${result['sent']} user(s)',
          ),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _selectedIds.clear());
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${l10n?.error ?? 'Error'}: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authControllerProvider);
    final l10n = AppLocalizations.of(context);
    final pageAsync =
        ref.watch(inactiveMembersProvider((page: _page, search: _search)));

    return authState.when(
      data: (session) {
        final user = session?.user;
        if (user == null || !Permissions.isAdminOrSubAdmin(user.role)) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n?.accessDenied ?? 'Access Denied')),
            body: Center(
              child: Text(l10n?.managersSectionOnly ?? 'This section is only available for managers'),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n?.inactiveMembers ?? 'Inactive Members'),
            actions: [
              if (_selectedIds.isNotEmpty)
                TextButton.icon(
                  onPressed: _sendNotification,
                  icon:
                      const Icon(Icons.notifications_active_outlined, size: 20),
                  label: Text(
                      '${l10n?.sendNotification ?? 'Send'} (${_selectedIds.length})'),
                ),
            ],
          ),
          floatingActionButton: _selectedIds.isEmpty
              ? null
              : FloatingActionButton.extended(
                  onPressed: _sendNotification,
                  icon: const Icon(Icons.notifications_active_outlined),
                  label: Text(
                    '${l10n?.sendNotification ?? 'Send notification'} (${_selectedIds.length})',
                  ),
                ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: l10n?.searchByNameEmail ?? 'Search by name, email...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _search = null);
                              ref.invalidate(inactiveMembersProvider(
                                  (page: _page, search: null)));
                            },
                          )
                        : null,
                  ),
                  onSubmitted: (value) {
                    setState(() {
                      _search = value.isEmpty ? null : value;
                      _page = 1;
                    });
                    ref.invalidate(
                        inactiveMembersProvider((page: 1, search: _search)));
                  },
                ),
              ),
              Expanded(
                child: pageAsync.when(
                  data: (page) {
                    final items = page.items;
                    if (items.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_outline,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text(
                              l10n?.noInactiveMembers ?? 'No inactive members',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                          ],
                        ),
                      );
                    }

                    final allSelected =
                        _selectedIds.length >= items.length && items.isNotEmpty;

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              Checkbox(
                                value: allSelected,
                                tristate: true,
                                onChanged: (_) => _toggleSelectAll(items),
                              ),
                              Text(
                                l10n?.selectAll ?? 'Select all',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const Spacer(),
                              Text(
                                '${page.totalRows} ${l10n?.total ?? 'total'}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: ListView.builder(
                            padding: EdgeInsets.only(
                              bottom: _selectedIds.isNotEmpty ? 80 : 16,
                            ),
                            itemCount: items.length,
                            itemBuilder: (ctx, index) {
                              final member = items[index];
                              final selected = _selectedIds.contains(member.id);
                              final lastOrder = member.lastOrderAt != null
                                  ? DateFormat.yMMMd()
                                      .format(member.lastOrderAt!)
                                  : (l10n?.never ?? 'Never');
                              final lastActive = member.lastActive != null
                                  ? DateFormat.yMMMd().add_Hm().format(member.lastActive!)
                                  : (l10n?.never ?? 'Never');
                              final lastLogin = member.lastLoginAt != null
                                  ? DateFormat.yMMMd().add_Hm().format(member.lastLoginAt!)
                                  : (l10n?.never ?? 'Never');

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                child: InkWell(
                                  onTap: () => _showUserDetails(member),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12, vertical: 8),
                                    child: Row(
                                      children: [
                                        GestureDetector(
                                          onTap: () =>
                                              _toggleSelection(member.id),
                                          behavior: HitTestBehavior.opaque,
                                          child: Checkbox(
                                            value: selected,
                                            onChanged: (_) =>
                                                _toggleSelection(member.id),
                                          ),
                                        ),
                                        CircleAvatar(
                                          backgroundColor: Theme.of(ctx)
                                              .colorScheme
                                              .primaryContainer,
                                          child: Text(
                                            (member.fullName.isNotEmpty
                                                    ? member.fullName[0]
                                                    : '?')
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: Theme.of(ctx)
                                                  .colorScheme
                                                  .onPrimaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                member.fullName,
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .titleMedium,
                                              ),
                                              Text(
                                                member.email,
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .bodySmall,
                                              ),
                                              Text(
                                                '${l10n?.lastOrder ?? 'Last order'}: $lastOrder',
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Colors
                                                          .orange.shade700,
                                                    ),
                                              ),
                                              Text(
                                                '${l10n?.lastActive ?? 'Last active'}: $lastActive',
                                                style: Theme.of(ctx)
                                                    .textTheme
                                                    .labelSmall
                                                    ?.copyWith(
                                                      color: Colors.grey[600],
                                                    ),
                                              ),
                                              if (member.lastLoginAt != null)
                                                Text(
                                                  '${l10n?.lastLogin ?? 'Last login'}: $lastLogin',
                                                  style: Theme.of(ctx)
                                                      .textTheme
                                                      .labelSmall
                                                      ?.copyWith(
                                                        color: Colors.grey[600],
                                                      ),
                                                ),
                                            ],
                                          ),
                                        ),
                                        Icon(
                                          Icons.chevron_right,
                                          color: Theme.of(ctx)
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        if (page.totalPages > 1)
                          Padding(
                            padding: const EdgeInsets.all(12),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: _page > 1
                                      ? () {
                                          setState(() => _page--);
                                          ref.invalidate(
                                            inactiveMembersProvider(
                                                (page: _page, search: _search)),
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_left),
                                ),
                                Text(
                                    '${l10n?.page ?? 'Page'} $_page / ${page.totalPages}'),
                                IconButton(
                                  onPressed: _page < page.totalPages
                                      ? () {
                                          setState(() => _page++);
                                          ref.invalidate(
                                            inactiveMembersProvider(
                                                (page: _page, search: _search)),
                                          );
                                        }
                                      : null,
                                  icon: const Icon(Icons.chevron_right),
                                ),
                              ],
                            ),
                          ),
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.error),
                        const SizedBox(height: 16),
                        Text('$err', textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: () => ref.invalidate(
                            inactiveMembersProvider(
                                (page: _page, search: _search)),
                          ),
                          child: Text(l10n?.retry ?? 'Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('$e')),
      ),
    );
  }
}
