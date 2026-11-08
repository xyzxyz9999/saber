import 'package:material_ui/material_ui.dart';
import 'package:saber/i18n/strings.g.dart';

enum ExportDestination { files, share, gallery }

class ExportDestinationDialog extends StatelessWidget {
  const new({super.key, required this.isImage});

  final bool isImage;

  static Future<ExportDestination?> show(
    BuildContext context, {
    required bool isImage,
  }) async {
    final navigator = Navigator.of(context, rootNavigator: true);
    // Image options start exporting and immediately pop their own dialog.
    // Let that happen before pushing this route, and don't retain their context.
    await Future<void>.value();
    if (!navigator.mounted) return null;
    return showDialog<ExportDestination>(
      context: navigator.context,
      builder: (context) => ExportDestinationDialog(isImage: isImage),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(t.common.exportDestination.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.save_alt),
            title: Text(t.common.exportDestination.saveToFiles),
            onTap: () => Navigator.of(context).pop(ExportDestination.files),
          ),
          if (isImage)
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: Text(t.common.exportDestination.saveToGallery),
              onTap: () => Navigator.of(context).pop(ExportDestination.gallery),
            )
          else
            ListTile(
              leading: const Icon(Icons.share),
              title: Text(t.common.exportDestination.share),
              onTap: () => Navigator.of(context).pop(ExportDestination.share),
            ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.cancel),
        ),
      ],
    );
  }
}
