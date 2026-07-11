import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:market_invoices_app/methods/printer.dart';
import 'package:market_invoices_app/pages/thermal_print_page.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/methods/str_manipulation.dart';
import 'package:market_invoices_app/widgets/buttons.dart';
import 'package:market_invoices_app/widgets/dialogs.dart' show AddManyDialog;
import 'package:market_invoices_app/widgets/loadscreen.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:market_invoices_app/widgets/speech2text.dart';

const int maxProducts = 57;

String unitaryCheck(bool boolean) {
  if (boolean) return "kg";
  return "un";
}

double division(num op1, num op2) => (op1 / op2).toDouble();
double multiplication(num op1, num op2) => (op1 * op2).toDouble();

void autoComplete(
  TextEditingController reference,
  TextEditingController option1,
  TextEditingController option2, {
  double Function(num, num) operation = multiplication,
}) {
  if (double.tryParse(reference.text) != null) {
    if (double.tryParse(option2.text) != null) {
      option1.text = operation(
        double.parse(reference.text),
        double.parse(option2.text),
      ).toString();
    } else if (double.tryParse(option1.text) != null) {
      option2.text = operation(
        double.parse(reference.text),
        double.parse(option1.text),
      ).toString();
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
  final Commerce commerce;

  @override
  State<ProductsPageWithWeight> createState() => _StateProductsPageWithWeight();
}

class _StateProductsPageWithWeight extends State<ProductsPageWithWeight> {
  bool _built = false;
  List<Item> items = [];
  final List<Item> selectedItems = [];
  final NumberFormat _currency = NumberFormat.currency(symbol: "R\$");
  final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  double sumTable(List<Item> items) {
    double total = 0;
    for (final produto in items) {
      total += produto.price * produto.quantity;
    }
    return total;
  }

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

  void _showLimitSnackBar() {
    scaffoldMessengerKey.currentState!.showSnackBar(const SnackBar(
      content: Text('Limite de produtos atingido nesta lista.'),
    ));
  }

  Future<void> addProduct() async {
    if (items.length >= maxProducts) return;
    await showDialog(
      context: context,
      builder: (context) => AddProductDialog(
        tableId: widget.id,
        commerceId: widget.commerce.id!,
        useProductId: widget.commerce.useProductId,
      ),
    );
    await _getRows();
  }

  void _addProductVoice() {
    if (items.length >= maxProducts) {
      _showLimitSnackBar();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => SpeechDialog(tableid: widget.id),
    ).then((_) => _getRows());
  }

  void _addManyProducts() {
    if (items.length >= maxProducts) {
      _showLimitSnackBar();
      return;
    }
    showDialog(
      context: context,
      builder: (context) => AddManyDialog(tableid: widget.id),
    ).then((_) => _getRows());
  }

  Future<void> edit(Item product) async {
    await showDialog(
      context: context,
      builder: (context) => EditProductDialog(
        product: product,
        commerceId: widget.commerce.id!,
      ),
    );
    await _getRows();
  }

  Future<void> removeProduct(Item produto) async {
    await db.removeItem(produto);
    await _getRows();
  }

  Future<void> printThermal() async {
    final data = await db.getItems(widget.id);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => ThermalPrintPage(items: data),
    ));
  }

  Future<void> printTable() async {
    final data = await db.getItems(widget.id);
    final tables = await db.getTables(widget.commerce.id!);
    final currentTable = tables.firstWhere((t) => t.id == widget.id);

    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (context) => PrintPage(
        commereceType: "vendas",
        data: data,
        tableName: "${widget.name}      ${widget.date}",
        useProductId: widget.commerce.useProductId,
        commerceId: widget.commerce.id,
        timestamp: currentTable.timestamp,
      ),
    ));
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
              onTap: _addManyProducts,
            ),
            SpeedDialChild(
              label: 'Adicionar por voz',
              child: const Icon(Icons.mic_none),
              onTap: _addProductVoice,
            ),
            SpeedDialChild(
              label: 'Impressão térmica',
              child: const Icon(Icons.receipt_long_outlined),
              onTap: printThermal,
            ),
            SpeedDialChild(
              label: 'Imprimir tabela',
              child: const Icon(Icons.print_outlined),
              onTap: printTable,
            ),
          ],
        ),
        appBar: AppBar(
          title: Text(
            '${widget.commerce.name} · ${widget.name}',
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
            : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Produto',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 72,
                          child: Text(
                            'Preço',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 64,
                          child: Text(
                            'Qtd',
                            textAlign: TextAlign.end,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                      itemCount: items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 4),
                      itemBuilder: (context, index) {
                        final item = items[index];
                        final selected = selectedItems.contains(item);
                        return _SellItemTile(
                          name: item.name,
                          price: _currency.format(item.price),
                          quantity: '${item.quantity} ${item.type}',
                          selected: selected,
                          onTap: () => _toggleSelection(item),
                        );
                      },
                    ),
                  ),
                ],
              ),
        bottomNavigationBar: items.isEmpty
            ? null
            : _TotalFooter(total: _currency.format(sumTable(items))),
      ),
    );
  }
}

class _TotalFooter extends StatelessWidget {
  const _TotalFooter({required this.total});

  final String total;
  static const double _fabClearance = 80;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainer,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 12, _fabClearance, 12 + bottomInset),
        child: Row(
          children: [
            Text(
              'Total',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              total,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SellItemTile extends StatelessWidget {
  const _SellItemTile({
    required this.name,
    required this.price,
    required this.quantity,
    required this.selected,
    required this.onTap,
  });

  final String name;
  final String price;
  final String quantity;
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
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
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
              SizedBox(
                width: 72,
                child: Text(
                  price,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(
                width: 64,
                child: Text(
                  quantity,
                  textAlign: TextAlign.end,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: selected
                        ? colorScheme.onPrimaryContainer.withValues(alpha: 0.8)
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddProductDialog extends StatefulWidget {
  const AddProductDialog({
    super.key,
    required this.tableId,
    required this.commerceId,
    required this.useProductId,
  });
  final int tableId;
  final int commerceId;
  final bool useProductId;

  @override
  State<AddProductDialog> createState() => _AddProductDialogState();
}

class _AddProductDialogState extends State<AddProductDialog> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController weightController = TextEditingController();
  final TextEditingController totalController = TextEditingController();
  String code = "";
  bool isUnitary = false;
  List<Product> availableProducts = [];
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    availableProducts = await db.getProducts(widget.commerceId);
    setState(() => _productsLoaded = true);
  }

  void _onProductSelected(Product product) {
    setState(() {
      nameController.text = product.name;
      code = product.productId.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final brlSymbol = Text(
      'R\$',
      style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.bold),
    );

    return AlertDialog(
      title: const Text('Novo produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_productsLoaded && availableProducts.isNotEmpty)
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }
                  return availableProducts.where((Product product) {
                    return product.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ||
                        product.productId
                            .toString()
                            .contains(textEditingValue.text);
                  });
                },
                displayStringForOption: (Product product) => product.name,
                onSelected: _onProductSelected,
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                  nameController.addListener(() {
                    controller.text = nameController.text;
                  });
                  controller.addListener(() {
                    nameController.text = controller.text;
                  });
                  return textFormFieldPers(
                    controller,
                    'Nome do produto',
                    keyboardType: TextInputType.name,
                    focusNode: focusNode,
                    onChanged: (value) {
                      final product = availableProducts.firstWhere(
                        (p) => p.name == value,
                        orElse: () => const Product(
                          id: 0,
                          commerceId: 0,
                          productId: 0,
                          name: '',
                        ),
                      );
                      setState(() => code = product.productId.toString());
                    },
                  );
                },
              )
            else
              textFormFieldPers(nameController, 'Nome do produto',
                  keyboardType: TextInputType.name),
            textFormFieldPers(
              priceController,
              'Preço',
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              prefix: brlSymbol,
              onChanged: (_) =>
                  autoComplete(priceController, totalController, weightController),
            ),
            textFormFieldPers(
              weightController,
              !isUnitary ? 'Peso (kg)' : 'Unidades',
              keyboardType: TextInputType.numberWithOptions(
                decimal: !isUnitary,
                signed: false,
              ),
              onChanged: (_) =>
                  autoComplete(weightController, totalController, priceController),
            ),
            textFormFieldPers(
              totalController,
              'Total (R\$)',
              prefix: brlSymbol,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => autoComplete(
                totalController,
                weightController,
                priceController,
                operation: division,
              ),
            ),
            if (widget.useProductId)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Código: $code',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: isUnitary,
              onChanged: (val) => setState(() => isUnitary = val!),
              title: const Text('Unitário'),
            ),
          ],
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
            int? productId;
            if (code.isNotEmpty) productId = int.tryParse(code);
            await db.insertItem(Item(
              name: nameController.text.capitalize(),
              price: double.parse(
                priceController.text.replaceFirst(RegExp(r','), '.'),
              ),
              tableId: widget.tableId,
              type: unitaryCheck(!isUnitary),
              quantity: double.parse(
                weightController.text.replaceFirst(RegExp(r','), '.'),
              ),
              productId: productId,
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

class EditProductDialog extends StatefulWidget {
  const EditProductDialog({
    super.key,
    required this.product,
    required this.commerceId,
  });

  final Item product;
  final int commerceId;

  @override
  State<EditProductDialog> createState() => _EditProductDialogState();
}

class _EditProductDialogState extends State<EditProductDialog> {
  late TextEditingController nameController;
  late TextEditingController priceController;
  late TextEditingController weightController;
  late TextEditingController totalController;
  late TextEditingController codeController;
  late bool isUnitary;
  List<Product> availableProducts = [];
  bool _productsLoaded = false;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.product.name);
    priceController =
        TextEditingController(text: widget.product.price.toString());
    weightController =
        TextEditingController(text: widget.product.quantity.toString());
    totalController = TextEditingController(
      text: (widget.product.price * widget.product.quantity).toString(),
    );
    codeController = TextEditingController(
      text: widget.product.productId?.toString() ?? '',
    );
    isUnitary = widget.product.type != "kg";
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    availableProducts = await db.getProducts(widget.commerceId);
    setState(() => _productsLoaded = true);
  }

  void _onProductSelected(Product product) {
    setState(() {
      nameController.text = product.name;
      codeController.text = product.productId.toString();
    });
  }

  @override
  Widget build(BuildContext context) {
    final brlSymbol = Text(
      'R\$',
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );

    return AlertDialog(
      title: const Text('Editar produto'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_productsLoaded && availableProducts.isNotEmpty)
              Autocomplete<Product>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<Product>.empty();
                  }
                  return availableProducts.where((Product product) {
                    return product.name
                            .toLowerCase()
                            .contains(textEditingValue.text.toLowerCase()) ||
                        product.productId
                            .toString()
                            .contains(textEditingValue.text);
                  });
                },
                displayStringForOption: (Product product) => product.name,
                onSelected: _onProductSelected,
                fieldViewBuilder:
                    (context, controller, focusNode, onEditingComplete) {
                  nameController.addListener(() {
                    controller.text = nameController.text;
                  });
                  controller.addListener(() {
                    nameController.text = controller.text;
                  });
                  return textFormFieldPers(
                    controller,
                    'Nome do produto',
                    keyboardType: TextInputType.name,
                    focusNode: focusNode,
                  );
                },
              )
            else
              textFormFieldPers(nameController, 'Nome do produto',
                  keyboardType: TextInputType.name),
            textFormFieldPers(
              codeController,
              'Código do produto',
              keyboardType: TextInputType.number,
            ),
            textFormFieldPers(
              priceController,
              'Preço',
              prefix: brlSymbol,
              keyboardType: const TextInputType.numberWithOptions(
                signed: false,
                decimal: false,
              ),
              onChanged: (_) =>
                  autoComplete(priceController, totalController, weightController),
            ),
            textFormFieldPers(
              weightController,
              !isUnitary ? 'Peso (kg)' : 'Unidades',
              keyboardType: TextInputType.numberWithOptions(
                decimal: !isUnitary,
                signed: false,
              ),
              onChanged: (_) =>
                  autoComplete(weightController, totalController, priceController),
            ),
            textFormFieldPers(
              totalController,
              'Total (R\$)',
              prefix: brlSymbol,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => autoComplete(
                totalController,
                weightController,
                priceController,
                operation: division,
              ),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              value: isUnitary,
              onChanged: (val) => setState(() => isUnitary = val!),
              title: const Text('Unitário'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            if (nameController.text.isEmpty ||
                priceController.text.isEmpty ||
                weightController.text.isEmpty) {
              return;
            }
            int? productId;
            if (codeController.text.isNotEmpty) {
              productId = int.tryParse(codeController.text);
            }
            await db.updateItem(Item(
              name: nameController.text.capitalize(),
              price: double.parse(
                priceController.text.replaceFirst(RegExp(r','), '.'),
              ),
              tableId: widget.product.tableId,
              quantity: double.parse(
                weightController.text.replaceFirst(RegExp(r','), '.'),
              ),
              type: unitaryCheck(!isUnitary),
              id: widget.product.id,
              productId: productId,
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
