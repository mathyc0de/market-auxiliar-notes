import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/main.dart';
import 'package:fruteira/methods/printer.dart';
import 'package:fruteira/methods/read_data.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;


class ProductsPageWithWeight extends StatefulWidget {
  const ProductsPageWithWeight({super.key, required this.id, required this.name, required this.date});
  final String name;
  final int id;
  final String date;
  
  @override
  State<ProductsPageWithWeight> createState() => _StateProductsPageWithWeight();
}

class _StateProductsPageWithWeight extends State<ProductsPageWithWeight> {

  bool _built = false;
  late List<DataRow> rows;
  int length = 0;
  bool _editorMode = false;
  NumberFormat f = NumberFormat.currency(symbol: "R\$");
  Widget? _leading;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();



  double sumTable(List<Item> items) {
    double total = 0;
    for (Item produto in items) {
      total += produto.price * produto.weight;
    }
    return total;
  }

  Future<void> _getRows() async {
    final List<Item> items = await datahandler.getItems(widget.id);
    length = items.length;
    rows = 
    [ 
      for (Item produto in items)
      DataRow(
        cells: [
          DataCell(
            onLongPress: () => edit(produto),
            Text(produto.name)
          ),
          DataCell(
            Text(f.format(produto.price))
          ),
          DataCell(
            Row(
              children: [
                Text(produto.wtype == 1? "${produto.weight} kg" : "${produto.weight.toInt()} unidade(s)"),
                if (_editorMode) IconButton(
                  onPressed: () => removeProduct(produto), 
                  icon: const Icon(Icons.do_disturb_on, color: Colors.red)
                  )
                ]
              )
          ),
        ] 
      ),
      if (items.isNotEmpty) DataRow(
        cells: [
          const DataCell(Text("Total")),
          DataCell(Text(f.format(sumTable(items)))),
          const DataCell(Text("")),
        ])
    ];
  }

  @override
  void initState() {
    _getRows().then((val) {
      _built = true;
      setState(() {});
    });
    super.initState();
  }

  Future<void> addProduct() async {
    print(length);
    if (length < 27) {
      bool unitary = false;
      final TextEditingController nameController = TextEditingController();
      final TextEditingController priceController = TextEditingController();
      final TextEditingController weightController = TextEditingController();
      await showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          content: StatefulBuilder(
            builder: (context, setState) =>  SingleChildScrollView(
              child: Column(
                children: [
                  textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                  textFormFieldPers(priceController, "Preço", keyboardType: TextInputType.number),
                  textFormFieldPers(weightController, !unitary? "Peso(kg)": "Unidades" , keyboardType: TextInputType.number),
                  CheckboxListTile(
                      value: unitary,
                      onChanged: (val) {
                        setState(() => unitary = val!);
                        },
                      title: const Text("Unitário"),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                      await datahandler.insertItem(Item(
                        name: nameController.text, 
                        price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')), 
                        listid: widget.id,
                        wtype: boolToInt(!unitary),
                        weight: double.parse(weightController.text.replaceFirst(RegExp(r','), '.'))
                        ));
                      await _getRows();
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      }, 
                    child: const Text("Adicionar produto"))
                ],
              ),
            ),
          ),
        ));
      await _getRows();
      setState(() {
      });
      return;
      }
      scaffoldMessengerKey
      .currentState!
      .showSnackBar(const SnackBar(
        content: Text(
          "Você atingiu o limite de produtos adicionados nesta lista."
          )
        )
      );
  }

  // Future<void> addMultiple() async {
  //   final TextEditingController textController = TextEditingController();
  //   await showDialog(
  //     context: context, 
  //     builder: (context) => AlertDialog(
  //       actions: [
  //         TextButton(
  //           onPressed: () => paste(textController), 
  //           child: const Text("Colar")
  //           ),
  //         TextButton(
  //           onPressed: () => textToList(textController.text),
  //           child: const Text("Adicionar Produtos")
  //           )
  //       ],
  //       content: textFormFieldPers(
  //         textController,
  //         "Escreva uma lista no formato NOME PREÇO em cada linha",
  //         keyboardType: TextInputType.text,
  //         height: 300
  //         ),
  //     )
  //   );
  // }

  
  int boolToInt(bool boolean) {
    if (boolean) return 1;
    return 0;
  }

  Future<void> edit(Item product) async {
    bool unitary = product.wtype == 1? false : true;
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController priceController = TextEditingController(text: product.price.toString());
    final TextEditingController weightController = TextEditingController(text: product.weight.toString());
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: StatefulBuilder(
          builder: (context, setState) =>  SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                textFormFieldPers(priceController, "Preço", keyboardType: TextInputType.number),
                textFormFieldPers(weightController, !unitary? "Peso(kg)": "Unidades" , keyboardType: TextInputType.number),
                CheckboxListTile(
                  value: unitary,
                  onChanged: (val) {
                    setState(() => unitary = val!);
                    },
                  title: const Text("Unitário"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || priceController.text.isEmpty || weightController.text.isEmpty) return;
                    await datahandler.updateItem(Item(
                      name: nameController.text, 
                      price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')), 
                      listid: widget.id,
                      weight: double.parse(weightController.text.replaceFirst(RegExp(r','), '.')),
                      wtype: boolToInt(!unitary),
                      id: product.id
                      ));
                    await _getRows();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Atualizar produto"))
              ],
            ),
          ),
        ),
      ));
    return;
  }

  
  void editorMode() {
    _editorMode = true;
    _leading = IconButton(
      onPressed: disableEditor, 
      icon: const Icon(Icons.delete, color: Colors.red)
    );
    _getRows().then((value) {
      setState(() {});
    });
  }


  void disableEditor() {
    _editorMode = false;
    _leading = null;
    _getRows().then((value) {
      setState(() {});
    });
  }


  Future<void> removeProduct(Item produto) async {
    await datahandler.removeItem(produto);
    await _getRows();
    setState(() {
    });
  }


  Future<void> printTable() async {
    List<Item> data = await datahandler.getItems(widget.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>  PrintPage(type: 1, data: data, tableName: "${widget.name}      ${widget.date}"))
      );
  }

  // void paste(TextEditingController controller) {
  //   Clipboard.getData(Clipboard.kTextPlain).then((value) {
  //     setState(() {
  //     controller.text = value!.text.toString();
  //     });
  //   }); 
  // }
  

  // void textToList(String text) {
  //   return;
  // }


  @override
  Widget build(BuildContext context) {
    if (!_built) return loadScreen();
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        floatingActionButton: SpeedDial(
           animatedIcon: AnimatedIcons.menu_close,
           children: [
            SpeedDialChild(
              label: "Adicionar Produto",
              child: const Icon(Icons.add),
              onTap: addProduct,
            ),
            SpeedDialChild(
              label: "Remover Produto",
              child: const Icon(Icons.delete),
              onTap: editorMode
            ),
            SpeedDialChild(
              label: "Imprimir Tabela",
              child: const Icon(Icons.print),
              onTap: printTable
            )
            // SpeedDialChild(
            //   label: "Adicionar vários produtos",
            //   child: const Icon(Icons.add_circle_sharp),
            //   onTap: addMultiple,
            // )
           ],
        ),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 147, 199, 27),
          title: Text(widget.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white),),
          centerTitle: true,
          leading: _leading
          
        ),
        body:
            SingleChildScrollView(
              child: DataTable(
                columns: const [
                  DataColumn(label: Text("Produto")),
                  DataColumn(label: Text("Preço")),
                  DataColumn(label: Text("Peso/Un")),
                  ],
                rows: rows
              ),
            )
      ),
    );
  }
}
