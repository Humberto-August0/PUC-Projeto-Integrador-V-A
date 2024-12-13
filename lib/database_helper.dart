import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

// Definindo a tabela de contatos
final String tableContact = 'contact';
final String columnId = 'id';
final String columnName = 'name';
final String columnEmail = 'email';
final String columnPhone = 'phone';

// Definindo a classe Contact
class Contact {
  int? id;
  String name;
  String email;
  String phone;

  Contact({this.id, required this.name, required this.email, required this.phone});

  // Converte um objeto Contact em um mapa para armazenar no banco
  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      columnName: name,
      columnEmail: email,
      columnPhone: phone,
    };
    if (id != null) map[columnId] = id;
    return map;
  }

  // Converte um mapa em um objeto Contact
  Contact.fromMap(Map<String, dynamic> map)
      : id = map[columnId],
        name = map[columnName],
        email = map[columnEmail],
        phone = map[columnPhone];
}

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('contact.db');
    return _database!;
  }

  // Criação do banco de dados SQLite
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  // Criação da tabela
  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableContact (
        $columnId INTEGER PRIMARY KEY AUTOINCREMENT,
        $columnName TEXT NOT NULL,
        $columnEmail TEXT NOT NULL,
        $columnPhone TEXT NOT NULL
      )
    ''');
  }

  // Inserir um novo contato
  Future<int> insertContact(Contact contact) async {
    final db = await instance.database;
    return await db.insert(tableContact, contact.toMap());
  }

  // Obter todos os contatos
  Future<List<Contact>> getContacts() async {
    final db = await instance.database;
    final result = await db.query(tableContact);
    return result.map((json) => Contact.fromMap(json)).toList();
  }

  // Atualizar um contato
  Future<int> updateContact(Contact contact) async {
    final db = await instance.database;
    return await db.update(
      tableContact,
      contact.toMap(),
      where: '$columnId = ?',
      whereArgs: [contact.id],
    );
  }

  // Deletar um contato
  Future<int> deleteContact(int id) async {
    final db = await instance.database;
    return await db.delete(
      tableContact,
      where: '$columnId = ?',
      whereArgs: [id],
    );
  }
}