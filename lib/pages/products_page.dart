import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/main.dart';
import 'package:fruteira/methods/printer.dart';
import 'package:fruteira/methods/read_data.dart';
import 'package:fruteira/methods/str_manipulation.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;

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



  int boolToInt(bool boolean) {
    if (boolean) return 1;
    return 0;
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
            Row(
              children: [
                Text(produto.wtype == 1?
                 "${f.format(produto.price)} / kg":
                 "${f.format(produto.price)} / Un"
                 ),
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
      bool unitary = false;
      final TextEditingController nameController = TextEditingController();
      final TextEditingController priceController = TextEditingController();
      await showDialog(
        context: context, 
        builder: (context) => AlertDialog(
          content: StatefulBuilder(
            builder: (context, setState) =>  SingleChildScrollView(
              child: Column(
                children: [
                  textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                  textFormFieldPers(priceController, !unitary? "Preço / kg": "Preço / Unidade", keyboardType: TextInputType.number),
                  CheckboxListTile(
                    title: const Text("Unitário"),
                    value: unitary, 
                    onChanged: (val) {
                      setState(() => unitary = val!);
                    }),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                      await datahandler.insertItem(Item(
                        name: nameController.text.capitalize(), 
                        price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')),
                        wtype: boolToInt(!unitary), 
                        listid: widget.id));
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
          textController,
          "Escreva uma lista no formato NOME PREÇO em cada linha",
          keyboardType: TextInputType.text,
          height: 300
          ),
      )
    );
  }

  Future<void> edit(Item product) async {
    bool unitary = product.wtype == 1? false : true;
    final TextEditingController nameController = TextEditingController(text: product.name);
    final TextEditingController priceController = TextEditingController(text: product.price.toString());
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: StatefulBuilder(
          builder: (context, setState) =>  SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome do Produto", keyboardType: TextInputType.name),
                textFormFieldPers(priceController, !unitary? "Preço / kg": "Preço / Unidade", keyboardType: TextInputType.number),
                CheckboxListTile(
                  title: const Text("Unitário"),
                  value: unitary, 
                  onChanged: (val) {
                    setState(() => unitary = val!);
                  }),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty || priceController.text.isEmpty) return;
                    await datahandler.updateItem(Item(
                      name: nameController.text.capitalize(), 
                      price: double.parse(priceController.text.replaceFirst(RegExp(r','), '.')), 
                      listid: widget.id,
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
      builder: (context) =>  PrintPage(type: 0, data: data, tableName: "${widget.name}      ${widget.date}"))
      );
  }

  void paste(TextEditingController controller) {
    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      setState(() {
      controller.text = value!.text.toString();
      });
    }); 
  }

  Future<void> rawAdd(String text, int listid) async {
    final List<Item>? result = textToList(text, listid);
    if (result == null) return;
    for (final Item item in result) {
      if (length >= 96) {
        scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(
          content: Text("O limite de 96 Produtos foi atingido, os excedentes não foram adicionados")));
        break;
        }
      datahandler.insertItem(item);
      length ++;
    }
    await _getRows();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> rawCopy() async {
    String str = "";
    final List<Item> items = await datahandler.getItems(widget.id);
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
    );
  }
}















