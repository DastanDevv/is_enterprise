class ProjectStage {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final DateTime startDate;
  final DateTime? endDate;
  final double weight; // Вес этапа для расчета прогресса (в процентах)
  final bool completed;
  final int order; // Порядок этапа в проекте

  ProjectStage({
    required this.id,
    required this.projectId,
    required this.name,
    required this.description,
    required this.startDate,
    this.endDate,
    required this.weight,
    required this.completed,
    required this.order,
  });

  // Создаем копию объекта ProjectStage с обновленными полями
  ProjectStage copyWith({
    String? id,
    String? projectId,
    String? name,
    String? description,
    DateTime? startDate,
    DateTime? endDate,
    double? weight,
    bool? completed,
    int? order,
  }) {
    return ProjectStage(
      id: id ?? this.id,
      projectId: projectId ?? this.projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      weight: weight ?? this.weight,
      completed: completed ?? this.completed,
      order: order ?? this.order,
    );
  }

  // Преобразование в Map для сохранения в базе данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'project_id': projectId,
      'name': name,
      'description': description,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'weight': weight,
      'completed': completed ? 1 : 0,
      'order': order,
    };
  }

  // Создание объекта ProjectStage из Map, полученного из базы данных
  factory ProjectStage.fromMap(Map<String, dynamic> map) {
    return ProjectStage(
      id: map['id'],
      projectId: map['project_id'],
      name: map['name'],
      description: map['description'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      weight: map['weight'],
      completed: map['completed'] == 1,
      order: map['order'],
    );
  }
}
