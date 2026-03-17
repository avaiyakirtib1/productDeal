import 'dart:convert';
import 'dart:io';
import 'package:csv/csv.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';

import '../../../auth/data/models/auth_models.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/permissions/permissions.dart';
import '../../data/repositories/manager_repository.dart';
import '../../../dashboard/data/repositories/dashboard_repository.dart';
import '../screens/manager_products_screen.dart';
import '../screens/select_wholesaler_screen.dart';
import '../../../../core/networking/api_client.dart';
import '../../../../core/localization/app_localizations.dart';

// Conditional import for web file download
import 'file_download_stub.dart' if (dart.library.html) 'file_download_web.dart'
    as file_download;

/// Provider for categories with slugs for CSV import
final categoriesWithSlugsProvider =
    FutureProvider.autoDispose<List<Map<String, String>>>((ref) async {
  try {
    final repo = ref.watch(dashboardRepositoryProvider);
    final categories = await repo.fetchCategories();
    return categories
        .map((cat) => {
              'id': cat.id,
              'name': cat.name,
              'slug': cat.slug,
            })
        .toList();
  } catch (e) {
    debugPrint('categoriesWithSlugsProvider error: $e');
    return [];
  }
});

class CsvImportModal extends ConsumerStatefulWidget {
  final String currentUserId;
  const CsvImportModal({super.key, required this.currentUserId});

  @override
  ConsumerState<CsvImportModal> createState() => _CsvImportModalState();
}

class _CsvImportModalState extends ConsumerState<CsvImportModal> {
  FilePickerResult? _fileResult;
  List<List<dynamic>>? _parsedCsv;
  bool _isImporting = false;
  String? _importError;
  Map<String, dynamic>? _importSummary;
  String? _selectedWholesalerId; // For admin to select wholesaler
  String? _selectedWholesalerName; // Store name for display

  @override
  void initState() {
    super.initState();
    debugPrint('Current User ID: ${widget.currentUserId}');
    if (widget.currentUserId.isNotEmpty) {
      _selectedWholesalerId = widget.currentUserId;
      _selectedWholesalerName = 'Current User'; // Fallback: localized in build
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final authState = ref.watch(authControllerProvider);
    final isAdmin = authState.maybeWhen(
      data: (session) =>
          Permissions.isAdminOrSubAdmin(session?.user.role ?? UserRole.kiosk),
      orElse: () => false,
    );

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.upload_file, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n.importProductsFromCsv,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Download Template Button
                  _buildDownloadTemplateButton(context, isAdmin),

                  const SizedBox(height: 24),

                  // File Picker
                  _buildFilePicker(context),

                  // Wholesaler selection (for admin)
                  if (isAdmin) ...[
                    const SizedBox(height: 16),
                    _buildWholesalerSelector(context),
                  ],

                  if (_parsedCsv != null) ...[
                    const SizedBox(height: 16),
                    _buildCsvPreview(context),
                  ],

                  if (_importError != null) ...[
                    const SizedBox(height: 16),
                    _buildErrorDisplay(context),
                  ],

                  if (_importSummary != null) ...[
                    const SizedBox(height: 16),
                    _buildImportSummary(context),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).dividerColor,
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: _isImporting ? null : () => Navigator.pop(context),
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isImporting || _parsedCsv == null
                      ? null
                      : () => _handleImport(context, isAdmin),
                  icon: _isImporting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload),
                  label:
                      Text(_isImporting ? l10n.importing : l10n.importProducts),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDownloadTemplateButton(
      BuildContext context, bool isAdmin) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: InkWell(
        onTap: () => _downloadTemplate(context, isAdmin),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.download,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.downloadCsvTemplate,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n.getSampleCsvWithColumns,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilePicker(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.selectCsvFile,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _isImporting ? null : () => _pickFile(context),
              icon: const Icon(Icons.folder_open),
              label: Text(_fileResult?.files.single.name ?? l10n.chooseFile),
            ),
            if (_fileResult != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.fileLabel.replaceAll('{name}', _fileResult!.files.single.name),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWholesalerSelector(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = _selectedWholesalerId == widget.currentUserId &&
            widget.currentUserId.isNotEmpty
        ? l10n.currentUserYou
        : (_selectedWholesalerName ?? '');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextFormField(
              readOnly: true,
              decoration: InputDecoration(
                labelText: l10n.wholesalerRequired,
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.arrow_drop_down),
                helperText: l10n.tapToSelectWholesalerForImport,
              ),
              controller: TextEditingController(text: displayName),
              onTap: () async {
                final l10nW = AppLocalizations.of(context)!;
                final selectedId = await context.push<String>(
                  SelectWholesalerScreen.routePath,
                  extra: {
                    'selectedWholesalerId': _selectedWholesalerId,
                  },
                );
                if (selectedId != null && mounted) {
                  // Fetch wholesaler name from API
                  try {
                    final dio = ref.read(dioProvider);
                    final response = await dio.get<Map<String, dynamic>>(
                      '/admin/users/$selectedId',
                    );
                    final user =
                        response.data?['data'] as Map<String, dynamic>?;
                    final name =
                        user?['businessName'] ?? user?['fullName'] ?? l10nW.unknown;
                    setState(() {
                      _selectedWholesalerId = selectedId;
                      _selectedWholesalerName = name.toString();
                    });
                  } catch (e) {
                    // If fetch fails, just use the ID (l10nW captured before await)
                    setState(() {
                      _selectedWholesalerId = selectedId;
                      _selectedWholesalerName =
                          l10nW.wholesalerLabel.replaceAll('{id}', selectedId);
                    });
                  }
                }
              },
              validator: (value) {
                if (_selectedWholesalerId == null) {
                  return l10n.pleaseSelectWholesaler;
                }
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCsvPreview(BuildContext context) {
    if (_parsedCsv == null || _parsedCsv!.isEmpty) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    final headerRow = _parsedCsv!.first;
    final dataRows = _parsedCsv!.skip(1).take(5).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.csvPreviewRows
                        .replaceAll('{n}', '${_parsedCsv!.length - 1}'),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    l10n.multipleRowsSameProductVariant,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 11,
                        ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: headerRow.map((header) {
                  return DataColumn(
                    label: Text(
                      header.toString(),
                      style: const TextStyle(fontSize: 12),
                    ),
                  );
                }).toList(),
                rows: dataRows.map((row) {
                  return DataRow(
                    cells: row.map((cell) {
                      return DataCell(
                        Text(
                          cell.toString(),
                          style: const TextStyle(fontSize: 11),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      );
                    }).toList(),
                  );
                }).toList(),
              ),
            ),
            if (_parsedCsv!.length > 6)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... and ${_parsedCsv!.length - 6} more rows',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorDisplay(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Theme.of(context).colorScheme.onErrorContainer,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                _importError!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImportSummary(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final summary = _importSummary!;
    final inserted = summary['inserted'] as int? ?? 0;
    final updated = summary['updated'] as int? ?? 0;
    final skipped = summary['skipped'] as int? ?? 0;
    final errors = summary['errors'] as List<dynamic>? ?? [];

    return Card(
      color: Theme.of(context).colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.check_circle,
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
                const SizedBox(width: 12),
                Text(
                  l10n.importComplete,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildSummaryRow(l10n.inserted, inserted, Colors.green),
            _buildSummaryRow(l10n.updated, updated, Colors.blue),
            _buildSummaryRow(l10n.skipped, skipped, Colors.orange),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ExpansionTile(
                title: Text(l10n.errorsCount.replaceAll('{n}', '${errors.length}')),
                children: [
                  ...errors.take(10).map((error) => Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 4,
                        ),
                        child: Text(
                          error.toString(),
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                  if (errors.length > 10)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        l10n.andMoreErrors.replaceAll('{n}', '${errors.length - 10}'),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickFile(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['csv'],
        allowMultiple: false,
      );

      if (result != null) {
        setState(() {
          _fileResult = result;
          _importError = null;
          _importSummary = null;
        });

        // Parse CSV - handle web and mobile differently
        if (kIsWeb) {
          // Web: Use bytes directly
          if (result.files.single.bytes != null) {
            await _parseCsvFromBytes(l10n, result.files.single.bytes!);
          } else {
            setState(() {
              _importError = l10n.failedToReadFileBytes;
            });
          }
        } else {
          // Mobile/Desktop: Use file path
          if (result.files.single.path != null) {
            await _parseCsvFromPath(l10n, result.files.single.path!);
          } else {
            setState(() {
              _importError = l10n.failedToGetFilePath;
            });
          }
        }
      }
    } catch (e) {
      setState(() {
        _importError = l10n.errorPickingFile.replaceAll('{error}', e.toString());
      });
    }
  }

  Future<void> _parseCsvFromPath(AppLocalizations l10n, String filePath) async {
    try {
      final file = File(filePath);
      final content = await file.readAsString();
      final csv = const CsvToListConverter().convert(content);

      if (csv.isEmpty) {
        setState(() {
          _importError = l10n.csvFileEmpty;
          _parsedCsv = null;
        });
        return;
      }

      setState(() {
        _parsedCsv = csv;
        _importError = null;
      });
    } catch (e) {
      setState(() {
        _importError = l10n.errorParsingCsv.replaceAll('{error}', e.toString());
        _parsedCsv = null;
      });
    }
  }

  Future<void> _parseCsvFromBytes(AppLocalizations l10n, Uint8List bytes) async {
    try {
      final content = utf8.decode(bytes);
      final csv = const CsvToListConverter().convert(content);

      if (csv.isEmpty) {
        setState(() {
          _importError = l10n.csvFileEmpty;
          _parsedCsv = null;
        });
        return;
      }

      setState(() {
        _parsedCsv = csv;
        _importError = null;
      });
    } catch (e) {
      setState(() {
        _importError = l10n.errorParsingCsv.replaceAll('{error}', e.toString());
        _parsedCsv = null;
      });
    }
  }

  Future<void> _downloadTemplate(BuildContext context, bool isAdmin) async {
    final l10n = AppLocalizations.of(context)!;
    try {
      final categoriesAsync = ref.read(categoriesWithSlugsProvider);
      final List<Map<String, String>> categories = await categoriesAsync.when(
        data: (data) => Future.value(data),
        loading: () async {
          final repo = ref.read(dashboardRepositoryProvider);
          final cats = await repo.fetchCategories();
          return cats
              .map((cat) => {
                    'id': cat.id,
                    'name': cat.name,
                    'slug': cat.slug,
                  })
              .toList();
        },
        error: (_, __) => Future.value(<Map<String, String>>[]),
      );

      // Build CSV template
      final headers = [
        'name',
        'description',
        'category_slug',
        if (isAdmin) 'owner_email',
        'sku',
        'price',
        'cost_price',
        'stock',
        'unit',
        'image_url',
        if (isAdmin) 'status',
        if (isAdmin) 'is_featured',
        'variant_sku',
        'variant_price',
        'variant_cost_price',
        'variant_stock',
        'variant_attributes',
      ];

      // Sample data rows
      // NOTE: For products with multiple variants, use multiple rows with the same product name
      // Each row represents one variant. The backend will group variants by product name/title.
      final sampleRows = [
        // Product 1 - Variant 1 (Red, Large)
        [
          'T-Shirt Classic',
          'Comfortable cotton t-shirt',
          categories.isNotEmpty ? categories.first['slug'] : 'electronics',
          if (isAdmin) 'wholesaler@example.com',
          'TSHIRT-001', // Product SKU (optional)
          '29.99', // Base price (used if no variant_price)
          '15.00', // Base cost price
          '0', // Base stock (variants have their own stock)
          'unit',
          'https://example.com/image.jpg',
          if (isAdmin) 'pending',
          if (isAdmin) 'false',
          'TSHIRT-001-RED-L', // Variant SKU
          '29.99', // Variant price
          '15.00', // Variant cost price
          '50', // Variant stock
          '{"Size":"L","Color":"Red"}', // Variant attributes (JSON format)
        ],
        // Product 1 - Variant 2 (Red, Medium) - Same product name, different variant
        [
          'T-Shirt Classic', // Same product name = same product
          'Comfortable cotton t-shirt',
          categories.isNotEmpty ? categories.first['slug'] : 'electronics',
          if (isAdmin) 'wholesaler@example.com',
          'TSHIRT-001', // Same product SKU
          '29.99',
          '15.00',
          '0',
          'unit',
          'https://example.com/image.jpg',
          if (isAdmin) 'pending',
          if (isAdmin) 'false',
          'TSHIRT-001-RED-M', // Different variant SKU
          '29.99',
          '15.00',
          '30', // Different stock
          '{"Size":"M","Color":"Red"}', // Different attributes
        ],
        // Product 1 - Variant 3 (Blue, Large) - Another variant of the same product
        [
          'T-Shirt Classic', // Same product name
          'Comfortable cotton t-shirt',
          categories.isNotEmpty ? categories.first['slug'] : 'electronics',
          if (isAdmin) 'wholesaler@example.com',
          'TSHIRT-001',
          '29.99',
          '15.00',
          '0',
          'unit',
          'https://example.com/image.jpg',
          if (isAdmin) 'pending',
          if (isAdmin) 'false',
          'TSHIRT-001-BLUE-L', // Different variant
          '29.99',
          '15.00',
          '25',
          '{"Size":"L","Color":"Blue"}',
        ],
        // Product 2 - Simple product (no variants, uses product-level price/stock)
        [
          'Simple Product',
          'A product without variants',
          categories.isNotEmpty ? categories.first['slug'] : 'electronics',
          if (isAdmin) 'wholesaler@example.com',
          'SIMPLE-001',
          '49.99', // Product price (required for simple products)
          '25.00', // Product cost price
          '100', // Product stock (required for simple products)
          'unit',
          '',
          if (isAdmin) 'pending',
          if (isAdmin) 'false',
          '', // No variant columns = simple product
          '',
          '',
          '',
          '',
        ],
      ];

      // Convert to CSV
      final csv = const ListToCsvConverter().convert([headers, ...sampleRows]);
      final csvBytes = utf8.encode(csv);
      final csvData = Uint8List.fromList(csvBytes);

      // Platform-specific file saving
      bool success = false;
      String? errorMessage;

      try {
        if (kIsWeb) {
          // Web: Use browser download via dart:html
          success = await file_download.downloadFileWeb(
              csvData, 'product_import_template.csv');
        } else {
          // Mobile and Desktop: Use FilePicker saveFile
          final result = await FilePicker.platform.saveFile(
            fileName: 'product_import_template.csv',
            bytes: csvData,
            type: FileType.custom,
            allowedExtensions: ['csv'],
          );
          success = result != null;
        }
      } catch (e) {
        errorMessage = e.toString();
        success = false;
        debugPrint('Error saving template: $e');
      }

      if (context.mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.templateSavedSuccessfully),
              backgroundColor: Colors.green,
            ),
          );
        } else if (errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${l10n.error}: $errorMessage'),
              backgroundColor: Colors.red,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(l10n.templateDownloadCancelled),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.errorGeneratingTemplate.replaceAll('{error}', e.toString())),
          ),
        );
      }
    }
  }

  Future<void> _handleImport(BuildContext context, bool isAdmin) async {
    if (_parsedCsv == null || _parsedCsv!.isEmpty) {
      setState(() {
        _importError = 'No CSV data to import';
      });
      return;
    }

    setState(() {
      _isImporting = true;
      _importError = null;
      _importSummary = null;
    });

    try {
      final repo = ref.read(managerRepositoryProvider);
      final authState = ref.read(authControllerProvider);
      final isAdmin = authState.maybeWhen(
        data: (session) =>
            Permissions.isAdminOrSubAdmin(session?.user.role ?? UserRole.kiosk),
        orElse: () => false,
      );

      // For admin, use selected wholesalerId; for wholesaler, use currentUserId
      final wholesalerId = isAdmin
          ? _selectedWholesalerId
          : authState.maybeWhen(
              data: (session) => session?.user.id,
              orElse: () => null,
            );

      if (isAdmin && wholesalerId == null) {
        setState(() {
          _isImporting = false;
          _importError = 'Please select a wholesaler';
        });
        return;
      }

      final summary = await repo.bulkImportProducts(_parsedCsv!,
          wholesalerId: wholesalerId);

      setState(() {
        _isImporting = false;
        _importSummary = summary;
      });

      // Refresh products list
      ref.read(managerProductsProvider.notifier).loadProducts(refresh: true);
    } catch (e) {
      setState(() {
        _isImporting = false;
        _importError = 'Import failed: $e';
      });
    }
  }
}
