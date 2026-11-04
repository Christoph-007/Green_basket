import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:greenbasket_app/config/theme.dart';
import 'package:greenbasket_app/data/repositories/admin_repository.dart';
import 'package:greenbasket_app/widgets/common/gb_snack.dart';

/// Small "Export CSV" action for the admin lists.
///
/// Fetches the CSV from the server using the filters the admin is looking
/// at, then copies it to the clipboard so it can be pasted into a
/// spreadsheet. [params] is read when tapped, so it always reflects the
/// current filters.
class ExportCsvButton extends StatefulWidget {
  final String path;
  final Map<String, dynamic> Function()? params;
  final String noun;

  const ExportCsvButton({
    super.key,
    required this.path,
    required this.noun,
    this.params,
  });

  @override
  State<ExportCsvButton> createState() => _ExportCsvButtonState();
}

class _ExportCsvButtonState extends State<ExportCsvButton> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      var csv = await AdminRepository().exportCsv(widget.path, params: widget.params?.call());
      if (csv.startsWith('\uFEFF')) csv = csv.substring(1);
      // First line is the header; empty text means nothing came back.
      final rows = csv.trim().isEmpty ? 0 : csv.trim().split('\n').length - 1;
      if (rows <= 0) {
        GBSnack.info('Nothing to export', 'No ${widget.noun} match the current filters.');
        return;
      }
      await Clipboard.setData(ClipboardData(text: csv));
      GBSnack.success('CSV copied', '$rows ${widget.noun} copied. Paste into a spreadsheet.');
    } catch (e) {
      GBSnack.fromError(e, title: "Couldn't export ${widget.noun}");
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      onPressed: _busy ? null : _export,
      icon: _busy
          ? const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.file_download_outlined, size: 18),
      label: const Text('Export CSV'),
      style: TextButton.styleFrom(foregroundColor: AppColors.primaryText),
    );
  }
}
