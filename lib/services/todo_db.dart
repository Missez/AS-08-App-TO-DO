import 'package:sqflite/sqflite.dart'; 
import 'package:path/path.dart'; 
import '../models/todo.dart'; 
 
class TodoDB { 
  static final TodoDB _instance = TodoDB._internal(); 
  factory TodoDB() => _instance; 
  TodoDB._internal(); 
 
  static Database? _db; 
 
  Future<Database> get database async { 
    if (_db != null) return _db!; 
    _db = await _initDB(); 
    return _db!; 
  } 
 
  Future<Database> _initDB() async { 
    final dbPath = await getDatabasesPath(); 
    final path = join(dbPath, 'todos.db'); 
    return openDatabase( 
      path, 
      version: 2, 
      onCreate: (db, version) async { 
        await db.execute(''' 
          CREATE TABLE todos ( 
            id INTEGER PRIMARY KEY AUTOINCREMENT, 
            title TEXT NOT NULL, 
            description TEXT DEFAULT '', 
            priority TEXT DEFAULT 'medium',
            due_date INTEGER,
            created_at INTEGER NOT NULL,
            is_done INTEGER NOT NULL DEFAULT 0 
          ) 
        '''); 
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          // เพิ่มคอลัมน์ใหม่สำหรับเวอร์ชัน 2
          await db.execute('ALTER TABLE todos ADD COLUMN description TEXT DEFAULT ""');
          await db.execute('ALTER TABLE todos ADD COLUMN priority TEXT DEFAULT "medium"');
          await db.execute('ALTER TABLE todos ADD COLUMN due_date INTEGER');
          await db.execute('ALTER TABLE todos ADD COLUMN created_at INTEGER NOT NULL DEFAULT 0');
        }
      },
    ); 
  } 
 
  // CRUD 
  Future<int> insertTodo(Todo todo) async { 
    final db = await database; 
    return db.insert('todos', todo.toMap(), 
        conflictAlgorithm: ConflictAlgorithm.replace); 
  } 
 
  Future<List<Todo>> getTodos() async { 
    final db = await database; 
    final res = await db.query('todos', orderBy: 'id DESC'); 
    return res.map((e) => Todo.fromMap(e)).toList(); 
  } 
 
  Future<int> updateTodo(Todo todo) async { 
    final db = await database; 
    return db.update('todos', todo.toMap(), 
        where: 'id = ?', whereArgs: [todo.id]); 
  } 
 
  Future<int> deleteTodo(int id) async { 
    final db = await database; 
    return db.delete('todos', where: 'id = ?', whereArgs: [id]); 
  } 
 
  Future<void> clearAll() async { 
    final db = await database; 
    await db.delete('todos'); 
  } 
} 