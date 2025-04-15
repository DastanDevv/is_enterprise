import 'package:uuid/uuid.dart';
import '../models/finance.dart';
import 'database_helper.dart';

class TransactionDao {
  final dbHelper = DatabaseHelper.instance;
  final uuid = Uuid();

  // Создание новой транзакции
  Future<String> createTransaction(Transaction transaction) async {
    final db = await dbHelper.database;

    // Генерируем уникальный ID, если не задан
    final transactionId = transaction.id.isEmpty ? uuid.v4() : transaction.id;

    // Создаем транзакцию с обновленным ID
    final transactionWithId = transaction.copyWith(id: transactionId);

    // Вставляем транзакцию в базу данных
    await db.insert('transactions', transactionWithId.toMap());

    return transactionId;
  }

  // Получение всех транзакций
  Future<List<Transaction>> getAllTransactions({
    DateTime? startDate,
    DateTime? endDate,
    TransactionType? type,
    TransactionCategory? category,
    String? projectId,
    String? clientId,
  }) async {
    final db = await dbHelper.database;

    // Формируем условия для фильтрации
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (type != null) {
      whereConditions.add('type = ?');
      whereArgs.add(type.index);
    }

    if (category != null) {
      whereConditions.add('category = ?');
      whereArgs.add(category.index);
    }

    if (projectId != null) {
      whereConditions.add('project_id = ?');
      whereArgs.add(projectId);
    }

    if (clientId != null) {
      whereConditions.add('client_id = ?');
      whereArgs.add(clientId);
    }

    // Формируем строку WHERE
    String whereClause =
        whereConditions.isNotEmpty ? whereConditions.join(' AND ') : '';

    final transactionMaps = await db.query(
      'transactions',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'date DESC',
    );

    return transactionMaps.map((map) => Transaction.fromMap(map)).toList();
  }

  // Получение транзакции по ID
  Future<Transaction?> getTransactionById(String id) async {
    final db = await dbHelper.database;

    final transactionMaps = await db.query(
      'transactions',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (transactionMaps.isEmpty) return null;

    return Transaction.fromMap(transactionMaps.first);
  }

  // Обновление транзакции
  Future<int> updateTransaction(Transaction transaction) async {
    final db = await dbHelper.database;

    return await db.update(
      'transactions',
      transaction.toMap(),
      where: 'id = ?',
      whereArgs: [transaction.id],
    );
  }

  // Удаление транзакции
  Future<int> deleteTransaction(String id) async {
    final db = await dbHelper.database;

    return await db.delete('transactions', where: 'id = ?', whereArgs: [id]);
  }

  // Получение суммы доходов за период
  Future<double> getTotalIncome({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    String? projectId,
    String? clientId,
  }) async {
    return await _getTotal(
      type: TransactionType.income,
      startDate: startDate,
      endDate: endDate,
      category: category,
      projectId: projectId,
      clientId: clientId,
    );
  }

  // Получение суммы расходов за период
  Future<double> getTotalExpense({
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    String? projectId,
    String? clientId,
  }) async {
    return await _getTotal(
      type: TransactionType.expense,
      startDate: startDate,
      endDate: endDate,
      category: category,
      projectId: projectId,
      clientId: clientId,
    );
  }

  // Внутренний метод для получения суммы транзакций
  Future<double> _getTotal({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
    TransactionCategory? category,
    String? projectId,
    String? clientId,
  }) async {
    final db = await dbHelper.database;

    // Формируем условия для фильтрации
    List<String> whereConditions = ['type = ?'];
    List<dynamic> whereArgs = [type.index];

    if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    if (category != null) {
      whereConditions.add('category = ?');
      whereArgs.add(category.index);
    }

    if (projectId != null) {
      whereConditions.add('project_id = ?');
      whereArgs.add(projectId);
    }

    if (clientId != null) {
      whereConditions.add('client_id = ?');
      whereArgs.add(clientId);
    }

    // Формируем строку WHERE
    String whereClause = whereConditions.join(' AND ');

    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM transactions WHERE $whereClause',
      whereArgs,
    );

    return result.first['total'] as double? ?? 0.0;
  }

  // Получение распределения транзакций по категориям
  Future<Map<TransactionCategory, double>> getCategoryDistribution({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await dbHelper.database;

    // Формируем условия для фильтрации
    List<String> whereConditions = ['type = ?'];
    List<dynamic> whereArgs = [type.index];

    if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    // Формируем строку WHERE
    String whereClause = whereConditions.join(' AND ');

    final result = await db.rawQuery(
      'SELECT category, SUM(amount) as total FROM transactions WHERE $whereClause GROUP BY category',
      whereArgs,
    );

    Map<TransactionCategory, double> distribution = {};

    for (var row in result) {
      final category = TransactionCategory.values[row['category'] as int];
      final total = row['total'] as double? ?? 0.0;
      distribution[category] = total;
    }

    return distribution;
  }

  // Получение распределения транзакций по проектам
  Future<Map<String, double>> getProjectDistribution({
    required TransactionType type,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await dbHelper.database;

    // Формируем условия для фильтрации
    List<String> whereConditions = ['type = ? AND project_id IS NOT NULL'];
    List<dynamic> whereArgs = [type.index];

    if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    // Формируем строку WHERE
    String whereClause = whereConditions.join(' AND ');

    final result = await db.rawQuery(
      'SELECT project_id, project_name, SUM(amount) as total FROM transactions WHERE $whereClause GROUP BY project_id',
      whereArgs,
    );

    Map<String, double> distribution = {};

    for (var row in result) {
      final projectName = row['project_name'] as String;
      final total = row['total'] as double? ?? 0.0;
      distribution[projectName] = total;
    }

    return distribution;
  }

  // Получение распределения доходов по клиентам
  Future<Map<String, double>> getClientDistribution({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final db = await dbHelper.database;

    // Формируем условия для фильтрации
    List<String> whereConditions = ['type = ? AND client_id IS NOT NULL'];
    List<dynamic> whereArgs = [TransactionType.income.index];

    if (startDate != null) {
      whereConditions.add('date >= ?');
      whereArgs.add(startDate.toIso8601String());
    }

    if (endDate != null) {
      whereConditions.add('date <= ?');
      whereArgs.add(endDate.toIso8601String());
    }

    // Формируем строку WHERE
    String whereClause = whereConditions.join(' AND ');

    final result = await db.rawQuery(
      'SELECT client_id, client_name, SUM(amount) as total FROM transactions WHERE $whereClause GROUP BY client_id',
      whereArgs,
    );

    Map<String, double> distribution = {};

    for (var row in result) {
      final clientName = row['client_name'] as String;
      final total = row['total'] as double? ?? 0.0;
      distribution[clientName] = total;
    }

    return distribution;
  }

  // Создание финансового отчета
  Future<FinancialReport> generateReport({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    // Получаем все транзакции за период
    final transactions = await getAllTransactions(
      startDate: startDate,
      endDate: endDate,
    );

    // Получаем суммы доходов и расходов
    final totalIncome = await getTotalIncome(
      startDate: startDate,
      endDate: endDate,
    );

    final totalExpense = await getTotalExpense(
      startDate: startDate,
      endDate: endDate,
    );

    // Получаем распределение по категориям
    final incomeByCategory = await getCategoryDistribution(
      type: TransactionType.income,
      startDate: startDate,
      endDate: endDate,
    );

    final expenseByCategory = await getCategoryDistribution(
      type: TransactionType.expense,
      startDate: startDate,
      endDate: endDate,
    );

    // Получаем распределение по проектам
    final incomeByProject = await getProjectDistribution(
      type: TransactionType.income,
      startDate: startDate,
      endDate: endDate,
    );

    final expenseByProject = await getProjectDistribution(
      type: TransactionType.expense,
      startDate: startDate,
      endDate: endDate,
    );

    // Получаем распределение по клиентам
    final incomeByClient = await getClientDistribution(
      startDate: startDate,
      endDate: endDate,
    );

    // Создаем объект отчета
    return FinancialReport(
      startDate: startDate,
      endDate: endDate,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
      balance: totalIncome - totalExpense,
      incomeByCategory: incomeByCategory,
      expenseByCategory: expenseByCategory,
      incomeByProject: incomeByProject,
      expenseByProject: expenseByProject,
      incomeByClient: incomeByClient,
      transactions: transactions,
    );
  }
}
