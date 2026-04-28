import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../models/expense.dart';

class PdfExportService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  /// Exporta relatório completo da viagem em PDF
  static Future<File> exportTripReport({
    required Trip trip,
    required List<Expense> expenses,
  }) async {
    final pdf = pw.Document();

    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.value);
    final remaining = trip.budget - totalSpent;
    final percentUsed = trip.budget > 0 ? (totalSpent / trip.budget) * 100 : 0;

    // Agrupar despesas por categoria
    final Map<String, double> byCategory = {};
    for (var expense in expenses) {
      byCategory[expense.category] =
          (byCategory[expense.category] ?? 0) + expense.value;
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Cabeçalho
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                decoration: pw.BoxDecoration(
                  color: PdfColors.deepPurple,
                  borderRadius: pw.BorderRadius.circular(10),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Relatório de Viagem',
                      style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Text(
                      trip.destination,
                      style: pw.TextStyle(
                        fontSize: 18,
                        color: PdfColors.white,
                      ),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Text(
                      trip.startDate != null && trip.endDate != null
                          ? '${DateFormat('dd/MM/yyyy').format(trip.startDate!)} - ${DateFormat('dd/MM/yyyy').format(trip.endDate!)}'
                          : 'Datas não definidas',
                      style: const pw.TextStyle(
                        fontSize: 12,
                        color: PdfColors.white,
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Resumo Financeiro
              pw.Text(
                'Resumo Financeiro',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Container(
                padding: const pw.EdgeInsets.all(15),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey300),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    _buildInfoRow('Orçamento Total:',
                        _currencyFormat.format(trip.budget)),
                    pw.SizedBox(height: 10),
                    _buildInfoRow(
                        'Total Gasto:', _currencyFormat.format(totalSpent)),
                    pw.SizedBox(height: 10),
                    _buildInfoRow(
                      'Saldo Restante:',
                      _currencyFormat.format(remaining),
                      valueColor:
                          remaining >= 0 ? PdfColors.green : PdfColors.red,
                    ),
                    pw.SizedBox(height: 10),
                    _buildInfoRow('Percentual Usado:',
                        '${percentUsed.toStringAsFixed(1)}%'),
                  ],
                ),
              ),

              pw.SizedBox(height: 30),

              // Despesas por Categoria
              pw.Text(
                'Despesas por Categoria',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              ...byCategory.entries.map((entry) {
                final percent =
                    totalSpent > 0 ? (entry.value / totalSpent) * 100 : 0;
                return pw.Container(
                  margin: const pw.EdgeInsets.only(bottom: 10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        '${_getCategoryEmoji(entry.key)} ${entry.key}',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Row(
                        children: [
                          pw.Text(
                            _currencyFormat.format(entry.value),
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                          pw.SizedBox(width: 10),
                          pw.Text(
                            '(${percent.toStringAsFixed(1)}%)',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          );
        },
      ),
    );

    // Página 2: Detalhamento de Despesas
    if (expenses.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Detalhamento de Despesas',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Tabela de despesas
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300),
                  children: [
                    // Cabeçalho
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(
                        color: PdfColors.grey200,
                      ),
                      children: [
                        _buildTableCell('Data', isHeader: true),
                        _buildTableCell('Descrição', isHeader: true),
                        _buildTableCell('Categoria', isHeader: true),
                        _buildTableCell('Valor', isHeader: true),
                      ],
                    ),
                    // Linhas de despesas
                    ...expenses.map((expense) {
                      return pw.TableRow(
                        children: [
                          _buildTableCell(
                            DateFormat('dd/MM').format(expense.date),
                          ),
                          _buildTableCell(expense.title),
                          _buildTableCell(expense.category),
                          _buildTableCell(
                            _currencyFormat.format(expense.value),
                          ),
                        ],
                      );
                    }).toList(),
                  ],
                ),

                pw.Spacer(),

                // Rodapé
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey100,
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Gerado em ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
                        style: const pw.TextStyle(
                          fontSize: 10,
                          color: PdfColors.grey600,
                        ),
                      ),
                      pw.Text(
                        'Travel App - Premium',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.deepPurple,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      );
    }

    // Salvar PDF
    final output = await getTemporaryDirectory();
    final file = File(
        '${output.path}/viagem_${trip.destination.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf');
    await file.writeAsBytes(await pdf.save());

    return file;
  }

  /// Compartilha o PDF gerado
  static Future<void> shareReport(File pdfFile, String tripName) async {
    await Share.shareXFiles(
      [XFile(pdfFile.path)],
      subject: 'Relatório de Viagem - $tripName',
      text: 'Confira o relatório completo da minha viagem para $tripName!',
    );
  }

  // Helpers
  static pw.Widget _buildInfoRow(
    String label,
    String value, {
    PdfColor? valueColor,
  }) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(
          label,
          style: const pw.TextStyle(fontSize: 12),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            fontWeight: pw.FontWeight.bold,
            color: valueColor ?? PdfColors.black,
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildTableCell(String text, {bool isHeader = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 10,
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
        ),
      ),
    );
  }

  static String _getCategoryEmoji(String category) {
    switch (category.toLowerCase()) {
      case 'alimentação':
        return '[FOOD]';
      case 'transporte':
        return '[TRANSPORT]';
      case 'hospedagem':
        return '[HOTEL]';
      case 'entretenimento':
        return '[FUN]';
      case 'compras':
        return '[SHOP]';
      case 'saúde':
        return '[HEALTH]';
      default:
        return '[MONEY]';
    }
  }
}
