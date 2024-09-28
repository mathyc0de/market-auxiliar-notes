import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/main.dart';
import 'package:fruteira/methods/read_data.dart';
import 'package:fruteira/pages/products_page.dart';
import 'package:fruteira/pages/sell_page.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/loadscreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _built = false;
  bool _editorMode = false;
  late List<Tables> tables;

  @override
  void initState() {
    datahandler.getTables().then((value) {
      tables = value;
      _built = true;
      setState(() {});
    });
    super.initState();
  }

  int boolToInt(bool boolean) {
    if (boolean) return 1;
    return 0;
  }

  Future<void> getData() async {
    tables = await datahandler.getTables();
    setState(() {
    });
  }

  String __buildDate(DateTime date) {
    return "${date.day}/${date.month}/${date.year}";
  }


  Future<void> addList(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    bool checkbox = false;
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome da Lista"),
                    CheckboxListTile(
                      title: const Text("Lista para Vendas"),
                      value: checkbox, 
                      onChanged: (value) {
                        setState(() {
                          checkbox = value!;
                        });
                      }
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    await datahandler.insertTable(
                      Tables(
                        name: nameController.text,
                        type: boolToInt(checkbox),
                        date: __buildDate(DateTime.now())
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
                    await datahandler.updateTable(
                      Tables(
                        name: nameController.text,
                        type: table.type,
                        date: table.date,
                        id: table.id,
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
        ],
      ),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 147, 199, 27),
        title: const Text("Listas da Fruteira", style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white),),
        centerTitle: true,
        leading: _editorMode? const Icon(Icons.do_not_disturb_on_rounded, color: Colors.red): null,
      ),
      body: 
      tables.isNotEmpty?
        ListView(
          children: [
            for (int index = 0; index <= tables.length - 1; index++)
            ListTile(
              onLongPress: () => edit(tables[index]),
              onTap: () async {
                if (!_editorMode) {
                  final Tables table = tables[index];
                  table.type == 0 ?

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductsPage(
                        id: table.id!, 
                        name: table.name,
                        date: table.date,
                        ),
                      )
                  ):

                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductsPageWithWeight(
                        id: table.id!, 
                        name: table.name,
                        date: table.date
                        ),
                      )
                  );
                }
                else {
                  final Tables table = tables[index];
                  if (await _confirmDelete(context, table.name)) {
                    datahandler.removeTable(table);
                    getData();
                  }
                  _editorMode = false;
                  setState(() {
                    });
                }
              },

              title: Row(
                children: [
                  Text(tables[index].name),
                  const Spacer(),
                  Text(tables[index].date, style: const TextStyle(color: Colors.grey))
                ]
                )
              ),
            ],
          )
      :
      const Align(
        alignment: Alignment.center,
        child: Text("Crie uma nova lista!"))
    );
  }
}