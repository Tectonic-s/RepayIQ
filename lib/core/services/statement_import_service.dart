import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class StatementImportService {
  // Key loaded from dart-define at build time, falls back to hardcoded for direct Xcode builds
  static const _apiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyDlnohujwH94ZLRA4x_ya8nTboylPkS4uo',
  );

  /// Picks a PDF, extracts text, sends to Gemini, returns validated field map.
  /// Returns null if user cancelled or extraction failed.
  /// Throws [StatementImportException] with a user-facing message on failure.
  static Future<Map<String, dynamic>?> importFromPdf() async {
    // 1. Pick PDF or image file
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return null;

    final file = result.files.single;
    final bytes = file.bytes!;
    final ext = file.extension?.toLowerCase() ?? '';

    // 2. Extract text
    String text;
    if (ext == 'pdf') {
      text = _extractText(bytes);
      if (text.trim().isEmpty) {
        throw StatementImportException(
          'This PDF appears to be scanned (image-based). '
          'Please try uploading a JPG or PNG screenshot of the statement instead.',
        );
      }
    } else {
      // For images, send directly to Gemini as multimodal input
      return await _callGeminiWithImage(bytes, ext);
    }

    // 3. Send to Gemini
    final extracted = await _callGemini(text);

    // 4. Validate — relax validation, return partial data if at least principal exists
    final principal = (extracted['principal'] as num?)?.toDouble();
    if (principal == null || principal <= 0) {
      throw StatementImportException(
        'Could not find the loan amount in this document. '
        'Please fill in the form manually.',
      );
    }

    return extracted;
  }

  static String _extractText(List<int> bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    final buffer = StringBuffer();
    final pageCount = doc.pages.count.clamp(0, 5); // up to 5 pages
    final extractor = PdfTextExtractor(doc);
    for (int i = 0; i < pageCount; i++) {
      buffer.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
    }
    doc.dispose();
    return buffer.toString();
  }

  /// For images: send directly to Gemini as multimodal input
  static Future<Map<String, dynamic>> _callGeminiWithImage(
      List<int> bytes, String ext) async {
    if (_apiKey.isEmpty) {
      throw StatementImportException(
        'AI extraction is not configured. Please contact support.',
      );
    }
    final model = GenerativeModel(model: 'gemini-2.5-flash', apiKey: _apiKey);
    final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';

    const prompt = 'You are a financial data extraction assistant for Indian bank documents. '
        'Extract loan details from this image. It may be a loan statement, sanction letter, or agreement. '
        'Return ONLY a valid JSON object with fields: '
        'loanName (string), lenderName (string), principal (number in rupees), interestRate (annual % as number), '
        'tenureMonths (integer), monthlyEmi (number in rupees), startDate (YYYY-MM-DD string). '
        'Strip all currency symbols and commas from numbers. Convert Indian lakh/crore notation. '
        'Use null for any field not clearly visible. No markdown, no explanation, JSON only.';

    final response = await model.generateContent([
      Content.multi([
        TextPart(prompt),
        DataPart(mimeType, Uint8List.fromList(bytes)),
      ]),
    ]);

    final raw = response.text ?? '';
    final cleaned = raw.replaceAll('```json', '').replaceAll('```', '').trim();
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    final jsonStr = jsonMatch?.group(0) ?? cleaned;
    try {
      final data = jsonDecode(jsonStr) as Map<String, dynamic>;
      final principal = (data['principal'] as num?)?.toDouble();
      if (principal == null || principal <= 0) {
        throw StatementImportException(
          'Could not find the loan amount in this image. '
          'Please fill in the form manually.',
        );
      }
      return data;
    } catch (e) {
      if (e is StatementImportException) rethrow;
      throw StatementImportException(
        'Could not read the image. Please try a clearer photo or a PDF.',
      );
    }
  }

  static Future<Map<String, dynamic>> _callGemini(String text) async {
    if (_apiKey.isEmpty) {
      throw StatementImportException(
        'AI extraction is not configured. Please contact support.',
      );
    }
    final model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey,
    );

    // Sanitise and truncate
    final sanitised = text
        .replaceAll(RegExp(r'ignore.{0,30}instruction', caseSensitive: false), '')
        .substring(0, text.length.clamp(0, 8000));

    final prompt = '''
You are a financial data extraction assistant specialising in Indian bank loan documents.
Extract loan details from the text below. The document may be a loan statement, sanction letter, loan agreement, or repayment schedule from any Indian bank or NBFC.

Common Indian bank field names to look for:
- Principal / Loan Amount / Sanctioned Amount / Disbursed Amount
- Rate of Interest / ROI / Interest Rate / p.a.
- Tenure / Loan Period / Repayment Period (in months or years)
- EMI / Monthly Instalment / Equated Monthly Instalment
- Disbursement Date / Loan Date / Start Date / Commencement Date
- Bank / Lender / Branch

Return ONLY a valid JSON object:
{
  "loanName": "loan type e.g. Home Loan, Personal Loan, Car Loan",
  "lenderName": "bank or NBFC name",
  "principal": <number in rupees, digits only>,
  "interestRate": <annual rate as number e.g. 8.5>,
  "tenureMonths": <total months as integer>,
  "monthlyEmi": <EMI amount in rupees as number>,
  "startDate": "YYYY-MM-DD"
}

Rules:
- Return ONLY the JSON. No explanation, no markdown, no code fences.
- Use null for any field you cannot find with confidence.
- Strip all currency symbols (₹, Rs, INR) and commas from numbers.
- Convert years to months for tenureMonths.
- If you see amounts like "5,00,000" that is 500000 in Indian numbering.

---
Document text:
$sanitised
''';

    final response = await model.generateContent([
      Content.text(prompt),
    ]);

    final raw = response.text ?? '';
    final cleaned = raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();

    // Extract JSON even if there's surrounding text
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(cleaned);
    final jsonStr = jsonMatch?.group(0) ?? cleaned;

    try {
      return jsonDecode(jsonStr) as Map<String, dynamic>;
    } catch (_) {
      throw StatementImportException(
        'Could not parse the extracted data. Please try again or fill in manually.',
      );
    }
  }

}

class StatementImportException implements Exception {
  final String message;
  const StatementImportException(this.message);
}
