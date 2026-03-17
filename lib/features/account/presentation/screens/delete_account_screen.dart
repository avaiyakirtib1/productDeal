import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/networking/api_exception.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../data/repositories/account_repository.dart';

class DeleteAccountScreen extends ConsumerStatefulWidget {
  const DeleteAccountScreen({super.key});

  static const routePath = '/account/delete';
  static const routeName = 'delete-account';

  @override
  ConsumerState<DeleteAccountScreen> createState() =>
      _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends ConsumerState<DeleteAccountScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSubmitting = false;
  bool _isConfirmed = false;
  late AnimationController _animationController;
  int _flippedCardIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    // Pre-fill email from current user
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user != null) {
      _emailController.text = user.email;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _reasonController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _flipCard(int index) {
    setState(() {
      if (_flippedCardIndex == index) {
        _flippedCardIndex = -1;
      } else {
        _flippedCardIndex = index;
      }
    });
  }

  Future<void> _submitDeletionRequest() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_isConfirmed) {
      final l10n = AppLocalizations.of(context);
      showSnackBar(
        context,
        l10n?.confirmActionPermanent ??
            'Please confirm that you understand this action is permanent',
        isError: true,
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final repository = ref.read(accountRepositoryProvider);
      final response = await repository.requestAccountDeletion(
        email: _emailController.text.trim(),
        reason: _reasonController.text.trim().isEmpty
            ? null
            : _reasonController.text.trim(),
      );

      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            icon: const Icon(
              Icons.check_circle,
              color: AppColors.success,
              size: 64,
            ),
            title: Text(l10n?.requestSubmitted ?? 'Request Submitted'),
            content: Text(
              response.message ??
                  (l10n?.deletionRequestSubmittedMessage ??
                      'Your account deletion request has been submitted successfully. Our team will review it within 24-48 hours. You will receive a confirmation email once your request is processed.'),
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.pop();
                },
                child: Text(l10n?.ok ?? 'OK'),
              ),
            ],
          ),
        );
      }
    } on ApiException catch (e) {
      if (mounted) {
        showSnackBar(context, e.message, isError: true);
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showSnackBar(
          context,
          l10n?.failedToSubmitDeletionRequest ??
              'Failed to submit deletion request. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final user = ref.watch(authControllerProvider).valueOrNull?.user;

    return Scaffold(
      appBar: AppBar(
        title: Builder(
          builder: (context) {
            final l10n = AppLocalizations.of(context);
            return Text(l10n?.deleteAccount ?? 'Delete Account');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo/Header Section
              Center(
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/kf_app_icon.jpg',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: AppColors.primary,
                          child: const Icon(
                            Icons.shopping_bag,
                            size: 50,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.requestAccountDeletion ?? 'Request Account Deletion',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return Text(
                    l10n?.sorryToSeeYouGo ?? "We're sorry to see you go",
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  );
                },
              ),
              const SizedBox(height: 32),

              // Process Cards (Flipcard Style)
              _buildProcessCards(),
              const SizedBox(height: 32),

              // Important Notice
              _buildNoticeBox(),
              const SizedBox(height: 32),

              // Form Fields
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    enabled: user == null, // Enable only if not pre-filled
                    decoration: InputDecoration(
                      labelText: l10n?.emailAddress ?? 'Email Address',
                      hintText:
                          l10n?.enterRegisteredEmail ??
                          'Enter your registered email address',
                      border: const OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return l10n?.emailAddressRequired ??
                            'Email address is required';
                      }
                      if (!value.contains('@')) {
                        return l10n?.pleaseEnterValidEmail ??
                            'Please enter a valid email address';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 20),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return TextFormField(
                    controller: _reasonController,
                    maxLines: 4,
                    textInputAction: TextInputAction.done,
                    decoration: InputDecoration(
                      labelText: l10n?.reasonForDeletionOptional ??
                          'Reason for Deletion (Optional)',
                      hintText: l10n?.helpUsImproveLeaving ??
                          "Help us improve by sharing why you're leaving...",
                      border: const OutlineInputBorder(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),

              // Confirmation Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Checkbox(
                    value: _isConfirmed,
                    onChanged: (value) {
                      setState(() {
                        _isConfirmed = value ?? false;
                      });
                    },
                    activeColor: AppColors.primary,
                  ),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        final l10n = AppLocalizations.of(context);
                        return Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Text(
                            l10n?.understandActionPermanent ??
                                'I understand that this action is permanent and cannot be undone',
                            style: theme.textTheme.bodyMedium,
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Submit Button
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return PrimaryButton(
                    label: l10n?.submitDeletionRequest ??
                        'Submit Deletion Request',
                    isLoading: _isSubmitting,
                    onPressed: _submitDeletionRequest,
                  );
                },
              ),
              const SizedBox(height: 20),

              // Support Link
              Center(
                child: Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return TextButton(
                      onPressed: () {
                        // You can add support contact action here
                        showSnackBar(context,
                            '${l10n?.contactSupportAt ?? 'Contact support at'} support@productdeal.com');
                      },
                      child: Text(l10n?.needHelpContactSupport ??
                          'Need help? Contact Support'),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProcessCards() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 600;
        if (isSmallScreen) {
          return Column(
            children: [
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _ProcessCard(
                    index: 0,
                    isFlipped: _flippedCardIndex == 0,
                    onTap: () => _flipCard(0),
                    number: '1',
                    icon: Icons.email_outlined,
                    title: l10n?.submitRequest ?? 'Submit Request',
                    description: l10n?.submitRequestDescription ??
                        'Enter your email address to request account deletion',
                    backTitle: l10n?.whatHappensNext ?? 'What happens next?',
                    backDescription: l10n?.reviewProcessDescription ??
                        'Our team will review your request within 24-48 hours. You\'ll receive a confirmation email once your request is processed.',
                  );
                },
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _ProcessCard(
                    index: 1,
                    isFlipped: _flippedCardIndex == 1,
                    onTap: () => _flipCard(1),
                    number: '2',
                    icon: Icons.search,
                    title: l10n?.reviewProcess ?? 'Review Process',
                    description: l10n?.ourTeamReviewsYourRequest ??
                        'Our team reviews your request',
                    backTitle: l10n?.reviewDetails ?? 'Review Details',
                    backDescription: l10n?.reviewDetailsDescription ??
                        'We verify your account and ensure all pending orders or transactions are completed before proceeding with deletion.',
                  );
                },
              ),
              const SizedBox(height: 12),
              Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _ProcessCard(
                    index: 2,
                    isFlipped: _flippedCardIndex == 2,
                    onTap: () => _flipCard(2),
                    number: '3',
                    icon: Icons.check_circle_outline,
                    title: l10n?.accountDeleted ?? 'Account Deleted',
                    description: l10n?.yourAccountIsPermanentlyRemoved ??
                        'Your account is permanently removed',
                    backTitle: l10n?.finalStep ?? 'Final Step',
                    backDescription: l10n?.finalStepDescription ??
                        'Once approved, your account data will be permanently deleted from our system. This action cannot be undone.',
                  );
                },
              ),
            ],
          );
        }
        return Row(
          children: [
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _ProcessCard(
                    index: 0,
                    isFlipped: _flippedCardIndex == 0,
                    onTap: () => _flipCard(0),
                    number: '1',
                    icon: Icons.email_outlined,
                    title: l10n?.submitRequest ?? 'Submit Request',
                    description: l10n?.submitRequestDescription ??
                        'Enter your email address to request account deletion',
                    backTitle: l10n?.whatHappensNext ?? 'What happens next?',
                    backDescription: l10n?.reviewProcessDescription ??
                        'Our team will review your request within 24-48 hours. You\'ll receive a confirmation email once your request is processed.',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _ProcessCard(
                    index: 1,
                    isFlipped: _flippedCardIndex == 1,
                    onTap: () => _flipCard(1),
                    number: '2',
                    icon: Icons.search,
                    title: l10n?.reviewProcess ?? 'Review Process',
                    description: l10n?.ourTeamReviewsYourRequest ??
                        'Our team reviews your request',
                    backTitle: l10n?.reviewDetails ?? 'Review Details',
                    backDescription: l10n?.reviewDetailsDescription ??
                        'We verify your account and ensure all pending orders or transactions are completed before proceeding with deletion.',
                  );
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Builder(
                builder: (context) {
                  final l10n = AppLocalizations.of(context);
                  return _ProcessCard(
                    index: 2,
                    isFlipped: _flippedCardIndex == 2,
                    onTap: () => _flipCard(2),
                    number: '3',
                    icon: Icons.check_circle_outline,
                    title: l10n?.accountDeleted ?? 'Account Deleted',
                    description: l10n?.yourAccountIsPermanentlyRemoved ??
                        'Your account is permanently removed',
                    backTitle: l10n?.finalStep ?? 'Final Step',
                    backDescription: l10n?.finalStepDescription ??
                        'Once approved, your account data will be permanently deleted from our system. This action cannot be undone.',
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNoticeBox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.warning.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.warning,
            size: 32,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Text(
                      l10n?.importantInformation ?? 'Important Information',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.warning,
                          ),
                    );
                  },
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildNoticeItem(l10n?.accountDeletionIsPermanent ??
                        'Account deletion is permanent and cannot be reversed');
                  },
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildNoticeItem(l10n?.allDataWillBeRemoved ??
                        'All your data, orders, and history will be permanently removed');
                  },
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildNoticeItem(l10n
                            ?.pendingOrdersMustBeCompleted ??
                        'Pending orders must be completed before deletion can proceed');
                  },
                ),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return _buildNoticeItem(l10n
                            ?.youllReceiveEmailConfirmation ??
                        'You\'ll receive an email confirmation once the process is complete');
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoticeItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '•',
            style: TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.warning,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProcessCard extends StatelessWidget {
  const _ProcessCard({
    required this.index,
    required this.isFlipped,
    required this.onTap,
    required this.number,
    required this.icon,
    required this.title,
    required this.description,
    required this.backTitle,
    required this.backDescription,
  });

  final int index;
  final bool isFlipped;
  final VoidCallback onTap;
  final String number;
  final IconData icon;
  final String title;
  final String description;
  final String backTitle;
  final String backDescription;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isFlipped
              ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.primaryLight],
                )
              : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.primaryLight.withValues(alpha: 0.1),
                  ],
                ),
          border: Border.all(
            color: isFlipped
                ? Colors.transparent
                : AppColors.primary.withValues(alpha: 0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child:
                isFlipped ? _buildBackSide(context) : _buildFrontSide(context),
          ),
        ),
      ),
    );
  }

  Widget _buildFrontSide(BuildContext context) {
    return Container(
      key: const ValueKey('front'),
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 8),
              Icon(icon, size: 48, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                description,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          // Number Badge
          Positioned(
            top: 8,
            left: 8,
            child: Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  number,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackSide(BuildContext context) {
    return Container(
      key: const ValueKey('back'),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            backTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            backDescription,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
