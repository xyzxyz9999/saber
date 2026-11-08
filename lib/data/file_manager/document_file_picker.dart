import 'dart:io';

import 'package:android_file_picker/android_file_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

abstract final class DocumentFilePicker {
  static const _androidOptions = FilePickerAndroidOptions(
    safOptions: AndroidSAFOptions(persistGrant: false),
  );

  static const _imageExtensions = [
    'jpg',
    'jpeg',
    'png',
    'gif',
    'tiff',
    'bmp',
    'tga',
    'ico',
    'pvrtc',
    'svg',
    'webp',
    'psd',
    'exr',
  ];

  static bool get _isAndroid => defaultTargetPlatform == TargetPlatform.android;

  static Future<PlatformFile?> pickNote() async {
    final file = await FilePicker.pickFile(androidOptions: _androidOptions);
    if (file != null) _validate(file, const ['sbn', 'sbn2', 'sba', 'pdf']);
    return file;
  }

  static Future<PlatformFile?> pickPdf() async {
    final file = await FilePicker.pickFile(
      type: _isAndroid ? FileType.any : FileType.custom,
      allowedExtensions: _isAndroid ? null : const ['pdf'],
      androidOptions: _androidOptions,
    );
    if (file != null) _validate(file, const ['pdf']);
    return file;
  }

  static Future<List<PlatformFile>> pickImages() async {
    // Remote providers may report application/octet-stream even for images.
    // FileType.any opens Android's document picker without a MIME filter.
    final files = await FilePicker.pickFiles(
      type: _isAndroid ? FileType.any : FileType.custom,
      allowedExtensions: _isAndroid ? null : _imageExtensions,
      androidOptions: _androidOptions,
    );
    for (final file in files) {
      // The editor already explains how to import PDFs selected as images.
      _validate(file, const [..._imageExtensions, 'pdf']);
    }
    return files;
  }

  static void _validate(PlatformFile file, List<String> extensions) {
    final extension = p.extension(file.name).toLowerCase();
    if (extension.isEmpty || !extensions.contains(extension.substring(1))) {
      throw FormatException('Unsupported file type', file.name);
    }
  }

  static String localPath(PlatformFile file) {
    // android_file_picker copies ContentResolver streams into its own cache.
    // Keep that cache intact: PDF assets can still need it after import returns.
    final path = file.path;
    if (path == null ||
        path.isEmpty ||
        Uri.tryParse(path)?.scheme == 'content') {
      throw FileSystemException(
        'The selected file has no local copy',
        file.name,
      );
    }
    return path;
  }

  static Future<Uri?> saveFile(String fileName, Uint8List bytes) {
    final mimeType = switch (p.extension(fileName).toLowerCase()) {
      '.pdf' => 'application/pdf',
      '.png' => 'image/png',
      '.jpg' || '.jpeg' => 'image/jpeg',
      '.svg' => 'image/svg+xml',
      '.zip' => 'application/zip',
      _ => 'application/octet-stream',
    };
    return FilePicker.saveFile(
      fileName: fileName,
      bytes: bytes,
      mimeType: mimeType,
    );
  }
}
