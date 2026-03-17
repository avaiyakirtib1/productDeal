import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/domain/models/banner_model.dart';
import '../../../dashboard/presentation/controllers/banner_controller.dart';
import '../widgets/banner_form.dart';

import '../../../../core/localization/app_localizations.dart';

class ManagerBannersScreen extends ConsumerWidget {
  const ManagerBannersScreen({super.key});

  static const routePath = '/manager/banners';
  static const routeName = 'manager-banners';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannersAsync = ref.watch(manageBannersProvider(null));
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.manageBanners),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(
          bottom: kBottomNavigationBarHeight,
        ),
        child: FloatingActionButton(
          onPressed: () => _showAddBannerDialog(context, ref),
          child: const Icon(Icons.add),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: bannersAsync.when(
        data: (banners) {
          if (banners.isEmpty) {
            return Center(child: Text(l10n.noBannersFound));
          }
          return ListView.builder(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 16,
              bottom: 16 +
                  MediaQuery.of(context).padding.bottom +
                  140, // Extra space for FAB above bottom nav (65 nav + 56 FAB + 20 margin)
            ),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Card(
                clipBehavior: Clip.antiAlias,
                margin: const EdgeInsets.only(bottom: 16),
                child: InkWell(
                  onTap: () => context.push(
                    '/manager/banners/${banner.id}',
                  ),
                  child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 150,
                      width: double.infinity,
                      child: CachedNetworkImage(
                        imageUrl: banner.imageUrl,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) =>
                            const Center(child: Icon(Icons.broken_image)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  banner.title,
                                  style:
                                      Theme.of(context).textTheme.titleMedium,
                                ),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: const Icon(Icons.edit,
                                        color: AppColors.primary),
                                    tooltip: l10n.edit,
                                    onPressed: () => context.push(
                                      '/manager/banners/${banner.id}',
                                    ),
                                  ),
                                  _StatusChip(status: banner.status),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                              '${l10n.type}: ${banner.type.name.toUpperCase()}'),
                          if ((banner.targetProductTitle ??
                                  banner.targetDealTitle ??
                                  banner.targetId) !=
                              null)
                            Text(
                                '${l10n.targetId}: ${banner.targetProductTitle ?? banner.targetDealTitle ?? banner.targetId}'),
                          if (banner.targetUrl != null)
                            Text('${l10n.url}: ${banner.targetUrl}'),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton.icon(
                                icon: const Icon(Icons.delete,
                                    color: AppColors.error),
                                label: Text(l10n.delete,
                                    style: const TextStyle(
                                        color: AppColors.error)),
                                onPressed: () =>
                                    _confirmDelete(context, ref, banner.id),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Text(
            '${l10n.error}: $err',
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _DeleteBannerDialog(
        bannerId: id,
        onDeleted: () {
          Navigator.pop(dialogContext);
          ref.invalidate(manageBannersProvider);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(l10n.bannerDeleted)),
            );
          }
        },
        onCancel: () => Navigator.pop(dialogContext),
        deleteBanner: (bid) =>
            ref.read(bannerActionsControllerProvider.notifier).deleteBanner(bid),
      ),
    );
  }

  void _showAddBannerDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => const BannerForm(isAdminCreate: false),
    );
  }
}

class _DeleteBannerDialog extends StatefulWidget {
  final String bannerId;
  final VoidCallback onDeleted;
  final VoidCallback onCancel;
  final Future<bool> Function(String) deleteBanner;

  const _DeleteBannerDialog({
    required this.bannerId,
    required this.onDeleted,
    required this.onCancel,
    required this.deleteBanner,
  });

  @override
  State<_DeleteBannerDialog> createState() => _DeleteBannerDialogState();
}

class _DeleteBannerDialogState extends State<_DeleteBannerDialog> {
  bool _isDeleting = false;
  String? _error;

  Future<void> _doDelete() async {
    final l10n = AppLocalizations.of(context);
    setState(() {
      _isDeleting = true;
      _error = null;
    });
    try {
      final success = await widget.deleteBanner(widget.bannerId);
      if (!mounted) return;
      if (success) {
        widget.onDeleted();
      } else {
        setState(() {
          _isDeleting = false;
          _error = l10n?.failedToDeleteBanner ?? 'Failed to delete banner';
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDeleting = false;
          _error = '${l10n?.error ?? 'Error'}: $e';
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(l10n?.deleteBanner ?? 'Delete Banner'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n?.deleteBannerConfirm ?? 'Are you sure you want to delete this banner?'),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isDeleting ? null : widget.onCancel,
          child: Text(l10n?.cancel ?? 'Cancel'),
        ),
        FilledButton(
          onPressed: _isDeleting ? null : _doDelete,
          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
          child: _isDeleting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(l10n?.delete ?? 'Delete'),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final BannerStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case BannerStatus.active:
      case BannerStatus.approved:
        color = Colors.green;
        break;
      case BannerStatus.pending:
        color = Colors.orange;
        break;
      case BannerStatus.rejected:
      case BannerStatus.inactive:
        color = Colors.red;
        break;
    }

    return Chip(
      label: Text(
        status.name.toUpperCase(),
        style: const TextStyle(color: Colors.white, fontSize: 10),
      ),
      backgroundColor: color,
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
    );
  }
}
