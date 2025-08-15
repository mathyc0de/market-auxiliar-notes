import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/methods/printer.dart';
import 'package:fruteira/methods/database.dart';
import 'package:fruteira/methods/str_manipulation.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;



String unitaryCheck(bool boolean) {
    if (boolean) return "kg";
    return "un";
  }

class ProductsPage extends StatefulWidget {
  const ProductsPage({
    super.key, 
    required this.id, 
    required this.name, 
    required this.date, 
    required this.commerce
    });

  final String name;
  final int id;
  final String date;
  final String commerce;
  
  @override
  State<ProductsPage> createState() => _StateProductsPage();
}

class _StateProductsPage extends State<ProductsPage> {
  bool _built = false;
  late List<DataRow> rows;
  bool _editorMode = false;
  int length = 0;
  NumberFormat f = NumberFormat.currency(symbol: "R\$");
  Widget? _leading;
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

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
            Row(
              children: [
                Text("${f.format(produto.price)} / ${produto.type}"),
                if (_editorMode) IconButton(
                  onPressed: () => removeProduct(produto), 
                  icon: const Icon(Icons.do_disturb_on, color: Colors.red)
                  )
                ]
              )
          )
        ] 
      )
    ];
    setState(() {});
  }

  @override
  void initState() {
    _getRows().then((val) {
      _built = true;
    });
    super.initState();
  }
  

  Future<void> addProduct() async {
    if (length < 96) {      
      await showDialog(context: context, builder: (context) => AddProductDialog(tableId: widget.id));
      await _getRows();
      return;
    }
  }

  Future<void> addMultiple() async {
    final TextEditingController textController = TextEditingController();
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () => paste(textController), 
            child: const Text("Colar")
            ),
          TextButton(
            onPressed: () => rawAdd(textController.text, widget.id),
            child: const Text("Adicionar Produtos")
            )
        ],
        content: textFormFieldPers(
          maxLength: 2000,
          textController,
          "Escreva uma lista no formato NOME PREÇO em cada linha",
          keyboardType: TextInputType.text,
          height: 300
          ),
      )
    );
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
      builder: (context) =>  PrintPage(commereceType: "precos", data: data, tableName: "${widget.name}      ${widget.date}"))
      );
  }

  void paste(TextEditingController controller) {
    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      setState(() {
      controller.text = value!.text.toString();
      });
    }); 
  }

  Future<void> rawAdd(String text, int tableid) async {
    final List<Item>? result = textToList(text, tableid);
    if (result == null) return;
    for (final Item item in result) {
      if (length >= 96) {
        scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(
          content: Text("O limite de 96 Produtos foi atingido, os excedentes não foram adicionados")));
        break;
        }
      db.insertItem(item);
      length ++;
    }
    await _getRows();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> rawCopy() async {
    String str = "";
    final List<Item> items = await db.getItems(widget.id);
    for (Item item in items) {
      str += "${item.extract()}\n";
    }
     await Clipboard.setData(ClipboardData(text: str));
    scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(
      content: Text("Dados copiados para a área de transferência")));
      
  }
  




  @override
  Widget build(BuildContext context) {
    if (!_built) return loadScreen();
    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: SafeArea(
        bottom: true,
        child: Scaffold(
          floatingActionButton: SpeedDial(
            elevation: 0,
            backgroundColor: const Color.fromARGB(30, 106, 117, 117),
            foregroundColor: Colors.lightGreen,
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
              ),
              SpeedDialChild(
                label: "Adicionar vários produtos",
                child: const Icon(Icons.add_circle_sharp),
                onTap: addMultiple,
              ),
              SpeedDialChild(
                label: "Copiar os dados",
                child: const Icon(Icons.copy),
                onTap: () async {await rawCopy();}
              )
             ],
          ),
          appBar: AppBar(
            backgroundColor: const Color.fromARGB(255, 147, 199, 27),
            title: Text("${widget.commerce} ${widget.name} ${widget.date}",
            style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
            centerTitle: true,
            leading: _leading
            
          ),
          body:
              SingleChildScrollView(
                child: DataTable(
                    columns: const [
                      DataColumn(label: Text("Produto")),
                      DataColumn(label: Text("Preço")),
                    ],
                    rows: rows
                    ),
              ),
        ),
      ),
    );
  }
}







class AddProductDialog extends StatelessWidget {
  AddProductDialog({super.key, required this.tableId});
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final int tableId;

  @override
  Widget build(BuildContext context) {
    bool isUnitary = false;
    return AlertDialog(
      content: StatefulBuilder(builder: (context, setState) => SingleChildScrollView(
        child: Column(
                children: [
                  textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                  textFormFieldPers(priceController, !isUnitary? "Preço / kg": "Preço / Unidade", keyboardType: TextInputType.number),
                  CheckboxListTile(
                    title: const Text("Unitário"),
                    value: isUnitary, 
                    onChanged: (val) {
                      setState(() => isUnitary = val!);
                    }),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                      await db.insertItem(Item(
                        name: nameController.text.capitalize(), 
                        price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')),
                        type: unitaryCheck(!isUnitary), 
                        tableId: tableId));
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
    priceController = TextEditingController(text: product.price.toString());

  final Item product;
  final TextEditingController nameController;
  final TextEditingController priceController;


  @override
  Widget build(BuildContext context) {
    bool isUnitary = product.type == "kg" ? false : true;
    return Dialog(
      child: StatefulBuilder(
          builder: (context, setState) =>  SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                textFormFieldPers(priceController, !isUnitary? "Preço / kg": "Preço / Unidade", keyboardType: TextInputType.number),
                CheckboxListTile(
                  title: const Text("Unitário"),
                  value: isUnitary, 
                  onChanged: (val) {
                    setState(() => isUnitary = val!);
                  }),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                    await db.updateItem(Item(
                      name: nameController.text.capitalize(), 
                      price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')), 
                      tableId: product.tableId,
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
