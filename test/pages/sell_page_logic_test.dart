import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_invoices_app/pages/sell_page.dart';

void main() {
  group('unitaryCheck', () {
    test('returns kg when isUnitary flag is true', () {
      expect(unitaryCheck(true), 'kg');
    });

    test('returns un when isUnitary flag is false', () {
      expect(unitaryCheck(false), 'un');
    });
  });

  group('division', () {
    test('divides two numbers', () {
      expect(division(100, 4), 25);
      expect(division(10, 4), 2.5);
    });
  });

  group('multiplication', () {
    test('multiplies two numbers', () {
      expect(multiplication(4, 15), 60);
      expect(multiplication(2.5, 20), 50);
    });
  });

  group('autoComplete', () {
    test('fills total when price and quantity are known', () {
      final price = TextEditingController(text: '4');
      final quantity = TextEditingController(text: '15');
      final total = TextEditingController();

      autoComplete(price, total, quantity);

      expect(total.text, '60.0');
    });

    test('fills quantity when price and total are known', () {
      final price = TextEditingController(text: '4');
      final quantity = TextEditingController();
      final total = TextEditingController(text: '60');

      autoComplete(total, quantity, price, operation: division);

      expect(quantity.text, '15.0');
    });
  });
}
