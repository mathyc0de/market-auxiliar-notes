import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/pages/products_page.dart';
import 'package:market_invoices_app/pages/sell_page.dart';
import 'package:market_invoices_app/widgets/buttons.dart';
import 'package:market_invoices_app/widgets/loadscreen.dart';

class CommercePage extends StatefulWidget {
  const CommercePage({super.key, required this.commerce});
  final Commerce commerce;

  @override
  State<CommercePage> createState() => _CommercePageState();
}

class _CommercePageState extends State<CommercePage> {
  bool _built = false;
  List<Tables> selectedTables = [];
  late List<Tables> tables;

  @override
  void initState() {
    db.getTables(widget.commerce.id!).then((value) {
      tables = value;
      _built = true;
      setState(() {});
    });
    super.initState();
  }

  Future<void> getData() async {
    tables = await db.getTables(widget.commerce.id!);
    setState(() {});
  }

  Future<void> addList(BuildContext context) async {
    final created = await showDialog<bool>(
      context: context,
      builder: (context) => PopScope(
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) FocusManager.instance.primaryFocus?.unfocus();
        },
        child: _AddListDialog(commerceId: widget.commerce.id!),
      ),
    );
    if (created == true) await getData();
  }

  Future<void> edit(Tables table) async {
    final TextEditingController nameController =
        TextEditingController(text: table.name);
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar lista'),
        content: textFormFieldPers(nameController, 'Nome da lista'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () async {
              if (nameController.text.isEmpty) return;
              try {
                await db.updateTable(Tables(
                  name: nameController.text,
                  date: table.date,
                  id: table.id,
                  commerceId: widget.commerce.id!,
                ));
                if (!context.mounted) return;
                Navigator.of(context).pop();
                await getData();
              } catch (e) {
                debugPrint('Erro ao editar tabela: $e');
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    nameController.dispose();
  }

  void onDeleteTable() async {
    for (final table in selectedTables) {
      await db.removeTable(table);
    }
    selectedTables.clear();
    await getData();
  }

  void handleProductIDs() {
    showDialog(
      context: context,
      builder: (context) => ProductIDDialog(commerceId: widget.commerce.id!),
    );
  }

  String _dateLabel(int index) {
    final date = tables[index].date;
    int count = 0;
    for (int i = 0; i < index; i++) {
      if (tables[i].name.isEmpty && tables[i].date == date) count++;
    }
    return count == 0 ? date : '$date ($count)';
  }

  void _toggleSelection(Tables table) {
    setState(() {
      selectedTables.contains(table)
          ? selectedTables.remove(table)
          : selectedTables.add(table);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_built) return const LoadScreen();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final hasSelection = selectedTables.isNotEmpty;

    return Scaffold(
      floatingActionButton: themedSpeedDial(
        context: context,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Adicionar nova lista',
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            onTap: () => addList(context),
          ),
          if (widget.commerce.useProductId)
            SpeedDialChild(
              child: const Icon(Icons.tag),
              label: 'Códigos de produtos',
              backgroundColor: colorScheme.tertiaryContainer,
              foregroundColor: colorScheme.onTertiaryContainer,
              onTap: handleProductIDs,
            ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          widget.commerce.name,
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          if (hasSelection) ...[
            IconButton(
              onPressed: () async {
                await edit(selectedTables.first);
                selectedTables.clear();
                setState(() {});
              },
              icon: const Icon(Icons.edit_outlined),
              tooltip: 'Editar',
            ),
            IconButton(
              onPressed: onDeleteTable,
              icon: Icon(Icons.delete_outline, color: colorScheme.error),
              tooltip: 'Deletar',
            ),
          ],
        ],
      ),
      body: tables.isNotEmpty
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: tables.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final table = tables[index];
                final selected = selectedTables.contains(table);
                final hasName = table.name.isNotEmpty;
                return _TableTile(
                  title: hasName ? table.name : _dateLabel(index),
                  subtitle: hasName ? table.date : null,
                  selected: selected,
                  onLongPress: () => _toggleSelection(table),
                  onTap: () async {
                    if (hasSelection) {
                      _toggleSelection(table);
                      return;
                    }
                    widget.commerce.type == "precos"
                        ? Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ProductsPage(
                              commerce: widget.commerce.name,
                              id: table.id!,
                              name: table.name,
                              date: table.date,
                            ),
                          ))
                        : Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => ProductsPageWithWeight(
                              commerce: widget.commerce,
                              id: table.id!,
                              name: table.name,
                              date: table.date,
                            ),
                          ));
                  },
                );
              },
            )
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.list_alt_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhuma lista ainda',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque em + para criar uma lista',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

class _AddListDialog extends StatefulWidget {
  const _AddListDialog({required this.commerceId});

  final int commerceId;

  @override
  State<_AddListDialog> createState() => _AddListDialogState();
}

class _AddListDialogState extends State<_AddListDialog> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  String _buildDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nova lista'),
      content: textFormFieldPers(
        _nameController,
        'Nome da lista (opcional)',
      ),
      actions: [
        TextButton(
          onPressed: () {
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop();
          },
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: () async {
            await db.insertTable(Tables(
              name: _nameController.text,
              date: _buildDate(DateTime.now()),
              commerceId: widget.commerceId,
            ));
            if (!context.mounted) return;
            FocusManager.instance.primaryFocus?.unfocus();
            Navigator.of(context).pop(true);
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.onLongPress,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: selected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                Icons.description_outlined,
                size: 20,
                color: selected
                    ? colorScheme.onPrimaryContainer
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: selected ? colorScheme.onPrimaryContainer : null,
                      ),
                    ),
                    if (subtitle != null)
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: selected
                              ? colorScheme.onPrimaryContainer.withValues(alpha: 0.7)
                              : colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 20,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProductIDDialog extends StatefulWidget {
  const ProductIDDialog({super.key, required this.commerceId});
  final int commerceId;

  @override
  State<ProductIDDialog> createState() => _ProductIDDialogState();
}

class _ProductIDDialogState extends State<ProductIDDialog> {
  final nameController = TextEditingController();
  final idController = TextEditingController();
  List<Product> products = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    nameController.dispose();
    idController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final loadedProducts = await db.getProducts(widget.commerceId);
    if (mounted) {
      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    }
  }

  Future<void> _addProduct() async {
    if (nameController.text.isEmpty || idController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Preencha todos os campos')),
      );
      return;
    }

    final int? productId = int.tryParse(idController.text);
    if (productId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Código inválido. Digite apenas números')),
      );
      return;
    }

    await db.insertProduct(Product(
      commerceId: widget.commerceId,
      productId: productId,
      name: nameController.text,
    ));

    nameController.clear();
    idController.clear();
    await _loadProducts();
  }

  Future<void> _removeProduct(int productId) async {
    await db.removeProduct(productId, widget.commerceId);
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Códigos de produtos', style: theme.textTheme.titleLarge),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Expanded(
                child: isLoading
                    ? Center(
                        child: CircularProgressIndicator(color: colorScheme.primary),
                      )
                    : products.isEmpty
                        ? Center(
                            child: Text(
                              'Nenhum produto cadastrado',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          )
                        : ListView.separated(
                            itemCount: products.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 4),
                            itemBuilder: (context, index) {
                              final product = products[index];
                              return Material(
                                color: colorScheme.surfaceContainerLow,
                                borderRadius: BorderRadius.circular(8),
                                child: ListTile(
                                  dense: true,
                                  leading: CircleAvatar(
                                    radius: 16,
                                    backgroundColor: colorScheme.primaryContainer,
                                    child: Text(
                                      '${product.productId}',
                                      style: theme.textTheme.labelSmall?.copyWith(
                                        color: colorScheme.onPrimaryContainer,
                                      ),
                                    ),
                                  ),
                                  title: Text(product.name),
                                  subtitle: Text('Código ${product.productId}'),
                                  trailing: IconButton(
                                    icon: Icon(
                                      Icons.delete_outline,
                                      color: colorScheme.error,
                                    ),
                                    onPressed: () =>
                                        _removeProduct(product.productId),
                                  ),
                                ),
                              );
                            },
                          ),
              ),
              const Divider(height: 1),
              const SizedBox(height: 12),
              Text('Adicionar produto', style: theme.textTheme.titleSmall),
              const SizedBox(height: 8),
              textFormFieldPers(nameController, 'Nome do produto', maxLength: 21),
              textFormFieldPers(
                idController,
                'Código do produto',
                keyboardType: TextInputType.number,
                maxLength: 10,
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: _addProduct,
                icon: const Icon(Icons.add),
                label: const Text('Adicionar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
