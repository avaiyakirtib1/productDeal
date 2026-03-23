import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/permissions/permissions.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/models/admin_user_model.dart';
import '../../data/repositories/admin_repository.dart';
import '../widgets/document_grid_viewer.dart';
import '../../../../core/localization/app_localizations.dart';

class AdminUsersPage {
  const AdminUsersPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.totalRows,
  });

  final List<AdminUser> items;
  final int page;
  final int limit;
  final int totalRows;
}

final adminUsersProvider = StateNotifierProvider.autoDispose<
    AdminUsersController, AsyncValue<AdminUsersPage>>(
  (ref) => AdminUsersController(ref.watch(adminRepositoryProvider)),
);

class AdminUsersController extends StateNotifier<AsyncValue<AdminUsersPage>> {
  AdminUsersController(this._repo) : super(const AsyncValue.loading()) {
    loadUsers();
  }

  final AdminRepository _repo;
  int _currentPage = 1;
  String? _search;
  String? _roleFilter;
  String? _statusFilter;
  final int _pageSize = 25;

  Future<void> loadUsers({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = const AsyncValue.loading();
    }

    try {
      final result = await _repo.getUsers(
        search: _search,
        role: _roleFilter,
        status: _statusFilter,
        page: _currentPage,
        limit: _pageSize,
      );

      final items = result['items'] as List<AdminUser>;
      final totalRows = result['totalRows'] as int;
      final page = result['page'] as int;
      final limit = result['limit'] as int;

      state = AsyncValue.data(
        AdminUsersPage(
          items: items,
          page: page,
          limit: limit,
          totalRows: totalRows,
        ),
      );
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setSearch(String? search) {
    _search = search?.trim().isEmpty == true ? null : search?.trim();
    loadUsers(refresh: true);
  }

  void setRoleFilter(String? role) {
    _roleFilter = role;
    loadUsers(refresh: true);
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadUsers(refresh: true);
  }

  void nextPage() {
    final current = state.value;
    if (current != null &&
        _currentPage < (current.totalRows / _pageSize).ceil()) {
      _currentPage++;
      loadUsers();
    }
  }

  void previousPage() {
    if (_currentPage > 1) {
      _currentPage--;
      loadUsers();
    }
  }

  void refresh() {
    loadUsers(refresh: true);
  }
}

class ManageUsersScreen extends ConsumerStatefulWidget {
  const ManageUsersScreen({super.key});

  static const routePath = '/admin/users';
  static const routeName = 'manageUsers';

  @override
  ConsumerState<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends ConsumerState<ManageUsersScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to search field
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    // Debounce search - only search when user stops typing
    // For now, we'll trigger on submit or filter change
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final usersAsync = ref.watch(adminUsersProvider);

    return authState.when(
      data: (session) {
        final user = session?.user;
        if (user == null || !Permissions.isAdminOrSubAdmin(user.role)) {
          return Scaffold(
            appBar: AppBar(title: Text(l10n.accessDenied)),
            body: Center(
              child: Text(l10n.administratorsOnlySection),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text(l10n.manageUsers),
            actions: [
              IconButton(
                icon: const Icon(Icons.add),
                onPressed: () => _showCreateUserModal(context, ref),
              ),
            ],
          ),
          body: Column(
            children: [
              // Search and filters
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: l10n.searchByNameEmailPhone,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(adminUsersProvider.notifier)
                                      .setSearch(null);
                                },
                              )
                            : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onSubmitted: (value) {
                        ref.read(adminUsersProvider.notifier).setSearch(value);
                      },
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                null, // Filter state is managed in controller
                            decoration: InputDecoration(
                              labelText: l10n.role,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: null, child: Text(l10n.allRoles)),
                              DropdownMenuItem(
                                  value: 'admin', child: Text(l10n.admin)),
                              DropdownMenuItem(
                                  value: 'sub_admin', child: Text(l10n.subAdmin)),
                              DropdownMenuItem(
                                  value: 'wholesaler',
                                  child: Text(l10n.wholesaler)),
                              DropdownMenuItem(
                                  value: 'kiosk', child: Text(l10n.kiosk)),
                            ],
                            onChanged: (value) {
                              ref
                                  .read(adminUsersProvider.notifier)
                                  .setRoleFilter(value);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                null, // Filter state is managed in controller
                            decoration: InputDecoration(
                              labelText: l10n.status,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                            ),
                            items: [
                              DropdownMenuItem(
                                  value: null, child: Text(l10n.allStatuses)),
                              DropdownMenuItem(
                                  value: 'pending', child: Text(l10n.pending)),
                              DropdownMenuItem(
                                  value: 'approved', child: Text(l10n.approved)),
                              DropdownMenuItem(
                                  value: 'rejected', child: Text(l10n.rejected)),
                              DropdownMenuItem(
                                  value: 'suspended', child: Text(l10n.suspended)),
                              DropdownMenuItem(
                                  value: 'need_more_info',
                                  child: Text(l10n.needMoreInfo)),
                            ],
                            onChanged: (value) {
                              ref
                                  .read(adminUsersProvider.notifier)
                                  .setStatusFilter(value);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Users list
              Expanded(
                child: usersAsync.when(
                  data: (page) {
                    final users = page.items;
                    final totalRows = page.totalRows;
                    final currentPage = page.page;
                    final totalPages = (totalRows / page.limit).ceil();

                    if (users.isEmpty) {
                      return Center(
                        child: Text(l10n.noUsersFound),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        ref.read(adminUsersProvider.notifier).refresh();
                      },
                      child: Column(
                        children: [
                          Expanded(
                            child: ListView.builder(
                              itemCount: users.length,
                              padding: const EdgeInsets.all(8),
                              itemBuilder: (context, index) {
                                final user = users[index];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      child: Text(
                                        user.fullName.isNotEmpty
                                            ? user.fullName[0].toUpperCase()
                                            : '?',
                                      ),
                                    ),
                                    title: Text(user.fullName),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(user.email),
                                        if (user.businessName != null)
                                          Text(
                                              '${l10n.business}: ${user.businessName}'),
                                        if (user.lastLoginAt != null)
                                          Text(
                                            '${l10n.lastLogin}: ${DateFormat('MMM dd, yyyy, HH:mm').format(user.lastLoginAt!)}'
                                            '${user.daysSinceLastLogin != null ? ' (${user.daysSinceLastLogin} ${l10n.daysAgo})' : ''}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (user.lastActive != null)
                                          Text(
                                            '${l10n.lastActive}: ${DateFormat('MMM dd, yyyy, HH:mm').format(user.lastActive!)}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall,
                                          ),
                                        if (user.activeDaysLast14 != null)
                                          Text(
                                            '${l10n.activeDaysLast14}: ${user.activeDaysLast14}',
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: (user.activeDaysLast14 ??
                                                              0) >
                                                          0
                                                      ? Colors.green
                                                      : Colors.orange,
                                                ),
                                          ),
                                        Row(
                                          children: [
                                            _StatusChip(status: user.status),
                                            const SizedBox(width: 8),
                                            _RoleChip(role: user.role),
                                          ],
                                        ),
                                        if (user.verificationDocuments !=
                                                null &&
                                            user.verificationDocuments!
                                                .isNotEmpty)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 4),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.description,
                                                    size: 14,
                                                    color: Colors.blue),
                                                const SizedBox(width: 4),
                                                Text(
                                                  l10n.docsCount.replaceAll('{count}', user.verificationDocuments!.length.toString()),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .bodySmall
                                                      ?.copyWith(
                                                        color: Colors.blue,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                      ],
                                    ),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit),
                                          onPressed: () => _showEditUserModal(
                                              context, ref, user),
                                        ),
                                        IconButton(
                                          icon: const Icon(Icons.delete,
                                              color: Colors.red),
                                          onPressed: () => _showDeleteDialog(
                                              context, ref, user),
                                        ),
                                      ],
                                    ),
                                    onTap: () =>
                                       _showEditUserModal(
                                              context, ref, user),
                                  ),
                                );
                              },
                            ),
                          ),
                          // Pagination
                          if (totalRows > page.limit)
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.chevron_left),
                                    onPressed: currentPage > 1
                                        ? () {
                                            ref
                                                .read(
                                                    adminUsersProvider.notifier)
                                                .previousPage();
                                          }
                                        : null,
                                  ),
                                  Text('${l10n.page} $currentPage ${l10n.ofLabel} $totalPages'),
                                  IconButton(
                                    icon: const Icon(Icons.chevron_right),
                                    onPressed: currentPage < totalPages
                                        ? () {
                                            ref
                                                .read(
                                                    adminUsersProvider.notifier)
                                                .nextPage();
                                          }
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, stack) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${l10n.error}: $error'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            ref.read(adminUsersProvider.notifier).refresh();
                          },
                          child: Text(l10n.retry),
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
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        appBar: AppBar(title: Text(l10n.error)),
        body: Center(child: Text('${l10n.error}: $error')),
      ),
    );
  }

  // ignore: unused_element
  void _showUserDetails(BuildContext context, AdminUser user) {
    // Fetch full user details including verification documents
    final userDetailAsync =
        ref.read(adminRepositoryProvider).getUserDetail(user.id);

    showDialog(
      context: context,
      builder: (dialogContext) => FutureBuilder<AdminUser>(
        future: userDetailAsync,
        builder: (context, snapshot) {
          final l10n = AppLocalizations.of(context)!;
          final fullUser = snapshot.data ?? user;
          final documents = fullUser.verificationDocuments ?? [];

          return AlertDialog(
            title: Text(fullUser.fullName),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _DetailRow(l10n.email, fullUser.email),
                  if (fullUser.phone != null)
                    _DetailRow(l10n.phone, fullUser.phone!),
                  if (fullUser.businessName != null)
                    _DetailRow(l10n.business, fullUser.businessName!),
                  _DetailRow(l10n.role, _roleToString(context, fullUser.role)),
                  _DetailRow(l10n.status, _statusToString(context, fullUser.status)),
                  if (fullUser.createdAt != null)
                    _DetailRow(l10n.created,
                        DateFormat('MMM dd, yyyy').format(fullUser.createdAt!)),
                  if (fullUser.lastActive != null)
                    _DetailRow(
                        l10n.lastActive,
                        DateFormat('MMM dd, yyyy')
                            .format(fullUser.lastActive!)),
                  if (fullUser.rejectionReason != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            l10n.rejectionReason,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.orange.shade900,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            fullUser.rejectionReason!,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.orange.shade900,
                                    ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (documents.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      '${l10n.verificationDocuments} (${documents.length}):',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...documents.asMap().entries.map((entry) {
                      final index = entry.key;
                      final docUrl = entry.value;
                      final isImage = docUrl.toLowerCase().endsWith('.jpg') ||
                          docUrl.toLowerCase().endsWith('.jpeg') ||
                          docUrl.toLowerCase().endsWith('.png');
                      final isPdf = docUrl.toLowerCase().endsWith('.pdf');

                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          leading: isImage
                              ? const Icon(Icons.image, color: Colors.blue)
                              : isPdf
                                  ? const Icon(Icons.picture_as_pdf,
                                      color: Colors.red)
                                  : const Icon(Icons.description),
                          title: Text(l10n.documentN.replaceAll('{n}', '${index + 1}')),
                          subtitle: Text(
                            docUrl.length > 50
                                ? '${docUrl.substring(0, 50)}...'
                                : docUrl,
                            style: const TextStyle(fontSize: 10),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () {
                              // Open document in browser/viewer
                              // You can use url_launcher here
                            },
                          ),
                          onTap: () {
                            // Show document grid viewer
                            Navigator.pop(dialogContext);
                            _showDocumentViewer(context, fullUser);
                          },
                        ),
                      );
                    }),
                  ] else if (fullUser.status == UserStatus.pending ||
                      fullUser.status == UserStatus.rejected ||
                      fullUser.status == UserStatus.needMoreInfo) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange.shade200),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning_amber,
                              color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.noVerificationDocumentsYet,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.orange.shade900,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: Text(l10n.close),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _showEditUserModal(context, ref, fullUser);
                },
                child: Text(l10n.edit),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDocumentViewer(BuildContext context, AdminUser user) {
    final l10n = AppLocalizations.of(context)!;
    // Combine categorized documents, gewerbescheinPhotos, and legacy documents
    final List<DocumentGridItem> allDocuments = [];
    final Set<String> seenUrls = <String>{};

    void addDoc(String url, String? type, String? label) {
      if (url.isNotEmpty && !seenUrls.contains(url)) {
        seenUrls.add(url);
        allDocuments.add(DocumentGridItem(
          url: url,
          type: type,
          label: label,
        ));
      }
    }

    // Add categorized documents first (preferred)
    if (user.categorizedDocuments != null &&
        user.categorizedDocuments!.isNotEmpty) {
      for (final doc in user.categorizedDocuments!) {
        final type = doc['type']?.toString();
        final label = type == 'passport'
            ? 'Passport'
            : type == 'gewerbeschein'
                ? 'Gewerbeschein'
                : type == 'businessLicense'
                    ? 'Business License'
                    : null;
        addDoc(doc['url']?.toString() ?? '', type, label);
      }
    }

    // Add gewerbescheinPhotos (in case not in categorizedDocuments)
    if (user.gewerbescheinPhotos != null) {
      for (final url in user.gewerbescheinPhotos!) {
        addDoc(url, 'gewerbeschein', 'Gewerbeschein');
      }
    }

    // Add legacy documents if no categorized documents
    if (allDocuments.isEmpty && user.verificationDocuments != null) {
      for (int i = 0; i < user.verificationDocuments!.length; i++) {
        addDoc(user.verificationDocuments![i], null, l10n.documentN.replaceAll('{n}', '${i + 1}'));
      }
    }

    if (allDocuments.isEmpty) {
      final l10n = AppLocalizations.of(context)!;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noDocumentsAvailable)),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => _DocumentViewerDialog(
        allDocuments: allDocuments,
        l10n: l10n,
      ),
    );
  }

  void _showEditUserModal(BuildContext context, WidgetRef ref, AdminUser user) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => _UserFormModal(
        user: user,
        onSave: (data) async {
          final repository = ref.read(adminRepositoryProvider);
          await repository.updateUser(user.id, data);
          if (modalContext.mounted) {
            Navigator.pop(modalContext);
            ref.read(adminUsersProvider.notifier).refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.userUpdatedSuccessfully)),
            );
          }
        },
      ),
    );
  }

  void _showCreateUserModal(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (modalContext) => _UserFormModal(
        user: null,
        onSave: (data) async {
          final repository = ref.read(adminRepositoryProvider);
          await repository.createUser(data);
          if (modalContext.mounted) {
            Navigator.pop(modalContext);
            ref.read(adminUsersProvider.notifier).refresh();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.userCreatedSuccessfully)),
            );
          }
        },
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, AdminUser user) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteUser),
        content: Text(
            l10n.deleteUserConfirm.replaceAll('{name}', user.fullName)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          TextButton(
            onPressed: () async {
              final repository = ref.read(adminRepositoryProvider);
              try {
                await repository.deleteUser(user.id);
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ref.read(adminUsersProvider.notifier).refresh();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(l10n.userDeletedSuccessfully)),
                  );
                }
              } catch (e) {
                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${l10n.error}: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
  }

  String _roleToString(BuildContext context, UserRole role) {
    final l10n = AppLocalizations.of(context)!;
    switch (role) {
      case UserRole.admin:
        return l10n.admin;
      case UserRole.subAdmin:
        return l10n.subAdmin;
      case UserRole.wholesaler:
        return l10n.wholesaler;
      case UserRole.kiosk:
        return l10n.kiosk;
    }
  }

  String _statusToString(BuildContext context, UserStatus status) {
    final l10n = AppLocalizations.of(context)!;
    switch (status) {
      case UserStatus.pending:
        return l10n.pending;
      case UserStatus.approved:
        return l10n.approved;
      case UserStatus.rejected:
        return l10n.rejected;
      case UserStatus.suspended:
        return l10n.suspended;
      case UserStatus.needMoreInfo:
        return l10n.needMoreInfo;
    }
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final UserStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    Color color;
    String text;
    switch (status) {
      case UserStatus.pending:
        color = Colors.orange;
        text = l10n.pending;
        break;
      case UserStatus.approved:
        color = Colors.green;
        text = l10n.approved;
        break;
      case UserStatus.rejected:
        color = Colors.red;
        text = l10n.rejected;
        break;
      case UserStatus.suspended:
        color = Colors.grey;
        text = l10n.suspended;
        break;
      case UserStatus.needMoreInfo:
        color = Colors.blue;
        text = l10n.needInfo;
        break;
    }

    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 10)),
      backgroundColor: color.withValues(alpha: 0.2),
      labelStyle: TextStyle(color: color, fontWeight: FontWeight.bold),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

class _RoleChip extends StatelessWidget {
  const _RoleChip({required this.role});

  final UserRole role;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    String text;
    switch (role) {
      case UserRole.admin:
        text = l10n.admin;
        break;
      case UserRole.subAdmin:
        text = l10n.subAdmin;
        break;
      case UserRole.wholesaler:
        text = l10n.wholesaler;
        break;
      case UserRole.kiosk:
        text = l10n.kiosk;
        break;
    }

    return Chip(
      label: Text(text, style: const TextStyle(fontSize: 10)),
      backgroundColor: Colors.blue.withValues(alpha: 0.2),
      labelStyle:
          const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
      padding: EdgeInsets.zero,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

enum _DocumentFilter { all, passport, gewerbeschein, businessLicense }

class _DocumentViewerDialog extends StatefulWidget {
  const _DocumentViewerDialog({
    required this.allDocuments,
    required this.l10n,
  });

  final List<DocumentGridItem> allDocuments;
  final AppLocalizations l10n;

  @override
  State<_DocumentViewerDialog> createState() => _DocumentViewerDialogState();
}

class _DocumentViewerDialogState extends State<_DocumentViewerDialog> {
  _DocumentFilter _filter = _DocumentFilter.all;

  String get _emptyMessage {
    switch (_filter) {
      case _DocumentFilter.all:
        return widget.l10n.noDocumentsAvailable;
      case _DocumentFilter.passport:
        return widget.l10n.noPassportDocuments;
      case _DocumentFilter.gewerbeschein:
        return widget.l10n.noGewerbescheinDocuments;
      case _DocumentFilter.businessLicense:
        return widget.l10n.noBusinessLicenseDocuments;
    }
  }

  List<DocumentGridItem> get _filteredDocuments {
    switch (_filter) {
      case _DocumentFilter.all:
        return widget.allDocuments;
      case _DocumentFilter.passport:
        return widget.allDocuments
            .where((d) => d.type == 'passport')
            .toList();
      case _DocumentFilter.gewerbeschein:
        return widget.allDocuments
            .where((d) => d.type == 'gewerbeschein')
            .toList();
      case _DocumentFilter.businessLicense:
        return widget.allDocuments
            .where((d) => d.type == 'businessLicense')
            .toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = widget.l10n;
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxHeight: 700, maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text(l10n.verificationDocuments),
              actions: [
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _FilterChip(
                    label: '${l10n.all} (${widget.allDocuments.length})',
                    selected: _filter == _DocumentFilter.all,
                    onTap: () =>
                        setState(() => _filter = _DocumentFilter.all),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '${l10n.passport} (${widget.allDocuments.where((d) => d.type == 'passport').length})',
                    selected: _filter == _DocumentFilter.passport,
                    onTap: () =>
                        setState(() => _filter = _DocumentFilter.passport),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '${l10n.gewerbeschein} (${widget.allDocuments.where((d) => d.type == 'gewerbeschein').length})',
                    selected: _filter == _DocumentFilter.gewerbeschein,
                    onTap: () =>
                        setState(() => _filter = _DocumentFilter.gewerbeschein),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: '${l10n.businessLicense} (${widget.allDocuments.where((d) => d.type == 'businessLicense').length})',
                    selected: _filter == _DocumentFilter.businessLicense,
                    onTap: () =>
                        setState(() => _filter = _DocumentFilter.businessLicense),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _filteredDocuments.isEmpty
                    ? Center(
                        child: Text(
                          _filter == _DocumentFilter.all
                              ? l10n.noDocumentsAvailable
                              : _emptyMessage,
                        ),
                      )
                    : DocumentGridViewer(
                        documents: _filteredDocuments,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _UserFormModal extends ConsumerStatefulWidget {
  const _UserFormModal({
    required this.user,
    required this.onSave,
  });

  final AdminUser? user;
  final Future<void> Function(Map<String, dynamic>) onSave;

  @override
  ConsumerState<_UserFormModal> createState() => _UserFormModalState();
}

class _UserFormModalState extends ConsumerState<_UserFormModal> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _businessNameController = TextEditingController();
  final _passwordController = TextEditingController();
  UserRole? _selectedRole;
  UserStatus? _selectedStatus;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.user != null) {
      _fullNameController.text = widget.user!.fullName;
      _emailController.text = widget.user!.email;
      _phoneController.text = widget.user!.phone ?? '';
      _businessNameController.text = widget.user!.businessName ?? '';
      _selectedRole = widget.user!.role;
      _selectedStatus = widget.user!.status;
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _businessNameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final data = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'businessName': _businessNameController.text.trim(),
        'role': _selectedRole.toString().split('.').last,
        'status': _selectedStatus.toString().split('.').last,
      };

      if (_passwordController.text.isNotEmpty) {
        data['password'] = _passwordController.text;
      }

      await widget.onSave(data);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.user == null ? l10n.createUser : l10n.editUser,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _fullNameController,
                  decoration: InputDecoration(
                    labelText: l10n.fullName,
                    border: const OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.fullNameRequired;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    labelText: l10n.email,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                  enabled: widget.user ==
                      null, // Can't change email for existing users
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return l10n.emailRequired;
                    }
                    if (!value.contains('@')) {
                      return l10n.invalidEmail;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  decoration: InputDecoration(
                    labelText: l10n.phoneOptional,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _businessNameController,
                  decoration: InputDecoration(
                    labelText: l10n.businessNameOptional,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserRole>(
                  initialValue: _selectedRole,
                  decoration: InputDecoration(
                    labelText: l10n.role,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: UserRole.admin, child: Text(l10n.admin)),
                    DropdownMenuItem(
                        value: UserRole.subAdmin, child: Text(l10n.subAdmin)),
                    DropdownMenuItem(
                        value: UserRole.wholesaler,
                        child: Text(l10n.wholesaler)),
                    DropdownMenuItem(
                        value: UserRole.kiosk, child: Text(l10n.kiosk)),
                  ],
                  onChanged: (value) => setState(() => _selectedRole = value),
                  validator: (value) =>
                      value == null ? l10n.roleRequired : null,
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<UserStatus>(
                  initialValue: _selectedStatus,
                  decoration: InputDecoration(
                    labelText: l10n.status,
                    border: const OutlineInputBorder(),
                  ),
                  items: [
                    DropdownMenuItem(
                        value: UserStatus.pending, child: Text(l10n.pending)),
                    DropdownMenuItem(
                        value: UserStatus.approved, child: Text(l10n.approved)),
                    DropdownMenuItem(
                        value: UserStatus.rejected,
                        child: Text(l10n.rejected)),
                    DropdownMenuItem(
                        value: UserStatus.suspended,
                        child: Text(l10n.suspended)),
                    DropdownMenuItem(
                        value: UserStatus.needMoreInfo,
                        child: Text(l10n.needInfo)),
                  ],
                  onChanged: (value) => setState(() => _selectedStatus = value),
                  validator: (value) =>
                      value == null ? l10n.statusRequired : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: widget.user == null
                        ? l10n.password
                        : l10n.newPasswordLeaveEmpty,
                    border: const OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: widget.user == null
                      ? (value) {
                          if (value == null || value.isEmpty) {
                            return l10n.passwordRequired;
                          }
                          if (value.length < 6) {
                            return l10n.passwordMinLength;
                          }
                          return null;
                        }
                      : null,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isSaving ? null : _save,
                  child: _isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(
                          widget.user == null ? l10n.createUser : l10n.updateUser),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
