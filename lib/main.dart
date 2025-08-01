import 'package:flutter/material.dart';
import 'package:fruteira/methods/read_data.dart';
import 'package:fruteira/pages/home.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

late final Database db;
late final DataHandler datahandler;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await dotenv.load(fileName: ".env");
  db = await openDatabase(
    join(await getDatabasesPath(),'data.db'),
    onCreate: (db, version) {
      db.execute(
        """
        CREATE TABLE commerces(id INTEGER PRIMARY KEY, name TEXT, type INTEGER)
        """
      );
      db.execute(
        """
        CREATE TABLE tables(id INTEGER PRIMARY KEY, name TEXT, date TEXT, paid FLOAT, commerceid INTEGER);
        """
      );
      db.execute(
        """
        CREATE TABLE items(id INTEGER PRIMARY KEY, name TEXT UNIQUE, price FLOAT, weight FLOAT, listid INTEGER, wtype INTEGER)
        """
      );
    },
    version: 1
  );
  datahandler = DataHandler(db: db);
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
