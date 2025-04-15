import 'package:flutter/material.dart';
import '../../models/finance.dart';
import '../../database/transaction_dao.dart';
import '../../widgets/finance_widgets/transaction_card.dart';
import '../../widgets/finance_widgets/summary_card.dart';
import 'financial_report_screen.dart';
import 'add_edit_transaction_screen.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  final TransactionDao _transactionDao = TransactionDao();
  List<Transaction> _transactions = [];
  double _totalIncome = 0;
  double _totalExpense = 0;
  bool _isLoading = true;
  TransactionType? _selectedTypeFilter;
  TransactionCategory? _selectedCategoryFilter;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Загрузка транзакций из базы данных
  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final transactions = await _transactionDao.getAllTransactions(
        type: _selectedTypeFilter,
        category: _selectedCategoryFilter,
      );

      // Получаем суммы доходов и расходов
      final totalIncome = await _transactionDao.getTotalIncome();
      final totalExpense = await _transactionDao.getTotalExpense();

      setState(() {
        _transactions = transactions;
        _totalIncome = totalIncome;
        _totalExpense = totalExpense;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при загрузке транзакций: $e'),
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

  // Удаление транзакции
  Future<void> _deleteTransaction(String transactionId) async {
    try {
      await _transactionDao.deleteTransaction(transactionId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Транзакция успешно удалена'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadTransactions();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении транзакции: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Показать диалог подтверждения удаления
  void _showDeleteConfirmationDialog(String transactionId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Удаление транзакции'),
            content: const Text(
              'Вы уверены, что хотите удалить эту транзакцию? '
              'Это действие невозможно отменить.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _deleteTransaction(transactionId);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Удалить'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Финансы'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтр',
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const FinancialReportScreen(),
                ),
              );
            },
            tooltip: 'Отчет',
          ),
        ],
      ),
      body: Column(
        children: [
          // Поисковая строка
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Поиск транзакций...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                            setState(() {
                              _searchQuery = '';
                            });
                            _loadTransactions();
                          },
                        )
                        : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                // Реализация поиска будет добавлена позже
              },
            ),
          ),

          // Чипы фильтров (если выбраны)
          if (_selectedTypeFilter != null || _selectedCategoryFilter != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_selectedTypeFilter != null)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Chip(
                          label: Text(_selectedTypeFilter!.name),
                          deleteIcon: const Icon(Icons.close, size: 18),
                          onDeleted: () {
                            setState(() {
                              _selectedTypeFilter = null;
                            });
                            _loadTransactions();
                          },
                          backgroundColor: _getTypeColor(
                            _selectedTypeFilter!,
                          ).withOpacity(0.2),
                          labelStyle: TextStyle(
                            color: _getTypeColor(_selectedTypeFilter!),
                            fontWeight: FontWeight.w500,
                          ),
                          deleteIconColor: _getTypeColor(_selectedTypeFilter!),
                        ),
                      ),
                    if (_selectedCategoryFilter != null)
                      Chip(
                        label: Text(_selectedCategoryFilter!.name),
                        deleteIcon: const Icon(Icons.close, size: 18),
                        onDeleted: () {
                          setState(() {
                            _selectedCategoryFilter = null;
                          });
                          _loadTransactions();
                        },
                        backgroundColor: Colors.grey[300],
                        labelStyle: TextStyle(
                          color: Colors.grey[800],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                  ],
                ),
              ),
            ),

          // Сводка
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SummaryCard(
              income: _totalIncome,
              expense: _totalExpense,
              balance: _totalIncome - _totalExpense,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const FinancialReportScreen(),
                  ),
                );
              },
            ),
          ),

          // Список транзакций
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _transactions.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 88),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return TransactionCard(
                          transaction: transaction,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddEditTransactionScreen(
                                      transaction: transaction,
                                    ),
                              ),
                            );
                            if (result == true) {
                              _loadTransactions();
                            }
                          },
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => AddEditTransactionScreen(
                                      transaction: transaction,
                                    ),
                              ),
                            );
                            if (result == true) {
                              _loadTransactions();
                            }
                          },
                          onDelete: () {
                            _showDeleteConfirmationDialog(transaction.id);
                          },
                        );
                      },
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AddEditTransactionScreen(),
            ),
          );
          if (result == true) {
            _loadTransactions();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Добавить транзакцию',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            _selectedTypeFilter != null || _selectedCategoryFilter != null
                ? 'Транзакции не найдены'
                : 'У вас пока нет транзакций',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedTypeFilter != null || _selectedCategoryFilter != null
                ? 'Попробуйте изменить параметры фильтров'
                : 'Создайте свою первую транзакцию, нажав кнопку "+"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (_selectedTypeFilter != null ||
              _selectedCategoryFilter != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _selectedTypeFilter = null;
                  _selectedCategoryFilter = null;
                });
                _loadTransactions();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Сбросить все фильтры'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Фильтры',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Тип транзакции',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children:
                          TransactionType.values.map((type) {
                            final isSelected = _selectedTypeFilter == type;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text(type.name),
                                selected: isSelected,
                                onSelected: (selected) {
                                  setState(() {
                                    _selectedTypeFilter =
                                        selected ? type : null;
                                  });
                                },
                                backgroundColor: Colors.grey[100],
                                selectedColor: _getTypeColor(
                                  type,
                                ).withOpacity(0.2),
                                checkmarkColor: _getTypeColor(type),
                                labelStyle: TextStyle(
                                  color:
                                      isSelected
                                          ? _getTypeColor(type)
                                          : Colors.black,
                                  fontWeight:
                                      isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                            );
                          }).toList(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Категория',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        TransactionCategory.values.map((category) {
                          final isSelected =
                              _selectedCategoryFilter == category;
                          return FilterChip(
                            label: Text(category.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategoryFilter =
                                    selected ? category : null;
                              });
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: Colors.grey[300],
                            labelStyle: TextStyle(
                              color:
                                  isSelected ? Colors.black : Colors.grey[700],
                              fontWeight:
                                  isSelected
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedTypeFilter = null;
                            _selectedCategoryFilter = null;
                          });
                        },
                        child: const Text('Сбросить все'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          this._loadTransactions();
                        },
                        child: const Text('Применить'),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Color _getTypeColor(TransactionType type) {
    String hexColor = type.color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
