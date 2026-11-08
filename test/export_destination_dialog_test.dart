import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:saber/components/files/export_destination_dialog.dart';
import 'package:saber/i18n/strings.g.dart';

void main() {
  for (final isImage in [false, true]) {
    final kind = isImage ? 'images' : 'notes';

    testWidgets('$kind offer files and only the existing destination', (
      tester,
    ) async {
      await _openDialog(tester, isImage: isImage);

      expect(find.text(t.common.exportDestination.title), findsOneWidget);
      expect(find.text(t.common.exportDestination.saveToFiles), findsOneWidget);
      expect(
        find.text(t.common.exportDestination.share),
        isImage ? findsNothing : findsOneWidget,
      );
      expect(
        find.text(t.common.exportDestination.saveToGallery),
        isImage ? findsOneWidget : findsNothing,
      );
      expect(find.text(t.common.cancel), findsOneWidget);
    });

    testWidgets('$kind return the files destination', (tester) async {
      final result = await _openDialog(tester, isImage: isImage);

      await tester.tap(find.text(t.common.exportDestination.saveToFiles));
      await tester.pumpAndSettle();

      expect(await result.value, ExportDestination.files);
      expect(find.byType(ExportDestinationDialog), findsNothing);
    });

    testWidgets('$kind return the existing destination', (tester) async {
      final result = await _openDialog(tester, isImage: isImage);

      await tester.tap(
        find.text(
          isImage
              ? t.common.exportDestination.saveToGallery
              : t.common.exportDestination.share,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        await result.value,
        isImage ? ExportDestination.gallery : ExportDestination.share,
      );
      expect(find.byType(ExportDestinationDialog), findsNothing);
    });

    for (final dismissal in ['cancel', 'barrier', 'back']) {
      testWidgets('$kind return null on $dismissal', (tester) async {
        final result = await _openDialog(tester, isImage: isImage);

        switch (dismissal) {
          case 'cancel':
            await tester.tap(find.text(t.common.cancel));
          case 'barrier':
            await tester.tapAt(const Offset(5, 5));
          case 'back':
            await tester.binding.handlePopRoute();
        }
        await tester.pumpAndSettle();

        expect(await result.value, isNull);
        expect(find.byType(ExportDestinationDialog), findsNothing);
      });
    }
  }

  testWidgets('survives the image options dialog closing immediately', (
    tester,
  ) async {
    late Future<ExportDestination?> result;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  content: TextButton(
                    onPressed: () {
                      result = ExportDestinationDialog.show(
                        context,
                        isImage: true,
                      );
                      Navigator.of(context).pop();
                    },
                    child: const Text('Download image'),
                  ),
                ),
              ),
              child: const Text('Image options'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Image options'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Download image'));
    await tester.pumpAndSettle();

    expect(find.text('Download image'), findsNothing);
    expect(find.byType(ExportDestinationDialog), findsOneWidget);

    await tester.tap(find.text(t.common.exportDestination.saveToFiles));
    await tester.pumpAndSettle();
    expect(await result, ExportDestination.files);
  });
}

// Wrap the pending route result so this helper doesn't wait for a selection.
Future<({Future<ExportDestination?> value})> _openDialog(
  WidgetTester tester, {
  required bool isImage,
}) async {
  late Future<ExportDestination?> result;
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => TextButton(
            onPressed: () {
              result = ExportDestinationDialog.show(context, isImage: isImage);
            },
            child: const Text('Export'),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Export'));
  await tester.pumpAndSettle();
  return (value: result);
}
