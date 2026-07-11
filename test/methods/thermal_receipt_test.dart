import 'package:flutter_test/flutter_test.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/widgets/thermal_receipt.dart';

import '../helpers/test_currency.dart';

void main() {
  final currency = testCurrency();

  group('formatPriceWithUnit', () {
    test('uses unit type instead of quantity', () {
      const item = Item(
        tableId: 1,
        name: 'Batata',
        price: 3.5,
        quantity: 1,
        type: 'un',
      );

      final formatted = formatPriceWithUnit(item, currency);
      expect(formatted, startsWith(currency.format(item.price)));
      expect(formatted, endsWith('/ un'));
      expect(formatted, isNot(contains('/ 1.0')));
    });

    test('formats kilogram items correctly', () {
      const item = Item(
        tableId: 1,
        name: 'Banana',
        price: 4,
        quantity: 15,
        type: 'kg',
      );

      final formatted = formatPriceWithUnit(item, currency);
      expect(formatted, startsWith(currency.format(item.price)));
      expect(formatted, endsWith('/ kg'));
    });
  });

  group('sumItems', () {
    test('sums price multiplied by quantity', () {
      final total = sumItems([
        const Item(tableId: 1, name: 'Banana', price: 4, quantity: 15, type: 'kg'),
        const Item(tableId: 1, name: 'Cx Tomate', price: 80, quantity: 1, type: 'un'),
        const Item(tableId: 1, name: 'Pera', price: 2.5, quantity: 20, type: 'un'),
      ]);

      expect(total, 190);
    });

    test('returns zero for empty list', () {
      expect(sumItems([]), 0);
    });
  });

  group('ThermalReceiptWidget.widthForDevicePixelRatio', () {
    test('scales receipt width based on device pixel ratio', () {
      expect(
        ThermalReceiptWidget.widthForDevicePixelRatio(2),
        192,
      );
      expect(
        ThermalReceiptWidget.widthForDevicePixelRatio(3),
        128,
      );
    });
  });
}
