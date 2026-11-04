import 'package:dio/dio.dart';
import 'package:greenbasket_app/widgets/common/gb_button.dart';
import 'package:greenbasket_app/widgets/common/gb_app_bar.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import '../../../data/repositories/merchant_repository.dart';

class BulkUploadScreen extends StatefulWidget {
  const BulkUploadScreen({super.key});

  @override
  State<BulkUploadScreen> createState() => _BulkUploadScreenState();
}

class _BulkUploadScreenState extends State<BulkUploadScreen> {
  final _repo = MerchantRepository();
  bool _fileSelected = false;
  String _selectedFileName = '';
  PlatformFile? _pickedFile;
  bool _instructionsExpanded = false;
  bool _isUploading = false;
  bool _isLoadingHistory = true;
  List<Map<String, dynamic>> _recentUploads = [];

  @override
  void initState() {
    super.initState();
    _fetchUploadHistory();
  }

  Future<void> _fetchUploadHistory() async {
    try {
      final history = await _repo.getUploadHistory();
      setState(() {
        _recentUploads = history;
        _isLoadingHistory = false;
      });
    } catch (_) {
      setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _selectFile() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['csv'],
    );
    if (file == null) return; // cancelled
    setState(() {
      _pickedFile = file;
      _fileSelected = true;
      _selectedFileName = file.name;
    });
  }

  Future<void> _downloadTemplate() async {
    try {
      final csv = await _repo.getUploadTemplate();
      await Clipboard.setData(ClipboardData(text: csv));
      GBSnack.success(
        'Template Copied',
        'CSV template copied to clipboard. Paste it into a .csv file and fill it in.',
        position: SnackPosition.BOTTOM,
      );
    } catch (_) {
      GBSnack.plain('Error', 'Could not load the CSV template', position: SnackPosition.BOTTOM);
    }
  }

  Future<void> _uploadFile() async {
    if (!_fileSelected || _pickedFile == null) {
      GBSnack.warning('No File Selected', 'Please select a CSV file to upload', position: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _isUploading = true);
    try {
      final bytes = await _pickedFile!.readAsBytes();
      final result = await _repo.bulkUploadProducts(
        bytes: bytes,
        fileName: _selectedFileName,
      );
      final ok = (result['successCount'] ?? 0) as int;
      final failed = (result['errorCount'] ?? 0) as int;
      final errors = List<Map<String, dynamic>>.from(result['errors'] ?? []);
      setState(() {
        _fileSelected = false;
        _selectedFileName = '';
        _pickedFile = null;
      });
      await _fetchUploadHistory();
      _showUploadResult(ok, failed, errors);
    } on DioException catch (e) {
      final body = e.response?.data;
      GBSnack.error('Upload Failed', (body is Map ? (body['error'] ?? body['message']) : null)?.toString() ??
            'Could not upload file. Please try again.', position: SnackPosition.BOTTOM);
    } catch (_) {
      GBSnack.error('Upload Failed', 'Could not read or upload the file. Please try again.', position: SnackPosition.BOTTOM);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showUploadResult(int ok, int failed, List<Map<String, dynamic>> errors) {
    Get.dialog(AlertDialog(
      title: Text(failed == 0 ? 'Upload complete' : 'Upload finished with errors'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$ok product(s) added, $failed row(s) failed.'),
            if (errors.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...errors.take(10).map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text('Row ${e['row']}: ${e['error']}',
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.error)),
                  )),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Get.back(), child: const Text('OK'))],
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GBAppBar(title: 'Bulk Upload Products', backIcon: Icons.arrow_back_ios_new, showDivider: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Upload area
            Semantics(button: true, child: GestureDetector(
              onTap: _isUploading ? null : _selectFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: _fileSelected
                      ? AppColors.primaryContainer
                      : AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: _fileSelected
                        ? AppColors.primary
                        : AppColors.border,
                    width: 1.5,
                    style: BorderStyle.solid,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _fileSelected
                          ? Icons.check_circle_outline
                          : Icons.upload_file_outlined,
                      size: 52,
                      color: _fileSelected
                          ? AppColors.primary
                          : AppColors.textHint,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      _fileSelected
                          ? 'File Selected'
                          : 'Tap to select CSV file',
                      style: AppTextStyles.titleMedium.copyWith(
                        color: _fileSelected
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    if (_fileSelected)
                      Text(
                        _selectedFileName,
                        style: AppTextStyles.bodySmall
                            .copyWith(color: AppColors.primary),
                        textAlign: TextAlign.center,
                      )
                    else
                      Text(
                        'Supported format: .csv only',
                        style: AppTextStyles.bodySmall,
                        textAlign: TextAlign.center,
                      ),
                    if (_fileSelected) ...[
                      const SizedBox(height: AppSpacing.md),
                      TextButton(
                        onPressed: () =>
                            setState(() {
                              _fileSelected = false;
                              _pickedFile = null;
                            }),
                        child: Text(
                          'Remove file',
                          style: AppTextStyles.bodySmall
                              .copyWith(color: AppColors.error),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            )),
            const SizedBox(height: AppSpacing.md),

            // Download template button
            SizedBox(
              width: double.infinity,
              child: GBButton(label: 'Download CSV Template', onPressed: _downloadTemplate, leadingIcon: Icons.download_outlined, variant: GBButtonVariant.outline),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Instructions accordion
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(AppRadius.md),
                    onTap: () => setState(
                        () => _instructionsExpanded = !_instructionsExpanded),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline,
                              color: AppColors.primary, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text('CSV Format Instructions',
                                style: AppTextStyles.titleMedium),
                          ),
                          Icon(
                            _instructionsExpanded
                                ? Icons.keyboard_arrow_up
                                : Icons.keyboard_arrow_down,
                            color: AppColors.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_instructionsExpanded) ...[
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Required columns (in order):',
                            style: AppTextStyles.bodyMedium
                                .copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ..._buildColumnRows([
                            ['A', 'name', 'Product name (required)'],
                            [
                              'B',
                              'category',
                              'Vegetables / Fruits / Dairy / Grains'
                            ],
                            ['C', 'price', 'Selling price in ₹ (number)'],
                            ['D', 'mrp', 'MRP in ₹ (number)'],
                            ['E', 'stock', 'Initial stock quantity'],
                            ['F', 'unit', 'kg / piece / bunch / litre'],
                            [
                              'G',
                              'description',
                              'Product description (optional)'
                            ],
                            ['H', 'organic', 'true / false'],
                          ]),
                          const SizedBox(height: AppSpacing.md),
                          Container(
                            padding: const EdgeInsets.all(AppSpacing.sm),
                            decoration: BoxDecoration(
                              color: AppColors.warning.withValues(alpha: 0.1),
                              borderRadius:
                                  BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.warning_amber_rounded,
                                    color: AppColors.warning, size: 16),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    'First row must be the header row. Max 500 products per upload.',
                                    style: AppTextStyles.bodySmall,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // Recent uploads
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Uploads', style: AppTextStyles.titleLarge),
                if (_isLoadingHistory)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            if (!_isLoadingHistory && _recentUploads.isEmpty)
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.border),
                ),
                child: Center(
                  child: Text('No upload history yet.',
                      style: AppTextStyles.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                ),
              )
            else
              ..._recentUploads
                  .map((upload) => _buildUploadHistoryCard(upload)),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
                color: AppColors.shadow,
                blurRadius: 8,
                offset: Offset(0, -2))
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isUploading ? null : _uploadFile,
              icon: _isUploading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.cloud_upload_outlined),
              label: Text(_isUploading ? 'Uploading...' : 'Upload Products'),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildColumnRows(List<List<String>> rows) {
    return rows.map((row) {
      return Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: AppColors.primaryContainer,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Center(
                child: Text(row[0],
                    style: AppTextStyles.labelSmall
                        .copyWith(color: AppColors.primary)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            SizedBox(
              width: 80,
              child: Text(row[1],
                  style: AppTextStyles.bodySmall
                      .copyWith(fontWeight: FontWeight.w600)),
            ),
            Expanded(
              child: Text(row[2], style: AppTextStyles.bodySmall),
            ),
          ],
        ),
      );
    }).toList();
  }

  Widget _buildUploadHistoryCard(Map<String, dynamic> upload) {
    final statusRaw =
        (upload['status'] ?? upload['uploadStatus'] ?? '').toString();
    final isSuccess = statusRaw.toLowerCase() == 'success' ||
        statusRaw.toLowerCase() == 'completed' ||
        statusRaw.toLowerCase() == 'partial';
    final filename =
        upload['filename'] ?? upload['fileName'] ?? 'upload.csv';
    final rawDate = (upload['date'] ?? upload['createdAt'] ?? '').toString();
    final parsed = DateTime.tryParse(rawDate)?.toLocal();
    final date = parsed == null
        ? (rawDate.isEmpty ? '-' : rawDate)
        : '${parsed.day.toString().padLeft(2, '0')}/${parsed.month.toString().padLeft(2, '0')}/${parsed.year}';
    final count = upload['count'] ?? upload['productCount'] ?? upload['successCount'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSuccess
                  ? AppColors.success.withValues(alpha: 0.1)
                  : AppColors.error.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(
              isSuccess
                  ? Icons.check_circle_outline
                  : Icons.error_outline,
              color: isSuccess ? AppColors.success : AppColors.error,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  filename.toString(),
                  style: AppTextStyles.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(date.toString(), style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm, vertical: 2),
                decoration: BoxDecoration(
                  color: isSuccess
                      ? AppColors.success.withValues(alpha: 0.1)
                      : AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.full),
                ),
                child: Text(
                  isSuccess ? 'Success' : 'Failed',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: isSuccess ? AppColors.success : AppColors.error,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                isSuccess ? '$count products' : 'Upload failed',
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
