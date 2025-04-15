import 'package:flutter/material.dart';
import '../../models/client.dart';
import '../../database/client_dao.dart';
import '../../widgets/client_widgets/client_card.dart';
import 'client_details_screen.dart';
import 'add_edit_client_screen.dart';

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({Key? key}) : super(key: key);

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  final ClientDao _clientDao = ClientDao();
  List<Client> _clients = [];
  bool _isLoading = true;
  String _selectedTypeFilter = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Загрузка клиентов из базы данных
  Future<void> _loadClients() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_searchQuery.isNotEmpty) {
        // Поиск клиентов по запросу
        final filteredClients = await _clientDao.getFilteredClients(
          search: _searchQuery,
          type:
              _selectedTypeFilter.isNotEmpty
                  ? ClientType.values.firstWhere(
                    (t) => t.name == _selectedTypeFilter,
                    orElse: () => ClientType.values.first,
                  )
                  : null,
        );
        setState(() {
          _clients = filteredClients;
        });
      } else if (_selectedTypeFilter.isNotEmpty) {
        // Фильтрация по типу
        final filteredClients = await _clientDao.getAllClients(
          typeFilter: _selectedTypeFilter,
        );
        setState(() {
          _clients = filteredClients;
        });
      } else {
        // Загрузка всех клиентов
        final allClients = await _clientDao.getAllClients();
        setState(() {
          _clients = allClients;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при загрузке клиентов: $e'),
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

  // Удаление клиента
  Future<void> _deleteClient(String clientId) async {
    try {
      await _clientDao.deleteClient(clientId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Клиент успешно удален'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadClients();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении клиента: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Показать диалог подтверждения удаления
  void _showDeleteConfirmationDialog(
    String clientId,
    String clientName,
    int projectsCount,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Удаление клиента'),
            content:
                projectsCount > 0
                    ? Text(
                      'Клиент "$clientName" имеет $projectsCount ${_projectsCountText(projectsCount)}. '
                      'Сначала удалите все проекты клиента.',
                    )
                    : Text(
                      'Вы уверены, что хотите удалить клиента "$clientName"? '
                      'Это действие невозможно отменить.',
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Отмена'),
              ),
              if (projectsCount == 0)
                ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _deleteClient(clientId);
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Удалить'),
                ),
            ],
          ),
    );
  }

  // Получение правильного склонения слова "проект"
  String _projectsCountText(int count) {
    if (count % 10 == 1 && count % 100 != 11) {
      return 'проект';
    } else if ([2, 3, 4].contains(count % 10) &&
        ![12, 13, 14].contains(count % 100)) {
      return 'проекта';
    } else {
      return 'проектов';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Клиенты'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Фильтр',
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
                hintText: 'Поиск клиентов...',
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
                            _loadClients();
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
                _loadClients();
              },
            ),
          ),

          // Чипы фильтров типов
          if (_selectedTypeFilter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(_selectedTypeFilter),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedTypeFilter = '';
                      });
                      _loadClients();
                    },
                    backgroundColor: _getTypeColor(
                      _selectedTypeFilter,
                    ).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getTypeColor(_selectedTypeFilter),
                      fontWeight: FontWeight.w500,
                    ),
                    deleteIconColor: _getTypeColor(_selectedTypeFilter),
                  ),
                ],
              ),
            ),

          // Список клиентов
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _clients.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 88),
                      itemCount: _clients.length,
                      itemBuilder: (context, index) {
                        final client = _clients[index];
                        return ClientCard(
                          client: client,
                          onTap: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ClientDetailsScreen(
                                      clientId: client.id,
                                    ),
                              ),
                            );
                            if (result == true) {
                              _loadClients();
                            }
                          },
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddEditClientScreen(client: client),
                              ),
                            );
                            if (result == true) {
                              _loadClients();
                            }
                          },
                          onDelete: () {
                            _showDeleteConfirmationDialog(
                              client.id,
                              client.name,
                              client.projectsCount,
                            );
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
              builder: (context) => const AddEditClientScreen(),
            ),
          );
          if (result == true) {
            _loadClients();
          }
        },
        child: const Icon(Icons.add),
        tooltip: 'Добавить клиента',
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedTypeFilter.isNotEmpty
                ? 'Клиенты не найдены'
                : 'У вас пока нет клиентов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedTypeFilter.isNotEmpty
                ? 'Попробуйте изменить параметры поиска или фильтры'
                : 'Создайте своего первого клиента, нажав кнопку "+"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _selectedTypeFilter.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedTypeFilter = '';
                });
                _loadClients();
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
                    'Фильтр по типу',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        ClientType.values.map((type) {
                          final isSelected = _selectedTypeFilter == type.name;
                          return FilterChip(
                            label: Text(type.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              Navigator.pop(context);
                              setState(() {
                                _selectedTypeFilter = selected ? type.name : '';
                              });
                              this.setState(() {
                                _selectedTypeFilter = selected ? type.name : '';
                              });
                              _loadClients();
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: _getTypeColor(
                              type.name,
                            ).withOpacity(0.2),
                            checkmarkColor: _getTypeColor(type.name),
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? _getTypeColor(type.name)
                                      : Colors.black,
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
                          Navigator.pop(context);
                          this.setState(() {
                            _selectedTypeFilter = '';
                          });
                          _loadClients();
                        },
                        child: const Text('Сбросить все'),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        child: const Text('Закрыть'),
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

  Color _getTypeColor(String typeName) {
    final type = ClientType.values.firstWhere(
      (t) => t.name == typeName,
      orElse: () => ClientType.individual,
    );

    // Конвертация HEX цвета в Color
    String hexColor = type.color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
