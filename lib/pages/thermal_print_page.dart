import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_thermal_printer/flutter_thermal_printer.dart';
import 'package:flutter_thermal_printer/utils/printer.dart';
import 'package:market_invoices_app/config/thermal_receipt_config.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/widgets/thermal_receipt.dart';

const Map<ConnectionType, String> normalizedConnectionTypeNames = {
  ConnectionType.BLE: 'Bluetooth',
  ConnectionType.USB: 'USB',
  ConnectionType.NETWORK: 'Wi-Fi',
};

class ThermalPrintPage extends StatefulWidget {
  const ThermalPrintPage({super.key, required this.items});
  final List<Item> items;

  @override
  State<ThermalPrintPage> createState() => _ThermalPrintPageState();
}

class _ThermalPrintPageState extends State<ThermalPrintPage> {
  final FlutterThermalPrinter _printerPlugin = FlutterThermalPrinter.instance;

  List<Printer> _printers = [];
  Printer? _selectedPrinter;
  bool _printing = false;
  StreamSubscription<List<Printer>>? _devicesSubscription;

  @override
  void initState() {
    super.initState();
    _printerPlugin.bleConfig = const BleConfig(
      connectionStabilizationDelay: Duration(seconds: 3),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) => _startScan());
  }

  Future<void> _startScan() async {
    _devicesSubscription?.cancel();
    await _printerPlugin.getPrinters(
      connectionTypes: [ConnectionType.BLE, ConnectionType.USB],
    );
    _devicesSubscription = _printerPlugin.devicesStream.listen((printers) {
      if (!mounted) return;
      setState(() {
        _printers = printers;
        _selectedPrinter = _resolveSelectedPrinter(printers);
      });
    });
  }

  bool _isSamePrinter(Printer a, Printer b) {
    return a.address == b.address && a.name == b.name;
  }

  Printer? _resolveSelectedPrinter(List<Printer> printers) {
    if (_selectedPrinter != null) {
      for (final Printer printer in printers) {
        if (_isSamePrinter(printer, _selectedPrinter!) &&
            (printer.isConnected ?? false)) {
          return printer;
        }
      }
    }

    for (final Printer printer in printers) {
      if (printer.isConnected ?? false) return printer;
    }

    if (_selectedPrinter != null) {
      for (final Printer printer in printers) {
        if (_isSamePrinter(printer, _selectedPrinter!)) return printer;
      }
    }

    return null;
  }

  Future<void> _print() async {
    final Printer? printer = _selectedPrinter;
    if (printer == null) {
      _showMessage('Selecione uma impressora');
      return;
    }

    setState(() => _printing = true);
    try {
      if (!(printer.isConnected ?? false)) {
        final connected = await _printerPlugin.connect(printer);
        if (!connected) {
          _showMessage('Não foi possível conectar à impressora');
          return;
        }
      }

      if (!mounted) return;
      final double receiptWidth = ThermalReceiptWidget.widthForDevicePixelRatio(
        View.of(context).devicePixelRatio,
      );
      await _printerPlugin.printWidget(
        context,
        printer: printer,
        printOnBle: true,
        cutAfterPrinted: true,
        paperSize: ThermalReceiptConfig.paperSize,
        widget: ThermalReceiptWidget(
          items: widget.items,
          width: receiptWidth,
        ),
      );
      _showMessage('Impressão enviada');
    } catch (e) {
      _showMessage('Erro ao imprimir: $e');
    } finally {
      if (mounted) setState(() => _printing = false);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _devicesSubscription?.cancel();
    _printerPlugin.stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final receiptWidth = ThermalReceiptWidget.widthForDevicePixelRatio(
      View.of(context).devicePixelRatio,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Impressão térmica',
          style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w500),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: _printing
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onSurface,
                    ),
                  )
                : const Icon(Icons.print_outlined),
            onPressed: _printing ? null : _print,
            tooltip: 'Imprimir',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: colorScheme.shadow.withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ThermalReceiptWidget(
                    items: widget.items,
                    width: receiptWidth,
                  ),
                ),
              ),
            ),
          ),
          Divider(height: 1, color: colorScheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text('Impressoras', style: theme.textTheme.titleSmall),
                const Spacer(),
                TextButton.icon(
                  onPressed: _startScan,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Buscar'),
                ),
              ],
            ),
          ),
          Expanded(
            flex: 1,
            child: _printers.isEmpty
                ? Center(
                    child: Text(
                      'Nenhuma impressora encontrada',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _printers.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 4),
                    itemBuilder: (context, index) {
                      final printer = _printers[index];
                      final selected = _selectedPrinter?.address == printer.address &&
                          _selectedPrinter?.name == printer.name;
                      return Material(
                        color: selected
                            ? colorScheme.primaryContainer
                            : colorScheme.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(8),
                        clipBehavior: Clip.antiAlias,
                        child: ListTile(
                          dense: true,
                          selected: selected,
                          leading: Icon(
                            printer.connectionType == ConnectionType.USB
                                ? Icons.usb
                                : Icons.bluetooth,
                            size: 20,
                            color: selected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                          title: Text(printer.name ?? 'Sem nome'),
                          subtitle: Text(
                            '${normalizedConnectionTypeNames[printer.connectionType] ?? 'Desconhecido'} · '
                            '${printer.isConnected == true ? 'Conectado' : 'Desconectado'}',
                          ),
                          onTap: () => setState(() => _selectedPrinter = printer),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
