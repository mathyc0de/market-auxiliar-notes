import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/main.dart';
import 'package:fruteira/methods/read_data.dart';
import 'package:fruteira/pages/commerce_page.dart';
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
  late List<Commerce> commerces;

  @override
  void initState() {
    datahandler.getCommerces().then((value) {
      commerces = value;
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
    commerces = await datahandler.getCommerces();
    setState(() {
    });
  }


  Future<void> addCommerce(BuildContext context) async {
    final TextEditingController nameController = TextEditingController();
    bool checkbox = false;
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome do Comércio"),
                CheckboxListTile(
                      title: const Text("Vendas"),
                      value: checkbox, 
                      onChanged: (value) {
                        setState(() {
                          checkbox = value!;
                        });
                  }),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    await datahandler.insertCommerce(
                      Commerce(
                        name: nameController.text,
                        type: boolToInt(checkbox),
                        )
                    );
                    await getData();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Criar comércio"))
              ],
            ),
          ),
        ),
      ));
    return;
  }


  
  Future<void> edit(Commerce commerce) async {
    final TextEditingController nameController = TextEditingController(text: commerce.name);
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: SingleChildScrollView(
            child: Column(
              children: [
                textFormFieldPers(nameController, "Nome do comércio"),
                ElevatedButton(
                  onPressed: () async {
                    if (nameController.text.isEmpty) return;
                    await datahandler.updateCommerce(
                      Commerce(
                        name: nameController.text,
                        type: commerce.type,
                        id: commerce.id,
                        )
                    );
                    await getData();
                    if (!context.mounted) return;
                    Navigator.of(context).pop();
                    }, 
                  child: const Text("Editar comércio"))
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

  Color getRandomColor() {
    final Random random = Random();
    Color color;
    int R, G, B;
    do {
      (R, G, B) = (
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256)
        );
      color = Color.fromARGB(
        255,
        random.nextInt(256),
        random.nextInt(256),
        random.nextInt(256),
      );
    } while ((R + G + B) > 700 || (R + G + B) < 50);
    return color;
  }

  Future<bool> _confirmDelete(BuildContext context, String commerce) async {
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
        content: Text("Você tem certeza que deseja deletar a lista $commerce?")
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
            label: 'Adicionar novo comércio',
            onTap: ()  => addCommerce(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete),
            label: 'Deletar comércio',
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
      commerces.isNotEmpty?
        ListView(
          children: [
            for (int index = 0; index <= commerces.length - 1; index++)
            ListTile(
              onLongPress: () => edit(commerces[index]),
              onTap: () async {
                if (!_editorMode) {
                  final Commerce commerce = commerces[index];
                  
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => CommercePage(
                          commerce: commerce,
                        ),
                      )
                  );
                }
                else {
                  final Commerce commerce = commerces[index];
                  if (await _confirmDelete(context, commerce.name)) {
                    datahandler.removeCommerce(commerce);
                    getData();
                  }
                  _editorMode = false;
                  setState(() {
                    });
                }
              },
              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minVerticalPadding: 0,
              title: Container(
                decoration: BoxDecoration(
                  boxShadow: kElevationToShadow[12],
                  border: Border.all(color: Colors.black),
                  color: getRandomColor(), 
                  borderRadius: const BorderRadius.all(Radius.circular(4))),
                height: 100,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(commerces[index].name, 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 25),),
                    // Text(tables[index].date, style: const TextStyle(color: Colors.grey))
                  ]
                  ),
              )
              ),
            ],
          )
      :
      const Align(
        alignment: Alignment.center,
        child: Text("Adicione um novo comércio!"))
    );
  }
}