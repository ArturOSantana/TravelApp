import 'dart:io';
import 'dart:math' as math;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../models/trip.dart';
import '../models/expense.dart';
import 'analytics_service.dart';

class PdfExportService {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'pt_BR',
    symbol: 'R\$',
    decimalDigits: 2,
  );

  // rela pdf
  static Future<File> exportTripReport({
    required Trip trip,
    required List<Expense> expenses,
  }) async {
    final pdf = pw.Document();

    // Calcular estatísticas
    final stats = AnalyticsService.calculateTripStatistics(
      trip: trip,
      expenses: expenses,
    );

    final totalSpent = expenses.fold<double>(0, (sum, e) => sum + e.value);
    final remaining = trip.budget - totalSpent;
    final percentUsed = trip.budget > 0 ? (totalSpent / trip.budget) * 100 : 0;

    final Map<String, double> byCategory = stats.categoryBreakdown;

    final dailySpending = AnalyticsService.groupByDay(expenses);

    // Calcular divisão por pessoa se for viagem em grupo
    Map<String, double> spendingByPerson = {};
    if (trip.isGroup && trip.members.isNotEmpty) {
      for (var expense in expenses) {
        if (expense.splits.isNotEmpty) {
          expense.splits.forEach((personId, amount) {
            spendingByPerson[personId] =
                (spendingByPerson[personId] ?? 0) + amount;
          });
        } else {
          final perPerson = expense.value /
              (trip.members.length + 1); // +1 
          spendingByPerson[expense.payerId] =
              (spendingByPerson[expense.payerId] ?? 0) + perPerson;
        }
      }
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

              // Gráfico dpiza 
              pw.Text(
                'Despesas por Categoria',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // pizza
                  pw.Expanded(
                    flex: 2,
                    child: pw.Container(
                      height: 200,
                      child: _buildPieChart(byCategory, totalSpent),
                    ),
                  ),
                  pw.SizedBox(width: 20),
                  // Legenda
                  pw.Expanded(
                    flex: 1,
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: byCategory.entries.map((entry) {
                        final percent = totalSpent > 0
                            ? (entry.value / totalSpent) * 100
                            : 0;
                        return pw.Container(
                          margin: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            children: [
                              pw.Container(
                                width: 12,
                                height: 12,
                                decoration: pw.BoxDecoration(
                                  color: _getCategoryColor(entry.key),
                                  borderRadius: pw.BorderRadius.circular(2),
                                ),
                              ),
                              pw.SizedBox(width: 8),
                              pw.Expanded(
                                child: pw.Column(
                                  crossAxisAlignment:
                                      pw.CrossAxisAlignment.start,
                                  children: [
                                    pw.Text(
                                      entry.key,
                                      style: const pw.TextStyle(fontSize: 10),
                                    ),
                                    pw.Text(
                                      '${_currencyFormat.format(entry.value)} (${percent.toStringAsFixed(1)}%)',
                                      style: pw.TextStyle(
                                        fontSize: 9,
                                        fontWeight: pw.FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),

              pw.SizedBox(height: 30),

              // Divisão por Pessoa (se for viagem em grupo)
              if (trip.isGroup && spendingByPerson.isNotEmpty) ...[
                pw.Text(
                  'Divisão de Gastos por Pessoa',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 15),
                pw.Container(
                  padding: const pw.EdgeInsets.all(15),
                  decoration: pw.BoxDecoration(
                    color: PdfColors.blue50,
                    border: pw.Border.all(color: PdfColors.blue200),
                    borderRadius: pw.BorderRadius.circular(8),
                  ),
                  child: pw.Column(
                    children: [
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Total de Participantes:',
                            style: const pw.TextStyle(fontSize: 12),
                          ),
                          pw.Text(
                            '${trip.members.length + 1}',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      pw.SizedBox(height: 10),
                      pw.Divider(),
                      pw.SizedBox(height: 10),
                      ...spendingByPerson.entries.map((entry) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            mainAxisAlignment:
                                pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'Pessoa ${entry.key.substring(0, 8)}...',
                                style: const pw.TextStyle(fontSize: 11),
                              ),
                              pw.Text(
                                _currencyFormat.format(entry.value),
                                style: pw.TextStyle(
                                  fontSize: 11,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.blue800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],
                  ),
                ),
                pw.SizedBox(height: 30),
              ],

              // Estatísticas Simplificadas
              pw.Text(
                'Estatísticas Principais',
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 15),

              pw.Row(
                children: [
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.green50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Média/Dia',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _currencyFormat.format(stats.averagePerDay),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Menor Gasto',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _currencyFormat.format(stats.minExpense),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 10),
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.red50,
                        borderRadius: pw.BorderRadius.circular(8),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'Maior Gasto',
                            style: const pw.TextStyle(
                              fontSize: 10,
                              color: PdfColors.grey700,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            _currencyFormat.format(stats.maxExpense),
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.red800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    // Página 2: Gráfico de Evolução Temporal
    if (dailySpending.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Evolução de Gastos ao Longo do Tempo',
                  style: pw.TextStyle(
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 20),

                // Gráfico de Linha
                pw.Container(
                  height: 250,
                  child: _buildLineChart(dailySpending, trip.budget),
                ),

                pw.SizedBox(height: 30),

                // Recomendações
                if (stats.recommendations.isNotEmpty) ...[
                  pw.Text(
                    'Recomendações',
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(15),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      borderRadius: pw.BorderRadius.circular(8),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: stats.recommendations.map((rec) {
                        return pw.Padding(
                          padding: const pw.EdgeInsets.only(bottom: 8),
                          child: pw.Row(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('• ',
                                  style: const pw.TextStyle(fontSize: 12)),
                              pw.Expanded(
                                child: pw.Text(
                                  rec,
                                  style: const pw.TextStyle(fontSize: 11),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
      );
    }

    // Página 3: Detalhamento de Despesas
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

  // TODO: Use this method when adding emoji support to PDF exports
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

  /// Constrói um gráfico de barras horizontais para categorias
  static pw.Widget _buildPieChart(
      Map<String, double> categories, double total) {
    if (categories.isEmpty || total == 0) {
      return pw.Center(child: pw.Text('Sem dados'));
    }

    final sortedCategories = categories.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return pw.Column(
      children: sortedCategories.map((entry) {
        final percent = (entry.value / total);
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 100,
                child: pw.Text(
                  entry.key,
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: (percent * 100).toInt(),
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: _getCategoryColor(entry.key),
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: ((1 - percent) * 100).toInt(),
                        child: pw.Container(),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  _currencyFormat.format(entry.value),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Constrói um gráfico de barras para evolução temporal
  static pw.Widget _buildLineChart(
      Map<DateTime, double> dailyData, double budget) {
    if (dailyData.isEmpty) {
      return pw.Center(child: pw.Text('Sem dados'));
    }

    final sortedEntries = dailyData.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final maxValue = dailyData.values.reduce(math.max);

    // Pega apenas os últimos 10 dias para não sobrecarregar
    final recentEntries = sortedEntries.length > 10
        ? sortedEntries.sublist(sortedEntries.length - 10)
        : sortedEntries;

    return pw.Column(
      children: recentEntries.map((entry) {
        final percent = maxValue > 0 ? (entry.value / maxValue) : 0;
        return pw.Container(
          margin: const pw.EdgeInsets.only(bottom: 8),
          child: pw.Row(
            children: [
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  DateFormat('dd/MM').format(entry.key),
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ),
              pw.Expanded(
                child: pw.Container(
                  height: 20,
                  decoration: pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.circular(4),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Expanded(
                        flex: (percent * 100).toInt().clamp(1, 100),
                        child: pw.Container(
                          decoration: pw.BoxDecoration(
                            color: PdfColors.deepPurple,
                            borderRadius: pw.BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      pw.Expanded(
                        flex: ((1 - percent) * 100).toInt().clamp(0, 99),
                        child: pw.Container(),
                      ),
                    ],
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.SizedBox(
                width: 80,
                child: pw.Text(
                  _currencyFormat.format(entry.value),
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                  textAlign: pw.TextAlign.right,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  /// Retorna cor para cada categoria
  static PdfColor _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'alimentação':
        return PdfColors.orange;
      case 'transporte':
        return PdfColors.blue;
      case 'hospedagem':
        return PdfColors.purple;
      case 'entretenimento':
        return PdfColors.pink;
      case 'compras':
        return PdfColors.green;
      case 'saúde':
        return PdfColors.red;
      default:
        return PdfColors.grey;
    }
  }
}
