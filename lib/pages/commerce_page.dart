import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:fruteira/main.dart';
import 'package:fruteira/methods/read_data.dart';
import 'package:fruteira/pages/products_page.dart';
import 'package:fruteira/pages/sell_page.dart';
import 'package:fruteira/widgets/buttons.dart';
import 'package:fruteira/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;

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
  NumberFormat f = NumberFormat.currency(symbol: "R\$");

  @override
  void initState() {
    datahandler.getTables(widget.commerce.id!).then((value) {
      tables = value;
      _built = true;
      setState(() {
      });
    });
    super.initState();
  }

  int boolToInt(bool boolean) {
    if (boolean) return 1;
    return 0;
  }

  Future<void> getData() async {
    tables = await datahandler.getTables(widget.commerce.id!);
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
                    await datahandler.insertTable(
                      Tables(
                        name: nameController.text,
                        date: __buildDate(DateTime.now()),
                        commerceid: widget.commerce.id!
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
    if (widget.commerce.type == 1) return editSell(table);
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
                        date: table.date,
                        id: table.id,
                        commerceid: widget.commerce.id!
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


  
  Future<void> editSell(Tables table) async {
    bool checkbox = false;
    final TextEditingController nameController = TextEditingController(text: table.name);
    final TextEditingController payment = TextEditingController();
    payment.text = "0";
    await showDialog(
      context: context, 
      builder: (context) => AlertDialog(
        content: StatefulBuilder(
          builder: (context, setState) => SingleChildScrollView(
              child: Column(
                children: [
                  textFormFieldPers(nameController, "Nome da Lista"),
                  textFormFieldPers(payment, "Adicionar Pagamento", enabled: !checkbox, keyboardType: const TextInputType.numberWithOptions(signed: false, decimal: true)),
                  CheckboxListTile(
                        title: const Text("Marcar como pago"),
                        value: checkbox, 
                        onChanged: (value) {
                          setState(() {
                            checkbox = value!;
                            checkbox? payment.text = "${table.total}" : payment.text = "0";
                          });
                    }),
                  ElevatedButton(
                    onPressed: () async {
                      if (nameController.text.isEmpty) return;
                      await datahandler.updateTable(
                        Tables(
                          name: nameController.text,
                          date: table.date,
                          id: table.id,
                          commerceid: widget.commerce.id!,
                          paid: double.tryParse(payment.text) ?? 0
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

  _updateTable() {
    datahandler.getTables(widget.commerce.id!).then((value) {
      tables = value;
      setState(() {
      });
      });
  }

  double _sumTotalWallet() {
    double sum = 0;
    for (Tables table in tables) {
      sum += table.total;
    }
    return sum;
  }

  double _sumTotalPayment() {
    double sum = 0;
    for (Tables table in tables) {
      sum += table.paid;
    }
    return sum;
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
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => ProductsPage(
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
                    datahandler.removeTable(table);
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


  Widget sellPage() {
    return tables.isNotEmpty? Column(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height / 1.5,
              child: ListView(
              children: [
                for (int index = 0; index <= tables.length - 1; index++)
                ListTile(
                  tileColor: 
                  (tables[index].paid >= tables[index].total && tables[index].paid > 0) ? Colors.black12 : Colors.white,
                  onLongPress: () => edit(tables[index]),
                  onTap: () async {
                    if (!_editorMode) {
                      final Tables table = tables[index];              
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => ProductsPageWithWeight(
                            commerce: widget.commerce.name,
                            id: table.id!, 
                            name: table.name,
                            date: table.date,
                            paid: table.paid,
                            ),
                          )
                      ).then((val) => _updateTable());
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
              
                  title: _getListCard(tables[index])
                  ),
                ],
              ),
          ),
        const Divider(),
        Text("Saldo devedor: ${f.format(_sumTotalWallet() - _sumTotalPayment())}", 
        style: const TextStyle(
          fontWeight: FontWeight.bold, 
          fontSize: 20
          ))
        ],
      )
      :       
      const Align(
        alignment: Alignment.center,
        child: Text("Crie uma nova lista!"));
  }

  // Future<void> addPayment() async {
    
  // }


  

  Row _getListCard(Tables table) {
    if (widget.commerce.type == 0) {
      return Row(
        children: [
          Text("${table.name} ${table.date}")
      ]);
    }
    return Row(
      children: [
        Text("${table.name} ${table.date}"),
        const Spacer(),
        Text("Pgto: ${f.format(table.paid)}/${f.format(table.total)}",
        style: TextStyle(color: table.paid >= table.total? Colors.green : Colors.red ),
        )
      ],
    );
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
      body: widget.commerce.type == 0 ?  productsPage() : sellPage()
    );
  }
}