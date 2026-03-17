import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/utils/snackbar.dart';
import '../../../../shared/widgets/payment_mode_selector.dart';
import '../../../../shared/widgets/primary_button.dart';
import '../../../../shared/widgets/primary_text_field.dart';
import '../../data/models/auth_models.dart';
import '../controllers/auth_controller.dart';
import '../controllers/register_form_controller.dart';
import '../widgets/auth_header.dart';
import '../widgets/auth_role_selector.dart';
import '../widgets/legal_document_viewer.dart';
import 'login_screen.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  static const routePath = '/register';
  static const routeName = 'register';

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameKey = GlobalKey<FormFieldState<String>>();
  final _emailKey = GlobalKey<FormFieldState<String>>();
  final _phoneKey = GlobalKey<FormFieldState<String>>();
  final _passwordKey = GlobalKey<FormFieldState<String>>();
  final _confirmPasswordKey = GlobalKey<FormFieldState<String>>();
  final _fullNameFocusNode = FocusNode();
  final _emailFocusNode = FocusNode();
  final _phoneFocusNode = FocusNode();
  final _passwordFocusNode = FocusNode();
  final _confirmPasswordFocusNode = FocusNode();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _businessController = TextEditingController();
  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _addressController = TextEditingController();
  final _paymentIbanController = TextEditingController();
  final _paymentBankAccountOwnerController = TextEditingController();
  bool _obscurePassword = true;

  /// Accepted payment modes (at least one). Default: cash on delivery.
  List<String> _paymentModes = ['cash_on_delivery'];
  bool _obscureConfirmPassword = true;
  UserRole _role = UserRole.kiosk;
  late final ProviderSubscription<AsyncValue<void>> _registerListener;
  bool _termsAccepted = false;
  bool _privacyAccepted = false;
  // Wholesaler-specific legal consent
  bool _agbAccepted = false;
  bool _complianceAccepted = false;
  bool _privacyLegalAccepted = false;
  bool _frameworkContractAccepted = false;

  @override
  void initState() {
    super.initState();
    _registerListener = ref.listenManual<AsyncValue<void>>(
        registerFormControllerProvider, (previous, next) {
      next.whenOrNull(
        data: (_) {
          // Don't manually redirect - let router handle it based on auth state
          // Router will automatically redirect based on user status (approved -> dashboard, pending -> waiting)
          // showSnackBar(
          //   context,
          //   'Registration received! We will notify you once the account is approved.',
          // );
          // Router will automatically redirect based on auth state
        },
        error: (error, stackTrace) {
          final message = ref
              .read(authControllerProvider.notifier)
              .resolveError(error)
              .message;
          showSnackBar(context, message, isError: true);
        },
      );
    });
  }

  @override
  void dispose() {
    _registerListener.close();
    _fullNameFocusNode.dispose();
    _emailFocusNode.dispose();
    _phoneFocusNode.dispose();
    _passwordFocusNode.dispose();
    _confirmPasswordFocusNode.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _businessController.dispose();
    _countryController.dispose();
    _cityController.dispose();
    _addressController.dispose();
    _paymentIbanController.dispose();
    _paymentBankAccountOwnerController.dispose();
    super.dispose();
  }

  bool get _isLegalComplete {
    if (_role == UserRole.wholesaler) {
      return _agbAccepted &&
          _complianceAccepted &&
          _privacyLegalAccepted &&
          _frameworkContractAccepted;
    }
    return _termsAccepted && _privacyAccepted;
  }

  void _focusFirstError() {
    final keys = [
      _fullNameKey,
      _emailKey,
      _phoneKey,
      _passwordKey,
      _confirmPasswordKey
    ];
    final nodes = [
      _fullNameFocusNode,
      _emailFocusNode,
      _phoneFocusNode,
      _passwordFocusNode,
      _confirmPasswordFocusNode
    ];
    for (var i = 0; i < keys.length; i++) {
      if (keys[i].currentState?.hasError == true) {
        nodes[i].requestFocus();
        return;
      }
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      _focusFirstError();
      return;
    }

    final isWholesaler = _role == UserRole.wholesaler;
    if (isWholesaler) {
      if (!_agbAccepted ||
          !_complianceAccepted ||
          !_privacyLegalAccepted ||
          !_frameworkContractAccepted) {
        final l10n = AppLocalizations.of(context);
        showSnackBar(
          context,
          l10n?.mustAcceptAllLegalDocuments ??
              'Please accept all legal documents to continue.',
          isError: true,
        );
        return;
      }
    } else {
      if (!_termsAccepted || !_privacyAccepted) {
        final l10n = AppLocalizations.of(context);
        showSnackBar(
          context,
          l10n?.mustAcceptTermsAndPrivacy ??
              'Please accept the Terms & Conditions and Data Privacy to continue.',
          isError: true,
        );
        return;
      }
    }

    ref.read(registerFormControllerProvider.notifier).submit(
          RegisterPayload(
            fullName: _fullNameController.text.trim(),
            email: _emailController.text.trim(),
            phone: _phoneController.text.trim().isEmpty
                ? null
                : _phoneController.text.trim(),
            password: _passwordController.text.trim(),
            role: _role,
            businessName: _businessController.text.trim().isEmpty
                ? null
                : _businessController.text.trim(),
            country: _countryController.text.trim().isEmpty
                ? null
                : _countryController.text.trim(),
            city: _cityController.text.trim().isEmpty
                ? null
                : _cityController.text.trim(),
            address: _addressController.text.trim().isEmpty
                ? null
                : _addressController.text.trim(),
            defaultPaymentModes: isWholesaler ? _paymentModes : null,
            paymentConfig: isWholesaler &&
                    (_paymentModes.contains('invoice') ||
                        _paymentModes.contains('bank_transfer')) &&
                    (_paymentIbanController.text.trim().isNotEmpty ||
                        _paymentBankAccountOwnerController.text
                            .trim()
                            .isNotEmpty)
                ? PaymentConfig(
                    iban: _paymentIbanController.text.trim().isEmpty
                        ? null
                        : _paymentIbanController.text.trim(),
                    accountHolderName:
                        _paymentBankAccountOwnerController.text.trim().isEmpty
                            ? null
                            : _paymentBankAccountOwnerController.text.trim(),
                  )
                : null,
            termsAccepted: isWholesaler ? true : _termsAccepted,
            privacyAccepted: isWholesaler ? true : _privacyAccepted,
            agbAccepted: isWholesaler ? _agbAccepted : null,
            complianceAccepted: isWholesaler ? _complianceAccepted : null,
            privacyLegalAccepted: isWholesaler ? _privacyLegalAccepted : null,
            frameworkContractAccepted:
                isWholesaler ? _frameworkContractAccepted : null,
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerFormControllerProvider);
    final isLoading = registerState.isLoading;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthHeader(
                title: l10n?.createAccountTitle ?? 'Create account',
                subtitle: l10n?.createAccountSubtitle ??
                    'Unlock curated wholesalers, big deals and logistics support.',
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show error message on page if registration failed
                      Builder(
                        builder: (context) {
                          final registerState =
                              ref.watch(registerFormControllerProvider);
                          final error = registerState.error;
                          if (error != null) {
                            final message = ref
                                .read(authControllerProvider.notifier)
                                .resolveError(error)
                                .message;
                            return Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 16),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .errorContainer,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.error_outline,
                                    color: Theme.of(context).colorScheme.error,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      message,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium
                                          ?.copyWith(
                                            color: Theme.of(context)
                                                .colorScheme
                                                .error,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                      Text(
                        l10n?.accountType ?? 'Account type',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 12),
                      IgnorePointer(
                        ignoring:
                            isLoading, // Disable role selection during registration
                        child: Opacity(
                          opacity: isLoading ? 0.5 : 1.0,
                          child: AuthRoleSelector(
                            value: _role,
                            onChanged: (role) => setState(() => _role = role),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      PrimaryTextField(
                        formFieldKey: _fullNameKey,
                        focusNode: _fullNameFocusNode,
                        controller: _fullNameController,
                        label: l10n?.fullName ?? 'Full name',
                        enabled: !isLoading, // Disable during registration
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.fullNameRequired ??
                                'Full name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      PrimaryTextField(
                        formFieldKey: _emailKey,
                        focusNode: _emailFocusNode,
                        controller: _emailController,
                        label: l10n?.workEmail ?? 'Work email',
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading, // Disable during registration
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return l10n?.emailRequired ?? 'Email is required';
                          }
                          if (!value.contains('@')) {
                            return l10n?.provideValidEmail ??
                                'Provide a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      PrimaryTextField(
                        formFieldKey: _phoneKey,
                        focusNode: _phoneFocusNode,
                        controller: _phoneController,
                        label: l10n?.phoneNumberOptional ??
                            'Phone number (optional)',
                        keyboardType: TextInputType.phone,
                        enabled: !isLoading, // Disable during registration
                        validator: (value) {
                          if (value != null &&
                              value.isNotEmpty &&
                              value.length < 8) {
                            return l10n?.enterValidPhoneNumber ??
                                'Enter a valid phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      PrimaryTextField(
                        controller: _businessController,
                        label: _role == UserRole.kiosk
                            ? (l10n?.kioskShopNameOptional ??
                                'Kiosk / Shop name (optional)')
                            : (l10n?.companyName ?? 'Company name'),
                        enabled: !isLoading, // Disable during registration
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryTextField(
                              controller: _countryController,
                              label: l10n?.country ?? 'Country',
                              enabled:
                                  !isLoading, // Disable during registration
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: PrimaryTextField(
                              controller: _cityController,
                              label: l10n?.city ?? 'City',
                              enabled:
                                  !isLoading, // Disable during registration
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      PrimaryTextField(
                        controller: _addressController,
                        label: l10n?.streetAddress ?? 'Street address',
                        maxLines: 2,
                        enabled: !isLoading, // Disable during registration
                        helperText: l10n?.addressWillBeGeocoded ??
                            'Address will be automatically geocoded to get coordinates',
                      ),
                      const SizedBox(height: 16),
                      PrimaryTextField(
                        formFieldKey: _passwordKey,
                        focusNode: _passwordFocusNode,
                        controller: _passwordController,
                        label: l10n?.createPassword ?? 'Create password',
                        obscureText: _obscurePassword,
                        enabled: !isLoading, // Disable during registration
                        validator: (value) {
                          if (value == null || value.length < 8) {
                            return l10n?.minimum8CharactersRequired ??
                                'Minimum 8 characters required';
                          }
                          return null;
                        },
                        suffix: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: isLoading
                              ? null
                              : () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      const SizedBox(height: 16),
                      PrimaryTextField(
                        formFieldKey: _confirmPasswordKey,
                        focusNode: _confirmPasswordFocusNode,
                        controller: _confirmPasswordController,
                        label: l10n?.confirmPasswordLabel ?? 'Confirm password',
                        obscureText: _obscureConfirmPassword,
                        enabled: !isLoading, // Disable during registration
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return l10n?.passwordsDoNotMatch ??
                                'Passwords do not match';
                          }
                          return null;
                        },
                        suffix: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined),
                          onPressed: isLoading
                              ? null
                              : () => setState(() => _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),

                      if (_role == UserRole.wholesaler) ...[
                        const SizedBox(height: 24),
                        Text(
                          l10n?.paymentMode ?? 'Payment Mode',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n?.paymentModeSubtitleMulti ??
                              'Select all payment methods you accept. You can change this later in your profile.',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                        const SizedBox(height: 12),
                        PaymentModeSelectorMulti(
                          value: _paymentModes,
                          onChanged: isLoading
                              ? null
                              : (v) => setState(() => _paymentModes = v),
                          l10n: l10n,
                        ),
                        if (_paymentModes.contains('invoice') ||
                            _paymentModes.contains('bank_transfer')) ...[
                          const SizedBox(height: 24),
                          Text(
                            l10n?.paymentSettings ?? 'Payment Settings',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            l10n?.paymentSettingsSubtitle ??
                                'Bank details for invoice/bank transfer orders. You can update these later in your profile.',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                          const SizedBox(height: 12),
                          PrimaryTextField(
                            controller: _paymentIbanController,
                            label:
                                l10n?.ibanBankAccount ?? 'IBAN / Bank Account',
                            enabled: !isLoading,
                          ),
                          const SizedBox(height: 12),
                          PrimaryTextField(
                            controller: _paymentBankAccountOwnerController,
                            label: l10n?.accountOwner ?? 'Account Owner',
                            enabled: !isLoading,
                          ),
                        ],
                      ],
                      const SizedBox(height: 24),
                      // Legal: Wholesaler = "Rechtliche Dokumente" (4 docs); Kiosk = simple T&C + Privacy
                      if (_role == UserRole.wholesaler) ...[
                        Text(
                          'Rechtliche Dokumente',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _LegalCheckboxWithLink(
                          value: _agbAccepted,
                          onChanged: isLoading
                              ? null
                              : (v) =>
                                  setState(() => _agbAccepted = v ?? false),
                          onTapLink: () => LegalDocumentViewer.showAgb(context),
                          label: 'Ich habe die ',
                          linkText: 'Allgemeinen Geschäftsbedingungen (AGB)',
                          labelSuffix: ' gelesen und akzeptiere diese.',
                        ),
                        _LegalCheckboxWithLink(
                          value: _complianceAccepted,
                          onChanged: isLoading
                              ? null
                              : (v) => setState(
                                  () => _complianceAccepted = v ?? false),
                          onTapLink: () =>
                              LegalDocumentViewer.showCompliance(context),
                          label: 'Ich akzeptiere die ',
                          linkText:
                              'Compliance-Richtlinie (Markenrecht & Produktintegrität)',
                          labelSuffix: '.',
                        ),
                        _LegalCheckboxWithLink(
                          value: _privacyLegalAccepted,
                          onChanged: isLoading
                              ? null
                              : (v) => setState(
                                  () => _privacyLegalAccepted = v ?? false),
                          onTapLink: () =>
                              LegalDocumentViewer.showPrivacy(context),
                          label: 'Ich stimme der ',
                          linkText: 'Datenschutzerklärung',
                          labelSuffix: ' und Datenübermittlung zu.',
                        ),
                        CheckboxListTile(
                          value: _frameworkContractAccepted,
                          onChanged: isLoading
                              ? null
                              : (value) => setState(() =>
                                  _frameworkContractAccepted = value ?? false),
                          controlAffinity: ListTileControlAffinity.leading,
                          title: GestureDetector(
                            onTap: () =>
                                LegalDocumentViewer.showRahmenvertrag(context),
                            child: RichText(
                              text: TextSpan(
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurface,
                                    ),
                                children: [
                                  const TextSpan(
                                      text: 'Ich bestätige, dass ich den '),
                                  TextSpan(
                                    text: 'Rahmenvertrag zur Nutzung der App',
                                    style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      decoration: TextDecoration.underline,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const TextSpan(text: ' gelesen habe.'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Kiosk: AGB + Data Privacy (same document display as wholesaler)
                        Text(
                          'Rechtliche Dokumente',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 12),
                        _LegalCheckboxWithLink(
                          value: _termsAccepted,
                          onChanged: isLoading
                              ? null
                              : (v) =>
                                  setState(() => _termsAccepted = v ?? false),
                          onTapLink: () => LegalDocumentViewer.showAgb(context),
                          label: 'Ich habe die ',
                          linkText: 'Allgemeinen Geschäftsbedingungen (AGB)',
                          labelSuffix: ' gelesen und akzeptiere diese.',
                        ),
                        _LegalCheckboxWithLink(
                          value: _privacyAccepted,
                          onChanged: isLoading
                              ? null
                              : (v) =>
                                  setState(() => _privacyAccepted = v ?? false),
                          onTapLink: () =>
                              LegalDocumentViewer.showPrivacy(context),
                          label: 'Ich stimme der ',
                          linkText: 'Datenschutzerklärung',
                          labelSuffix: ' und Datenübermittlung zu.',
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Icon(Icons.verified_user,
                              color: AppColors.primary.withValues(alpha: .7)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              l10n?.weVerifyEveryBusiness ??
                                  'We verify every business manually to keep the marketplace trusted.',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      PrimaryButton(
                        label: l10n?.submitForReview ?? 'Submit for review',
                        prefixIcon: Icons.send_rounded,
                        isLoading: isLoading,
                        onPressed:
                            (isLoading || !_isLegalComplete) ? null : _submit,
                      ),
                      const SizedBox(height: 16),
                      IgnorePointer(
                        ignoring:
                            isLoading, // Disable navigation during registration
                        child: Opacity(
                          opacity: isLoading ? 0.5 : 1.0,
                          child: TextButton(
                            onPressed: () => context.go(LoginScreen.routePath),
                            child: Text(l10n?.alreadyVerifiedSignIn ??
                                'Already verified? Sign in'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LegalCheckboxWithLink extends StatelessWidget {
  const _LegalCheckboxWithLink({
    required this.value,
    required this.onChanged,
    required this.onTapLink,
    required this.label,
    required this.linkText,
    required this.labelSuffix,
  });

  final bool value;
  final ValueChanged<bool?>? onChanged;
  final VoidCallback onTapLink;
  final String label;
  final String linkText;
  final String labelSuffix;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.onSurface,
        );
    final linkStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          decoration: TextDecoration.underline,
          fontWeight: FontWeight.w600,
        );
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
      title: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(label, style: style),
          GestureDetector(
            onTap: onTapLink,
            child: Text(linkText, style: linkStyle),
          ),
          Text(labelSuffix, style: style),
        ],
      ),
    );
  }
}
