import 'dart:typed_data';
import 'package:fruteira/methods/database.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';




class PrintPage extends StatefulWidget {
  const PrintPage({required this.commereceType, required this.data, required this.tableName, this.useProductId = false, this.commerceId, this.timestamp, super.key});
  final List<Item> data;
  final String commereceType;
  final String tableName;
  final bool useProductId;
  final int? commerceId;
  final int? timestamp;

  @override
  State<PrintPage> createState() => _PrintPageState();
}

class _PrintPageState extends State<PrintPage> {
  double cellFontSize = 8.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text("Listas da Fruteira"),
          actions: [
            IconButton(
              icon: const Icon(Icons.text_decrease),
              onPressed: () {
                setState(() {
                  if (cellFontSize > 4) cellFontSize -= 0.5;
                });
              },
              tooltip: 'Diminuir fonte',
            ),
            Center(
              child: Text('${cellFontSize.toStringAsFixed(1)}'),
            ),
            IconButton(
              icon: const Icon(Icons.text_increase),
              onPressed: () {
                setState(() {
                  if (cellFontSize < 16) cellFontSize += 0.5;
                });
              },
              tooltip: 'Aumentar fonte',
            ),
          ],
        ),
        body: PdfPreview(
          build: (format) => _generatePdf(format, "Lista")
        )
      );
  }

  double sumTable(List<Item> items) {
    double total = 0;
    for (Item produto in items) {
      total += produto.price * produto.quantity;
    }
    return total;
  }

  List<List<String>> getData() {
    final int length = widget.data.length;
    final int collumns = length ~/ 58 + 1;
    final List<List<String>> result;
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    if (widget.commereceType == "vendas") {
      result = [];
      for (final Item item in widget.data) {
          if (widget.useProductId) {
            result.add([
              item.productId?.toString() ?? '-',
              item.name, 
              f.format(item.price), 
              "${item.quantity} ${item.type}",
              f.format(item.price * item.quantity)
              ]);
          } else {
            result.add([
              item.name, 
              f.format(item.price), 
              "${item.quantity} ${item.type}",
              f.format(item.price * item.quantity)
              ]);
          }
        }
        result.add([widget.useProductId ? "" : "", "Total"]);
        result.last.add(f.format(sumTable(widget.data)));
        return result;
    }
    if (collumns == 1) {
              result = [];
                for (final Item item in widget.data) {
                  result.add([
                    item.name, 
                    "${f.format(item.price)} / ${item.quantity}"
                    ]);
                }
                return result;
    }
    result = List.generate(58, (_) => []);
    int idx = 0;
    for (int i=0; i <= length - 1; i++) {
      i % 57 == 0? idx = 0 : null;
      result[idx].add(widget.data[i].representation());
      idx++;
      }
    return result;
    }
  

  List<String> getHeaders() {
    if (widget.commereceType == "vendas") {
      if (widget.useProductId) {
        return ['Código', 'Produto', 'Preço', 'Peso / Qtd', 'Valores'];
      } else {
        return ['Produto', 'Preço', 'Peso / Qtd', 'Valores'];
      }
    }
    if (widget.data.length <= 57) {
        return ['Produto', 'Preço'];
    }
    return ["Coluna 1" , "Coluna 2", "Coluna 3", "Coluna 4"];
  }



Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final result = getData();
    final headers = getHeaders();
    
    // Buscar preços anteriores se useProductId está ativado
    Map<int, double> previousPrices = {};
    if (widget.useProductId && widget.commerceId != null && widget.timestamp != null) {
      for (final item in widget.data) {
        if (item.productId != null) {
          final previousPrice = await db.getPreviousPrice(widget.commerceId!, item.productId!, widget.timestamp!);
          if (previousPrice != null) {
            previousPrices[item.productId!] = previousPrice;
          }
        }
      }
    }
    
    // Criar tabela com coloração condicional
    final table = widget.useProductId && previousPrices.isNotEmpty
        ? _createColoredTable(result, headers, cellFontSize, previousPrices)
        : pw.TableHelper.fromTextArray(
            data: result,
            headers: headers,
            headerStyle: pw.TextStyle(fontSize: cellFontSize + 1, fontWeight: pw.FontWeight.bold),
            cellStyle: pw.TextStyle(fontSize: cellFontSize),
            cellAlignment: pw.Alignment.centerLeft,
            headerPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            cellPadding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
          );
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(4),
        build: (context) => pw.Column(
          children: [
            pw.Text(
              widget.tableName,
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 3),
            pw.Divider(),
            pw.SizedBox(height: 2),
            table
          ]
        )
      )
    );

    return pdf.save();
  }

  /// Cria tabela com linhas coloridas baseado na variação de preço
  pw.Widget _createColoredTable(
    List<List<String>> result, 
    List<String> headers, 
    double cellFontSize,
    Map<int, double> previousPrices
  ) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey300),
          children: headers.map((header) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 3),
            child: pw.Text(
              header,
              style: pw.TextStyle(fontSize: cellFontSize + 1, fontWeight: pw.FontWeight.bold),
            ),
          )).toList(),
        ),
        // Data rows
        ...result.asMap().entries.map((entry) {
          final index = entry.key;
          final row = entry.value;
          
          // Determinar cor da linha e símbolo baseado na comparação de preço
          PdfColor? backgroundColor;
          String priceSymbol = '';
          if (index < widget.data.length && widget.data[index].productId != null) {
            final productId = widget.data[index].productId!;
            if (previousPrices.containsKey(productId)) {
              final previousPrice = previousPrices[productId]!;
              final currentPrice = widget.data[index].price;
              
              if (currentPrice < previousPrice) {
                backgroundColor = PdfColors.green100; // Preço reduziu
                priceSymbol = '  v';
              } else if (currentPrice > previousPrice) {
                backgroundColor = PdfColors.red100; // Preço aumentou
                priceSymbol = '  ^';
              }
              // Se igual, não aplica cor nem símbolo
            }
          }
          
          return pw.TableRow(
            decoration: backgroundColor != null 
                ? pw.BoxDecoration(color: backgroundColor)
                : null,
            children: row.asMap().entries.map((cellEntry) {
              final cellIndex = cellEntry.key;
              final cell = cellEntry.value;
              
              // Adicionar símbolo na coluna de preço (índice 2)
              final displayText = (cellIndex == 2 && priceSymbol.isNotEmpty) 
                  ? '$cell$priceSymbol' 
                  : cell;
              
              return pw.Padding(
                padding: const pw.EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                child: pw.Text(
                  displayText,
                  style: pw.TextStyle(fontSize: cellFontSize),
                ),
              );
            }).toList(),
          );
        }).toList(),
      ],
    );
  }
}