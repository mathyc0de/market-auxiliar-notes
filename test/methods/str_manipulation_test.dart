import 'package:flutter_test/flutter_test.dart';
import 'package:market_invoices_app/methods/str_manipulation.dart';

void main() {
  group('isNumeric', () {
    test('returns false for null', () {
      expect(isNumeric(null), isFalse);
    });

    test('returns true for valid numbers', () {
      expect(isNumeric('10'), isTrue);
      expect(isNumeric('3.5'), isTrue);
    });

    test('returns false for non-numeric strings', () {
      expect(isNumeric('abc'), isFalse);
      expect(isNumeric(''), isFalse);
    });
  });

  group('cleanLine', () {
    test('trims whitespace', () {
      expect(cleanLine('  banana 3.5  '), 'banana 3.5');
    });

    test('removes trailing comma', () {
      expect(cleanLine('banana 3,5,'), 'banana 3,5');
    });
  });

  group('retriveInfo', () {
    test('parses name and price from space-separated line', () {
      final (name, price) = retriveInfo('banana 3.5'.split(' '));
      expect(name, 'banana');
      expect(price, 3.5);
    });

    test('parses multi-word product names', () {
      final (name, price) = retriveInfo('batata doce 10'.split(' '));
      expect(name, 'batata doce');
      expect(price, 10);
    });

    test('parses comma decimal separator', () {
      final (name, price) = retriveInfo('cebola 3,50'.split(' '));
      expect(name, 'cebola');
      expect(price, 3.5);
    });

    test('returns zero price when no numeric token exists', () {
      final (name, price) = retriveInfo('sem preco'.split(' '));
      expect(name, 'sem preco');
      expect(price, 0);
    });
  });

  group('cutStr', () {
    test('returns unchanged string when within limit', () {
      expect(cutStr('Banana'), 'Banana');
    });

    test('truncates strings longer than maxSize', () {
      expect(cutStr('abcdefghijklmnopqrstuvwxyz'), 'abcdefghijklmnopqrstu');
    });
  });

  group('textToList', () {
    test('returns null for empty input', () {
      expect(textToList('', 1), isNull);
    });

    test('parses multiple lines into items', () {
      final result = textToList('banana 4\nlaranja 3,5', 7);
      expect(result, isNotNull);
      expect(result!.length, 2);
      expect(result[0].name, 'Banana');
      expect(result[0].price, 4);
      expect(result[0].tableId, 7);
      expect(result[1].name, 'Laranja');
      expect(result[1].price, 3.5);
    });

    test('defaults quantity to 1 and type to kg', () {
      final result = textToList('pera 2', 1)!;
      expect(result.first.quantity, 1);
      expect(result.first.type, 'kg');
    });
  });

  group('speechToList', () {
    test('converts decoded AI payload into items', () {
      final result = speechToList([
        {
          'nome': 'banana',
          'preço': 4,
          'quantidade': 15,
          'formato': 'kg',
        },
        {
          'nome': 'cx tomate',
          'preço': 80,
          'quantidade': 1,
          'formato': 'un',
        },
      ], 3);

      expect(result.length, 2);
      expect(result[0].name, 'Banana');
      expect(result[0].price, 4);
      expect(result[0].quantity, 15);
      expect(result[0].type, 'kg');
      expect(result[1].name, 'Cx tomate');
      expect(result[1].type, 'un');
      expect(result.every((item) => item.tableId == 3), isTrue);
    });
  });

  group('String capitalize extension', () {
    test('capitalizes first letter only', () {
      expect('banana'.capitalize(), 'Banana');
      expect('cx tomate'.capitalize(), 'Cx tomate');
    });
  });
}
