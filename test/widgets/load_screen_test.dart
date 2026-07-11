import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_invoices_app/widgets/loadscreen.dart';

void main() {
  testWidgets('shows centered loading indicator', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoadScreen(),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}
