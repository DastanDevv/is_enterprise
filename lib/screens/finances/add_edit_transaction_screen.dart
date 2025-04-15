import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../models/finance.dart';
import '../../database/transaction_dao.dart';
import '../../database/project_dao.dart';
import '../../database/client_dao.dart';
import '../../models/project.dart';
import '../../models/client.dart';

class AddEditTransactionScreen extends StatefulWidget {
  final Transaction? transaction;

  const AddEditTransactionScreen({Key? key, this.transaction})
    : super(key: key);

  @override
  State<AddEditTransactionScreen> createState() =>
      _AddEditTransactionScreenState();
}

class _AddEditTransactionScreenState extends State<AddEditTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _transactionDao = TransactionDao();
  final _projectDao = ProjectDao();
  final _clientDao = ClientDao();

  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  late DateTime _date;

  Project? _selectedProject;
  Client? _selectedClient;

  List<Project> _projects = [];
  List<Client> _clients = [];

  bool _isLoading = false;
  bool _isInitLoading = true;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _loadProjectsAndClients();
    _initializeForm();
  }

  Future<void> _loadProjectsAndClients() async {
    try {
      // Загружаем проекты
      final projects = await _projectDao.getAllProjects();

      // Загружаем клиентов
      final clients = await _clientDao.getAllClients();

      setState(() {
        _projects = projects;
        _clients = clients;
        _isInitLoading = false;
      });
    } catch (e) {
      print('Ошибка при загрузке данных: $e');
      setState(() {
        _isInitLoading = false;
      });
    }
  }

  void _initializeForm() {
    if (widget.transaction != null) {
      // Режим редактирования
      _isEditMode = true;

      _selectedType = widget.transaction!.type;
      _selectedCategory = widget.transaction!.category;
      _amountController.text = widget.transaction!.amount.toString();
      _descriptionController.text = widget.transaction!.description ?? '';
      _date = widget.transaction!.date;

      // Связанный проект будет установлен после загрузки проектов
      // Связанный клиент будет установлен после загрузки клиентов
    } else {
      // Режим создания новой транзакции
      _selectedType = TransactionType.income;
      _selectedCategory = TransactionCategory.projectPayment;
      _date = DateTime.now();
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final amount = double.parse(_amountController.text);

      final transaction = Transaction(
        id: _isEditMode ? widget.transaction!.id : '',
        type: _selectedType,
        category: _selectedCategory,
        amount: amount,
        date: _date,
        description:
            _descriptionController.text.isNotEmpty
                ? _descriptionController.text
                : null,
        projectId: _selectedProject?.id,
        projectName: _selectedProject?.name,
        clientId: _selectedClient?.id,
        clientName: _selectedClient?.name,
      );

      if (_isEditMode) {
        await _transactionDao.updateTransaction(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Транзакция успешно обновлена'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _transactionDao.createTransaction(transaction);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Транзакция успешно создана'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Возвращаемся на предыдущий экран с результатом
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении транзакции: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditMode ? 'Редактирование транзакции' : 'Новая транзакция',
        ),
      ),
      body:
          _isInitLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Тип транзакции
                      const Text(
                        'Тип транзакции',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTypeButton(
                              type: TransactionType.income,
                              icon: Icons.arrow_downward,
                              color: Colors.green,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTypeButton(
                              type: TransactionType.expense,
                              icon: Icons.arrow_upward,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Категория транзакции
                      const Text(
                        'Категория',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<TransactionCategory>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.category),
                        ),
                        items:
                            TransactionCategory.values.map((category) {
                              return DropdownMenuItem<TransactionCategory>(
                                value: category,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null) {
                            return 'Выберите категорию';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Сумма
                      TextFormField(
                        controller: _amountController,
                        decoration: const InputDecoration(
                          labelText: 'Сумма (сом)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.monetization_on),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d+\.?\d{0,2}'),
                          ),
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите сумму';
                          }
                          try {
                            final amount = double.parse(value);
                            if (amount <= 0) {
                              return 'Сумма должна быть больше нуля';
                            }
                          } catch (e) {
                            return 'Введите корректное число';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Дата
                      InkWell(
                        onTap: () => _selectDate(context),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Дата',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(DateFormat('dd.MM.yyyy').format(_date)),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Описание
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание (необязательно)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 24),

                      // Связь с проектом и клиентом
                      const Text(
                        'Связи',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Проект
                      DropdownButtonFormField<Project?>(
                        value: _selectedProject,
                        decoration: const InputDecoration(
                          labelText: 'Проект (необязательно)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<Project?>(
                            value: null,
                            child: Text('Не выбрано'),
                          ),
                          ..._projects.map((project) {
                            return DropdownMenuItem<Project?>(
                              value: project,
                              child: Text(project.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedProject = value;

                            // Если выбран проект, автоматически устанавливаем его клиента
                            if (value != null) {
                              _selectedClient = _clients.firstWhere(
                                (client) => client.id == value.clientId,
                                orElse: () => _selectedClient!,
                              );
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Клиент
                      DropdownButtonFormField<Client?>(
                        value: _selectedClient,
                        decoration: const InputDecoration(
                          labelText: 'Клиент (необязательно)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                        items: [
                          const DropdownMenuItem<Client?>(
                            value: null,
                            child: Text('Не выбрано'),
                          ),
                          ..._clients.map((client) {
                            return DropdownMenuItem<Client?>(
                              value: client,
                              child: Text(client.name),
                            );
                          }).toList(),
                        ],
                        onChanged: (value) {
                          setState(() {
                            _selectedClient = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Кнопка сохранения
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveTransaction,
                          child:
                              _isLoading
                                  ? const CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  )
                                  : Text(
                                    _isEditMode
                                        ? 'Сохранить изменения'
                                        : 'Создать транзакцию',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildTypeButton({
    required TransactionType type,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedType == type;

    return InkWell(
      onTap: () {
        setState(() {
          _selectedType = type;
        });
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.2) : Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: isSelected ? color.withOpacity(0.2) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? color : Colors.grey[600],
                size: 30,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              type.name,
              style: TextStyle(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? color : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
