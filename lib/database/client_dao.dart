import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';
import '../models/client.dart';
import 'database_helper.dart';

class ClientDao {
  final dbHelper = DatabaseHelper.instance;
  final uuid = Uuid();

  // Создание нового клиента
  Future<String> createClient(Client client) async {
    final db = await dbHelper.database;

    // Генерируем уникальный ID, если не задан
    final clientId = client.id.isEmpty ? uuid.v4() : client.id;

    // Создаем клиента с обновленным ID
    final clientWithId = client.copyWith(id: clientId);

    // Вставляем клиента в базу данных
    await db.insert('clients', clientWithId.toMap());

    return clientId;
  }

  // Получение всех клиентов
  Future<List<Client>> getAllClients({String? typeFilter}) async {
    final db = await dbHelper.database;

    // Формируем запрос с учетом фильтра типа
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (typeFilter != null && typeFilter.isNotEmpty) {
      final typeIndex = ClientType.values.indexWhere(
        (type) => type.name.toLowerCase() == typeFilter.toLowerCase(),
      );

      if (typeIndex >= 0) {
        whereClause = 'type = ?';
        whereArgs = [typeIndex];
      }
    }

    final clientMaps = await db.query(
      'clients',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );

    // Для каждого клиента получаем количество связанных проектов
    List<Client> clients = [];
    for (var clientMap in clientMaps) {
      final projectCount = await _getClientProjectsCount(
        clientMap['id'] as String,
      );
      clients.add(Client.fromMap(clientMap, projectsCount: projectCount));
    }

    return clients;
  }

  // Получение количества проектов клиента
  Future<int> _getClientProjectsCount(String clientId) async {
    final db = await dbHelper.database;

    final result = await db.rawQuery(
      'SELECT COUNT(*) as count FROM projects WHERE client_id = ?',
      [clientId],
    );

    return Sqflite.firstIntValue(result) ?? 0;
  }

  // Получение клиента по ID
  Future<Client?> getClientById(String id) async {
    final db = await dbHelper.database;

    final clientMaps = await db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (clientMaps.isEmpty) return null;

    final projectCount = await _getClientProjectsCount(id);
    return Client.fromMap(clientMaps.first, projectsCount: projectCount);
  }

  // Обновление клиента
  Future<int> updateClient(Client client) async {
    final db = await dbHelper.database;

    return await db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  // Удаление клиента
  Future<int> deleteClient(String id) async {
    final db = await dbHelper.database;

    // Проверяем, есть ли у клиента проекты
    final projectCount = await _getClientProjectsCount(id);
    if (projectCount > 0) {
      throw Exception(
        'Невозможно удалить клиента, так как у него есть проекты',
      );
    }

    return await db.delete('clients', where: 'id = ?', whereArgs: [id]);
  }

  // Получение клиентов с фильтрацией и сортировкой
  Future<List<Client>> getFilteredClients({
    String? search,
    ClientType? type,
    String? sortBy,
    bool ascending = true,
  }) async {
    final db = await dbHelper.database;

    // Формируем условия для фильтрации
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      whereConditions.add(
        '(name LIKE ? OR contact_person LIKE ? OR email LIKE ?)',
      );
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (type != null) {
      whereConditions.add('type = ?');
      whereArgs.add(type.index);
    }

    // Формируем строку WHERE
    String whereClause =
        whereConditions.isNotEmpty ? whereConditions.join(' AND ') : '';

    // Определяем поле для сортировки
    String orderByField = 'name';
    if (sortBy != null) {
      switch (sortBy) {
        case 'created_at':
          orderByField = 'created_at';
          break;
        case 'last_contact_date':
          orderByField = 'last_contact_date';
          break;
        case 'type':
          orderByField = 'type';
          break;
      }
    }

    // Формируем сортировку
    String orderBy = '$orderByField ${ascending ? 'ASC' : 'DESC'}';

    // Выполняем запрос
    final clientMaps = await db.query(
      'clients',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    // Для каждого клиента получаем количество связанных проектов
    List<Client> clients = [];
    for (var clientMap in clientMaps) {
      final projectCount = await _getClientProjectsCount(
        clientMap['id'] as String,
      );
      clients.add(Client.fromMap(clientMap, projectsCount: projectCount));
    }

    return clients;
  }

  // Получение проектов клиента
  Future<List<Map<String, dynamic>>> getClientProjects(String clientId) async {
    final db = await dbHelper.database;

    return await db.query(
      'projects',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'start_date DESC',
    );
  }

  // Обновление даты последнего контакта с клиентом
  Future<int> updateLastContactDate(String clientId, DateTime date) async {
    final db = await dbHelper.database;

    return await db.update(
      'clients',
      {'last_contact_date': date.toIso8601String()},
      where: 'id = ?',
      whereArgs: [clientId],
    );
  }
}
