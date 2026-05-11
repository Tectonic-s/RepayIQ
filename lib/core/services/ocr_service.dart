import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class OcrService {
  static final _textRecognizer = TextRecognizer();

  /// Scan a document using camera or gallery and extract text using ML Kit
  static Future<String?> scanDocument({required ImageSource source}) async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: source);
      if (image == null) return null;

      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      
      return recognizedText.text;
    } catch (e) {
      throw OcrException('Failed to scan document: $e');
    }
  }

  /// Parse loan details from OCR text using regex patterns
  static Map<String, dynamic> parseOcrText(String text) {
    final data = <String, dynamic>{};

    // Principal amount patterns
    final principalPatterns = [
      RegExp(r'(?:loan amount|principal|sanctioned amount|disbursed amount)[:\s]*₹?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'₹\s*([0-9,]+(?:\.[0-9]{2})?)\s*(?:loan|principal)', caseSensitive: false),
    ];
    for (final pattern in principalPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amount = match.group(1)?.replaceAll(',', '');
        data['principal'] = double.tryParse(amount ?? '');
        break;
      }
    }

    // Interest rate patterns
    final ratePatterns = [
      RegExp(r'(?:interest rate|rate of interest|roi)[:\s]*([0-9]+(?:\.[0-9]{1,2})?)\s*%', caseSensitive: false),
      RegExp(r'([0-9]+(?:\.[0-9]{1,2})?)\s*%\s*(?:p\.a|per annum|interest)', caseSensitive: false),
    ];
    for (final pattern in ratePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        data['interestRate'] = double.tryParse(match.group(1) ?? '');
        break;
      }
    }

    // Tenure patterns
    final tenurePatterns = [
      RegExp(r'(?:tenure|loan period|repayment period)[:\s]*([0-9]+)\s*(?:months?|mon)', caseSensitive: false),
      RegExp(r'([0-9]+)\s*(?:months?|mon)\s*(?:tenure|period)', caseSensitive: false),
      RegExp(r'(?:tenure|loan period|repayment period)[:\s]*([0-9]+)\s*(?:years?|yrs?)', caseSensitive: false),
    ];
    for (final pattern in tenurePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        var months = int.tryParse(match.group(1) ?? '');
        if (months != null) {
          // If pattern mentions years, convert to months
          if (pattern.pattern.contains('years?|yrs?')) {
            months = months * 12;
          }
          data['tenureMonths'] = months;
          break;
        }
      }
    }

    // EMI amount patterns
    final emiPatterns = [
      RegExp(r'(?:emi|monthly installment|monthly payment)[:\s]*₹?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
      RegExp(r'₹\s*([0-9,]+(?:\.[0-9]{2})?)\s*(?:emi|per month)', caseSensitive: false),
    ];
    for (final pattern in emiPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amount = match.group(1)?.replaceAll(',', '');
        data['emi'] = double.tryParse(amount ?? '');
        break;
      }
    }

    // Processing fee patterns
    final feePatterns = [
      RegExp(r'(?:processing fee|processing charges)[:\s]*₹?\s*([0-9,]+(?:\.[0-9]{2})?)', caseSensitive: false),
    ];
    for (final pattern in feePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amount = match.group(1)?.replaceAll(',', '');
        data['processingFee'] = double.tryParse(amount ?? '');
        break;
      }
    }

    // Start date patterns
    final datePatterns = [
      RegExp(r'(?:disbursement date|loan date|start date)[:\s]*([0-9]{1,2})[/-]([0-9]{1,2})[/-]([0-9]{4})', caseSensitive: false),
      RegExp(r'([0-9]{1,2})[/-]([0-9]{1,2})[/-]([0-9]{4})', caseSensitive: false),
    ];
    for (final pattern in datePatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '');
        final month = int.tryParse(match.group(2) ?? '');
        final year = int.tryParse(match.group(3) ?? '');
        if (day != null && month != null && year != null) {
          try {
            final date = DateTime(year, month, day);
            data['startDate'] = date.toIso8601String();
            break;
          } catch (_) {}
        }
      }
    }

    // Lender name patterns
    final lenderPatterns = [
      RegExp(r'(?:bank|lender)[:\s]*([A-Z][A-Za-z\s]+(?:Bank|Finance))', caseSensitive: false),
      RegExp(r'(HDFC|ICICI|SBI|Axis|Kotak|PNB|BOI|IDBI|Union|Canara|Indian)\s*Bank', caseSensitive: false),
    ];
    for (final pattern in lenderPatterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        data['lenderName'] = match.group(1)?.trim();
        break;
      }
    }

    return data;
  }

  static void dispose() {
    _textRecognizer.close();
  }
}

class OcrException implements Exception {
  final String message;
  OcrException(this.message);
}
