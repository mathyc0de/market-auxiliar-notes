import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/methods/printer.dart';
import 'package:fruteira/methods/database.dart';
import 'package:fruteira/methods/str_manipulation.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/dialogs.dart' show AddManyDialog;
import 'package:fruteira/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:fruteira/widgets/speech2text.dart';


String unitaryCheck(bool boolean) {
    if (boolean) return "kg";
    return "un";
  }

double division(num op1, num op2) => (op1 / op2).toDouble();
double multiplication(num op1, num op2) => (op1 * op2).toDouble();

void autoComplete(TextEditingController reference, TextEditingController option1, TextEditingController option2, {double Function(num, num) operation = multiplication}) {
  if (double.tryParse(reference.text) != null) {
    if (double.tryParse(option2.text) != null) { 
      option1.text = (operation(double.parse(reference.text), double.parse(option2.text))).toString();
    }
    else if (double.tryParse(option1.text) != null) {
      option2.text = (operation(double.parse(reference.text), double.parse(option1.text))).toString();
    }
  }
}


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
      total += produto.price * produto.quantity;
    }
    return total;
  }

  Future<void> _getRows() async {
    final List<Item> items = await db.getItems(widget.id);
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
                Text("${produto.quantity} ${produto.type}"),
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
      await showDialog(context: context, builder: (context) => AddProductDialog(tableId: widget.id));
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
      builder: (context) => SpeechDialog(tableid: widget.id)
    ).then((val) => _getRows());
  }

  void _addManyProducts() {
    showDialog(
      context: context, 
      builder: (context) => AddManyDialog(tableid: widget.id)
    ).then((val) => _getRows());
  }

  
  String unitaryCheck(bool boolean) {
    if (boolean) return "un";
    return "kg";
  }

  Future<void> edit(Item product) async {
    await showDialog(context: context, builder: (context) => EditProductDialog(product: product));
    await _getRows();
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
    await db.removeItem(produto);
    await _getRows();
  }


  Future<void> printTable() async {
    List<Item> data = await db.getItems(widget.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) =>  PrintPage(commereceType: "vendas", data: data, tableName: "${widget.name}      ${widget.date}"))
      );
  }


  @override
  Widget build(BuildContext context) {
    if (!_built) return loadScreen();
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        floatingActionButton: SpeedDial(
          backgroundColor: const Color.fromARGB(30, 106, 117, 117),
          foregroundColor: Colors.lightGreen,
          elevation: 0,
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
            SafeArea(
              bottom: true,
              child: SingleChildScrollView(
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text("Produto")),
                    DataColumn(label: Text("Preço")),
                    DataColumn(label: Text("Peso/Un")),
                    ],
                  rows: rows
                ),
              ),
            )
      ),
    );
  }
}



class AddProductDialog extends StatelessWidget {
  AddProductDialog({super.key, required this.tableId});
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  final int tableId;

  @override
  Widget build(BuildContext context) {
    bool isUnitary = false;
    return AlertDialog(
      content: StatefulBuilder(builder: (context, setState) => SingleChildScrollView(
        child: Column(
                children: [
                  textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                  textFormFieldPers(priceController, "Preço", keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false), onChanged: (p0) => autoComplete(priceController, totalController, weightController)),
                  textFormFieldPers(weightController, !isUnitary? "Peso(kg)": "Unidades" , keyboardType: TextInputType.numberWithOptions(decimal: isUnitary? false : true, signed: false), onChanged: (p0) => autoComplete(weightController, totalController, priceController)),
                  textFormFieldPers(totalController, "Total (R\$)", keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (p0) => autoComplete(totalController, weightController, priceController, operation: division)),
                  CheckboxListTile(
                      value: isUnitary,
                      onChanged: (val) {
                        setState(() => isUnitary = val!);
                        },
                      title: const Text("Unitário"),
                    ),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                      await db.insertItem(Item(
                        name: nameController.text.capitalize(), 
                        price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')), 
                        tableId: tableId,
                        type: unitaryCheck(!isUnitary),
                        quantity: double.parse(weightController.text.replaceFirst(RegExp(r','), '.'))
                        ));
                      if (!context.mounted) return;
                      Navigator.of(context).pop();
                      }, 
                    child: const Text("Adicionar produto"))
                ],
              ),
      )),
    );
  }
}



class EditProductDialog extends StatelessWidget {
  EditProductDialog({super.key, required this.product}): 
    nameController = TextEditingController(text: product.name),
    priceController = TextEditingController(text: product.price.toString()),
    weightController = TextEditingController(text: product.quantity.toString()),
    totalController = TextEditingController(text: (product.price * product.quantity).toString());

  final Item product;
  final TextEditingController nameController;
  final TextEditingController priceController;
  final TextEditingController weightController;
  final TextEditingController totalController;


  @override
  Widget build(BuildContext context) {
    bool isUnitary = product.type == "kg" ? false : true;
    return AlertDialog(
      content: StatefulBuilder(
          builder: (context, setState) =>  SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                textFormFieldPers(priceController, "Preço", keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: false), onChanged: (p0) => autoComplete(priceController, totalController, weightController)),
                textFormFieldPers(weightController, !isUnitary? "Peso(kg)": "Unidades" , keyboardType: TextInputType.numberWithOptions(decimal: isUnitary? false : true, signed: false), onChanged: (p0) => autoComplete(weightController, totalController, priceController)),
                textFormFieldPers(totalController, "Total (R\$)", keyboardType: const TextInputType.numberWithOptions(decimal: true), onChanged: (p0) => autoComplete(totalController, weightController, priceController, operation: division)),
                CheckboxListTile(
                  value: isUnitary,
                  onChanged: (val) {
                    setState(() => isUnitary = val!);
                    },
                  title: const Text("Unitário"),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || priceController.text.isEmpty || weightController.text.isEmpty) return;
                    await db.updateItem(Item(
                      name: nameController.text.capitalize(), 
                      price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')), 
                      tableId: product.tableId,
                      quantity: double.parse(weightController.text.replaceFirst(RegExp(r','), '.')),
                      type: unitaryCheck(!isUnitary),
                      id: product.id
                      ));
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Atualizar produto"))
              ],
            ),
          ),
        ),
    );
  }
}
