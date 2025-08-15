import 'dart:typed_data';
import 'package:fruteira/methods/database.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class PrintPage extends StatelessWidget {
  const PrintPage({required this.commereceType, required this.data, required this.tableName, super.key});
  final List<Item> data;
  final String commereceType;
  final String tableName;
  
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
    final int collumns = length ~/ 33 + 1;
    final List<List<String>> result;
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    if (commereceType == "vendas") {
      result = [];
      for (final Item item in data) {
          result.add([
            item.name, 
            f.format(item.price), 
            "${item.quantity} ${item.type}",
            f.format(item.price * item.quantity)
            ]);
        }
        result.add(["Total"]);
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
    result = List.generate(33, (_) => []);
    int idx = 0;
    for (int i=0; i <= length - 1; i++) {
      i % 32 == 0? idx = 0 : null;
      result[idx].add(data[i].representation());
      idx++;
      }
    return result;
    }
  

  List<String> getHeaders() {
    if (commereceType == "vendas") {
      return ['Produto', 'Preço', 'Peso / Qtd', 'Valores'];
    }
    if (data.length <= 32) {
        return ['Produto', 'Preço'];
    }
    return ["Coluna 1" , "Coluna 2", "Coluna 3"];
  }



Future<Uint8List> _generatePdf(PdfPageFormat format, String title) async {
    final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
    final result = getData();
    final headers = getHeaders();
    final table = pw.TableHelper.fromTextArray(
      data: result,
      headers: headers,
    );
    pdf.addPage(
      pw.Page(
        margin: const pw.EdgeInsets.all(6),
        build: (context) => pw.Column(
          children: [
            pw.Text(tableName),
            pw.Divider(),
            table
          ]
        )
      )
    );

    return pdf.save();
  }
}