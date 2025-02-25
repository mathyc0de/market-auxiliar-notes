import 'package:intl/intl.dart' show NumberFormat;
import 'package:sqflite/sqflite.dart';


class Commerce {
  const Commerce ({
    this.id,
    required this.name,
    required this.type,
  });

  final int? id;
  final String name;
  final int type;

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
      required this.name, 
      required this.price, 
      required this.listid,
      this.weight = 1,
      this.wtype = 1,
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
      'wtype': wtype,
    };
  }

  String representation() {
    final NumberFormat f = NumberFormat.currency(symbol: "R\$");
    return 
      wtype == 1? 
        "$name ${f.format(price)}"
        :"$name ${f.format(price)}";
    }
  
  String extract() {
    return "$name $price";
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
    id: $id,
    )""";
  }
}

class Tables {

  Tables({
    this.id, 
    required this.name, 
    required this.date,
    required this.commerceid, 
    this.paid = 0,
    this.total = 0
    });

  final int? id;
  final String name;
  final String date;
  final double paid;
  final int commerceid;
  double total;
  

  Map<String, Object?> toMap() {
    return {
      'name': name,
      'date': date,
      'paid': paid,
      'commerceid': commerceid
    };
  }

  @override
  String toString() {
    return """
      tables{
        id: $id, 
        name: $name, 
        date: $date, 
        paid: $paid,
        commerceid: $commerceid
        }""";
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

  Future<void> insertCommerce(Commerce commerce) async {
    await db.insert(
      "commerces", 
      commerce.toMap());
    return;
  }

  Future<void> removeCommerce(Commerce commerce) async {
    await db.delete("commerces", where: 'id=${commerce.id}');
    await db.delete("tables", where: 'commerceid = ${commerce.id}');
    await db.delete("items", where: "commerceid = ${commerce.id}");
  }


  Future<void> addPayment(Tables table, double value) async {
    await db.rawUpdate(
      """
        UPDATE tables SET paid = $value WHERE id = ${table.id}
      """,
    );
  }

  Future<void> updateCommerce(Commerce commerce) async {
    await db.rawUpdate(
      """
      UPDATE commerces SET name = ? WHERE id = ${commerce.id}
      """, [commerce.name]
    );
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

  Future<List<Commerce>> getCommerces() async {
    final List<Map<String, Object?>> commerces = await db.query("commerces");
    if (commerces.isEmpty) return [];
    return [
      for (
        final {
        'id': id as int,
        'name': name as String,
        'type': type as int
      } in commerces)
      Commerce(id: id, name: name, type: type)
    ];
  }


  Future<List<Tables>> getTables(int commerceid) async {
    final List<Map<String, Object?>> tables = await db.query("tables", where: "commerceid = $commerceid", orderBy: "id ASC");
    if (tables.isEmpty) return [];
    return [
      for (
        final {
        'id': id as int,
        'name': name as String,
        'date': date as String,
        'commerceid': commerceid as int,
        'paid': paid as double,
        }
      in tables)
      Tables(name: name, id: id, date: date, commerceid: commerceid, paid: paid, total: await getTotal(id))
    ].reversed.toList();
  }

  Future<double> getTotal(int listid) async {
    double sum = 0;
    final List<Map<String, Object?>> items = await db.query(
      'items',
      where: 'listid = $listid',
      columns: ['price', 'weight']
    );
    for (final {
      'price': price as double,
      'weight': weight as double
    } in items) {
        sum += price * weight;
      }
    return sum;
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
        'wtype': wtype as int,
        }
      in items)
      Item(
        id: id ,
        name: name, 
        listid: listid, 
        price: price, 
        weight: weight, 
        wtype: wtype,
        )
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
        UPDATE tables SET name = ?, paid = ${table.paid} WHERE id = ${table.id}
      """,
      [table.name]
    );
  }

  Future<void> logData() async {
    print(await getRawData());
  }

}