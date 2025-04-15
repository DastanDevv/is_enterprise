import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  // Получение базы данных (создание, если не существует)
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('dastan_database.db');
    return _database!;
  }

  // Инициализация базы данных
  Future<Database> _initDB(String filePath) async {
    final documentsDirectory = await getApplicationDocumentsDirectory();
    final path = join(documentsDirectory.path, filePath);

    return await openDatabase(
      path,
      version: 3, // Повышаем версию для добавления таблицы транзакций
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  // Обновление базы данных
  Future _upgradeDB(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Добавляем таблицу клиентов
      await _createClientsTable(db);

      // В SQLite нельзя добавить ограничение внешнего ключа к существующей таблице
      // Вместо этого нужно пересоздать таблицу с ограничением

      // 1. Переименовываем существующую таблицу
      await db.execute('ALTER TABLE projects RENAME TO projects_old');

      // 2. Создаем новую таблицу с нужной структурой и внешним ключом
      await db.execute('''
      CREATE TABLE projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        client_id TEXT NOT NULL,
        client_name TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        actual_end_date TEXT,
        budget REAL NOT NULL,
        status INTEGER NOT NULL,
        progress REAL NOT NULL,
        manager_id TEXT,
        team_members TEXT,
        notes TEXT,
        FOREIGN KEY (client_id) REFERENCES clients (id)
      )
      ''');

      // 3. Копируем данные из старой таблицы в новую
      await db.execute('''
      INSERT INTO projects
      SELECT * FROM projects_old
      ''');

      // 4. Удаляем старую таблицу
      await db.execute('DROP TABLE projects_old');

      // 5. Пересоздаем таблицу этапов проекта с внешним ключом
      await db.execute('DROP TABLE IF EXISTS project_stages_old');
      await db.execute(
        'ALTER TABLE project_stages RENAME TO project_stages_old',
      );

      await db.execute('''
      CREATE TABLE project_stages (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        name TEXT NOT NULL,
        description TEXT NOT NULL,
        start_date TEXT NOT NULL,
        end_date TEXT,
        weight REAL NOT NULL,
        completed INTEGER NOT NULL,
        "order" INTEGER NOT NULL,
        FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
      )
      ''');

      await db.execute('''
      INSERT INTO project_stages
      SELECT * FROM project_stages_old
      ''');

      await db.execute('DROP TABLE project_stages_old');
    }

    if (oldVersion < 3) {
      // Добавляем таблицу транзакций для модуля финансов
      await _createTransactionsTable(db);
    }
  }

  // Создание таблиц базы данных
  Future _createDB(Database db, int version) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const boolType = 'INTEGER NOT NULL'; // 0 или 1
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    // Таблица клиентов
    await _createClientsTable(db);

    // Таблица проектов
    await db.execute('''
    CREATE TABLE projects (
      id $idType,
      name $textType,
      description $textType,
      client_id $textType,
      client_name $textType,
      start_date $textType,
      end_date $textNullableType,
      actual_end_date $textNullableType,
      budget $realType,
      status $intType,
      progress $realType,
      manager_id $textNullableType,
      team_members $textNullableType,
      notes $textNullableType,
      FOREIGN KEY (client_id) REFERENCES clients (id)
    )
    ''');

    // Таблица этапов проекта
    await db.execute('''
    CREATE TABLE project_stages (
      id $idType,
      project_id $textType,
      name $textType,
      description $textType,
      start_date $textType,
      end_date $textNullableType,
      weight $realType,
      completed $boolType,
      "order" $intType,
      FOREIGN KEY (project_id) REFERENCES projects (id) ON DELETE CASCADE
    )
    ''');

    // Таблица финансовых транзакций
    await _createTransactionsTable(db);
  }

  // Создание таблицы клиентов
  Future _createClientsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const intType = 'INTEGER NOT NULL';

    await db.execute('''
    CREATE TABLE clients (
      id $idType,
      name $textType,
      contact_person $textType,
      phone $textType,
      email $textType,
      address $textType,
      type $intType,
      website $textNullableType,
      notes $textNullableType,
      created_at $textType,
      last_contact_date $textNullableType
    )
    ''');
  }

  // Создание таблицы финансовых транзакций
  Future _createTransactionsTable(Database db) async {
    const idType = 'TEXT PRIMARY KEY';
    const textType = 'TEXT NOT NULL';
    const textNullableType = 'TEXT';
    const intType = 'INTEGER NOT NULL';
    const realType = 'REAL NOT NULL';

    await db.execute('''
    CREATE TABLE transactions (
      id $idType,
      type $intType,
      category $intType,
      amount $realType,
      date $textType,
      description $textNullableType,
      project_id $textNullableType,
      project_name $textNullableType,
      client_id $textNullableType,
      client_name $textNullableType,
      FOREIGN KEY (project_id) REFERENCES projects (id),
      FOREIGN KEY (client_id) REFERENCES clients (id)
    )
    ''');
  }

  // Закрытие базы данных
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
