import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:market_invoices_app/methods/printer.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/methods/str_manipulation.dart';
import 'package:market_invoices_app/widgets/buttons.dart';
import 'package:market_invoices_app/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;

const int maxProducts = 228;

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
    required this.commerce,
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
  final List<Item> selectedItems = [];
  List<Item> items = [];
  final NumberFormat _currency = NumberFormat.currency(symbol: "R\$");
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  Future<void> _getRows() async {
    items = await db.getItems(widget.id);
    setState(() {});
  }

  @override
  void initState() {
    _getRows().then((_) {
      _built = true;
      setState(() {});
    });
    super.initState();
  }

  void _toggleSelection(Item item) {
    setState(() {
      selectedItems.contains(item)
          ? selectedItems.remove(item)
          : selectedItems.add(item);
    });
  }

  Future<void> addProduct() async {
    if (items.length < maxProducts) {
      await showDialog(
        context: context,
        builder: (context) => AddProductDialog(tableId: widget.id),
      );
      await _getRows();
    }
  }

  Future<void> addMultiple() async {
    final TextEditingController textController = TextEditingController();
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adicionar vários produtos'),
        content: textFormFieldPers(
          textController,
          'Uma linha por produto: NOME PREÇO',
          keyboardType: TextInputType.text,
          maxLength: 2000,
        ),
        actions: [
          TextButton(
            onPressed: () => paste(textController),
            child: const Text('Colar'),
          ),
          FilledButton(
            onPressed: () => rawAdd(textController.text, widget.id),
            child: const Text('Adicionar'),
          ),
        ],
      ),
    );
    textController.dispose();
  }

  Future<void> edit(Item product) async {
    await showDialog(
      context: context,
      builder: (context) => EditProductDialog(product: product),
    );
    await _getRows();
  }

  Future<void> removeProduct(Item produto) async {
    await db.removeItem(produto);
    await _getRows();
  }

  Future<void> printTable() async {
    final data = await db.getItems(widget.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PrintPage(
        commereceType: "precos",
        data: data,
        tableName: "${widget.name}      ${widget.date}",
      ),
    ));
  }

  void paste(TextEditingController controller) {
    Clipboard.getData(Clipboard.kTextPlain).then((value) {
      setState(() => controller.text = value!.text.toString());
    });
  }

  Future<void> rawAdd(String text, int tableid) async {
    final List<Item>? result = textToList(text, tableid);
    if (result == null) return;
    for (final Item item in result) {
      if (items.length >= maxProducts) {
        scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(
          content: Text(
            "O limite de $maxProducts produtos foi atingido, os excedentes não foram adicionados",
          ),
        ));
        break;
      }
      await db.insertItem(item);
    }
    await _getRows();
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<void> rawCopy() async {
    final buffer = StringBuffer();
    for (final item in items) {
      buffer.writeln(item.extract());
    }
    await Clipboard.setData(ClipboardData(text: buffer.toString()));
    scaffoldMessengerKey.currentState!.showSnackBar(
      const SnackBar(content: Text('Dados copiados')),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_built) return const LoadScreen();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final atLimit = items.length >= maxProducts;
    final hasSelection = selectedItems.isNotEmpty;

    return ScaffoldMessenger(
      key: scaffoldMessengerKey,
      child: Scaffold(
        floatingActionButton: themedSpeedDial(
          context: context,
          children: [
            SpeedDialChild(
              label: 'Adicionar produto',
              child: const Icon(Icons.add),
              backgroundColor: colorScheme.secondaryContainer,
              foregroundColor: colorScheme.onSecondaryContainer,
              onTap: addProduct,
            ),
            SpeedDialChild(
              label: 'Adicionar vários',
              child: const Icon(Icons.playlist_add),
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
              onTap: addMultiple,
            ),
            SpeedDialChild(
              label: 'Imprimir',
              child: const Icon(Icons.print_outlined),
              onTap: printTable,
            ),
            SpeedDialChild(
              label: 'Copiar dados',
              child: const Icon(Icons.copy_outlined),
              onTap: rawCopy,
            ),
          ],
        ),
        appBar: AppBar(
          title: Text(
            '${widget.commerce} · ${widget.name}',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w500),
          ),
          centerTitle: true,
          actions: hasSelection
              ? [
                  if (selectedItems.length == 1)
                    IconButton(
                      onPressed: () async {
                        await edit(selectedItems.first);
                        selectedItems.clear();
                        setState(() {});
                      },
                      icon: const Icon(Icons.edit_outlined),
                    ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    onPressed: () async {
                      for (final produto in selectedItems) {
                        await removeProduct(produto);
                      }
                      selectedItems.clear();
                      setState(() {});
                    },
                  ),
                ]
              : [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Center(
                      child: Text(
                        '${items.length}/$maxProducts',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: atLimit ? colorScheme.error : colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                ],
        ),
        body: items.isEmpty
            ? Center(
                child: Text(
                  'Nenhum produto na lista',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 4),
                itemBuilder: (context, index) {
                  final item = items[index];
                  final selected = selectedItems.contains(item);
                  return _PriceItemTile(
                    name: item.name,
                    priceLabel: '${_currency.format(item.price)} / ${item.type}',
                    selected: selected,
                    onTap: () => _toggleSelection(item),
                  );
                },
              ),
      ),
    );
  }
}

class _PriceItemTile extends StatelessWidget {
  const _PriceItemTile({
    required this.name,
    required this.priceLabel,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String priceLabel;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  name,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: selected ? colorScheme.onPrimaryContainer : null,
                  ),
                ),
              ),
              Text(
                priceLabel,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: selected
                      ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                      : colorScheme.onSurfaceVariant,
                ),
              ),
            ],
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
    final brlSymbol = Text(
      'R\$',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );

    return AlertDialog(
      title: const Text('Novo produto'),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              textFormFieldPers(nameController, 'Nome do produto',
                  keyboardType: TextInputType.name),
              textFormFieldPers(
                priceController,
                !isUnitary ? 'Preço / kg' : 'Preço / unidade',
                keyboardType: TextInputType.number,
                prefix: brlSymbol,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unitário'),
                value: isUnitary,
                onChanged: (val) => setState(() => isUnitary = val!),
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
          onPressed: () async {
            if (nameController.text.isEmpty || priceController.text.isEmpty) {
              return;
            }
            await db.insertItem(Item(
              name: nameController.text.capitalize(),
              price: double.parse(
                priceController.text.replaceFirst(RegExp(r','), '.'),
              ),
              type: unitaryCheck(!isUnitary),
              tableId: tableId,
            ));
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Adicionar'),
        ),
      ],
    );
  }
}

class EditProductDialog extends StatelessWidget {
  EditProductDialog({super.key, required this.product})
      : nameController = TextEditingController(text: product.name),
        priceController = TextEditingController(text: product.price.toString());

  final Item product;
  final TextEditingController nameController;
  final TextEditingController priceController;

  @override
  Widget build(BuildContext context) {
    bool isUnitary = product.type != "kg";
    final brlSymbol = Text(
      'R\$',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );

    return AlertDialog(
      title: const Text('Editar produto'),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              textFormFieldPers(nameController, 'Nome do produto',
                  keyboardType: TextInputType.name),
              textFormFieldPers(
                priceController,
                !isUnitary ? 'Preço / kg' : 'Preço / unidade',
                keyboardType: TextInputType.number,
                prefix: brlSymbol,
              ),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Unitário'),
                value: isUnitary,
                onChanged: (val) => setState(() => isUnitary = val!),
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
          onPressed: () async {
            if (nameController.text.isEmpty || priceController.text.isEmpty) {
              return;
            }
            await db.updateItem(Item(
              name: nameController.text.capitalize(),
              price: double.parse(
                priceController.text.replaceFirst(RegExp(r','), '.'),
              ),
              tableId: product.tableId,
              type: unitaryCheck(!isUnitary),
              id: product.id,
            ));
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
