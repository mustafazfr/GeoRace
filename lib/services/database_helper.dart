import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern: Bu sınıftan sadece bir tane örnek oluşturulmasını sağlar.
  // Bu, veritabanı bağlantısının birden çok kez açılmasını engeller.
  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  // Veritabanı bağlantısını getiren metod.
  // Eğer bağlantı daha önce oluşturulmadıysa, oluşturur.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  // Veritabanını diske kaydetmek ve başlatmak için.
  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_database.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate, // Veritabanı ilk kez oluşturulduğunda çalışacak metod.
    );
  }

  // Veritabanı şemasını (tabloları) oluşturma.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY, -- Firebase'den gelen UID
        email TEXT,
        name TEXT,
        surname TEXT,
        birthDate TEXT,
        birthPlace TEXT,
        city TEXT
      )
    ''');
  }

  // Kullanıcı bilgilerini SQLite'a ekleme veya güncelleme.
  // `ConflictAlgorithm.replace` sayesinde, aynı id'ye sahip bir kayıt varsa
  // eskisini silip yenisini ekler (update gibi çalışır).
  Future<void> saveUser(Map<String, dynamic> user) async {
    final db = await instance.database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // Kullanıcıyı id'sine göre veritabanından getirme.
  Future<Map<String, dynamic>?> getUser(String id) async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isNotEmpty) {
      return maps.first;
    }
    return null;
  }
}