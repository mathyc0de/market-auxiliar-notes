import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/methods/database.dart';
import 'package:fruteira/pages/products_page.dart';
import 'package:fruteira/pages/sell_page.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/loadscreen.dart';

class CommercePage extends StatefulWidget {
  const CommercePage({super.key, required this.commerce});
  final Commerce commerce;

  @override
  State<CommercePage> createState() => _CommercePageState();
}

class _CommercePageState extends State<CommercePage> {
  bool _built = false;
  bool _editorMode = false;
  late List<Tables> tables;

  @override
  void initState() {
    db.getTables(widget.commerce.id!).then((value) {
      tables = value;
      _built = true;
      setState(() {
      });
    });
    super.initState();
  }

  Future<void> getData() async {
    tables = await db.getTables(widget.commerce.id!);
    setState(() {
    });
  }

  String __buildDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }


  Future<void> addList(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome da Lista (opcional)"),
                ElevatedButton(
                  onPressed: () async {
                    await db.insertTable(
                      Tables(
                        name: nameController.text,
                        date: __buildDate(DateTime.now()),
                        commerceId: widget.commerce.id!,
                        )
                    );
                    await getData();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Criar lista"))
              ],
            ),
          ),
        ),
      ));
    return;
  }

  Future<void> edit(Tables table) async {
    final TextEditingController nameController = TextEditingController(text: table.name);
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome da Lista"),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    await db.updateTable(
                      Tables(
                        name: nameController.text,
                        date: table.date,
                        id: table.id,
                        commerceId: widget.commerce.id!
                        )
                    );
                    await getData();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Editar lista"))
              ],
            ),
          ),
        ),
    );
    return;
  }

  void removeList() {
    setState(() {
      _editorMode = true;
    });
    return;
  }

  Future<bool> _confirmDelete(BuildContext context, String tableName) async {
    bool? result = await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmar'),
            ),
        ],
        content: Text("Você tem certeza que deseja deletar a lista $tableName?")
      )
    );
    result ??= false;
    return result;
  }


  Widget productsPage() {
    return tables.isNotEmpty?
        ListView(
          children: [
            for (int index = 0; index <= tables.length - 1; index++)
            ListTile(
              onLongPress: () => edit(tables[index]),
              onTap: () async {
                if (!_editorMode) {
                  final Tables table = tables[index];
                  widget.commerce.type == "precos" ?
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductsPage(
                        commerce: widget.commerce.name,
                        id: table.id!, 
                        name: table.name,
                        date: table.date,
                        ),
                      )
                  )
                  :
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductsPageWithWeight(
                        commerce: widget.commerce.name,
                        id: table.id!, 
                        name: table.name,
                        date: table.date,
                        ),
                      )
                  );
                }
                else {
                  final Tables table = tables[index];
                  if (await _confirmDelete(context, table.name)) {
                    db.removeTable(table);
                    getData();
                  }
                  _editorMode = false;
                  setState(() {
                    });
                }
              },

              title: Text("${tables[index].name} ${tables[index].date}")
              ),
            ],
          )
      :
      const Align(
        alignment: Alignment.center,
        child: Text("Crie uma nova lista!"));
  }


  @override
  Widget build(BuildContext context) {
    if (!_built) return loadScreen();
    return Scaffold(
      floatingActionButton:SpeedDial(
        animatedIcon: AnimatedIcons.menu_close,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Adicionar nova lista',
            onTap: ()  => addList(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            label: 'Deletar lista',
            onTap: removeList,
          ),
          // SpeedDialChild(
          //   child: const Icon(Icons.attach_money),
          //   label: 'Adicionar Pagamento',
          //   onTap: add
          // )
        ],
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 147, 199, 27),
        title: Text(widget.commerce.name, style: const TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
        leading: _editorMode? const Icon(Icons.do_not_disturb_on_rounded, color: Colors.red): null,
      ),
      body: productsPage()
    );
  }
}