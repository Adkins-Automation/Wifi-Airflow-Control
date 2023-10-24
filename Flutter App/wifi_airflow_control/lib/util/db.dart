import 'dart:io';

import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:i_flow/dto/user.dart';

class DatabaseHelper {
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _db;
  Future<Database> get db async => _db ??= await _initDatabase();

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'users.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users(
        uid INTEGER PRIMARY KEY,
        name TEXT,
        photoUrl TEXT
      )
      ''');
  }

  Future<List<User>> getUsers() async {
    Database db = await instance.db;
    var users = await db.query('users', orderBy: 'uid');
    List<User> userList =
        users.isNotEmpty ? users.map((e) => User.fromMap(e)).toList() : [];
    return userList;
  }

  static Future<void> insertUser(User user) async {
    final db = await instance.db;
    await db.insert('user',
        {'uid': user.uid, 'name': user.name, 'photoUrl': user.photoUrl});
  }
}
