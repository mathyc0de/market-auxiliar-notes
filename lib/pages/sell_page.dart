import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/main.dart';
import 'package:fruteira/methods/printer.dart';
import 'package:fruteira/methods/read_data.dart';
import 'package:fruteira/methods/str_manipulation.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/dialogs.dart' show AddManyDialog;
import 'package:fruteira/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:fruteira/widgets/speech2text.dart';


class ProductsPageWithWeight extends StatefulWidget {
  const ProductsPageWithWeight({
    super.key, 
    required this.id, 
    required this.name, 
    required this.date,
    required this.commerce,
    });

  final String name;
  final int id;
  final String date;
  final String commerce;
  
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
      if (items.isNotEmpty) 
      DataRow(
        cells: [
          const DataCell(Text("Total")),
          DataCell(Text(f.format(sumTable(items)))),
          const DataCell(Text("")),
        ]),

        
    ];
    setState(() {
    });
  }

  @override
  void initState() {
    _getRows().then((val) {
      _built = true;
    });
    super.initState();
  }

  Future<void> addProduct() async {
    if (length < 32) {
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
                  textFormFieldPers(priceController, "Preço", keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false)),
                  textFormFieldPers(weightController, !unitary? "Peso(kg)": "Unidades" , keyboardType: TextInputType.numberWithOptions(decimal: unitary? false : true, signed: false)),
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
                        name: nameController.text.capitalize(), 
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

 


  void _addProductVoice() {
    showDialog(
      context: context, 
      builder: (context) => SpeechDialog(listid: widget.id)
    ).then((val) => _getRows());
  }

  void _addManyProducts() {
    showDialog(
      context: context, 
      builder: (context) => AddManyDialog(listid: widget.id)
    ).then((val) => _getRows());
  }

  
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
                      name: nameController.text.capitalize(), 
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
    _getRows();
  }


  void disableEditor() {
    _editorMode = false;
    _leading = null;
    _getRows();
  }


  Future<void> removeProduct(Item produto) async {
    await datahandler.removeItem(produto);
    await _getRows();
  }


  Future<void> printTable() async {
    List<Item> data = await datahandler.getItems(widget.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>  PrintPage(type: 1, data: data, tableName: "${widget.name}      ${widget.date}"))
      );
  }


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
              label: "Adicionar vários produtos",
              child: const Icon(Icons.add_circle),
              onTap: _addManyProducts
            ),
            SpeedDialChild(
              label: "Adicionar vários produtos por voz",
              child: const Icon(Icons.mic),
              onTap: _addProductVoice,

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
           ],
        ),
        appBar: AppBar(
          backgroundColor: const Color.fromARGB(255, 147, 199, 27),
          title: Text("${widget.commerce} ${widget.name} ${widget.date}", style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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
