import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:saber/components/files/file_import_error_dialog.dart';
import 'package:saber/i18n/strings.g.dart';

void main() {
  for (final kind in FileImportKind.values) {
    testWidgets('$kind format errors appear above the import menu', (
      tester,
    ) async {
      late BuildContext editorContext;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                editorContext = context;
                return TextButton(
                  onPressed: () => showModalBottomSheet<void>(
                    context: context,
                    builder: (context) => TextButton(
                      onPressed: () => FileImportErrorDialog.show(
                        editorContext,
                        error: const FormatException(),
                        kind: kind,
                      ),
                      child: const Text('Import'),
                    ),
                  ),
                  child: const Text('Menu'),
                );
              },
            ),
          ),
        ),
      );
      await tester.tap(find.text('Menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Import'));
      await tester.pumpAndSettle();
      expect(find.byType(FileImportErrorDialog), findsOneWidget);
      expect(find.text(t.home.invalidFormat), findsNothing);
      expect(
        find.text(
          kind == FileImportKind.images
              ? t.common.invalidImageFormat
              : t.common.invalidPdfFormat,
        ),
        findsOneWidget,
      );
      await tester.tap(find.text(t.common.done));
      await tester.pumpAndSettle();
      expect(find.byType(FileImportErrorDialog), findsNothing);
      expect(find.text('Import'), findsOneWidget);
    });
  }

  testWidgets('read failures show retry guidance', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: FileImportErrorDialog(
          error: Exception('provider offline'),
          kind: FileImportKind.images,
        ),
      ),
    );
    expect(find.text(t.common.fileAccessError), findsOneWidget);
  });
}
