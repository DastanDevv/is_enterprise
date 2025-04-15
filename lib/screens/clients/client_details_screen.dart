import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/client.dart';
import '../../database/client_dao.dart';
import '../../database/project_dao.dart';
import '../../models/project.dart';
import '../../widgets/project_widgets/project_card.dart';
import '../projects/project_details_screen.dart';
import 'add_edit_client_screen.dart';

class ClientDetailsScreen extends StatefulWidget {
  final String clientId;

  const ClientDetailsScreen({Key? key, required this.clientId})
    : super(key: key);

  @override
  State<ClientDetailsScreen> createState() => _ClientDetailsScreenState();
}

class _ClientDetailsScreenState extends State<ClientDetailsScreen> {
  final ClientDao _clientDao = ClientDao();
  final ProjectDao _projectDao = ProjectDao();
  Client? _client;
  List<Project> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClientAndProjects();
  }

  Future<void> _loadClientAndProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Загружаем информацию о клиенте
      final client = await _clientDao.getClientById(widget.clientId);

      // Загружаем проекты клиента
      List<Project> projects = [];
      if (client != null) {
        final projectsData = await _clientDao.getClientProjects(client.id);
        for (var projectMap in projectsData) {
          final stages = await _projectDao.getProjectStages(
            projectMap['id'] as String,
          );
          projects.add(Project.fromMap(projectMap, stages));
        }
      }

      setState(() {
        _client = client;
        _projects = projects;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при загрузке данных: $e'),
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

  // Обновление даты последнего контакта
  Future<void> _updateLastContactDate() async {
    if (_client == null) return;

    try {
      await _clientDao.updateLastContactDate(_client!.id, DateTime.now());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Дата последнего контакта обновлена'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadClientAndProjects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при обновлении даты: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Форматеры для дат и валюты
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_isLoading ? 'Детали клиента' : (_client?.name ?? '')),
        actions: [
          if (!_isLoading && _client != null)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'edit') {
                  _editClient();
                } else if (value == 'update_contact') {
                  _updateLastContactDate();
                }
              },
              itemBuilder:
                  (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Редактировать'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'update_contact',
                      child: Row(
                        children: [
                          Icon(Icons.update, size: 18),
                          SizedBox(width: 8),
                          Text('Обновить дату контакта'),
                        ],
                      ),
                    ),
                  ],
            ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _client == null
              ? _buildNotFoundState()
              : SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Блок основной информации о клиенте
                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Имя и тип клиента
                          Row(
                            children: [
                              // Аватар клиента
                              Container(
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _getTypeColor(
                                    _client!.type,
                                  ).withOpacity(0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    _getInitials(_client!.name),
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: _getTypeColor(_client!.type),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),

                              // Имя клиента
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _client!.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getTypeColor(
                                          _client!.type,
                                        ).withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        _client!.type.name,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: _getTypeColor(_client!.type),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Контактное лицо
                          _buildInfoRow(
                            icon: Icons.person,
                            title: 'Контактное лицо:',
                            value: _client!.contactPerson,
                          ),
                          const SizedBox(height: 12),

                          // Телефон
                          _buildInfoRow(
                            icon: Icons.phone,
                            title: 'Телефон:',
                            value: _client!.phone,
                          ),
                          const SizedBox(height: 12),

                          // Email
                          _buildInfoRow(
                            icon: Icons.email,
                            title: 'Email:',
                            value: _client!.email,
                          ),
                          const SizedBox(height: 12),

                          // Адрес
                          _buildInfoRow(
                            icon: Icons.location_on,
                            title: 'Адрес:',
                            value: _client!.address,
                          ),

                          // Веб-сайт
                          if (_client!.website != null &&
                              _client!.website!.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            _buildInfoRow(
                              icon: Icons.web,
                              title: 'Веб-сайт:',
                              value: _client!.website!,
                            ),
                          ],

                          const SizedBox(height: 24),

                          // Даты создания и последнего контакта
                          Row(
                            children: [
                              Expanded(
                                child: _buildDateInfo(
                                  'Дата создания',
                                  dateFormat.format(_client!.createdAt),
                                  Icons.calendar_today,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildDateInfo(
                                  'Последний контакт',
                                  _client!.lastContactDate != null
                                      ? dateFormat.format(
                                        _client!.lastContactDate!,
                                      )
                                      : 'Не было',
                                  Icons.history,
                                ),
                              ),
                            ],
                          ),

                          // Примечания
                          if (_client!.notes != null &&
                              _client!.notes!.isNotEmpty) ...[
                            const SizedBox(height: 24),
                            const Text(
                              'Примечания:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _client!.notes!,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Заголовок для проектов клиента
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Проекты клиента (${_projects.length})',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Список проектов клиента
                    if (_projects.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.folder_outlined,
                                size: 48,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'У клиента пока нет проектов',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _projects.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (context, index) {
                          final project = _projects[index];
                          return ProjectCard(
                            project: project,
                            onTap: () async {
                              final result = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (context) => ProjectDetailsScreen(
                                        projectId: project.id,
                                      ),
                                ),
                              );
                              if (result == true) {
                                _loadClientAndProjects();
                              }
                            },
                          );
                        },
                      ),
                  ],
                ),
              ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[700],
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 16)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(String title, String date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                title,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            date,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Future<void> _editClient() async {
    if (_client == null) return;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddEditClientScreen(client: _client),
      ),
    );

    if (result == true) {
      _loadClientAndProjects();
    }
  }

  Widget _buildNotFoundState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person_off, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Клиент не найден',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Клиент с указанным ID не существует',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text('Вернуться к списку клиентов'),
          ),
        ],
      ),
    );
  }

  // Получение инициалов из имени
  String _getInitials(String name) {
    final nameParts = name.split(' ');
    if (nameParts.length > 1) {
      return '${nameParts[0][0]}${nameParts[1][0]}';
    } else if (name.isNotEmpty) {
      return name[0];
    } else {
      return '?';
    }
  }

  // Функция для получения цвета типа клиента
  Color _getTypeColor(ClientType type) {
    String hexColor = type.color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
