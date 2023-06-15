import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._();
  static Database? _database;

  DatabaseHelper._();

  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }

    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'results.db');
    return await openDatabase(path, version: 1, onCreate: _createDB);
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE resultados (
        id_resultado INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre_partida TEXT NOT NULL,
        nombre_jugador1 TEXT NOT NULL,
        nombre_jugador2 TEXT NOT NULL,
        ganador TEXT NOT NULL,
        punto INTEGER NOT NULL,
        estado TEXT NOT NULL
      )
    ''');
  }

  Future<int> insertResult(Resultado resultado) async {
    final db = await database;
    return await db.insert('resultados', resultado.toMap());
  }

  Future<List<Resultado>> getResults() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('resultados');
    return List.generate(maps.length, (i) {
      return Resultado.fromMap(maps[i]);
    });
  }

  Future<void> updateResult(Resultado resultado) async {
    final db = await database;
    await db.update(
      'resultados',
      resultado.toMap(),
      where: 'id_resultado = ?',
      whereArgs: [resultado.id],
    );
  }
}

class Resultado {
  int? id;
  String nombrePartida;
  String nombreJugador1;
  String nombreJugador2;
  String ganador;
  int punto;
  String estado;

  Resultado({
    this.id,
    required this.nombrePartida,
    required this.nombreJugador1,
    required this.nombreJugador2,
    required this.ganador,
    required this.punto,
    required this.estado,
  });

  Map<String, dynamic> toMap() {
    return {
      'id_resultado': id,
      'nombre_partida': nombrePartida,
      'nombre_jugador1': nombreJugador1,
      'nombre_jugador2': nombreJugador2,
      'ganador': ganador,
      'punto': punto,
      'estado': estado,
    };
  }

  factory Resultado.fromMap(Map<String, dynamic> map) {
    return Resultado(
      id: map['id_resultado'],
      nombrePartida: map['nombre_partida'],
      nombreJugador1: map['nombre_jugador1'],
      nombreJugador2: map['nombre_jugador2'],
      ganador: map['ganador'],
      punto: map['punto'],
      estado: map['estado'],
    );
  }
}
