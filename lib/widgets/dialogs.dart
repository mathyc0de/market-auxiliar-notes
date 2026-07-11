import 'dart:convert' show jsonDecode;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard;
import 'package:market_invoices_app/methods/ai_services.dart' show Prompt, sendToGroq;
import 'package:market_invoices_app/methods/database.dart' show Item, db;
import 'package:market_invoices_app/methods/str_manipulation.dart' show speechToList;
import 'package:market_invoices_app/widgets/buttons.dart';

class AddManyDialog extends StatefulWidget {
  const AddManyDialog({super.key, required this.tableid});
  final int tableid;

  @override
  State<AddManyDialog> createState() => _AddManyDialogState();
}

class _AddManyDialogState extends State<AddManyDialog> {
  final TextEditingController _controller = TextEditingController();
  String? _out;
  List<Item> _items = [];

  void paste(TextEditingController controller) {
    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      setState(() => controller.text = value!.text.toString());
    });
  }

  Future<void> addToDB() async {
    try {
      for (final item in _items) {
        await db.insertItem(item);
      }
    } catch (e) {
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (context) => const ErrorDialog(
          errorMessage:
              'Houve um erro ao adicionar os itens. Verifique quantidade, nome e preço.',
        ),
      );
    }
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<bool> uploadStatus() async {
    if (_out == null) {
      await showDialog(
        context: context,
        builder: (context) => const ErrorDialog(
          errorMessage:
              'Erro de conexão. Verifique sua internet e tente novamente.',
        ),
      );
      return false;
    }
    return true;
  }

  Future<void> processs() async {
    _out = await sendToGroq(_controller.text, Prompt.sellPagePrompt);
    if (!(await uploadStatus())) {
      if (!mounted) return;
      Navigator.of(context).pop();
      return;
    }
    _controller.text = '';
    _items = speechToList(jsonDecode(_out!), widget.tableid);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (_items.isNotEmpty) {
      return AlertDialog(
        title: const Text('Confirmar produtos'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final item in _items)
                  Material(
                    color: colorScheme.surfaceContainerLow,
                    borderRadius: BorderRadius.circular(8),
                    child: ListTile(
                      dense: true,
                      title: Text(
                        '${item.quantity} ${item.type} ${item.name}',
                        style: theme.textTheme.bodyMedium,
                      ),
                      subtitle: Text('R\$ ${item.price}'),
                      trailing: IconButton(
                        icon: Icon(Icons.close, color: colorScheme.error),
                        onPressed: () => setState(() => _items.remove(item)),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: addToDB,
            child: const Text('Adicionar'),
          ),
        ],
      );
    }

    return AlertDialog(
      title: const Text('Adicionar por descrição'),
      content: SizedBox(
        height: 150,
        child: textFormFieldPers(
          _controller,
          'Descreva os produtos',
          maxLength: 1000,
          expands: true,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => paste(_controller),
          child: const Text('Colar'),
        ),
        FilledButton(
          onPressed: processs,
          child: const Text('Processar'),
        ),
      ],
    );
  }
}

class ErrorDialog extends StatelessWidget {
  const ErrorDialog({super.key, required this.errorMessage});
  final String errorMessage;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Erro'),
      content: SingleChildScrollView(child: Text(errorMessage)),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    );
  }
}
