import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/localization/app_localizations.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/permissions/permissions.dart';
import '../../../../core/localization/currency_controller.dart';
import '../../../../core/services/currency_service.dart';
import '../../../../shared/utils/snackbar_utils.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../auth/presentation/screens/login_screen.dart';
import '../../data/models/deal_models.dart';
import '../../data/repositories/deal_repository.dart';

class DealOrderForm extends ConsumerStatefulWidget {
  const DealOrderForm({super.key, required this.deal, this.onOrderPlaced});

  final Deal deal;
  final VoidCallback? onOrderPlaced; // Callback to notify parent

  @override
  ConsumerState<DealOrderForm> createState() => _DealOrderFormState();
}

class _DealOrderFormState extends ConsumerState<DealOrderForm> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _notesController = TextEditingController();
  bool _isSubmitting = false;
  /// Synchronous guard so two taps cannot start two requests before the first frame rebuilds.
  bool _placementLocked = false;
  double? _sliderValue;

  @override
  void initState() {
    super.initState();
    _quantityController.text = widget.deal.minOrderQuantity.toString();
    _sliderValue = widget.deal.minOrderQuantity.toDouble();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  int? get _quantity {
    final text = _quantityController.text.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text);
  }

  double get _subtotal {
    final qty = _quantity ?? 0;
    return qty * widget.deal.dealPrice;
  }

  double get _shippingCost {
    final qty = _quantity ?? widget.deal.minOrderQuantity;
    return widget.deal.calculateShippingCost(qty);
  }

  double get _totalAmount {
    return _subtotal + _shippingCost;
  }

  Future<void> _submit() async {
    debugPrint('Submit button pressed, validating form');
    if (!_formKey.currentState!.validate()) return;
    debugPrint('Form validated');

    final authState = ref.read(authControllerProvider);
    final session = authState.valueOrNull;
    debugPrint('Session: ${session?.user}');
    if (session == null) {
      debugPrint('Showing login error snackbar');
      if (mounted) {
        final l10n = AppLocalizations.of(context);
        SnackbarUtils.showError(
          context,
          l10n?.pleaseLoginToPlaceOrder ?? 'Please login to place an order',
          action: SnackBarAction(
            label: l10n?.login ?? 'Login',
            onPressed: () {
              context.go(LoginScreen.routePath);
            },
          ),
        );
      }
      return;
    }

    final canPlace = Permissions.canPlaceOrderOnDeal(session.user.role);

    if (!canPlace) {
      if (mounted) {
        SnackbarUtils.showError(
          context,
          AppLocalizations.of(context)?.canOnlyViewDeals ??
              'You are not allowed to place orders on this deal.',
        );
      }
      return;
    }

    if (_placementLocked) return;
    _placementLocked = true;
    setState(() => _isSubmitting = true);

    try {
      final repo = ref.read(dealRepositoryProvider);
      await repo.placeOrder(
        dealId: widget.deal.id,
        quantity: _quantity ?? widget.deal.minOrderQuantity,
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      if (!mounted) return;

      SnackbarUtils.showSuccess(
        context,
        AppLocalizations.of(context)?.orderPlacedSuccessfully ??
            'Order placed successfully!',
        duration: const Duration(seconds: 4),
      );

      // Clear form immediately; refresh deal/providers after this frame so UI feels instant.
      _notesController.clear();
      _quantityController.text = widget.deal.minOrderQuantity.toString();
      _sliderValue = widget.deal.minOrderQuantity.toDouble();

      Future.microtask(() {
        if (!mounted) return;
        widget.onOrderPlaced?.call();
      });
    } catch (e) {
      debugPrint('Error: $e');
      if (mounted) {
        final message = e is DioException
            ? mapDioException(e).message
            : (AppLocalizations.of(context)?.failedToPlaceOrder ??
                'Failed to place order');
        SnackbarUtils.showError(context, message);
      }
    } finally {
      _placementLocked = false;
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(
        currencyControllerProvider); // Rebuild when display currency changes
    final theme = Theme.of(context);
    final deal = widget.deal;
    final l10n = AppLocalizations.of(context);

    // Fix slider values to prevent accessibility crash
    final minQty = deal.minOrderQuantity.toDouble();
    final maxQty = deal.targetQuantity.toDouble();

    // Ensure max is always greater than min
    final sliderMin = minQty;
    final sliderMax = maxQty > minQty ? maxQty : minQty + 100;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)?.placeOrder ?? 'Place Order',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.quantity ?? 'Quantity',
                  hintText: AppLocalizations.of(context)?.enterQuantity ??
                      'Enter quantity',
                  prefixIcon: const Icon(Icons.numbers),
                  suffixText: 'units',
                  helperText:
                      'Min: ${deal.minOrderQuantity}, Max: ${deal.targetQuantity}',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ],
                validator: (value) {
                  final l10n = AppLocalizations.of(context);
                  if (value == null || value.trim().isEmpty) {
                    return l10n?.pleaseEnterQuantity ?? 'Please enter quantity';
                  }
                  final qty = int.tryParse(value.trim());
                  if (qty == null) {
                    return l10n?.invalidQuantity ?? 'Invalid quantity';
                  }
                  if (qty < deal.minOrderQuantity) {
                    return '${l10n?.minimumOrderIs ?? 'Minimum order is'} ${deal.minOrderQuantity}';
                  }
                  if (qty > deal.targetQuantity) {
                    return '${l10n?.maximumOrderIs ?? 'Maximum order is'} ${deal.targetQuantity}';
                  }
                  return null;
                },
                onChanged: (_) => setState(() {
                  debugPrint("Input Value Changed");
                  _sliderValue = _quantity?.toDouble();
                }),
              ),
              const SizedBox(height: 12),
              // Quantity slider - Only show if there's a meaningful range
              if (sliderMax > sliderMin) ...[
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: Theme.of(context).colorScheme.primary,
                    inactiveTrackColor:
                        Theme.of(context).colorScheme.primaryContainer,
                    thumbColor: Theme.of(context).colorScheme.primary,
                    overlayColor: const Color(0x330C9FD0),
                  ),
                  child: Slider(
                    min: sliderMin,
                    max: sliderMax,
                    divisions: (sliderMax - sliderMin).clamp(1, 100).toInt(),
                    value:
                        (_sliderValue ?? sliderMin).clamp(sliderMin, sliderMax),
                    label:
                        '${(_sliderValue ?? sliderMin).round()} ${AppLocalizations.of(context)?.units ?? 'units'}',
                    onChanged: (value) {
                      debugPrint('Slider value: $value');
                      setState(() {
                        _sliderValue = value;
                        _quantityController.text = value.round().toString();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 8),
              ],
              if (sliderMax > sliderMin)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${AppLocalizations.of(context)?.minQuantityLabel ?? 'Min'}: ${deal.minOrderQuantity}',
                      style: theme.textTheme.bodySmall,
                    ),
                    Text(
                      '${AppLocalizations.of(context)?.selectedLabel ?? 'Selected'}: ${_quantity ?? deal.minOrderQuantity}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      '${AppLocalizations.of(context)?.maxQuantityLabel ?? 'Max'}: ${deal.targetQuantity}',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: InputDecoration(
                  labelText: AppLocalizations.of(context)?.notesOptional ??
                      'Notes (Optional)',
                  hintText: AppLocalizations.of(context)?.addSpecialInstructions ??
                      'Add any special instructions...',
                  prefixIcon: Icon(Icons.note_outlined),
                ),
                maxLines: 3,
                textInputAction: TextInputAction.done,
              ),
              const SizedBox(height: 16),
              // Order Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.subtotal ?? 'Subtotal',
                          style: theme.textTheme.bodyMedium,
                        ),
                        Text(
                          '${context.formatPriceEurOnly(_subtotal)} '
                          '(${context.formatPriceUsdFromEur(_subtotal)})',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                    if (_shippingCost > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 16,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)?.shipping ??
                                    'Shipping',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Text(
                            '${context.formatPriceEurOnly(_shippingCost)} '
                            '(${context.formatPriceUsdFromEur(_shippingCost)})',
                            style: theme.textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ] else if (widget.deal.shippingFreeThreshold != null &&
                        (_quantity ?? widget.deal.minOrderQuantity) >=
                            widget.deal.shippingFreeThreshold!) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.local_shipping,
                                size: 16,
                                color: Colors.green,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                AppLocalizations.of(context)?.shipping ??
                                    'Shipping',
                                style: theme.textTheme.bodyMedium,
                              ),
                            ],
                          ),
                          Text(
                            'FREE',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const Divider(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          AppLocalizations.of(context)?.totalAmount ??
                              'Total Amount',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${context.formatPriceEurOnly(_totalAmount)}\n(${context.formatPriceUsdFromEur(_totalAmount)})',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  AppLocalizations.of(context)?.paymentAfterOrderConfirmed ??
                      'Payment will be requested after your order is confirmed (e.g. bank transfer).',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_isSubmitting || _placementLocked)
                      ? null
                      : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(l10n?.placeOrder ?? 'Place Order'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
