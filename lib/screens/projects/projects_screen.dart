import 'package:flutter/material.dart';
import '../../models/project.dart';
import '../../database/project_dao.dart';
import '../../widgets/project_widgets/project_card.dart';
import 'project_details_screen.dart';
import 'add_edit_project_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final ProjectDao _projectDao = ProjectDao();
  List<Project> _projects = [];
  bool _isLoading = true;
  String _selectedStatusFilter = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Загрузка проектов из базы данных
  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_searchQuery.isNotEmpty) {
        // Поиск проектов по запросу
        final filteredProjects = await _projectDao.getFilteredProjects(
          search: _searchQuery,
          status:
              _selectedStatusFilter.isNotEmpty
                  ? ProjectStatus.values.firstWhere(
                    (s) => s.name == _selectedStatusFilter,
                    orElse: () => ProjectStatus.values.first,
                  )
                  : null,
        );
        setState(() {
          _projects = filteredProjects;
        });
      } else if (_selectedStatusFilter.isNotEmpty) {
        // Фильтрация по статусу
        final filteredProjects = await _projectDao.getAllProjects(
          statusFilter: _selectedStatusFilter,
        );
        setState(() {
          _projects = filteredProjects;
        });
      } else {
        // Загрузка всех проектов
        final allProjects = await _projectDao.getAllProjects();
        setState(() {
          _projects = allProjects;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при загрузке проектов: $e'),
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

  // Удаление проекта
  Future<void> _deleteProject(String projectId) async {
    try {
      await _projectDao.deleteProject(projectId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Проект успешно удален'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadProjects();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при удалении проекта: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Показать диалог подтверждения удаления
  void _showDeleteConfirmationDialog(String projectId, String projectName) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Удаление проекта'),
            content: Text(
              'Вы уверены, что хотите удалить проект "$projectName"? '
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
                  _deleteProject(projectId);
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
        title: const Text('Проекты'),
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
                hintText: 'Поиск проектов...',
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
                            _loadProjects();
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
                _loadProjects();
              },
            ),
          ),

          // Чипы фильтров статусов
          if (_selectedStatusFilter.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Wrap(
                spacing: 8,
                children: [
                  Chip(
                    label: Text(_selectedStatusFilter),
                    deleteIcon: const Icon(Icons.close, size: 18),
                    onDeleted: () {
                      setState(() {
                        _selectedStatusFilter = '';
                      });
                      _loadProjects();
                    },
                    backgroundColor: _getStatusColor(
                      _selectedStatusFilter,
                    ).withOpacity(0.2),
                    labelStyle: TextStyle(
                      color: _getStatusColor(_selectedStatusFilter),
                      fontWeight: FontWeight.w500,
                    ),
                    deleteIconColor: _getStatusColor(_selectedStatusFilter),
                  ),
                ],
              ),
            ),

          // Список проектов
          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _projects.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                      padding: const EdgeInsets.only(top: 8, bottom: 88),
                      itemCount: _projects.length,
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
                              _loadProjects();
                            }
                          },
                          onEdit: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        AddEditProjectScreen(project: project),
                              ),
                            );
                            if (result == true) {
                              _loadProjects();
                            }
                          },
                          onDelete: () {
                            _showDeleteConfirmationDialog(
                              project.id,
                              project.name,
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
              builder: (context) => const AddEditProjectScreen(),
            ),
          );
          if (result == true) {
            _loadProjects();
          }
        },
        tooltip: 'Добавить проект',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isNotEmpty || _selectedStatusFilter.isNotEmpty
                ? 'Проекты не найдены'
                : 'У вас пока нет проектов',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _searchQuery.isNotEmpty || _selectedStatusFilter.isNotEmpty
                ? 'Попробуйте изменить параметры поиска или фильтры'
                : 'Создайте свой первый проект, нажав кнопку "+"',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty || _selectedStatusFilter.isNotEmpty) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _selectedStatusFilter = '';
                });
                _loadProjects();
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
                    'Фильтр по статусу',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children:
                        ProjectStatus.values.map((status) {
                          final isSelected =
                              _selectedStatusFilter == status.name;
                          return FilterChip(
                            label: Text(status.name),
                            selected: isSelected,
                            onSelected: (selected) {
                              Navigator.pop(context);
                              setState(() {
                                _selectedStatusFilter =
                                    selected ? status.name : '';
                              });
                              this.setState(() {
                                _selectedStatusFilter =
                                    selected ? status.name : '';
                              });
                              _loadProjects();
                            },
                            backgroundColor: Colors.grey[100],
                            selectedColor: _getStatusColor(
                              status.name,
                            ).withOpacity(0.2),
                            checkmarkColor: _getStatusColor(status.name),
                            labelStyle: TextStyle(
                              color:
                                  isSelected
                                      ? _getStatusColor(status.name)
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
                            _selectedStatusFilter = '';
                          });
                          _loadProjects();
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

  Color _getStatusColor(String statusName) {
    final status = ProjectStatus.values.firstWhere(
      (s) => s.name == statusName,
      orElse: () => ProjectStatus.planning,
    );

    // Конвертация HEX цвета в Color
    String hexColor = status.color.replaceAll('#', '');
    if (hexColor.length == 6) {
      hexColor = 'FF$hexColor';
    }
    return Color(int.parse(hexColor, radix: 16));
  }
}
