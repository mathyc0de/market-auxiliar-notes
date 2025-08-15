import 'package:flutter/material.dart';
import 'package:fruteira/methods/database.dart' show DBManager, db;
import 'package:fruteira/pages/home.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await dotenv.load(fileName: ".env");
  db = DBManager(db: await openDatabase(
    join(await getDatabasesPath(),'data.db'),
    onOpen: (db) => db.execute("PRAGMA foreign_keys = ON;"),
    onCreate: (db, version) {
      db.execute(
        """
        CREATE TABLE commerces(
        commerce_id INTEGER PRIMARY KEY, 
        name TEXT, 
        type TEXT);
        """
      );
      db.execute(
        """
        CREATE TABLE tables(
        table_id INTEGER PRIMARY KEY, 
        name TEXT, 
        date TEXT,
        commerce_id INTEGER,
        FOREIGN KEY (commerce_id) REFERENCES commerces(commerce_id) ON DELETE CASCADE);
        """
      );
      db.execute(
        """
        CREATE TABLE items(
        item_id INTEGER PRIMARY KEY,
        name TEXT,
        price FLOAT,
        quantity FLOAT,
        type VARCHAR(2) NOT NULL,
        table_id INTEGER,
        FOREIGN KEY (table_id) REFERENCES tables(table_id) ON DELETE CASCADE
        );
        """
      );
    },
    version: 1
  ));
  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      darkTheme: ThemeData(
        // brightness: Brightness.dark,
      ),
      debugShowCheckedModeBanner: false,
      theme: ThemeData( 
        colorScheme: ColorScheme.fromSeed(seedColor: const Color.fromARGB(255, 186, 255, 23)),
      ),
      home: const HomePage(),
    );
  }
}
