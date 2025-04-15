import 'package:intl/intl.dart';

enum TransactionType { income, expense }

extension TransactionTypeExtension on TransactionType {
  String get name {
    switch (this) {
      case TransactionType.income:
        return 'Доход';
      case TransactionType.expense:
        return 'Расход';
    }
  }

  String get color {
    switch (this) {
      case TransactionType.income:
        return '#66BB6A'; // Зеленый
      case TransactionType.expense:
        return '#EF5350'; // Красный
    }
  }
}

enum TransactionCategory {
  projectPayment, // Оплата по проекту
  salary, // Зарплата
  rent, // Аренда
  equipment, // Оборудование
  utilities, // Коммунальные услуги
  marketing, // Маркетинг
  tax, // Налоги
  other, // Прочее
}

extension TransactionCategoryExtension on TransactionCategory {
  String get name {
    switch (this) {
      case TransactionCategory.projectPayment:
        return 'Оплата по проекту';
      case TransactionCategory.salary:
        return 'Зарплата';
      case TransactionCategory.rent:
        return 'Аренда';
      case TransactionCategory.equipment:
        return 'Оборудование';
      case TransactionCategory.utilities:
        return 'Коммунальные услуги';
      case TransactionCategory.marketing:
        return 'Маркетинг';
      case TransactionCategory.tax:
        return 'Налоги';
      case TransactionCategory.other:
        return 'Прочее';
    }
  }

  String get icon {
    switch (this) {
      case TransactionCategory.projectPayment:
        return 'payment';
      case TransactionCategory.salary:
        return 'people';
      case TransactionCategory.rent:
        return 'home';
      case TransactionCategory.equipment:
        return 'computer';
      case TransactionCategory.utilities:
        return 'flash_on';
      case TransactionCategory.marketing:
        return 'campaign';
      case TransactionCategory.tax:
        return 'account_balance';
      case TransactionCategory.other:
        return 'more_horiz';
    }
  }
}

class Transaction {
  final String id;
  final TransactionType type;
  final TransactionCategory category;
  final double amount;
  final DateTime date;
  final String? description;
  final String? projectId;
  final String? projectName;
  final String? clientId;
  final String? clientName;

  Transaction({
    required this.id,
    required this.type,
    required this.category,
    required this.amount,
    required this.date,
    this.description,
    this.projectId,
    this.projectName,
    this.clientId,
    this.clientName,
  });

  // Копирование объекта с измененными полями
  Transaction copyWith({
    String? id,
    TransactionType? type,
    TransactionCategory? category,
    double? amount,
    DateTime? date,
    String? description,
    String? projectId,
    String? projectName,
    String? clientId,
    String? clientName,
  }) {
    return Transaction(
      id: id ?? this.id,
      type: type ?? this.type,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      date: date ?? this.date,
      description: description ?? this.description,
      projectId: projectId ?? this.projectId,
      projectName: projectName ?? this.projectName,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
    );
  }

  // Преобразование в Map для сохранения в базе данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'type': type.index,
      'category': category.index,
      'amount': amount,
      'date': date.toIso8601String(),
      'description': description,
      'project_id': projectId,
      'project_name': projectName,
      'client_id': clientId,
      'client_name': clientName,
    };
  }

  // Создание объекта из Map
  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      type: TransactionType.values[map['type']],
      category: TransactionCategory.values[map['category']],
      amount: map['amount'],
      date: DateTime.parse(map['date']),
      description: map['description'],
      projectId: map['project_id'],
      projectName: map['project_name'],
      clientId: map['client_id'],
      clientName: map['client_name'],
    );
  }

  // Форматированная сумма
  String getFormattedAmount() {
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: 'сом',
      decimalDigits: 0,
    );

    return currencyFormat.format(amount);
  }
}

class FinancialReport {
  final DateTime startDate;
  final DateTime endDate;
  final double totalIncome;
  final double totalExpense;
  final double balance;
  final Map<TransactionCategory, double> incomeByCategory;
  final Map<TransactionCategory, double> expenseByCategory;
  final Map<String, double> incomeByProject;
  final Map<String, double> expenseByProject;
  final Map<String, double> incomeByClient;
  final List<Transaction> transactions;

  FinancialReport({
    required this.startDate,
    required this.endDate,
    required this.totalIncome,
    required this.totalExpense,
    required this.balance,
    required this.incomeByCategory,
    required this.expenseByCategory,
    required this.incomeByProject,
    required this.expenseByProject,
    required this.incomeByClient,
    required this.transactions,
  });

  // Статические методы для создания отчетов за разные периоды
  static DateTime getStartOfMonth() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  static DateTime getEndOfMonth() {
    final now = DateTime.now();
    final lastDay = DateTime(now.year, now.month + 1, 0).day;
    return DateTime(now.year, now.month, lastDay, 23, 59, 59);
  }

  static DateTime getStartOfQuarter() {
    final now = DateTime.now();
    final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 1;
    return DateTime(now.year, quarterMonth, 1);
  }

  static DateTime getEndOfQuarter() {
    final now = DateTime.now();
    final quarterMonth = ((now.month - 1) ~/ 3) * 3 + 3;
    final lastDay = DateTime(now.year, quarterMonth + 1, 0).day;
    return DateTime(now.year, quarterMonth, lastDay, 23, 59, 59);
  }

  static DateTime getStartOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 1, 1);
  }

  static DateTime getEndOfYear() {
    final now = DateTime.now();
    return DateTime(now.year, 12, 31, 23, 59, 59);
  }
}
