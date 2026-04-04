import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../features/loans/domain/entities/loan.dart';
import 'emi_calculator.dart';

class ReportGenerator {
  static final _currency = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
  static final _date = DateFormat('dd MMM yyyy');

  static Future<void> exportLoanSummaryPdf(List<Loan> loans) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.nunitoRegular();
    final fontBold = await PdfGoogleFonts.nunitoBold();

    final active = loans.where((l) => l.status == 'Active').toList();
    final totalOutstanding = active.fold(0.0, (s, l) => s + l.outstandingBalance);
    final totalEmi = active.fold(0.0, (s, l) => s + l.monthlyEmi);
    final totalInterest = active.fold(0.0, (s, l) =>
        s + (l.monthlyEmi * l.tenureMonths - l.principal).clamp(0, double.infinity));

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        build: (ctx) => [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('RepayIQ', style: pw.TextStyle(font: fontBold, fontSize: 22, color: PdfColor.fromHex('00897B'))),
                  pw.Text('Loan Summary Report', style: pw.TextStyle(fontSize: 13, color: PdfColor.fromHex('6B7280'))),
                ],
              ),
              pw.Text('Generated: ${_date.format(DateTime.now())}',
                  style: pw.TextStyle(fontSize: 10, color: PdfColor.fromHex('6B7280'))),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Divider(color: PdfColor.fromHex('E5E7EB')),
          pw.SizedBox(height: 16),

          // Summary cards row
          pw.Row(
            children: [
              _summaryBox('Total Outstanding', _currency.format(totalOutstanding), '00897B', fontBold, font),
              pw.SizedBox(width: 12),
              _summaryBox('Monthly EMI', _currency.format(totalEmi), '1E6FFF', fontBold, font),
              pw.SizedBox(width: 12),
              _summaryBox('Total Interest', _currency.format(totalInterest), 'FFB020', fontBold, font),
            ],
          ),
          pw.SizedBox(height: 24),

          // Loans table
          pw.Text('Active Loans', style: pw.TextStyle(font: fontBold, fontSize: 14)),
          pw.SizedBox(height: 10),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColor.fromHex('E5E7EB'), width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(2.5),
              1: const pw.FlexColumnWidth(1.5),
              2: const pw.FlexColumnWidth(1.5),
              3: const pw.FlexColumnWidth(1.5),
              4: const pw.FlexColumnWidth(1.5),
              5: const pw.FlexColumnWidth(1.2),
            },
            children: [
              // Header row
              pw.TableRow(
                decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
                children: ['Loan Name', 'Type', 'Principal', 'EMI', 'Outstanding', 'Progress']
                    .map((h) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          child: pw.Text(h, style: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColor.fromHex('374151'))),
                        ))
                    .toList(),
              ),
              // Data rows
              ...active.map((l) => pw.TableRow(
                    children: [
                      l.loanName,
                      l.loanType,
                      _currency.format(l.principal),
                      _currency.format(l.monthlyEmi),
                      _currency.format(l.outstandingBalance),
                      '${(l.progressPercent * 100).toStringAsFixed(0)}%',
                    ]
                        .map((v) => pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                              child: pw.Text(v, style: pw.TextStyle(font: font, fontSize: 9)),
                            ))
                        .toList(),
                  )),
            ],
          ),
          pw.SizedBox(height: 28),

          // Per-loan amortisation summaries
          ...active.map((loan) => _loanAmortSection(loan, fontBold, font)),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (_) async => pdf.save());
  }

  static pw.Widget _summaryBox(String label, String value, String hex, pw.Font bold, pw.Font regular) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: PdfColor.fromHex(hex).shade(0.3), width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(label, style: pw.TextStyle(font: regular, fontSize: 9, color: PdfColor.fromHex('6B7280'))),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(font: bold, fontSize: 13, color: PdfColor.fromHex(hex))),
          ],
        ),
      ),
    );
  }

  static pw.Widget _loanAmortSection(Loan loan, pw.Font bold, pw.Font regular) {
    final schedule = EmiCalculator.amortisationSchedule(
      principal: loan.principal,
      annualRate: loan.interestRate,
      tenureMonths: loan.tenureMonths,
    );

    // Show first 6 and last 3 rows to keep PDF concise
    final rows = schedule.length <= 9
        ? schedule
        : [...schedule.take(6), ...schedule.skip(schedule.length - 3)];
    final hasEllipsis = schedule.length > 9;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('${loan.loanName} — Amortisation',
            style: pw.TextStyle(font: bold, fontSize: 12)),
        pw.SizedBox(height: 6),
        pw.Table(
          border: pw.TableBorder.all(color: PdfColor.fromHex('E5E7EB'), width: 0.5),
          columnWidths: {
            0: const pw.FlexColumnWidth(0.8),
            1: const pw.FlexColumnWidth(1.5),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
            4: const pw.FlexColumnWidth(1.5),
          },
          children: [
            pw.TableRow(
              decoration: pw.BoxDecoration(color: PdfColor.fromHex('F3F4F6')),
              children: ['Mo.', 'EMI', 'Principal', 'Interest', 'Balance']
                  .map((h) => pw.Padding(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                        child: pw.Text(h, style: pw.TextStyle(font: bold, fontSize: 8, color: PdfColor.fromHex('374151'))),
                      ))
                  .toList(),
            ),
            for (int i = 0; i < rows.length; i++) ...[
              if (hasEllipsis && i == 6)
                pw.TableRow(children: List.generate(5, (_) => pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  child: pw.Text('...', style: pw.TextStyle(font: regular, fontSize: 8, color: PdfColor.fromHex('9CA3AF'))),
                ))),
              pw.TableRow(
                children: [
                  rows[i]['month']!.toInt().toString(),
                  _currency.format(rows[i]['emi']),
                  _currency.format(rows[i]['principal']),
                  _currency.format(rows[i]['interest']),
                  _currency.format(rows[i]['balance']),
                ]
                    .map((v) => pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                          child: pw.Text(v, style: pw.TextStyle(font: regular, fontSize: 8)),
                        ))
                    .toList(),
              ),
            ],
          ],
        ),
        pw.SizedBox(height: 20),
      ],
    );
  }
}
