import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../../models/project.dart';
import '../../models/project_stage.dart';
import '../../database/project_dao.dart';

class AddEditProjectScreen extends StatefulWidget {
  final Project? project;

  const AddEditProjectScreen({super.key, this.project});

  @override
  State<AddEditProjectScreen> createState() => _AddEditProjectScreenState();
}

class _AddEditProjectScreenState extends State<AddEditProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectDao = ProjectDao();
  final _uuid = Uuid();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _clientIdController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _budgetController = TextEditingController();

  late DateTime _startDate;
  DateTime? _endDate;
  DateTime? _actualEndDate;
  late ProjectStatus _status;
  List<ProjectStage> _stages = [];
  String? _managerId;
  List<String>? _teamMembers;

  bool _isLoading = false;
  bool _isEditMode = false;

  @override
  void initState() {
    super.initState();
    _initializeForm();
  }

  void _initializeForm() {
    if (widget.project != null) {
      // Режим редактирования
      _isEditMode = true;

      _nameController.text = widget.project!.name;
      _descriptionController.text = widget.project!.description;
      _clientIdController.text = widget.project!.clientId;
      _clientNameController.text = widget.project!.clientName;
      _budgetController.text = widget.project!.budget.toString();

      _startDate = widget.project!.startDate;
      _endDate = widget.project!.endDate;
      _actualEndDate = widget.project!.actualEndDate;
      _status = widget.project!.status;

      // Создаем копии этапов проекта
      _stages =
          widget.project!.stages
              .map(
                (stage) => ProjectStage(
                  id: stage.id,
                  projectId: stage.projectId,
                  name: stage.name,
                  description: stage.description,
                  startDate: stage.startDate,
                  endDate: stage.endDate,
                  weight: stage.weight,
                  completed: stage.completed,
                  order: stage.order,
                ),
              )
              .toList();

      _managerId = widget.project!.managerId;
      _teamMembers = widget.project!.teamMembers;
    } else {
      // Режим создания нового проекта
      _startDate = DateTime.now();
      _status = ProjectStatus.planning;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _clientIdController.dispose();
    _clientNameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime initialDate =
        isStartDate ? _startDate : (_endDate ?? _startDate);

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: isStartDate ? DateTime(2020) : _startDate,
      lastDate: DateTime(2030),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Если дата начала позже даты окончания, корректируем дату окончания
          if (_endDate != null && _startDate.isAfter(_endDate!)) {
            _endDate = null;
          }
        } else {
          _endDate = picked;
        }
      });
    }
  }

  Future<void> _saveProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Рассчитываем прогресс на основе этапов
      double progress = 0.0;
      if (_stages.isNotEmpty) {
        double totalWeight = _stages.fold(
          0,
          (sum, stage) => sum + stage.weight,
        );
        double completedWeight = _stages.fold(
          0,
          (sum, stage) => sum + (stage.completed ? stage.weight : 0),
        );

        progress = totalWeight > 0 ? (completedWeight / totalWeight) : 0.0;
      }

      final project = Project(
        id: _isEditMode ? widget.project!.id : '',
        name: _nameController.text,
        description: _descriptionController.text,
        clientId:
            _clientIdController.text.isEmpty
                ? _uuid.v4()
                : _clientIdController.text,
        clientName: _clientNameController.text,
        startDate: _startDate,
        endDate: _endDate,
        actualEndDate: _actualEndDate,
        budget: double.parse(_budgetController.text),
        status: _status,
        stages: _stages,
        progress: progress,
        managerId: _managerId,
        teamMembers: _teamMembers,
        notes: widget.project?.notes,
      );

      if (_isEditMode) {
        await _projectDao.updateProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект успешно обновлен'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        await _projectDao.createProject(project);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Проект успешно создан'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Возвращаемся на предыдущий экран с результатом
      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка при сохранении проекта: $e'),
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
        title: Text(_isEditMode ? 'Редактирование проекта' : 'Новый проект'),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Основная информация о проекте
                      const Text(
                        'Основная информация',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Название проекта
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название проекта',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.folder),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название проекта';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Описание проекта
                      TextFormField(
                        controller: _descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание проекта',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.description),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Клиент
                      TextFormField(
                        controller: _clientNameController,
                        decoration: const InputDecoration(
                          labelText: 'Название клиента',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите название клиента';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Бюджет проекта
                      TextFormField(
                        controller: _budgetController,
                        decoration: const InputDecoration(
                          labelText: 'Бюджет проекта (сом)',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.monetization_on),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Введите бюджет проекта';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Даты проекта
                      const Text(
                        'Даты проекта',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Дата начала
                      InkWell(
                        onTap: () => _selectDate(context, true),
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Дата начала',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(_startDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Дата окончания (планируемая)
                      InkWell(
                        onTap: () => _selectDate(context, false),
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Планируемая дата окончания',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.event),
                            suffixIcon:
                                _endDate != null
                                    ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          _endDate = null;
                                        });
                                      },
                                    )
                                    : null,
                          ),
                          child: Text(
                            _endDate != null
                                ? DateFormat('dd.MM.yyyy').format(_endDate!)
                                : 'Не указана',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Статус проекта
                      DropdownButtonFormField<ProjectStatus>(
                        value: _status,
                        decoration: const InputDecoration(
                          labelText: 'Статус проекта',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.flag),
                        ),
                        items:
                            ProjectStatus.values.map((status) {
                              return DropdownMenuItem<ProjectStatus>(
                                value: status,
                                child: Text(status.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _status = value;

                              // Автоматически устанавливаем фактическую дату завершения
                              if (value == ProjectStatus.completed &&
                                  _actualEndDate == null) {
                                _actualEndDate = DateTime.now();
                              } else if (value != ProjectStatus.completed) {
                                _actualEndDate = null;
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Фактическая дата завершения (показывается только для завершенных проектов)
                      if (_status == ProjectStatus.completed)
                        InkWell(
                          onTap: () async {
                            final DateTime? picked = await showDatePicker(
                              context: context,
                              initialDate: _actualEndDate ?? DateTime.now(),
                              firstDate: _startDate,
                              lastDate: DateTime.now(),
                            );

                            if (picked != null) {
                              setState(() {
                                _actualEndDate = picked;
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: const InputDecoration(
                              labelText: 'Фактическая дата завершения',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.check_circle),
                            ),
                            child: Text(
                              _actualEndDate != null
                                  ? DateFormat(
                                    'dd.MM.yyyy',
                                  ).format(_actualEndDate!)
                                  : 'Не указана',
                            ),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Этапы проекта
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Этапы проекта',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _addStage,
                            icon: const Icon(Icons.add),
                            label: const Text('Добавить этап'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Список этапов проекта
                      if (_stages.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.format_list_bulleted,
                                  size: 48,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Этапы проекта не определены',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Добавьте этапы для отслеживания прогресса',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[500],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ReorderableListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _stages.length,
                          onReorder: (oldIndex, newIndex) {
                            setState(() {
                              if (oldIndex < newIndex) {
                                newIndex -= 1;
                              }
                              final item = _stages.removeAt(oldIndex);
                              _stages.insert(newIndex, item);

                              // Обновляем порядковые номера
                              for (int i = 0; i < _stages.length; i++) {
                                _stages[i] = _stages[i].copyWith(order: i);
                              }
                            });
                          },
                          itemBuilder: (context, index) {
                            final stage = _stages[index];
                            return _buildStageItem(stage, index);
                          },
                        ),

                      const SizedBox(height: 32),

                      // Кнопка сохранения
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _saveProject,
                          child: Text(
                            _isEditMode
                                ? 'Сохранить изменения'
                                : 'Создать проект',
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

  Widget _buildStageItem(ProjectStage stage, int index) {
    return Card(
      key: ValueKey(stage.id),
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Иконка для перетаскивания
                Icon(Icons.drag_handle, color: Colors.grey[400]),
                const SizedBox(width: 8),

                // Название этапа
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (stage.description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          stage.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),

                // Чекбокс "Выполнено"
                Checkbox(
                  value: stage.completed,
                  onChanged: (value) {
                    setState(() {
                      _stages[index] = stage.copyWith(
                        completed: value ?? false,
                      );
                    });
                  },
                ),
              ],
            ),

            // Даты и вес в отдельной строке для лучшего размещения
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Даты
                Flexible(
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        DateFormat('dd.MM.yyyy').format(stage.startDate),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Стрелка между датами
                Icon(Icons.arrow_forward, size: 12, color: Colors.grey[400]),

                // Дата окончания
                Flexible(
                  child: Row(
                    children: [
                      Icon(Icons.event, size: 14, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        stage.endDate != null
                            ? DateFormat('dd.MM.yyyy').format(stage.endDate!)
                            : 'Не указана',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Вес этапа
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${(stage.weight * 100).round()}%',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                // Кнопки действий
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit, size: 20),
                      onPressed: () => _editStage(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(
                        Icons.delete,
                        size: 20,
                        color: Colors.red,
                      ),
                      onPressed: () => _removeStage(index),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      splashRadius: 20,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _addStage() {
    _showStageDialog();
  }

  void _editStage(int index) {
    _showStageDialog(stageIndex: index);
  }

  void _removeStage(int index) {
    setState(() {
      _stages.removeAt(index);

      // Обновляем порядковые номера
      for (int i = 0; i < _stages.length; i++) {
        _stages[i] = _stages[i].copyWith(order: i);
      }
    });
  }

  void _showStageDialog({int? stageIndex}) {
    final isEditing = stageIndex != null;
    final stage = isEditing ? _stages[stageIndex] : null;

    final nameController = TextEditingController(text: stage?.name ?? '');
    final descriptionController = TextEditingController(
      text: stage?.description ?? '',
    );
    final weightController = TextEditingController(
      text: stage != null ? (stage.weight * 100).toString() : '10',
    );

    var startDate = stage?.startDate ?? _startDate;
    DateTime? endDate = stage?.endDate;
    var completed = stage?.completed ?? false;

    showDialog(
      context: context,
      builder:
          (context) => StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
                title: Text(isEditing ? 'Редактирование этапа' : 'Новый этап'),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Название этапа
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'Название этапа',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Описание этапа
                      TextFormField(
                        controller: descriptionController,
                        decoration: const InputDecoration(
                          labelText: 'Описание',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 16),

                      // Дата начала
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: startDate,
                            firstDate: _startDate,
                            lastDate: _endDate ?? DateTime(2030),
                          );

                          if (picked != null) {
                            setState(() {
                              startDate = picked;
                              // Если дата начала позже даты окончания, сбрасываем дату окончания
                              if (endDate != null &&
                                  startDate.isAfter(endDate!)) {
                                endDate = null;
                              }
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Дата начала',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.calendar_today),
                          ),
                          child: Text(
                            DateFormat('dd.MM.yyyy').format(startDate),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Дата окончания
                      InkWell(
                        onTap: () async {
                          final DateTime? picked = await showDatePicker(
                            context: context,
                            initialDate: endDate ?? startDate,
                            firstDate: startDate,
                            lastDate: _endDate ?? DateTime(2030),
                          );

                          if (picked != null) {
                            setState(() {
                              endDate = picked;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Дата окончания',
                            border: const OutlineInputBorder(),
                            prefixIcon: const Icon(Icons.event),
                            suffixIcon:
                                endDate != null
                                    ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        setState(() {
                                          endDate = null;
                                        });
                                      },
                                    )
                                    : null,
                          ),
                          child: Text(
                            endDate != null
                                ? DateFormat('dd.MM.yyyy').format(endDate!)
                                : 'Не указана',
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Вес этапа
                      TextFormField(
                        controller: weightController,
                        decoration: const InputDecoration(
                          labelText: 'Вес этапа (%)',
                          border: OutlineInputBorder(),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Флаг "Выполнено"
                      Row(
                        children: [
                          Checkbox(
                            value: completed,
                            onChanged: (value) {
                              setState(() {
                                completed = value ?? false;
                              });
                            },
                          ),
                          const Text('Этап выполнен'),
                        ],
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text('Отмена'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      if (nameController.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Введите название этапа'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      // Проверяем и преобразуем вес
                      double weight;
                      try {
                        weight = double.parse(weightController.text) / 100;
                        if (weight <= 0 || weight > 1) {
                          throw Exception('Вес должен быть от 1 до 100');
                        }
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Введите корректный вес этапа (от 1 до 100)',
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                        return;
                      }

                      final newStage = ProjectStage(
                        id: stage?.id ?? _uuid.v4(),
                        projectId: stage?.projectId ?? '',
                        name: nameController.text,
                        description: descriptionController.text,
                        startDate: startDate,
                        endDate: endDate,
                        weight: weight,
                        completed: completed,
                        order: stage?.order ?? _stages.length,
                      );

                      this.setState(() {
                        if (isEditing) {
                          _stages[stageIndex] = newStage;
                        } else {
                          _stages.add(newStage);
                        }
                      });

                      Navigator.pop(context);
                    },
                    child: Text(isEditing ? 'Сохранить' : 'Добавить'),
                  ),
                ],
              );
            },
          ),
    );
  }
}
