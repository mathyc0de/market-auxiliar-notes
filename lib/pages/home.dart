import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/pages/commerce_page.dart';
import 'package:market_invoices_app/widgets/buttons.dart';
import 'package:market_invoices_app/widgets/loadscreen.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _built = false;
  bool _editorMode = false;
  int _navBarIndex = 0;
  late List<Commerce> commerces;
  List<Commerce> displaiedCommerces = [];

  @override
  void initState() {
    db.getCommerces().then((value) {
      commerces = value;
      updateDisplaiedCommerces(_navBarIndex);
      _built = true;
      setState(() {});
    });
    super.initState();
  }

  Future<void> getData() async {
    commerces = await db.getCommerces();
    updateDisplaiedCommerces(_navBarIndex);
    setState(() {});
  }

  Future<void> addCommerce(BuildContext context) async {
    await showDialog(
      context: context,
      builder: (context) => AddCommerceDialog(
        type: _navBarIndex == 0 ? "vendas" : "precos",
      ),
    );
    await getData();
  }

  Future<void> edit(Commerce commerce) async {
    await showDialog(
      context: context,
      builder: (context) => EditCommerceDialog(commerce: commerce),
    );
    await getData();
  }

  void removeList() {
    setState(() => _editorMode = true);
  }

  Future<bool> _confirmDelete(BuildContext context, String commerce) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Deletar comércio'),
        content: Text('Deseja deletar "$commerce"?'),
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
      ),
    );
    return result ?? false;
  }

  void updateDisplaiedCommerces(int index) {
    _navBarIndex = index;
    displaiedCommerces = commerces
        .where((element) => element.type == (index == 0 ? "vendas" : "precos"))
        .toList();
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (!_built) return const LoadScreen();

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      floatingActionButton: themedSpeedDial(
        context: context,
        children: [
          SpeedDialChild(
            child: const Icon(Icons.add),
            label: 'Adicionar novo comércio',
            backgroundColor: colorScheme.secondaryContainer,
            foregroundColor: colorScheme.onSecondaryContainer,
            onTap: () => addCommerce(context),
          ),
          SpeedDialChild(
            child: const Icon(Icons.delete_outline),
            label: 'Deletar comércio',
            backgroundColor: colorScheme.errorContainer,
            foregroundColor: colorScheme.onErrorContainer,
            onTap: removeList,
          ),
        ],
      ),
      appBar: AppBar(
        title: Text(
          'Market Invoices',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        centerTitle: true,
        leading: _editorMode
            ? IconButton(
                icon: const Icon(Icons.close),
                tooltip: 'Cancelar exclusão',
                onPressed: () => setState(() => _editorMode = false),
              )
            : null,
      ),
      body: displaiedCommerces.isNotEmpty
          ? ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: displaiedCommerces.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final commerce = displaiedCommerces[index];
                return _CommerceTile(
                  commerce: commerce,
                  editorMode: _editorMode,
                  onLongPress: () => edit(commerce),
                  onTap: () async {
                    if (!_editorMode) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => CommercePage(commerce: commerce),
                        ),
                      );
                      return;
                    }
                    if (await _confirmDelete(context, commerce.name)) {
                      db.removeCommerce(commerce.id!);
                      getData();
                    }
                    setState(() => _editorMode = false);
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
                      Icons.storefront_outlined,
                      size: 48,
                      color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Nenhum comércio ainda',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Toque em + para adicionar',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _navBarIndex,
        onDestinationSelected: updateDisplaiedCommerces,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Vendas',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined),
            selectedIcon: Icon(Icons.sell),
            label: 'Preços',
          ),
        ],
      ),
    );
  }
}

class _CommerceTile extends StatelessWidget {
  const _CommerceTile({
    required this.commerce,
    required this.editorMode,
    required this.onTap,
    required this.onLongPress,
  });

  final Commerce commerce;
  final bool editorMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Material(
      color: colorScheme.surfaceContainerLow,
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
                editorMode ? Icons.delete_outline : Icons.store_outlined,
                size: 20,
                color: editorMode
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  commerce.name,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                editorMode ? Icons.remove_circle_outline : Icons.chevron_right,
                size: 20,
                color: editorMode
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class AddCommerceDialog extends StatelessWidget {
  AddCommerceDialog({super.key, required this.type});
  final TextEditingController nameController = TextEditingController();
  final String type;

  @override
  Widget build(BuildContext context) {
    bool useProduct = false;
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Novo comércio'),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textFormFieldPers(nameController, 'Nome do comércio'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Usar IDs de produtos',
                  style: theme.textTheme.bodyMedium,
                ),
                value: useProduct,
                onChanged: (value) => setState(() => useProduct = value!),
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
            if (nameController.text.isEmpty) return;
            await db.insertCommerce(
              Commerce(
                name: nameController.text,
                type: type,
                useProductId: useProduct,
              ),
            );
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Criar'),
        ),
      ],
    );
  }
}

class EditCommerceDialog extends StatelessWidget {
  EditCommerceDialog({super.key, required this.commerce})
      : nameController = TextEditingController(text: commerce.name);
  final TextEditingController nameController;
  final Commerce commerce;

  @override
  Widget build(BuildContext context) {
    bool useProduct = commerce.useProductId;
    final theme = Theme.of(context);

    return AlertDialog(
      title: const Text('Editar comércio'),
      content: StatefulBuilder(
        builder: (context, setState) => SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              textFormFieldPers(nameController, 'Nome do comércio'),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Usar IDs de produtos',
                  style: theme.textTheme.bodyMedium,
                ),
                value: useProduct,
                onChanged: (value) => setState(() => useProduct = value!),
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
            if (nameController.text.isEmpty && commerce.useProductId == useProduct) {
              return;
            }
            await db.updateCommerce(commerce.id!, nameController.text, useProduct);
            if (!context.mounted) return;
            Navigator.of(context).pop();
          },
          child: const Text('Salvar'),
        ),
      ],
    );
  }
}
