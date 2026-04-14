import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// On-device OCR using Google ML Kit.
/// The image never leaves the device — zero network calls.
class OcrService {
  /// Extracts text from [imageFile] entirely on-device.
  /// Creates and closes a fresh TextRecognizer per call — no instance reuse.
  /// Throws [OcrException] with a user-friendly message on failure.
  static Future<String> extractText(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(inputImage);
      final text = result.text;
      if (text.trim().isEmpty) {
        throw OcrException(
          'No text found in this image. '
          'Try a clearer photo with better lighting.',
        );
      }
      return text;
    } catch (e) {
      if (e is OcrException) rethrow;
      throw OcrException('Could not read the image. Please try again.');
    } finally {
      await recognizer.close(); // always close to free memory
    }
  }
}

class OcrException implements Exception {
  final String message;
  const OcrException(this.message);
}
