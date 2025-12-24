import 'dart:typed_data';
import 'package:fruteira/methods/database.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';




class PrintPage extends StatelessWidget {
  const PrintPage({required this.commereceType, required this.data, required this.tableName, this.useProductId = false, super.key});
  final List<Item> data;
  final String commereceType;
  final String tableName;
  final bool useProductId;
  
  // final content;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: const Text("Listas da Fruteira")),
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
    final int length = data.length;
    final int collumns = length ~/ 58 + 1;
    final List<List<String>> result;
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    if (commereceType == "vendas") {
      result = [];
      for (final Item item in data) {
          if (useProductId) {
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
        result.add([useProductId ? "" : "", "Total"]);
        result.last.add(f.format(sumTable(data)));
        return result;
    }
    if (collumns == 1) {
              result = [];
                for (final Item item in data) {
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
      result[idx].add(data[i].representation());
      idx++;
      }
    return result;
    }
  

  List<String> getHeaders() {
    if (commereceType == "vendas") {
      if (useProductId) {
        return ['Código', 'Produto', 'Preço', 'Peso / Qtd', 'Valores'];
      } else {
        return ['Produto', 'Preço', 'Peso / Qtd', 'Valores'];
      }
    }
    if (data.length <= 57) {
        return ['Produto', 'Preço'];
    }
    return ["Coluna 1" , "Coluna 2", "Coluna 3", "Coluna 4"];
  }



Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final result = getData();
    final headers = getHeaders();
    const double cellFontSize = 8;
    final table = pw.TableHelper.fromTextArray(
      data: result,
      headers: headers,
      headerStyle: pw.TextStyle(fontSize: cellFontSize + 1, fontWeight: pw.FontWeight.bold),
      cellStyle: const pw.TextStyle(fontSize: cellFontSize),
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
              tableName,
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
}