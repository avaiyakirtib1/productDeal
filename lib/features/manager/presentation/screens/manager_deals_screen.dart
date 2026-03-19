import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../data/models/manager_models.dart';
import '../../data/repositories/manager_repository.dart';
import '../../data/providers/manager_data_providers.dart';
import '../../../wholesaler/presentation/widgets/create_deal_modal.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';

bool _isManagerDealEnded(ManagerDeal deal) =>
    deal.status == 'ended' || deal.status == 'cancelled';

final managerDealsProvider = StateNotifierProvider.autoDispose<
    ManagerDealsController, AsyncValue<ManagerDealsPage>>(
  (ref) => ManagerDealsController(ref.watch(managerRepositoryProvider)),
);

class ManagerDealsController
    extends StateNotifier<AsyncValue<ManagerDealsPage>> {
  ManagerDealsController(this._repo) : super(const AsyncValue.loading()) {
    loadDeals();
  }

  final ManagerRepository _repo;
  int _currentPage = 1;
  String? _statusFilter;

  Future<void> loadDeals({bool refresh = false}) async {
    if (refresh) {
      _currentPage = 1;
      state = const AsyncValue.loading();
    }

    try {
      final page = await _repo.fetchDeals(
        page: _currentPage,
        status: _statusFilter,
      );

      if (refresh) {
        state = AsyncValue.data(page);
      } else {
        final current = state.value;
        if (current != null) {
          state = AsyncValue.data(
            ManagerDealsPage(
              items: [...current.items, ...page.items],
              page: page.page,
              limit: page.limit,
              totalRows: page.totalRows,
            ),
          );
        } else {
          state = AsyncValue.data(page);
        }
      }
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setStatusFilter(String? status) {
    _statusFilter = status;
    loadDeals(refresh: true);
  }
}

class ManagerDealsScreen extends ConsumerWidget {
  const ManagerDealsScreen({super.key});

  static const routePath = '/manager/deals';
  static const routeName = 'managerDeals';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final authState = ref.watch(authControllerProvider);
    final dealsAsync = ref.watch(managerDealsProvider);
    final l10n = AppLocalizations.of(context)!;

    return authState.when(
      data: (session) {
        final user = session?.user;
        final canAdd = user != null && Permissions.canAddDeals(user.role);

        return Scaffold(
          appBar: AppBar(
            title: Text(
              Permissions.isAdminOrSubAdmin(user?.role ?? UserRole.kiosk)
                  ? l10n.manageDeals
                  : l10n.myDeals,
            ),
          ),
          floatingActionButton: canAdd
              ? Padding(
                  padding: const EdgeInsets.only(
                    bottom: kBottomNavigationBarHeight,
                  ),
                  child: FloatingActionButton(
                    onPressed: () => _showCreateDealModal(context, ref),
                    child: const Icon(Icons.add),
                  ),
                )
              : null,
          floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
          body: dealsAsync.when(
            data: (page) {
              if (page.items.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.local_offer_outlined,
                        size: 64,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n.noDealsYet,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      if (canAdd)
                        ElevatedButton.icon(
                          onPressed: () {
                            _showCreateDealModal(context, ref);
                          },
                          icon: const Icon(Icons.add),
                          label: Text(l10n.createYourFirstDeal),
                        ),
                    ],
                  ),
                );
              }

              return RefreshIndicator(
                onRefresh: () async {
                  ref
                      .read(managerDealsProvider.notifier)
                      .loadDeals(refresh: true);
                },
                child: ListView.builder(
                  padding: EdgeInsets.only(
                    left: 16,
                    right: 16,
                    top: 16,
                    bottom: 16 +
                        MediaQuery.of(context).padding.bottom +
                        140, // Extra space for FAB above bottom nav (65 nav + 56 FAB + 20 margin)
                  ),
                  itemCount: page.items.length,
                  itemBuilder: (context, index) {
                    final deal = page.items[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        onTap: () async {
                          await context.push('/deals/${deal.id}');
                          if (context.mounted) {
                            ref
                                .read(managerDealsProvider.notifier)
                                .loadDeals(refresh: true);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      deal.title,
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleMedium
                                          ?.copyWith(
                                              fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Chip(
                                    label: Text(deal.status.toUpperCase()),
                                    backgroundColor: _getStatusColor(
                                      deal.status,
                                      Theme.of(context),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '${context.formatPriceEurOnly(deal.dealPrice)} '
                                          '(${context.formatPriceUsdFromEur(deal.dealPrice)})',
                                          style: Theme.of(context)
                                              .textTheme
                                              .titleLarge
                                              ?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context)
                                                    .colorScheme
                                                    .primary,
                                              ),
                                        ),
                                        Text(
                                          '${deal.orderCount} ${l10n.ordersCountSuffix}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        _isManagerDealEnded(deal)
                                            ? (l10n.dealClosed)
                                            : '${deal.receivedQuantity}/${deal.targetQuantity}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleMedium
                                            ?.copyWith(
                                                fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        '${(_isManagerDealEnded(deal) ? 100.0 : deal.progressPercent).toStringAsFixed(0)}%',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              LinearProgressIndicator(
                                value: (_isManagerDealEnded(deal) ? 100.0 : deal.progressPercent) / 100,
                                minHeight: 6,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('${l10n.error}: $error'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => ref
                        .read(managerDealsProvider.notifier)
                        .loadDeals(refresh: true),
                    child: Text(l10n.retry),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => Scaffold(
        appBar: AppBar(),
        body: Center(child: Text('Error: $error')),
      ),
    );
  }

  void _showCreateDealModal(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) => Consumer(
        builder: (context, ref, child) {
          final authState = ref.watch(authControllerProvider);
          final isAdmin = authState.maybeWhen(
            data: (session) => Permissions.isAdminOrSubAdmin(
                session?.user.role ?? UserRole.kiosk),
            orElse: () => false,
          );

          // Load wholesalers if admin
          final wholesalersAsync = isAdmin
              ? ref.watch(wholesalersForProductProvider)
              : const AsyncValue.data(<Map<String, String>>[]);

          return wholesalersAsync.when(
            data: (wholesalers) {
              final session = ref.read(authControllerProvider).valueOrNull;
              return CreateDealModal(
                onSave: (data) async {
                  await ref
                      .read(managerRepositoryProvider)
                      .createDeal(data.toJson());
                  ref
                      .read(managerDealsProvider.notifier)
                      .loadDeals(refresh: true);
                  if (modalContext.mounted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (modalContext.mounted &&
                          Navigator.canPop(modalContext)) {
                        Navigator.pop(modalContext);
                      }
                    });
                    ScaffoldMessenger.of(modalContext).showSnackBar(
                      SnackBar(content: Text(l10n.dealCreatedSuccessfully)),
                    );
                  }
                },
                currentUserId: session?.user.id,
                initialUser: session?.user,
                wholesalers: wholesalers,
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (error, stack) {
              debugPrint('wholesalersForProductProvider error: $error');
              final session = ref.read(authControllerProvider).valueOrNull;
              return CreateDealModal(
                onSave: (data) async {
                  await ref
                      .read(managerRepositoryProvider)
                      .createDeal(data.toJson());
                  ref
                      .read(managerDealsProvider.notifier)
                      .loadDeals(refresh: true);
                  if (modalContext.mounted) {
                    SchedulerBinding.instance.addPostFrameCallback((_) {
                      if (modalContext.mounted &&
                          Navigator.canPop(modalContext)) {
                        Navigator.pop(modalContext);
                      }
                    });
                    ScaffoldMessenger.of(modalContext).showSnackBar(
                      SnackBar(
                        content: Text(
                          AppLocalizations.of(modalContext)
                                  ?.dealCreatedSuccessfully ??
                              l10n.dealCreatedSuccessfully,
                        ),
                      ),
                    );
                  }
                },
                currentUserId: session?.user.id,
                initialUser: session?.user,
                wholesalers: const [],
              );
            },
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status, ThemeData theme) {
    switch (status.toLowerCase()) {
      case 'live':
        return Colors.green.withValues(alpha: 0.2);
      case 'scheduled':
        return Colors.blue.withValues(alpha: 0.2);
      case 'draft':
        return Colors.grey.withValues(alpha: 0.2);
      case 'ended':
        return Colors.orange.withValues(alpha: 0.2);
      case 'cancelled':
        return Colors.red.withValues(alpha: 0.2);
      default:
        return theme.colorScheme.surfaceContainerHighest;
    }
  }
}
