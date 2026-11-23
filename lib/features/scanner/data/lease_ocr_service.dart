import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

/// On-device OCR service backed by Google ML Kit Text Recognition.
/// Images never leave the device.
class LeaseOcrService {
  LeaseOcrService({ImagePicker? imagePicker})
      : _imagePicker = imagePicker ?? ImagePicker();

  final ImagePicker _imagePicker;

  /// Picks an image from [source] and runs 100% on-device text recognition.
  /// Returns `null` if the user cancels image selection.
  Future<String?> scanFromSource(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 92,
      maxWidth: 2200,
    );
    if (picked == null) return null;

    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final inputImage = InputImage.fromFilePath(picked.path);
      final recognizedText = await recognizer.processImage(inputImage);
      return recognizedText.text.trim();
    } finally {
      await recognizer.close();
    }
  }
}
