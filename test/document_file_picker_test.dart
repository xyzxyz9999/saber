import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:saber/data/file_manager/document_file_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('miguelruivo.flutter.plugins.filepicker');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  late FilePickerPlatform originalPlatform;
  late List<MethodCall> calls;
  Object? response;
  PlatformException? error;

  setUp(() {
    originalPlatform = FilePickerPlatform.instance;
    FilePickerAndroid.registerWith();
    debugDefaultTargetPlatformOverride = TargetPlatform.android;
    calls = [];
    response = null;
    error = null;
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      if (error != null) throw error!;
      return response;
    });
  });

  tearDown(() {
    messenger.setMockMethodCallHandler(channel, null);
    FilePickerPlatform.instance = originalPlatform;
    debugDefaultTargetPlatformOverride = null;
  });

  Map<String, Object?> picked(String name, {String? path}) => {
    'name': name,
    'path': path ?? '/cache/$name',
    'size': 3,
    'uri': 'content://cloud/document/123',
    'safHandle': {'uri': 'content://cloud/document/123', 'access': 'readOnly'},
  };

  void expectDocumentRequest({required bool multiple}) {
    expect(calls.single.method, 'any');
    expect(calls.single.arguments['allowedExtensions'], isNull);
    expect(calls.single.arguments['allowMultipleSelection'], multiple);
    expect(calls.single.arguments['androidSafOptions'], {
      'grant': 'transient',
      'access': 'readOnly',
      'autoPersist': false,
    });
  }

  test(
    'images use documents without MIME filters and allow multiple picks',
    () async {
      response = [picked('diagram.PNG'), picked('drawing.svg')];
      final files = await DocumentFilePicker.pickImages();
      expect(files.map((file) => file.name), ['diagram.PNG', 'drawing.svg']);
      expectDocumentRequest(multiple: true);
    },
  );

  for (final extension in ['sbn', 'sbn2', 'sba', 'pdf']) {
    test('imports $extension with a generic provider MIME type', () async {
      response = [picked('Note.${extension.toUpperCase()}')];
      final file = await DocumentFilePicker.pickNote();
      expect(file!.name, 'Note.${extension.toUpperCase()}');
      expectDocumentRequest(multiple: false);
    });
  }

  test('PDF selection uses documents and validates the display name', () async {
    response = [picked('paper.PDF', path: '/cache/opaque')];
    expect((await DocumentFilePicker.pickPdf())!.name, 'paper.PDF');
    expectDocumentRequest(multiple: false);
  });

  test('unsupported note and PDF formats are rejected', () async {
    response = [picked('unsupported.txt')];
    await expectLater(DocumentFilePicker.pickNote(), throwsFormatException);
    await expectLater(DocumentFilePicker.pickPdf(), throwsFormatException);
  });

  test('unsupported image selection rejects the whole batch', () async {
    response = [picked('valid.png'), picked('unsupported.txt')];
    await expectLater(DocumentFilePicker.pickImages(), throwsFormatException);
  });

  test('PDF image picks retain the existing PDF guidance path', () async {
    response = [picked('paper.pdf')];
    expect((await DocumentFilePicker.pickImages()).single.name, 'paper.pdf');
  });

  test('cancellation returns no selections', () async {
    expect(await DocumentFilePicker.pickNote(), isNull);
    expect(await DocumentFilePicker.pickPdf(), isNull);
    expect(await DocumentFilePicker.pickImages(), isEmpty);
  });

  test(
    'provider failures propagate instead of becoming successful picks',
    () async {
      error = PlatformException(code: 'read_failed');
      await expectLater(
        DocumentFilePicker.pickNote(),
        throwsA(isA<PlatformException>()),
      );
    },
  );

  test(
    'provider bytes are read from the plugin cache, not the source URI',
    () async {
      final directory = await Directory.systemTemp.createTemp('saber-picker-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/remote.png');
      await file.writeAsBytes([1, 2, 3]);
      response = [picked('remote.png', path: file.path)];
      final selection = (await DocumentFilePicker.pickImages()).single;
      expect(DocumentFilePicker.localPath(selection), file.path);
      expect(await selection.readAsBytes(), [1, 2, 3]);
    },
  );

  test('a raw content URI is never passed to path-only consumers', () {
    final file = AndroidPlatformFile(
      name: 'note.sba',
      uri: Uri.parse('content://cloud/document/123'),
    );
    expect(
      () => DocumentFilePicker.localPath(file),
      throwsA(isA<FileSystemException>()),
    );
  });

  for (final (name, mime) in [
    ('note.sba', 'application/octet-stream'),
    ('note.pdf', 'application/pdf'),
    ('page.PNG', 'image/png'),
    ('notes.zip', 'application/zip'),
  ]) {
    test(
      'save $name sends the filename, MIME type, and original bytes',
      () async {
        final bytes = Uint8List.fromList([0, 128, 255]);
        response = 'content://cloud/document/saved';
        expect(
          await DocumentFilePicker.saveFile(name, bytes),
          Uri.parse(response! as String),
        );
        expect(calls.single.method, 'save');
        expect(calls.single.arguments['fileName'], name);
        expect(calls.single.arguments['fileType'], mime);
        expect(calls.single.arguments['bytes'], bytes);
      },
    );
  }

  test('save cancellation and failure do not report a destination', () async {
    expect(await DocumentFilePicker.saveFile('note.sba', Uint8List(0)), isNull);
    error = PlatformException(code: 'write_failed');
    await expectLater(
      DocumentFilePicker.saveFile('note.sba', Uint8List(0)),
      throwsA(isA<PlatformException>()),
    );
  });

  test('other platforms retain their image and PDF filters', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    await DocumentFilePicker.pickImages();
    expect(calls.last.method, 'custom');
    expect(
      calls.last.arguments['allowedExtensions'],
      containsAll(['png', 'svg', 'exr']),
    );
    await DocumentFilePicker.pickPdf();
    expect(calls.last.method, 'custom');
    expect(calls.last.arguments['allowedExtensions'], ['pdf']);
    await DocumentFilePicker.pickNote();
    expect(calls.last.method, 'any');
  });
}
