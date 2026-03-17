import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/domain/models/banner_model.dart';
import '../../../dashboard/presentation/controllers/banner_controller.dart';
import '../widgets/banner_form.dart';

class BannerDetailScreen extends ConsumerWidget {
  const BannerDetailScreen({super.key, required this.bannerId});

  static const routePath = '/manager/banners/:id';
  static const routeName = 'banner-detail';

  final String bannerId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bannerAsync = ref.watch(bannerDetailProvider(bannerId));
    final l10n = AppLocalizations.of(context)!;
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final isAdminOrManager =
        user?.role == UserRole.admin || user?.role == UserRole.subAdmin;
    final isOwner = user != null &&
        bannerAsync.valueOrNull != null &&
        bannerAsync.valueOrNull!.createdBy == user.id;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.bannerDetails),
        actions: [
          if (bannerAsync.hasValue &&
              bannerAsync.value != null &&
              (isAdminOrManager || isOwner))
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => _showEditBanner(context, ref, bannerAsync.value!),
            ),
        ],
      ),
      body: bannerAsync.when(
        data: (banner) {
          if (banner == null) {
            return Center(child: Text(l10n.bannerNotFound));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          const Center(child: Icon(Icons.broken_image, size: 48)),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _StatusChip(status: banner.status),
                const SizedBox(height: 4),
                Text(
                  banner.title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (banner.description != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    banner.description!,
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
                const SizedBox(height: 16),
                const Divider(),
                _DetailRow(
                    label: l10n.type, value: banner.type.name.toUpperCase()),
                _DetailRow(
                    label: l10n.status, value: banner.status.name.toUpperCase()),
                if ((banner.targetProductTitle ??
                        banner.targetDealTitle ??
                        banner.targetId) !=
                    null)
                  _DetailRow(
                      label: l10n.targetId,
                      value: (banner.targetProductTitle ??
                              banner.targetDealTitle ??
                              banner.targetId)!),
                if (banner.targetUrl != null)
                  _DetailRow(label: l10n.url, value: banner.targetUrl!),
                if (banner.startDate != null)
                  _DetailRow(
                    label: l10n.startDate,
                    value: DateFormat('yyyy-MM-dd').format(banner.startDate!),
                  ),
                if (banner.endDate != null)
                  _DetailRow(
                    label: l10n.endDate,
                    value: DateFormat('yyyy-MM-dd').format(banner.endDate!),
                  ),
                _DetailRow(
                    label: '${l10n.views}:', value: '${banner.viewCount}'),
                _DetailRow(
                    label: '${l10n.clicks}:', value: '${banner.clickCount}'),
                const SizedBox(height: 24),
                if (isAdminOrManager || isOwner)
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () =>
                              _showEditBanner(context, ref, banner),
                          icon: const Icon(Icons.edit),
                          label: Text(l10n.edit),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _confirmDelete(context, ref, banner.id),
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          label: Text(
                            l10n.delete,
                            style: const TextStyle(color: AppColors.error),
                          ),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('${l10n.error}: $err'),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => ref.invalidate(bannerDetailProvider(bannerId)),
                child: Text(l10n.retry),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBanner(
      BuildContext context, WidgetRef ref, BannerModel banner) {
    final isAdminOrManager =
        ref.read(authControllerProvider).valueOrNull?.user.role ==
            UserRole.admin ||
        ref.read(authControllerProvider).valueOrNull?.user.role ==
            UserRole.subAdmin;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (ctx) => BannerForm(
        isAdminCreate: ref.read(authControllerProvider).valueOrNull?.user.role ==
            UserRole.admin,
        initialBanner: banner,
        canEditStatus: isAdminOrManager,
        onSaved: () {
          ref.invalidate(bannerDetailProvider(bannerId));
          ref.invalidate(manageBannersProvider);
        },
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, String id) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.deleteBanner),
        content: Text(l10n.deleteBannerConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () async {
              final success = await ref
                  .read(bannerActionsControllerProvider.notifier)
                  .deleteBanner(id);
              if (!context.mounted) return;
              Navigator.pop(dialogContext);
              if (success) {
                ref.invalidate(manageBannersProvider);
                if (context.mounted) context.pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(l10n.bannerDeleted)),
                );
              }
            },
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(l10n.delete),
          ),
        ],
      ),
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
    return Align(
      alignment: Alignment.centerLeft,
      child: Chip(
        label: Text(status.name.toUpperCase(),
            style: const TextStyle(color: Colors.white, fontSize: 10)),
        backgroundColor: color,
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

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
              label,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: Text(value, overflow: TextOverflow.ellipsis),
          ),
        ],
      ),
    );
  }
}
