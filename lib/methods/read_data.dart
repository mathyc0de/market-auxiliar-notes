import 'package:intl/intl.dart' show NumberFormat;
import 'package:sqflite/sqflite.dart';


class Item {
  const Item(
    {this.id, 
    required this.name, 
    required this.price, 
    required this.listid, 
    this.weight = 1,
    this.wtype = 1
    });

  final int? id;
  final String name;
  final double price;
  final int listid;
  final double weight;
  final int wtype;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'price': price,
      'listid': listid,
      'weight': weight,
      'wtype': wtype
    };
  }

  String representation() {
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    return 
      wtype == 1? 
        "$name ${f.format(price)}"
        :"$name ${f.format(price)}";
    }


  @override
  String toString() {
    return """
    item(
    name: $name, 
    price: $price, 
    listid: $listid, 
    weight: $weight,
    wtype: $wtype
    id: $id)""";
  }
}

class Tables {
  const Tables({this.id,required this.name, required this.type, required this.date});
  final int? id;
  final String name;
  final int type;
  final String date;

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'type': type,
      'date': date
    };
  }

  @override
  String toString() {
    return 'tables{id: $id, name: $name, type: $type, date: $date}';
  }
}


class DataHandler {
  const DataHandler({required this.db});
  final Database db;

  Future<String> getRawData() async {
    var tables = await db.query("tables");
    var items = await db.query("items");
    return tables.toString() + items.toString();
  }

  Future<void> insertTable(Tables table) async {
    await db.insert(
      "tables", 
      table.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace
    );
    return;
  }

  Future<void> removeTable(Tables table) async {
    await db.delete(
      "tables",
      where: 'id = ${table.id}'
    );
    await db.delete(
        "items",
        where: "listid = ${table.id}"
      );
      return;
   }


  Future<void> insertItem(Item item) async {
    await db.insert(
      "items", 
      item.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace);
    return;
  }


  Future<void> removeItem(Item item) async {
    await db.delete(
      "items",
      where: "id = ${item.id}"
    );
    return;
  }


  Future<List<Tables>> getTables() async {
    final List<Map<String, Object?>> tables = await db.query("tables");
    if (tables.isEmpty) return [];
    return [
      for (
        final {
        'id': id as int,
        'name': name as String,
        'type': type as int,
        'date': date as String
        }
      in tables)
      Tables(name: name, id: id, type: type, date: date)
    ].reversed.toList();
  }


  Future<List<Item>> getItems(int id) async {
    final List<Map<String, Object?>> items = await db.query(
      'items',
      where: 'listid = $id',
      orderBy: 'name ASC'
    );
    return [
      for (
        final {
        'id': id as int,
        'name': name as String,
        'price': price as double,
        'listid': listid as int,
        'weight': weight as double,
        'wtype': wtype as int
        }
      in items)
      Item(
        id: id ,
        name: name, 
        listid: listid, 
        price: price, 
        weight: weight, 
        wtype: wtype)
    ];
  }

  Future<void> updateItem(Item item) async {
    await db.rawUpdate(
      """
        UPDATE items SET name = ?, price = ?, weight = ?, wtype = ? WHERE id = ${item.id}
      """,
      [item.name, item.price, item.weight, item.wtype]
    );
  }

  Future<void> updateTable(Tables table) async {
    await db.rawUpdate(
      """
        UPDATE tables SET name = ? WHERE id = ${table.id}
      """,
      [table.name]
    );
  }

  Future<void> logData() async {
    print(await getRawData());
  }

}