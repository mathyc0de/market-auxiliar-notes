import 'package:flutter/material.dart';
import 'package:intl/intl.dart' show NumberFormat;
import 'package:market_invoices_app/config/thermal_receipt_config.dart';
import 'package:market_invoices_app/methods/database.dart';

String formatPriceWithUnit(Item item, NumberFormat f) {
  return '${f.format(item.price)} / ${item.type}';
}

double sumItems(List<Item> items) {
  return items.fold(0.0, (sum, item) => sum + item.price * item.quantity);
}

class ThermalReceiptWidget extends StatelessWidget {
  const ThermalReceiptWidget({
    super.key,
    required this.items,
    required this.width,
  });

  final List<Item> items;
  final double width;

  static const double _bodyFontSize = 7;
  static const double _marketNameFontSize = 9;
  static const double _horizontalPadding = 4;

  /// Largura lógica para que a captura caiba no papel térmico.
  static double widthForDevicePixelRatio(double devicePixelRatio) {
    return ThermalReceiptConfig.paperDots / devicePixelRatio;
  }

  @override
  Widget build(BuildContext context) {
    final NumberFormat f = NumberFormat.currency(symbol: 'R\$');
    final double total = sumItems(items);
    final double contentWidth = width - (_horizontalPadding * 2);

    return SizedBox(
      width: width,
      child: Material(
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: _horizontalPadding,
            vertical: 4,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (ThermalReceiptConfig.logoAssetPath.isNotEmpty)
                Center(
                  child: Image.asset(
                    ThermalReceiptConfig.logoAssetPath,
                    height: 36,
                    fit: BoxFit.contain,
                  ),
                ),
              if (ThermalReceiptConfig.logoAssetPath.isNotEmpty)
                const SizedBox(height: 4),
              Text(
                ThermalReceiptConfig.marketNamePlaceholder,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: _marketNameFontSize),
              ),
              const SizedBox(height: 6),
              const Divider(thickness: 1, height: 1),
              const SizedBox(height: 4),
              _ReceiptRow(
                contentWidth: contentWidth,
                nome: 'Nome',
                preco: 'Preço',
                quantidade: 'Qtd',
              ),
              const Divider(height: 1),
              for (final Item item in items)
                _ReceiptRow(
                  contentWidth: contentWidth,
                  nome: item.name,
                  preco: formatPriceWithUnit(item, f),
                  quantidade: item.quantity.toString(),
                ),
              const Divider(thickness: 1, height: 1),
              _TotalRow(contentWidth: contentWidth, total: f.format(total)),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  const _ReceiptRow({
    required this.contentWidth,
    required this.nome,
    required this.preco,
    required this.quantidade,
  });

  final double contentWidth;
  final String nome;
  final String preco;
  final String quantidade;

  static const TextStyle _style =
      TextStyle(fontSize: ThermalReceiptWidget._bodyFontSize);

  @override
  Widget build(BuildContext context) {
    final double precoWidth = contentWidth * 0.46;
    final double quantidadeWidth = contentWidth * 0.16;
    final double nomeWidth =
        contentWidth - precoWidth - quantidadeWidth;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SizedBox(
        width: contentWidth,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: nomeWidth,
              child: Text(
                nome,
                style: _style,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: precoWidth,
              child: Text(
                preco,
                style: _style,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(
              width: quantidadeWidth,
              child: Text(
                quantidade,
                style: _style,
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({
    required this.contentWidth,
    required this.total,
  });

  final double contentWidth;
  final String total;

  static const TextStyle _style =
      TextStyle(fontSize: ThermalReceiptWidget._bodyFontSize);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: SizedBox(
        width: contentWidth,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Total', style: _style),
            Text(total, style: _style),
          ],
        ),
      ),
    );
  }
}
