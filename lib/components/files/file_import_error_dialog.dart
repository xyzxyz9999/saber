import 'package:cupertino_ui/cupertino_ui.dart';
import 'package:material_ui/material_ui.dart';
import 'package:saber/components/theming/adaptive_alert_dialog.dart';
import 'package:saber/i18n/strings.g.dart';

enum FileImportKind { images, pdf }

class FileImportErrorDialog extends StatelessWidget {
  const new({super.key, required this.error, required this.kind});

  final Object error;
  final FileImportKind kind;

  static Future<void> show(
    BuildContext context, {
    required Object error,
    required FileImportKind kind,
  }) => showAdaptiveDialog<void>(
    context: context,
    builder: (context) => FileImportErrorDialog(error: error, kind: kind),
  );

  @override
  Widget build(BuildContext context) {
    final message = error is FormatException
        ? switch (kind) {
            FileImportKind.images => t.common.invalidImageFormat,
            FileImportKind.pdf => t.common.invalidPdfFormat,
          }
        : t.common.fileAccessError;
    return AdaptiveAlertDialog(
      title: Text(
        kind == FileImportKind.images
            ? t.editor.toolbar.photo
            : t.editor.menu.import,
      ),
      content: Text(message),
      actions: [
        CupertinoDialogAction(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(t.common.done),
        ),
      ],
    );
  }
}
