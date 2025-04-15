import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/finance.dart';
import '../../database/transaction_dao.dart';
import '../../widgets/finance_widgets/summary_card.dart';
import '../../widgets/finance_widgets/category_chart.dart';

enum ReportPeriod { month, quarter, year, custom }

extension ReportPeriodExtension on ReportPeriod {
  String get name {
    switch (this) {
      case ReportPeriod.month:
        return 'Текущий месяц';
      case ReportPeriod.quarter:
        return 'Текущий квартал';
      case ReportPeriod.year:
        return 'Текущий год';
      case ReportPeriod.custom:
        return 'Произвольный период';
    }
  }
}

class FinancialReportScreen extends StatefulWidget {
  const FinancialReportScreen({Key? key}) : super(key: key);

  @override
  State<FinancialReportScreen> createState() => _FinancialReportScreenState();
}

class _FinancialReportScreenState extends State<FinancialReportScreen> {
  final TransactionDao _transactionDao = TransactionDao();

  ReportPeriod _selectedPeriod = ReportPeriod.month;
  DateTime _startDate = FinancialReport.getStartOfMonth();
  DateTime _endDate = FinancialReport.getEndOfMonth();

  FinancialReport? _report;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadReport();
  }

  Future<void> _loadReport() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final report = await _transactionDao.generateReport(
        startDate: _startDate,
        endDate: _endDate,
      );

      setState(() {
        _report = report;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при формировании отчета: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _changePeriod(ReportPeriod period) {
    setState(() {
      _selectedPeriod = period;

      // Устанавливаем даты в зависимости от выбранного периода
      switch (period) {
        case ReportPeriod.month:
          _startDate = FinancialReport.getStartOfMonth();
          _endDate = FinancialReport.getEndOfMonth();
          break;
        case ReportPeriod.quarter:
          _startDate = FinancialReport.getStartOfQuarter();
          _endDate = FinancialReport.getEndOfQuarter();
          break;
        case ReportPeriod.year:
          _startDate = FinancialReport.getStartOfYear();
          _endDate = FinancialReport.getEndOfYear();
          break;
        case ReportPeriod.custom:
          // Для произвольного периода оставляем текущие даты
          // и вызываем диалог выбора периода
          _showDateRangeDialog();
          return;
      }

      _loadReport();
    });
  }

  Future<void> _showDateRangeDialog() async {
    final DateTimeRange? dateRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: Theme.of(context).colorScheme.primary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (dateRange != null) {
      setState(() {
        _startDate = dateRange.start;
        _endDate = dateRange.end;
      });

      _loadReport();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Форматер для дат
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансовый отчет'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              // Функция для экспорта отчета
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Функция экспорта отчета будет доступна в следующих версиях',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            tooltip: 'Экспорт отчета',
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _report == null
              ? Center(
                child: Text(
                  'Не удалось сформировать отчет',
                  style: TextStyle(color: Colors.grey[600], fontSize: 16),
                ),
              )
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Выбор периода
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Период отчета',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildPeriodChip(ReportPeriod.month),
                                const SizedBox(width: 8),
                                _buildPeriodChip(ReportPeriod.quarter),
                                const SizedBox(width: 8),
                                _buildPeriodChip(ReportPeriod.year),
                                const SizedBox(width: 8),
                                _buildPeriodChip(ReportPeriod.custom),
                              ],
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'С ${dateFormat.format(_startDate)} по ${dateFormat.format(_endDate)}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Финансовый итог
                    SummaryCard(
                      income: _report!.totalIncome,
                      expense: _report!.totalExpense,
                      balance: _report!.balance,
                    ),

                    // Диаграммы категорий
                    if (_report!.totalIncome > 0)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CategoryPieChart(
                              data: _report!.incomeByCategory,
                              type: TransactionType.income,
                              totalAmount: _report!.totalIncome,
                            ),
                          ),
                        ),
                      ),

                    if (_report!.totalExpense > 0)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: CategoryPieChart(
                              data: _report!.expenseByCategory,
                              type: TransactionType.expense,
                              totalAmount: _report!.totalExpense,
                            ),
                          ),
                        ),
                      ),

                    // Распределение по проектам (если есть данные)
                    if (_report!.incomeByProject.isNotEmpty ||
                        _report!.expenseByProject.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Распределение по проектам',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildProjectsDistribution(),
                              ],
                            ),
                          ),
                        ),
                      ),

                    // Распределение по клиентам (если есть данные)
                    if (_report!.incomeByClient.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Card(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Доходы по клиентам',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildClientsDistribution(),
                              ],
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
    );
  }

  Widget _buildPeriodChip(ReportPeriod period) {
    final isSelected = _selectedPeriod == period;

    return FilterChip(
      label: Text(period.name),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          _changePeriod(period);
        }
      },
      backgroundColor: Colors.grey[100],
      selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
      checkmarkColor: Theme.of(context).colorScheme.primary,
      labelStyle: TextStyle(
        color:
            isSelected ? Theme.of(context).colorScheme.primary : Colors.black,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  Widget _buildProjectsDistribution() {
    // Форматер для валюты
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: 'сом',
      decimalDigits: 0,
    );

    // Объединяем доходы и расходы по проектам
    final projectData = <String, Map<String, double>>{};

    for (var entry in _report!.incomeByProject.entries) {
      projectData[entry.key] = {'income': entry.value, 'expense': 0};
    }

    for (var entry in _report!.expenseByProject.entries) {
      if (projectData.containsKey(entry.key)) {
        projectData[entry.key]!['expense'] = entry.value;
      } else {
        projectData[entry.key] = {'income': 0, 'expense': entry.value};
      }
    }

    if (projectData.isEmpty) {
      return Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // Сортируем проекты по доходам (от большего к меньшему)
    final sortedProjects =
        projectData.entries.toList()..sort(
          (a, b) => (b.value['income']! - b.value['expense']!).compareTo(
            a.value['income']! - a.value['expense']!,
          ),
        );

    return Column(
      children:
          sortedProjects.map((entry) {
            final projectName = entry.key;
            final income = entry.value['income']!;
            final expense = entry.value['expense']!;
            final profit = income - expense;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    projectName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Доход: ${currencyFormat.format(income)}',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.green,
                        ),
                      ),
                      Text(
                        'Расход: ${currencyFormat.format(expense)}',
                        style: const TextStyle(fontSize: 14, color: Colors.red),
                      ),
                      Text(
                        'Прибыль: ${currencyFormat.format(profit)}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: profit >= 0 ? Colors.green : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: income > 0 ? expense / income : 0,
                      backgroundColor: Colors.green[100],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.red[400]!,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }

  Widget _buildClientsDistribution() {
    // Форматер для валюты
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: 'сом',
      decimalDigits: 0,
    );

    if (_report!.incomeByClient.isEmpty) {
      return Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // Сортируем клиентов по доходам (от большего к меньшему)
    final sortedClients =
        _report!.incomeByClient.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

    return Column(
      children:
          sortedClients.map((entry) {
            final clientName = entry.key;
            final income = entry.value;
            final percentage = income / _report!.totalIncome * 100;

            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    clientName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        currencyFormat.format(income),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).colorScheme.primary,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
    );
  }
}
