import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static Future<Database> get database async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'my_database.db');
    return openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute(
            'CREATE TABLE users (uid INTEGER PRIMARY KEY, displayName TEXT, photoUrl TEXT, dampers TEXT)');
      },
    );
  }

  static Future<void> insertData(String data) async {
    final db = await database;
    await db.insert('my_table', {'data': data});
  }

  static Future<List<Map<String, dynamic>>> retrieveData() async {
    final db = await database;
    return db.query('my_table');
  }
}

Future<void> saveData() async {
  await DatabaseHelper.insertData('value');
}

Future<void> retrieveData() async {
  final data = await DatabaseHelper.retrieveData();
  // Process the retrieved data
}
