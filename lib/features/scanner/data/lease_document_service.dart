import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart';

import '../../../core/config/app_config.dart';

/// Result of reading a local PDF or text lease document on-device.
class PickedLeaseDocument {
  const PickedLeaseDocument({
    required this.fileName,
    required this.extractedText,
  });

  final String fileName;
  final String extractedText;
}

/// Picks a `.pdf` or `.txt` lease file and extracts its text 100% locally on-device.
///
/// - `.txt` files are decoded directly in Dart.
/// - `.pdf` files are parsed natively via Apache PDFBox (Android) or Apple PDFKit (iOS)
///   over the `com.leaseshield/hybrid_ai` channel with zero cloud upload.
class LeaseDocumentService {
  LeaseDocumentService({MethodChannel? channel})
      : _channel = channel ?? const MethodChannel(AppConfig.hybridAiChannelName);

  final MethodChannel _channel;

  Future<PickedLeaseDocument?> pickAndExtractDocument() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt'],
      withData: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.single;
    final path = file.path;
    if (path == null || path.isEmpty) {
      throw Exception('Unable to access selected file path.');
    }

    final ext = (file.extension ?? '').toLowerCase();
    String extractedText;

    if (ext == 'txt') {
      extractedText = (await File(path).readAsString()).trim();
    } else if (ext == 'pdf') {
      final text = await _channel.invokeMethod<String>(
        'extractPdfText',
        <String, dynamic>{'path': path},
      );
      extractedText = (text ?? '').trim();
    } else {
      throw Exception('Unsupported file type: .$ext. Please select a PDF or TXT file.');
    }

    final cleanName = file.name.replaceAll(RegExp(r'\.(pdf|txt)$', caseSensitive: false), '');
    return PickedLeaseDocument(
      fileName: cleanName.isEmpty ? 'Uploaded Lease Document' : cleanName,
      extractedText: extractedText,
    );
  }
}
