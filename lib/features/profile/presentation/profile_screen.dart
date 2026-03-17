import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'dart:typed_data';
import '../../../core/localization/app_localizations.dart';
import '../../../core/utils/snackbar.dart';
import '../../../core/services/upload_service.dart';
import '../../../core/services/image_picker_helper.dart';
import '../../../shared/widgets/network_avatar.dart';
import '../../../shared/widgets/primary_button.dart';
import '../../../shared/widgets/primary_text_field.dart';
import '../../auth/data/models/auth_models.dart';
import '../../auth/presentation/controllers/auth_controller.dart';
import '../../stories/presentation/screens/create_story_screen.dart';
import '../../../shared/widgets/payment_mode_selector.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  static const routePath = '/profile';
  static const routeName = 'profile';

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _businessController = TextEditingController();
  final _phoneController = TextEditingController();
  final _taglineController = TextEditingController();
  final _paymentIbanController = TextEditingController();
  final _paymentBankAccountOwnerController = TextEditingController();
  final _paymentInstructionsController = TextEditingController();
  final _paymentReferenceTemplateController = TextEditingController();
  bool _saving = false;
  List<UserLocation> _locations = const [];
  PickedFileData? _selectedAvatarImage;
  bool _uploadingAvatar = false;
  /// Accepted payment modes (at least one)
  List<String> _paymentModes = ['cash_on_delivery'];

  @override
  void initState() {
    super.initState();
    final user = ref.read(authControllerProvider).valueOrNull?.user;
    if (user != null) {
      _fullNameController.text = user.fullName;
      _businessController.text = user.businessName ?? '';
      _phoneController.text = user.phone ?? '';
      _taglineController.text = user.tagline ?? '';
      _paymentIbanController.text = user.effectiveIban ?? '';
      _paymentBankAccountOwnerController.text = user.effectiveAccountHolder ?? '';
      _paymentInstructionsController.text = user.paymentConfig?.paymentInstructions ?? user.paymentInstructions ?? '';
      _paymentReferenceTemplateController.text = user.paymentConfig?.paymentReferenceTemplate ?? user.paymentReferenceTemplate ?? '';
      // Initialize locations from user's locations array
      _locations = user.locations;
      // Accepted payment modes from profile or infer from payment config
      if (user.defaultPaymentModes != null && user.defaultPaymentModes!.isNotEmpty) {
        _paymentModes = List<String>.from(user.defaultPaymentModes!);
      } else {
        final single = user.defaultPaymentMode ??
            ((user.effectiveIban ?? '').trim().isNotEmpty ||
                    (user.effectiveAccountHolder ?? '').trim().isNotEmpty
                ? 'bank_transfer'
                : 'cash_on_delivery');
        _paymentModes = [single];
      }
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _businessController.dispose();
    _phoneController.dispose();
    _taglineController.dispose();
    _paymentIbanController.dispose();
    _paymentBankAccountOwnerController.dispose();
    _paymentInstructionsController.dispose();
    _paymentReferenceTemplateController.dispose();
    super.dispose();
  }

  Future<void> _uploadAvatar() async {
    try {
      setState(() => _uploadingAvatar = true);
      final uploadService = ref.read(uploadServiceProvider);

      // Pick and crop image to square (1:1 aspect ratio) for profile
      final imageData = await ImagePickerHelper.pickAndCropImage(
        circular: true,
        aspectRatioX: 1.0,
        aspectRatioY: 1.0,
      );

      if (imageData == null) {
        setState(() => _uploadingAvatar = false);
        return;
      }

      setState(() => _selectedAvatarImage = imageData);

      final url = await uploadService.uploadFile(
        fileData: imageData,
        folder: 'profiles',
      );

      // Update profile with new avatar URL
      final payload = UpdateProfilePayload(avatarUrl: url);
      await ref.read(authControllerProvider.notifier).updateProfile(payload);

      if (mounted) {
        setState(() => _uploadingAvatar = false);
        final l10n = AppLocalizations.of(context);
        showSnackBar(
            context, l10n?.profileImageUpdated ?? 'Profile image updated');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _uploadingAvatar = false);
        final l10n = AppLocalizations.of(context);
        showSnackBar(context,
            '${l10n?.failedToUploadImage ?? 'Failed to upload image'}: $e',
            isError: true);
      }
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    // If there's a new avatar image, upload it first
    String? avatarUrl;
    if (_selectedAvatarImage != null) {
      try {
        final uploadService = ref.read(uploadServiceProvider);
        avatarUrl = await uploadService.uploadFile(
          fileData: _selectedAvatarImage!,
          folder: 'profiles',
        );
      } catch (e) {
        if (mounted) {
          setState(() => _saving = false);
          final l10n = AppLocalizations.of(context);
          showSnackBar(
            context,
            '${l10n?.failedToUploadImage ?? 'Failed to upload image'}: $e',
            isError: true,
          );
          return;
        }
      }
    }

    final payload = UpdateProfilePayload(
      fullName: _fullNameController.text.trim().isEmpty
          ? null
          : _fullNameController.text.trim(),
      businessName: _businessController.text.trim().isEmpty
          ? null
          : _businessController.text.trim(),
      phone: _phoneController.text.trim().isEmpty
          ? null
          : _phoneController.text.trim(),
      tagline: _taglineController.text.trim().isEmpty
          ? null
          : _taglineController.text.trim(),
      avatarUrl: avatarUrl,
      defaultPaymentModes: _paymentModes,
      paymentConfig: (_paymentModes.contains('invoice') || _paymentModes.contains('bank_transfer'))
          ? PaymentConfig(
              iban: _paymentIbanController.text.trim().isEmpty ? null : _paymentIbanController.text.trim(),
              accountHolderName: _paymentBankAccountOwnerController.text.trim().isEmpty ? null : _paymentBankAccountOwnerController.text.trim(),
              paymentInstructions: _paymentInstructionsController.text.trim().isEmpty ? null : _paymentInstructionsController.text.trim(),
              paymentReferenceTemplate: _paymentReferenceTemplateController.text.trim().isEmpty ? null : _paymentReferenceTemplateController.text.trim(),
            )
          : const PaymentConfig(), // Clear when Cash selected
      // Legacy single address fields (for backward compatibility)
      country: null,
      city: null,
      address: null,
      latitude: null,
      longitude: null,
      // All addresses in locations array
      locations: _locations,
    );

    try {
      await ref.read(authControllerProvider.notifier).updateProfile(payload);
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        showSnackBar(context, l10n?.profileUpdated ?? 'Profile updated');
      }
    } catch (error) {
      final message =
          ref.read(authControllerProvider.notifier).resolveError(error).message;
      if (mounted) {
        showSnackBar(context, message, isError: true);
      }
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
  }

  void _removeLocation(int index) {
    setState(() {
      _locations = List.from(_locations)..removeAt(index);
    });
  }

  Future<void> _editLocation(int index, UserLocation location) async {
    final l10n = AppLocalizations.of(context);
    final result = await _showLocationDialog(
      initialLocation: location,
      title: l10n?.editAddressTitle ?? 'Edit Address',
    );

    if (result != null && mounted) {
      setState(() {
        _locations = List.from(_locations)..[index] = result;
      });
    }
  }

  Future<void> _addLocation() async {
    final l10n = AppLocalizations.of(context);
    final result = await _showLocationDialog(
      title: l10n?.addAddressTitle ?? 'Add Address',
    );

    if (result != null && mounted) {
      setState(() {
        _locations = [..._locations, result];
      });
    }
  }

  /// Location dialog: address/city/country only (same as register). Backend geocodes to get coordinates.
  Future<UserLocation?> _showLocationDialog({
    UserLocation? initialLocation,
    required String title,
  }) async {
    final labelController =
        TextEditingController(text: initialLocation?.label ?? '');
    final addressController =
        TextEditingController(text: initialLocation?.address ?? '');
    final countryController =
        TextEditingController(text: initialLocation?.country ?? '');
    final cityController =
        TextEditingController(text: initialLocation?.city ?? '');

    return showDialog<UserLocation?>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return PrimaryTextField(
                      controller: labelController,
                      label: l10n?.labelExample ??
                          'Label (e.g. Home, Office, Main Outlet)',
                    );
                  },
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return PrimaryTextField(
                      controller: addressController,
                      label: l10n?.streetAreaOptional ??
                          'Street / Area (optional)',
                      maxLines: 2,
                    );
                  },
                ),
                const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final l10n = AppLocalizations.of(context);
                    return Row(
                      children: [
                        Expanded(
                          child: PrimaryTextField(
                            controller: countryController,
                            label:
                                l10n?.countryOptional ?? 'Country (optional)',
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: PrimaryTextField(
                            controller: cityController,
                            label: l10n?.cityOptional ?? 'City (optional)',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          actions: [
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(null),
                  child: Text(l10n?.cancel ?? 'Cancel'),
                );
              },
            ),
            Builder(
              builder: (context) {
                final l10n = AppLocalizations.of(context);
                return FilledButton(
                  onPressed: () {
                    // Same as register: address/city/country only; backend geocodes for coordinates
                    Navigator.of(dialogContext).pop(
                      UserLocation(
                        label: labelController.text.trim().isEmpty
                            ? null
                            : labelController.text.trim(),
                        address: addressController.text.trim().isEmpty
                            ? null
                            : addressController.text.trim(),
                        country: countryController.text.trim().isEmpty
                            ? null
                            : countryController.text.trim(),
                        city: cityController.text.trim().isEmpty
                            ? null
                            : cityController.text.trim(),
                        latitude: null,
                        longitude: null,
                      ),
                    );
                  },
                  child: Text(initialLocation == null
                      ? (l10n?.add ?? 'Add')
                      : (l10n?.save ?? 'Save')),
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull?.user;
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n?.profile ?? 'Profile'),
        actions: [
          // Create Story button (Wholesalers only)
          if (user?.role == UserRole.wholesaler)
            IconButton(
              onPressed: () => context.push(CreateStoryScreen.routePath),
              icon: const Icon(Icons.add_photo_alternate),
              tooltip: l10n?.createStory ?? 'Create Story',
            ),
          TextButton(
            onPressed: _saving ? null : _saveProfile,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n?.save ?? 'Save'),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Center(
              child: Stack(
                children: [
                  _selectedAvatarImage != null
                      ? CircleAvatar(
                          radius: 45,
                          backgroundImage: _selectedAvatarImage!.isWeb
                              ? MemoryImage(Uint8List.fromList(
                                      _selectedAvatarImage!.bytes!))
                                  as ImageProvider
                              : FileImage(_selectedAvatarImage!.fileAsFile),
                        )
                      : NetworkAvatar(
                          imageUrl: user?.avatarUrl ?? '',
                          size: 90,
                          borderWidth: 3,
                          borderColor: Theme.of(context).colorScheme.primary,
                        ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: _uploadingAvatar
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.camera_alt,
                                color: Colors.white, size: 20),
                        onPressed: _uploadingAvatar ? null : _uploadAvatar,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            PrimaryTextField(
              controller: _fullNameController,
              label: l10n?.fullName ?? 'Full name',
              validator: (value) => value == null || value.isEmpty
                  ? (l10n?.nameIsRequired ?? 'Name is required')
                  : null,
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _businessController,
              label: l10n?.businessNameOptional ?? 'Business name (optional)',
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _phoneController,
              label: l10n?.phoneOptional ?? 'Phone (optional)',
            ),
            const SizedBox(height: 16),
            PrimaryTextField(
              controller: _taglineController,
              label: l10n?.tagline ?? 'Tagline',
            ),
            // Payment Mode + Payment Settings for Admin, SubAdmin, Wholesaler (all can create products/deals)
            if (user?.role == UserRole.admin ||
                user?.role == UserRole.subAdmin ||
                user?.role == UserRole.wholesaler) ...[
              const SizedBox(height: 24),
              Text(
                l10n?.paymentMode ?? 'Payment Mode',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                l10n?.paymentModeSubtitleMulti ??
                    l10n?.paymentModeSubtitle ??
                    'Select all payment methods you accept. You can change this later.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: 12),
              PaymentModeSelectorMulti(
                value: _paymentModes,
                onChanged: _saving ? null : (v) => setState(() => _paymentModes = v),
                l10n: l10n,
              ),
              if (_paymentModes.contains('invoice') ||
                  _paymentModes.contains('bank_transfer')) ...[
                const SizedBox(height: 24),
                Text(
                  l10n?.paymentSettings ?? 'Payment Settings',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.paymentSettingsSubtitle ??
                      'Bank details for invoice/bank transfer orders. You can update these later.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _paymentIbanController,
                  label: l10n?.ibanBankAccount ?? 'IBAN / Bank Account',
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _paymentBankAccountOwnerController,
                  label: l10n?.accountOwner ?? 'Account Owner',
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _paymentInstructionsController,
                  label: l10n?.paymentInstructions ?? 'Payment Instructions',
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                PrimaryTextField(
                  controller: _paymentReferenceTemplateController,
                  label: l10n?.referenceTemplate ?? 'Reference Template (use {orderId}, {buyerId})',
                ),
              ],
            ],
            const SizedBox(height: 24),
            // Addresses Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n?.addresses ?? 'Addresses',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                FilledButton.icon(
                  onPressed: _addLocation,
                  icon: const Icon(Icons.add, size: 18),
                  label: Text(l10n?.addAddress ?? 'Add Address'),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_locations.isEmpty)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      Icon(
                        Icons.location_off_outlined,
                        size: 48,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        l10n?.noAddressesAdded ?? 'No addresses added',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n?.addYourFirstAddress ??
                            'Add your first address to get started',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              ..._locations.asMap().entries.map((entry) {
                final index = entry.key;
                final loc = entry.value;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    leading: CircleAvatar(
                      backgroundColor:
                          Theme.of(context).colorScheme.primaryContainer,
                      child: Icon(
                        Icons.location_on,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                    ),
                    title: Text(
                      loc.label ?? '${l10n?.address ?? 'Address'} ${index + 1}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        if (loc.address != null && loc.address!.isNotEmpty)
                          Text(loc.address!),
                        Text(
                          [
                            if (loc.city != null && loc.city!.isNotEmpty)
                              loc.city,
                            if (loc.country != null && loc.country!.isNotEmpty)
                              loc.country,
                          ].whereType<String>().join(', '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        if (loc.latitude != null && loc.longitude != null)
                          Text(
                            '${loc.latitude!.toStringAsFixed(6)}, ${loc.longitude!.toStringAsFixed(6)}',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      fontFamily: 'monospace',
                                    ),
                          ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          tooltip: l10n?.editAddress ?? 'Edit address',
                          onPressed: () => _editLocation(index, loc),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: l10n?.removeAddress ?? 'Remove address',
                          color: Theme.of(context).colorScheme.error,
                          onPressed: () => _removeLocation(index),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
            PrimaryButton(
              label: l10n?.saveChanges ?? 'Save changes',
              isLoading: _saving,
              onPressed: _saveProfile,
            ),
          ],
        ),
      ),
    );
  }
}
