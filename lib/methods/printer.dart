import 'dart:typed_data';
import 'package:fruteira/methods/read_data.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:flutter/material.dart';

class PrintPage extends StatelessWidget {
  const PrintPage({required this.type, required this.data, required this.tableName, super.key});
  final List<Item> data;
  final int type;
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
      total += produto.price * produto.weight;
    }
    return total;
  }

  List<List<String>> getData() {
    final int length = data.length;
    final int collumns = length ~/ 32 + 1;
    final List<List<String>> result;
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    if (type == 1) {
      result = [];
      for (final Item item in data) {
          result.add([
            item.name, 
            f.format(item.price), 
            item.wtype == 1? "${item.weight} kg": "${item.weight} Un",
            f.format(item.price * item.weight)
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
                    item.wtype == 1? "${f.format(item.price)} / kg": "${f.format(item.price)} / Un"
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
    if (type == 1) {
      return ['Produto', 'Preço', 'Peso / Qtd', 'Valores'];
    }
    if (data.length <= 33) {
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
        margin: const pw.EdgeInsets.symmetric(vertical: 0, horizontal: 4),
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