import 'package:market_invoices_app/methods/database.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

Future<DBManager> createTestDatabase() async {
  final database = await databaseFactoryFfi.openDatabase(
    '${inMemoryDatabasePath}_${DateTime.now().microsecondsSinceEpoch}',
    options: OpenDatabaseOptions(
      singleInstance: false,
      version: 3,
      onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON;'),
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE commerces(
            commerce_id INTEGER PRIMARY KEY,
            name TEXT,
            type TEXT,
            use_product_id INTEGER DEFAULT 0
          );
        ''');
        await db.execute('''
          CREATE TABLE products(
            id INTEGER PRIMARY KEY,
            commerce_id INTEGER,
            product_id INTEGER NOT NULL,
            name TEXT,
            UNIQUE(commerce_id, product_id),
            FOREIGN KEY (commerce_id) REFERENCES commerces(commerce_id) ON DELETE CASCADE
          );
        ''');
        await db.execute('''
          CREATE TABLE tables(
            table_id INTEGER PRIMARY KEY,
            name TEXT,
            date TEXT,
            commerce_id INTEGER,
            timestamp INTEGER DEFAULT 0,
            FOREIGN KEY (commerce_id) REFERENCES commerces(commerce_id) ON DELETE CASCADE
          );
        ''');
        await db.execute('''
          CREATE TABLE items(
            item_id INTEGER PRIMARY KEY,
            name TEXT,
            price FLOAT,
            quantity FLOAT,
            type VARCHAR(2) NOT NULL,
            table_id INTEGER,
            product_id INTEGER,
            FOREIGN KEY (table_id) REFERENCES tables(table_id) ON DELETE CASCADE
          );
        ''');
      },
    ),
  );

  return DBManager(db: database);
}
