import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'ocr_service.dart';

/// Imports loan details from a PDF or image entirely on-device.
/// No data is sent to any server or AI service.
/// Text extraction: syncfusion (PDF) or ML Kit (images).
/// Field parsing: regex — fully offline.
class StatementImportService {

  static Future<Map<String, dynamic>?> importFromPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return null;

    final file = result.files.single;
    final bytes = file.bytes!;
    final ext = file.extension?.toLowerCase() ?? '';

    // ── Step 1: Extract text on-device ──────────────────────────────────────
    String text;
    if (ext == 'pdf') {
      text = _extractPdfText(bytes);
      if (text.trim().isEmpty) {
        throw StatementImportException(
          'This PDF appears to be scanned. '
          'Please upload a JPG or PNG photo of the statement instead.',
        );
      }
    } else {
      // Image — use ML Kit OCR (on-device, zero network)
      final dir = await getTemporaryDirectory();
      final tmpFile = File('${dir.path}/ocr_import.$ext');
      await tmpFile.writeAsBytes(bytes);
      try {
        text = await OcrService.extractText(tmpFile);
      } on OcrException catch (e) {
        throw StatementImportException(e.message);
      } finally {
        await tmpFile.delete();
      }
    }

    // ── Step 2: Parse fields with regex — fully offline ──────────────────────
    final extracted = _parseFields(text);

    // ── Step 3: Validate — need at least principal ───────────────────────────
    final principal = extracted['principal'] as double?;
    if (principal == null || principal <= 0) {
      throw StatementImportException(
        'Could not find the loan amount in this document. '
        'Please fill in the form manually.',
      );
    }

    return extracted;
  }

  // ── PDF text extraction ────────────────────────────────────────────────────

  static String _extractPdfText(List<int> bytes) {
    final doc = PdfDocument(inputBytes: bytes);
    final buffer = StringBuffer();
    final pageCount = doc.pages.count.clamp(0, 5);
    final extractor = PdfTextExtractor(doc);
    for (int i = 0; i < pageCount; i++) {
      buffer.writeln(extractor.extractText(startPageIndex: i, endPageIndex: i));
    }
    doc.dispose();
    return buffer.toString();
  }

  // ── On-device regex field parser ───────────────────────────────────────────

  static Map<String, dynamic> _parseFields(String text) {
    return {
      'principal': _extractAmount(text, [
        r'(?:sanctioned|disbursed|loan)\s*amount[:\s₹Rs.]*([0-9,. ]+)',
        r'principal[:\s₹Rs.]*([0-9,. ]+)',
        r'loan\s*amount[:\s₹Rs.]*([0-9,. ]+)',
      ]),
      'interestRate': _extractRate(text),
      'tenureMonths': _extractTenure(text),
      'monthlyEmi': _extractAmount(text, [
        r'(?:monthly\s*)?emi[:\s₹Rs.]*([0-9,. ]+)',
        r'equated\s*monthly\s*instalment[:\s₹Rs.]*([0-9,. ]+)',
        r'monthly\s*instalment[:\s₹Rs.]*([0-9,. ]+)',
      ]),
      'startDate': _extractDate(text),
      'lenderName': _extractLender(text),
      'loanName': _extractLoanType(text),
    };
  }

  static double? _extractAmount(String text, List<String> patterns) {
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        final raw = match.group(1)?.replaceAll(RegExp(r'[, ]'), '') ?? '';
        final value = double.tryParse(raw);
        if (value != null && value > 0) return value;
      }
    }
    return null;
  }

  static double? _extractRate(String text) {
    final patterns = [
      r'(?:rate\s*of\s*interest|roi|interest\s*rate)[:\s]*([0-9.]+)\s*%',
      r'([0-9.]+)\s*%\s*(?:p\.?a\.?|per\s*annum)',
    ];
    for (final pattern in patterns) {
      final match = RegExp(pattern, caseSensitive: false).firstMatch(text);
      if (match != null) {
        final value = double.tryParse(match.group(1) ?? '');
        if (value != null && value > 0 && value <= 50) return value;
      }
    }
    return null;
  }

  static int? _extractTenure(String text) {
    // Try months first
    final monthMatch = RegExp(
      r'(?:tenure|loan\s*period|repayment\s*period)[:\s]*([0-9]+)\s*(?:months?|mos?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (monthMatch != null) {
      final v = int.tryParse(monthMatch.group(1) ?? '');
      if (v != null && v > 0 && v <= 360) return v;
    }
    // Try years and convert
    final yearMatch = RegExp(
      r'(?:tenure|loan\s*period|repayment\s*period)[:\s]*([0-9]+)\s*(?:years?|yrs?)',
      caseSensitive: false,
    ).firstMatch(text);
    if (yearMatch != null) {
      final v = int.tryParse(yearMatch.group(1) ?? '');
      if (v != null && v > 0 && v <= 30) return v * 12;
    }
    return null;
  }

  static String? _extractDate(String text) {
    // DD/MM/YYYY or DD-MM-YYYY
    final match = RegExp(
      r'(?:disbursement|start|commencement|loan)\s*date[:\s]*(\d{1,2})[\/\-](\d{1,2})[\/\-](\d{4})',
      caseSensitive: false,
    ).firstMatch(text);
    if (match != null) {
      final d = match.group(1)!.padLeft(2, '0');
      final m = match.group(2)!.padLeft(2, '0');
      final y = match.group(3)!;
      return '$y-$m-$d';
    }
    return null;
  }

  static String? _extractLender(String text) {
    final banks = [
      'SBI', 'HDFC', 'ICICI', 'Axis', 'Kotak', 'PNB', 'Bank of Baroda',
      'Canara', 'Union Bank', 'IndusInd', 'Yes Bank', 'IDFC', 'Bajaj',
      'Tata Capital', 'Muthoot', 'Manappuram', 'LIC Housing',
    ];
    for (final bank in banks) {
      if (text.toLowerCase().contains(bank.toLowerCase())) return bank;
    }
    return null;
  }

  static String? _extractLoanType(String text) {
    final types = {
      'Home Loan': ['home loan', 'housing loan', 'mortgage'],
      'Vehicle Loan': ['vehicle loan', 'car loan', 'auto loan', 'two wheeler'],
      'Personal Loan': ['personal loan'],
      'Education Loan': ['education loan', 'student loan'],
      'Business Loan': ['business loan', 'msme', 'working capital'],
      'Consumer Durable': ['consumer durable', 'emi card', 'no cost emi'],
    };
    final lower = text.toLowerCase();
    for (final entry in types.entries) {
      for (final keyword in entry.value) {
        if (lower.contains(keyword)) return entry.key;
      }
    }
    return null;
  }
}

class StatementImportException implements Exception {
  final String message;
  const StatementImportException(this.message);
}
