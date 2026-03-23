import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/localization/app_localizations.dart';
import '../../../../core/providers/places_service_provider.dart';
import '../../../../core/services/places_service.dart';
import '../../../../core/utils/snackbar.dart';

typedef StructuredAddressCallback = void Function(
  String? city,
  String? country,
);

/// Google Places autocomplete for registration: debounced queries, session
/// tokens, structured city/country for the API payload.
class RegisterPlacesAddressField extends ConsumerStatefulWidget {
  const RegisterPlacesAddressField({
    super.key,
    required this.controller,
    required this.onStructuredChanged,
    required this.enabled,
    required this.label,
    required this.hintText,
    required this.helperText,
  });

  final TextEditingController controller;
  final StructuredAddressCallback onStructuredChanged;
  final bool enabled;
  final String label;
  final String hintText;
  final String helperText;

  @override
  ConsumerState<RegisterPlacesAddressField> createState() =>
      _RegisterPlacesAddressFieldState();
}

class _RegisterPlacesAddressFieldState
    extends ConsumerState<RegisterPlacesAddressField> {
  final FocusNode _focusNode = FocusNode();
  final Uuid _uuid = Uuid();
  late String _sessionToken;
  int _debounceSeq = 0;
  bool _applyingFromPlaces = false;
  String? _placesInlineHint;
  bool _warnedPlacesConfig = false;

  @override
  void initState() {
    super.initState();
    _sessionToken = _uuid.v4();
    widget.controller.addListener(_onManualTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onManualTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  void _onManualTextChanged() {
    if (_applyingFromPlaces) return;
    widget.onStructuredChanged(null, null);
    setState(() {});
  }

  Future<Iterable<PlacePrediction>> _optionsBuilder(
    TextEditingValue value,
  ) async {
    final text = value.text.trim();
    if (text.length < 2) {
      if (mounted) {
        setState(() => _placesInlineHint = null);
      }
      return const [];
    }
    _debounceSeq++;
    final seq = _debounceSeq;
    await Future<void>.delayed(PlacesService.debounceDelay);
    if (!mounted || seq != _debounceSeq) {
      return const [];
    }
    final service = ref.read(placesServiceProvider);
    if (!service.isConfigured) {
      if (mounted) {
        setState(() => _placesInlineHint = null);
        if (!_warnedPlacesConfig) {
          _warnedPlacesConfig = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final l10n = AppLocalizations.of(context);
              showSnackBar(
                context,
                l10n?.placesAddressSearchConfigError ??
                    'Address search is unavailable. Check your network and that '
                        'the app points to the correct API server (API_BASE_URL).',
                isError: true,
              );
            }
          });
        }
      }
      return const [];
    }

    final outcome = await service.fetchAutocompleteOutcome(
      input: text,
      sessionToken: _sessionToken,
    );
    if (!mounted || seq != _debounceSeq) {
      return outcome.predictions;
    }

    final l10n = AppLocalizations.of(context);
    setState(() {
      _placesInlineHint = outcome.showNoResultsHint
          ? (l10n?.placesNoAddressResults ??
              'No addresses found. Try a different search.')
          : null;
    });

    if (outcome.showApiErrorSnack) {
      final msg = outcome.googleErrorMessage ??
          outcome.googleStatus ??
          (l10n?.placesAddressSearchRequestFailed ??
              'Address search failed. Check your connection or try again later.');
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          showSnackBar(context, msg, isError: true);
        }
      });
    }

    return outcome.predictions;
  }

  Future<void> _onSelected(PlacePrediction prediction) async {
    if (mounted) {
      setState(() => _placesInlineHint = null);
    }
    final service = ref.read(placesServiceProvider);
    if (!service.isConfigured) {
      _applyText(prediction.description);
      return;
    }

    final details = await service.fetchPlaceDetails(
      placeId: prediction.placeId,
      sessionToken: _sessionToken,
    );

    _sessionToken = _uuid.v4();

    if (!mounted) return;

    if (details == null) {
      final l10n = AppLocalizations.of(context);
      showSnackBar(
        context,
        l10n?.placesLookupFailed ??
            'Address lookup unavailable. You can type your address manually.',
        isError: false,
      );
      _applyText(prediction.description);
      widget.onStructuredChanged(null, null);
      return;
    }

    _applyText(details.formattedAddress);
    widget.onStructuredChanged(details.city, details.country);
  }

  void _applyText(String text) {
    _applyingFromPlaces = true;
    widget.controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
    _applyingFromPlaces = false;
    setState(() {});
  }

  void _clear() {
    widget.controller.clear();
    _sessionToken = _uuid.v4();
    widget.onStructuredChanged(null, null);
    setState(() {
      _placesInlineHint = null;
    });
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final screenW = MediaQuery.sizeOf(context).width;
    final screenH = MediaQuery.sizeOf(context).height;
    final optionsWidth = (screenW - 48).clamp(200.0, screenW);
    final optionsMaxH = screenH * 0.4;
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RawAutocomplete<PlacePrediction>(
          textEditingController: widget.controller,
          focusNode: _focusNode,
          displayStringForOption: (p) => p.description,
          optionsBuilder: _optionsBuilder,
          onSelected: _onSelected,
          optionsViewOpenDirection: OptionsViewOpenDirection.down,
          optionsViewBuilder: (context, onSelected, options) {
            final list = options.toList();
            if (list.isEmpty) {
              return const SizedBox.shrink();
            }
            return Padding(
              padding: EdgeInsets.only(bottom: bottomInset + 8),
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  width: optionsWidth,
                  child: Material(
                    color: scheme.surface,
                    elevation: 24,
                    shadowColor: Colors.black54,
                    surfaceTintColor: scheme.surfaceTint,
                    borderRadius: BorderRadius.circular(8),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(maxHeight: optionsMaxH),
                      child: ListView.builder(
                        padding: EdgeInsets.zero,
                        shrinkWrap: true,
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          return InkWell(
                            onTap: () => onSelected(item),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              child: Text(
                                item.description,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
              enabled: widget.enabled,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              keyboardType: TextInputType.streetAddress,
              onFieldSubmitted: (_) => onSubmitted(),
              decoration: InputDecoration(
                labelText: widget.label,
                hintText: widget.hintText,
                helperText: widget.helperText,
                alignLabelWithHint: true,
                suffixIcon: widget.controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: widget.enabled ? _clear : null,
                        tooltip: 'Clear',
                      ),
              ),
            );
          },
        ),
        if (_placesInlineHint != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _placesInlineHint!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ),
      ],
    );
  }
}
