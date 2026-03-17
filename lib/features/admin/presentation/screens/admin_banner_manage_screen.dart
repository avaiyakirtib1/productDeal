import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../dashboard/presentation/controllers/banner_controller.dart';
import '../../../dashboard/domain/models/banner_model.dart';
import '../../../manager/presentation/widgets/banner_form.dart';

class AdminBannerManageScreen extends ConsumerStatefulWidget {
  const AdminBannerManageScreen({super.key});

  static const routePath = '/admin/banners';
  static const routeName = 'admin-banners';

  @override
  ConsumerState<AdminBannerManageScreen> createState() =>
      _AdminBannerManageScreenState();
}

class _AdminBannerManageScreenState
    extends ConsumerState<AdminBannerManageScreen> {
  // Default to 'all' so users see all banners (avoids "No banners found" when banners are approved/active)
  String _selectedStatusFilter = 'all'; // 'all', 'pending', 'approved', 'rejected'

  @override
  Widget build(BuildContext context) {
    // Pass null when 'all' so backend returns all banners
    final statusForApi = _selectedStatusFilter == 'all'
        ? null
        : _selectedStatusFilter;
    final bannersAsync = ref.watch(manageBannersProvider(statusForApi));

    return Scaffold(
      appBar: AppBar(
        title: Text(
          AppLocalizations.of(context)?.adminBannerManagement ??
              'Admin Banner Management',
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddBannerDialog(context, ref),
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SegmentedButton<String>(
              segments: [
                ButtonSegment(
                  value: 'all',
                  label: Text(
                    AppLocalizations.of(context)?.all ?? 'All',
                  ),
                ),
                ButtonSegment(
                  value: 'pending',
                  label: Text(
                    AppLocalizations.of(context)?.requests ?? 'Requests',
                  ),
                ),
                ButtonSegment(
                  value: 'approved',
                  label: Text(
                    AppLocalizations.of(context)?.active ?? 'Active',
                  ),
                ),
                ButtonSegment(
                  value: 'rejected',
                  label: Text(
                    AppLocalizations.of(context)?.rejected ?? 'Rejected',
                  ),
                ),
              ],
              selected: {_selectedStatusFilter},
              onSelectionChanged: (Set<String> newSelection) {
                setState(() {
                  _selectedStatusFilter = newSelection.first;
                });
              },
            ),
          ),
          Expanded(
            child: bannersAsync.when(
              data: (banners) {
                if (banners.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)?.noBannersFoundShort ??
                          'No banners found.',
                    ),
                  );
                }
                return ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 + 80, // Space for FAB
                  ),
                  itemCount: banners.length,
                  itemBuilder: (context, index) {
                    final banner = banners[index];
                    return InkWell(
                      onTap: () => context.push('/manager/banners/${banner.id}'),
                      borderRadius: BorderRadius.circular(12),
                      child: _AdminBannerCard(banner: banner),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(
                child: Text(
                  '${AppLocalizations.of(context)?.error ?? 'Error'}: $err',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const BannerForm(isAdminCreate: true),
    );
  }
}

class _AdminBannerCard extends ConsumerStatefulWidget {
  final BannerModel banner;

  const _AdminBannerCard({required this.banner});

  @override
  ConsumerState<_AdminBannerCard> createState() => _AdminBannerCardState();
}

class _AdminBannerCardState extends ConsumerState<_AdminBannerCard> {
  String? _loadingAction; // 'approve' | 'reject' | 'deactivate'

  @override
  Widget build(BuildContext context) {
    final banner = widget.banner;
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              SizedBox(
                height: 180,
                width: double.infinity,
                child: CachedNetworkImage(
                  imageUrl: banner.imageUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) =>
                      const Center(child: Icon(Icons.broken_image)),
                ),
              ),
              Positioned(
                  top: 8,
                  left: 8,
                  child: IconButton(
                    icon: const Icon(Icons.edit, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                    tooltip: AppLocalizations.of(context)?.edit ?? 'Edit',
                    onPressed: () =>
                        context.push('/manager/banners/${banner.id}'),
                  )),
              Positioned(
                  top: 8,
                  right: 8,
                  child: Chip(
                    label: Text(banner.status.name.toUpperCase(),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 10)),
                    backgroundColor: _getStatusColor(banner.status),
                  ))
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(banner.title,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 4),
                if (banner.description != null) ...[
                  Text(banner.description!,
                      style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 8),
                ],
                const Divider(),
                _DetailRow(
                    label: 'Type', value: banner.type.name.toUpperCase()),
                if ((banner.targetProductTitle ??
                        banner.targetDealTitle ??
                        banner.targetId) !=
                    null)
                  _DetailRow(
                      label: 'Target',
                      value: (banner.targetProductTitle ??
                              banner.targetDealTitle ??
                              banner.targetId)!),
                if (banner.targetUrl != null)
                  _DetailRow(label: 'URL', value: banner.targetUrl!),
                if (banner.startDate != null)
                  _DetailRow(
                      label: 'Start',
                      value:
                          DateFormat('yyyy-MM-dd').format(banner.startDate!)),
                if (banner.endDate != null)
                  _DetailRow(
                      label: 'End',
                      value: DateFormat('yyyy-MM-dd').format(banner.endDate!)),
                const SizedBox(height: 16),
                if (banner.status == BannerStatus.pending)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 100,
                        height: 40,
                        child: OutlinedButton.icon(
                          onPressed: _loadingAction != null
                              ? null
                              : () => _updateStatus(context, ref, 'rejected'),
                          icon: _loadingAction == 'reject'
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.red,
                                  ),
                                )
                              : const Icon(Icons.close, color: Colors.red),
                          label: Text(
                            _loadingAction == 'reject' ? '' : 'Reject',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 120,
                        height: 40,
                        child: FilledButton.icon(
                          onPressed: _loadingAction != null
                              ? null
                              : () => _updateStatus(context, ref, 'approved'),
                          icon: _loadingAction == 'approve'
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.check),
                          label: Text(
                            _loadingAction == 'approve' ? '' : 'Approve',
                          ),
                        ),
                      ),
                    ],
                  ),
                if (banner.status == BannerStatus.approved)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      SizedBox(
                        width: 130,
                        height: 40,
                        child: TextButton.icon(
                          onPressed: _loadingAction != null
                              ? null
                              : () => _updateStatus(context, ref, 'inactive'),
                          icon: _loadingAction == 'deactivate'
                              ? SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Theme.of(context)
                                        .colorScheme.primary,
                                  ),
                                )
                              : const Icon(Icons.pause),
                          label: Text(
                            _loadingAction == 'deactivate'
                                ? ''
                                : 'Deactivate',
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(BannerStatus status) {
    switch (status) {
      case BannerStatus.active:
      case BannerStatus.approved:
        return Colors.green.shade100;
      case BannerStatus.pending:
        return Colors.orange.shade100;
      case BannerStatus.rejected:
      case BannerStatus.inactive:
        return Colors.red.shade100;
    }
  }

  Future<void> _updateStatus(
      BuildContext context, WidgetRef ref, String newStatus) async {
    final actionKey = newStatus == 'approved'
        ? 'approve'
        : newStatus == 'rejected'
            ? 'reject'
            : 'deactivate';
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _loadingAction = actionKey);
    try {
      final success = await ref
          .read(bannerActionsControllerProvider.notifier)
          .updateStatus(widget.banner.id, newStatus);
      if (!context.mounted) return;
      if (success) {
        ref.invalidate(manageBannersProvider);
        final msg = newStatus == 'approved'
            ? 'Banner approved'
            : newStatus == 'rejected'
                ? 'Banner rejected'
                : 'Banner deactivated';
        messenger.showSnackBar(SnackBar(content: Text(msg)));
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)?.failedToUpdateBanner ??
                  'Failed to update banner',
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loadingAction = null);
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
