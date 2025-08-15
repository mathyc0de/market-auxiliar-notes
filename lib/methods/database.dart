import 'package:intl/intl.dart' show NumberFormat;
import 'package:sqflite/sqflite.dart';

late final DBManager db;


class Commerce {
  const Commerce ({
    this.id,
    required this.name,
    required this.type,
  });

  final int? id;
  final String name;
  final String type;

   Map<String, Object?> toMap() {
    return {
      'name': name,
      'type': type
    };
  }
}



class Item {
  const Item(
    {
      this.id, 
      required this.tableId,
      required this.name, 
      required this.price, 
      this.quantity = 1,
      this.type = "kg",
    });

  final int? id;
  final int tableId;
  final String name;
  final double price;
  final double quantity;
  final String type;

  Map<String, Object?> toMap() {
    return {
      'table_id': tableId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'type': type,
    };
  }

  String representation() {
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    return "$name ${f.format(price)}";
    }
  
  String extract() {
    return "$name $price";
  }


  @override
  String toString() {
    return """
    item(
    table_id: $tableId,
    name: $name, 
    price: $price, 
    quantity: $quantity,
    type: $type
    item_id: $id,
    )""";
  }
}

class Tables {

  Tables({
    this.id, 
    required this.commerceId,
    required this.name, 
    required this.date,
    });

  final int? id;
  final int commerceId;
  final String name;
  final String date;
  

  Map<String, Object?> toMap() {
    return {
      'commerce_id': commerceId,
      'name': name,
      'date': date,
    };
  }

  @override
  String toString() {
    return """
      tables{
        table_id: $id, 
        commerce_id: $commerceId
        name: $name, 
        date: $date, 
        }""";
  }

}


class DBManager {
  const DBManager({required this.db});
  final Database db;

  // Future<String> getRawData() async {
  //   var tables = await db.query("tables");
  //   var items = await db.query("items");
  //   return tables.toString() + items.toString();
  // }

  Future<void> insertCommerce(Commerce commerce) async {
    await db.insert(
      "commerces", 
      commerce.toMap());
    return;
  }

  Future<void> removeCommerce(int commerceid) async {
    await db.delete("commerces", where: 'commerce_id=$commerceid');
  }

  Future<void> updateCommerce(int commerceid, String newName) async {
    await db.rawUpdate(
      """
      UPDATE commerces SET name = ? WHERE commerce_id = $commerceid
      """, [newName]
    );
  }
 
  Future<void> insertTable(Tables table) async {
    await db.insert(
      "tables", 
      table.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
  }

  Future<void> removeTable(Tables table) async {
    await db.delete(
      "tables",
      where: 'table_id = ${table.id}'
    );
   }


  Future<void> insertItem(Item item) async {
    await db.insert(
      "items", 
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort);
    return;
  }


  Future<void> removeItem(Item item) async {
    await db.delete(
      "items",
      where: "table_id = ${item.tableId}"
    );
    return;
  }

  Future<List<Commerce>> getCommerces() async {
    final List<Map<String, Object?>> commerces = await db.query("commerces");
    if (commerces.isEmpty) return [];
    return [
      for (
        final {
        'commerce_id': id as int,
        'name': name as String,
        'type': type as String
      } in commerces)
      Commerce(id: id, name: name, type: type)
    ];
  }


  Future<List<Tables>> getTables(int commerceId) async {
    final List<Map<String, Object?>> tables = await db.query("tables", where: "commerce_id = $commerceId", orderBy: "table_id ASC");
    if (tables.isEmpty) return [];
    return [
      for (
        final {
        'table_id': id as int,
        'name': name as String,
        'date': date as String,
        'commerce_id': commerceId as int
        }
      in tables)
      Tables(name: name, id: id, date: date, commerceId: commerceId)
    ].reversed.toList();
  }

  Future<double> getTotal(int tableId) async {
    double sum = 0;
    final List<Map<String, Object?>> items = await db.query(
      'items',
      where: 'table_id = $tableId',
      columns: ['price', 'quantity']
    );
    for (final {
      'price': price as double,
      'quantity': quantity as double
    } in items) {
        sum += price * quantity;
      }
    return sum;
  }


  Future<List<Item>> getItems(int tableId) async {
    final List<Map<String, Object?>> items = await db.query(
      'items',
      where: 'table_id = $tableId',
      orderBy: 'name ASC'
    );
    return [
      for (
        final {
        'item_id': id as int,
        'name': name as String,
        'price': price as double,
        'table_id': tableId as int,
        'quantity': quantity as double,
        'type': type as String,
        }
      in items)
      Item(
        id: id ,
        name: name, 
        tableId: tableId, 
        price: price, 
        quantity: quantity, 
        type: type,
        )
    ];
  }

  Future<void> updateItem(Item item) async {
    await db.rawUpdate(
      """
        UPDATE items SET name = ?, price = ?, quantity = ?, type = ? WHERE item_id = ${item.id}
      """,
      [item.name, item.price, item.quantity, item.type]
    );
  }

  Future<void> updateTable(Tables table) async {
    await db.rawUpdate(
      """
        UPDATE tables SET name = ? WHERE table_id = ${table.id}
      """,
      [table.name]
    );
  }

  // Future<void> logData() async {
  //   print(await getRawData());
  // }

}