import 'package:flutter_test/flutter_test.dart';
import 'package:market_invoices_app/methods/database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../helpers/test_database.dart';

void main() {
  late DBManager dbManager;
  late Database rawDatabase;

  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    dbManager = await createTestDatabase();
    rawDatabase = dbManager.db;
  });

  tearDown(() async {
    await rawDatabase.close();
  });

  group('Commerce CRUD', () {
    test('inserts and retrieves commerces', () async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Fruteira DR', type: 'vendas'),
      );
      await dbManager.insertCommerce(
        const Commerce(name: 'Promoções', type: 'precos'),
      );

      final commerces = await dbManager.getCommerces();
      expect(commerces.length, 2);
      expect(commerces[0].name, 'Fruteira DR');
      expect(commerces[0].type, 'vendas');
      expect(commerces[1].type, 'precos');
    });

    test('updates commerce name and product id flag', () async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Old Name', type: 'vendas'),
      );
      final commerce = (await dbManager.getCommerces()).first;

      await dbManager.updateCommerce(commerce.id!, 'New Name', true);
      final updated = (await dbManager.getCommerces()).first;

      expect(updated.name, 'New Name');
      expect(updated.useProductId, isTrue);
    });

    test('deletes commerce and cascades related data', () async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Temp', type: 'vendas'),
      );
      final commerce = (await dbManager.getCommerces()).first;
      await dbManager.insertTable(
        Tables(name: 'Morning', date: '11/7/2026', commerceId: commerce.id!),
      );

      await dbManager.removeCommerce(commerce.id!);

      expect(await dbManager.getCommerces(), isEmpty);
      expect(await dbManager.getTables(commerce.id!), isEmpty);
    });
  });

  group('Tables CRUD', () {
    test('inserts and retrieves tables in reverse order', () async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Store', type: 'vendas'),
      );
      final commerceId = (await dbManager.getCommerces()).first.id!;

      await dbManager.insertTable(
        Tables(name: 'First', date: '1/1/2026', commerceId: commerceId),
      );
      await dbManager.insertTable(
        Tables(name: 'Second', date: '2/1/2026', commerceId: commerceId),
      );

      final tables = await dbManager.getTables(commerceId);
      expect(tables.length, 2);
      expect(tables.first.name, 'Second');
      expect(tables.last.name, 'First');
    });

    test('updates table name', () async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Store', type: 'vendas'),
      );
      final commerceId = (await dbManager.getCommerces()).first.id!;
      await dbManager.insertTable(
        Tables(name: 'Old', date: '11/7/2026', commerceId: commerceId),
      );
      final table = (await dbManager.getTables(commerceId)).first;

      await dbManager.updateTable(
        Tables(
          id: table.id,
          name: 'Updated',
          date: table.date,
          commerceId: commerceId,
        ),
      );

      final updated = (await dbManager.getTables(commerceId)).first;
      expect(updated.name, 'Updated');
    });
  });

  group('Items CRUD', () {
    late int tableId;

    setUp(() async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Store', type: 'vendas'),
      );
      final commerceId = (await dbManager.getCommerces()).first.id!;
      await dbManager.insertTable(
        Tables(name: 'List', date: '11/7/2026', commerceId: commerceId),
      );
      tableId = (await dbManager.getTables(commerceId)).first.id!;
    });

    test('inserts and retrieves items ordered by name', () async {
      await dbManager.insertItem(
        Item(name: 'Pera', price: 2.5, quantity: 20, type: 'un', tableId: tableId),
      );
      await dbManager.insertItem(
        Item(name: 'Banana', price: 4, quantity: 15, type: 'kg', tableId: tableId),
      );

      final items = await dbManager.getItems(tableId);
      expect(items.length, 2);
      expect(items.first.name, 'Banana');
      expect(items.last.name, 'Pera');
    });

    test('calculates total from price and quantity', () async {
      await dbManager.insertItem(
        Item(name: 'Banana', price: 4, quantity: 15, type: 'kg', tableId: tableId),
      );
      await dbManager.insertItem(
        Item(name: 'Cx Tomate', price: 80, quantity: 1, type: 'un', tableId: tableId),
      );

      final total = await dbManager.getTotal(tableId);
      expect(total, 140);
    });

    test('updates item fields', () async {
      await dbManager.insertItem(
        Item(name: 'Banana', price: 4, quantity: 15, type: 'kg', tableId: tableId),
      );
      final item = (await dbManager.getItems(tableId)).first;

      await dbManager.updateItem(
        Item(
          id: item.id,
          name: 'Banana Prata',
          price: 5,
          quantity: 10,
          type: 'kg',
          tableId: tableId,
        ),
      );

      final updated = (await dbManager.getItems(tableId)).first;
      expect(updated.name, 'Banana Prata');
      expect(updated.price, 5);
      expect(updated.quantity, 10);
    });

    test('removes item', () async {
      await dbManager.insertItem(
        Item(name: 'Banana', price: 4, quantity: 15, type: 'kg', tableId: tableId),
      );
      final item = (await dbManager.getItems(tableId)).first;

      await dbManager.removeItem(item);
      expect(await dbManager.getItems(tableId), isEmpty);
    });
  });

  group('Products CRUD', () {
    test('inserts and retrieves products by commerce', () async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Store', type: 'vendas', useProductId: true),
      );
      final commerceId = (await dbManager.getCommerces()).first.id!;

      await dbManager.insertProduct(
        Product(commerceId: commerceId, productId: 101, name: 'Banana'),
      );
      await dbManager.insertProduct(
        Product(commerceId: commerceId, productId: 102, name: 'Pera'),
      );

      final products = await dbManager.getProducts(commerceId);
      expect(products.length, 2);
      expect(products.first.productId, 101);
      expect(products.last.name, 'Pera');
    });

    test('getPreviousPrice returns latest price before timestamp', () async {
      await dbManager.insertCommerce(
        const Commerce(name: 'Store', type: 'vendas', useProductId: true),
      );
      final commerceId = (await dbManager.getCommerces()).first.id!;

      await dbManager.insertTable(
        Tables(name: 'Old', date: '1/1/2026', commerceId: commerceId, timestamp: 1),
      );
      await dbManager.insertTable(
        Tables(name: 'New', date: '2/1/2026', commerceId: commerceId, timestamp: 2),
      );
      final tables = await dbManager.getTables(commerceId);
      final oldTable = tables.last;
      final newTable = tables.first;

      await dbManager.insertItem(
        Item(
          name: 'Banana',
          price: 3.5,
          quantity: 1,
          type: 'kg',
          tableId: oldTable.id!,
          productId: 101,
        ),
      );

      final previousPrice = await dbManager.getPreviousPrice(
        commerceId,
        101,
        newTable.timestamp!,
      );

      expect(previousPrice, 3.5);
    });
  });

  group('Item model helpers', () {
    test('toMap round-trips expected fields', () {
      const item = Item(
        tableId: 1,
        name: 'Banana',
        price: 4,
        quantity: 15,
        type: 'kg',
        productId: 10,
      );

      expect(item.toMap(), {
        'table_id': 1,
        'name': 'Banana',
        'price': 4,
        'quantity': 15,
        'type': 'kg',
        'product_id': 10,
      });
    });

    test('extract returns name and raw price', () {
      const item = Item(tableId: 1, name: 'Banana', price: 4, quantity: 15, type: 'kg');
      expect(item.extract(), 'Banana 4.0');
    });
  });
}
