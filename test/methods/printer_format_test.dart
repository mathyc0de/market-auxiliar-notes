import 'package:flutter_test/flutter_test.dart';
import 'package:market_invoices_app/methods/database.dart';

import '../helpers/test_currency.dart';

/// Mirrors the price-list cell format used in printer.dart for "precos" lists.
String priceListCell(Item item) {
  return '${testCurrency().format(item.price)} / ${item.type}';
}

void main() {
  group('price list PDF cell format', () {
    test('shows unit type (un) not quantity', () {
      const item = Item(
        tableId: 1,
        name: 'Abóbora',
        price: 3.5,
        quantity: 1,
        type: 'un',
      );

      final formatted = priceListCell(item);
      expect(formatted, startsWith(testCurrency().format(item.price)));
      expect(formatted, endsWith('/ un'));
      expect(formatted, isNot(contains('/ 1.0')));
    });

    test('shows unit type (kg) for weight-based products', () {
      const item = Item(
        tableId: 1,
        name: 'Batata',
        price: 3.5,
        quantity: 1,
        type: 'kg',
      );

      final formatted = priceListCell(item);
      expect(formatted, startsWith(testCurrency().format(item.price)));
      expect(formatted, endsWith('/ kg'));
    });
  });
}
