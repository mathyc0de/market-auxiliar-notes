import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:market_invoices_app/widgets/thermal_receipt.dart';

void main() {
  setUp(() {
    Intl.defaultLocale = 'pt_BR';
  });

  testWidgets('renders product rows and total with readable ink on paper', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData.dark(),
        home: const Scaffold(
          body: ThermalReceiptWidget(
            width: 200,
            items: [
              Item(
                tableId: 1,
                name: 'Banana',
                price: 4,
                quantity: 15,
                type: 'kg',
              ),
              Item(
                tableId: 1,
                name: 'Cx Tomate',
                price: 80,
                quantity: 1,
                type: 'un',
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Banana'), findsOneWidget);
    expect(find.text('Cx Tomate'), findsOneWidget);
    expect(find.textContaining('/ kg'), findsOneWidget);
    expect(find.textContaining('/ un'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.textContaining('140'), findsOneWidget);
  });
}
