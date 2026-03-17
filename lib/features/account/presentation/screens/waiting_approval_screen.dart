import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../data/models/account_models.dart';
import '../providers/account_status_provider.dart';
import '../widgets/approved_state_widget.dart';
import '../widgets/status_section.dart';
import '../widgets/categorized_upload_section.dart';
import '../widgets/email_section.dart';

class WaitingApprovalScreen extends ConsumerStatefulWidget {
  const WaitingApprovalScreen({super.key});

  static const routePath = '/waiting-approval';
  static const routeName = 'waitingApproval';

  @override
  ConsumerState<WaitingApprovalScreen> createState() =>
      _WaitingApprovalScreenState();
}

class _WaitingApprovalScreenState extends ConsumerState<WaitingApprovalScreen>
    with WidgetsBindingObserver {
  int _countdownSeconds = 10;
  Timer? _countdownTimer;
  AccountStatus? _lastStatus; // ignore: unused_field

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _startCountdown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownSeconds = 10;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          if (_countdownSeconds > 0) {
            _countdownSeconds--;
          } else {
            _countdownSeconds = 10; // Reset countdown
          }
        });
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Resume polling when app comes to foreground
    if (state == AppLifecycleState.resumed) {
      ref.invalidate(accountStatusProvider);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(accountStatusProvider);
    final l10n = AppLocalizations.of(context);

    // Reset countdown when status changes
    ref.listen<AsyncValue<AccountStatus>>(accountStatusProvider,
        (previous, next) {
      next.whenData((status) {
        final previousStatus = previous?.value;
        if (previousStatus != null && previousStatus.status != status.status) {
          _startCountdown();
        }
        _lastStatus = status;
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.accountApproval ?? 'Account Approval'),
        automaticallyImplyLeading: false,
        elevation: 0,
        centerTitle: true,
      ),
      body: statusAsync.when(
        data: (status) {
          // Auto-navigate if approved
          if (status.isApproved) {
            // Refresh user session first to update status
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              if (mounted) {
                try {
                  // Refresh the user session to get updated status
                  await ref.read(authControllerProvider.notifier).refreshUser();

                  // Small delay to ensure state is updated
                  await Future.delayed(const Duration(milliseconds: 300));

                  // Navigate to main app
                  if (context.mounted) {
                    context.go(DashboardScreen.routePath);
                  }
                } catch (e) {
                  // If refresh fails, still try to navigate
                  // The router redirect will handle it
                  if (context.mounted) {
                    context.go(DashboardScreen.routePath);
                  }
                }
              }
            });
            return const ApprovedStateWidget();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 16),
                // Status Section
                StatusSection(
                  status: status,
                  countdownSeconds: _countdownSeconds,
                ),
                const SizedBox(height: 32),
                // Categorized Upload Section
                const CategorizedUploadSection(),
                const SizedBox(height: 24),
                // Email Section
                const EmailSection(),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
        loading: () {
          final loadingL10n = AppLocalizations.of(context);
          final loadingTheme = Theme.of(context);
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  strokeWidth: 3,
                ),
                const SizedBox(height: 16),
                Text(
                  loadingL10n?.loadingAccountStatus ??
                      'Loading account status...',
                  style: loadingTheme.textTheme.bodyLarge?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          );
        },
        error: (error, stack) {
          final errorL10n = AppLocalizations.of(context);
          final errorTheme = Theme.of(context);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    errorL10n?.errorLoadingStatus ?? 'Error Loading Status',
                    style: errorTheme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    error.toString(),
                    style: errorTheme.textTheme.bodyMedium?.copyWith(
                      color: Colors.grey.shade600,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => ref.invalidate(accountStatusProvider),
                    icon: const Icon(Icons.refresh),
                    label: Text(errorL10n?.retry ?? 'Retry'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
