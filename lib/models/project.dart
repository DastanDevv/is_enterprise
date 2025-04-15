import 'package:flutter_vkr/models/project_stage.dart';

enum ProjectStatus { planning, inProgress, completed, onHold, cancelled }

extension ProjectStatusExtension on ProjectStatus {
  String get name {
    switch (this) {
      case ProjectStatus.planning:
        return 'Планирование';
      case ProjectStatus.inProgress:
        return 'В работе';
      case ProjectStatus.completed:
        return 'Завершен';
      case ProjectStatus.onHold:
        return 'На паузе';
      case ProjectStatus.cancelled:
        return 'Отменен';
    }
  }

  String get color {
    switch (this) {
      case ProjectStatus.planning:
        return '#5C6BC0'; // Синий
      case ProjectStatus.inProgress:
        return '#26A69A'; // Бирюзовый
      case ProjectStatus.completed:
        return '#66BB6A'; // Зеленый
      case ProjectStatus.onHold:
        return '#FFB74D'; // Оранжевый
      case ProjectStatus.cancelled:
        return '#EF5350'; // Красный
    }
  }
}

class Project {
  final String id;
  final String name;
  final String description;
  final String clientId;
  final String clientName;
  final DateTime startDate;
  final DateTime? endDate;
  final DateTime? actualEndDate;
  final double budget;
  final ProjectStatus status;
  final List<ProjectStage> stages;
  final double progress;
  final String? managerId;
  final List<String>? teamMembers;
  final String? notes;

  Project({
    required this.id,
    required this.name,
    required this.description,
    required this.clientId,
    required this.clientName,
    required this.startDate,
    this.endDate,
    this.actualEndDate,
    required this.budget,
    required this.status,
    required this.stages,
    required this.progress,
    this.managerId,
    this.teamMembers,
    this.notes,
  });

  // Создаем копию объекта Project с обновленными полями
  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? clientId,
    String? clientName,
    DateTime? startDate,
    DateTime? endDate,
    DateTime? actualEndDate,
    double? budget,
    ProjectStatus? status,
    List<ProjectStage>? stages,
    double? progress,
    String? managerId,
    List<String>? teamMembers,
    String? notes,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      clientId: clientId ?? this.clientId,
      clientName: clientName ?? this.clientName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      actualEndDate: actualEndDate ?? this.actualEndDate,
      budget: budget ?? this.budget,
      status: status ?? this.status,
      stages: stages ?? this.stages,
      progress: progress ?? this.progress,
      managerId: managerId ?? this.managerId,
      teamMembers: teamMembers ?? this.teamMembers,
      notes: notes ?? this.notes,
    );
  }

  // Преобразование в Map для сохранения в базе данных
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'client_id': clientId,
      'client_name': clientName,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate?.toIso8601String(),
      'actual_end_date': actualEndDate?.toIso8601String(),
      'budget': budget,
      'status': status.index,
      'progress': progress,
      'manager_id': managerId,
      'team_members': teamMembers != null ? teamMembers!.join(',') : null,
      'notes': notes,
    };
  }

  // Создание объекта Project из Map, полученного из базы данных
  factory Project.fromMap(Map<String, dynamic> map, List<ProjectStage> stages) {
    return Project(
      id: map['id'],
      name: map['name'],
      description: map['description'],
      clientId: map['client_id'],
      clientName: map['client_name'],
      startDate: DateTime.parse(map['start_date']),
      endDate: map['end_date'] != null ? DateTime.parse(map['end_date']) : null,
      actualEndDate:
          map['actual_end_date'] != null
              ? DateTime.parse(map['actual_end_date'])
              : null,
      budget: map['budget'],
      status: ProjectStatus.values[map['status']],
      stages: stages,
      progress: map['progress'],
      managerId: map['manager_id'],
      teamMembers:
          map['team_members'] != null ? map['team_members'].split(',') : null,
      notes: map['notes'],
    );
  }

  // Расчет прогресса на основе этапов проекта
  double calculateProgress() {
    if (stages.isEmpty) return 0.0;

    double totalWeight = stages.fold(0, (sum, stage) => sum + stage.weight);
    double completedWeight = stages.fold(
      0,
      (sum, stage) => sum + (stage.completed ? stage.weight : 0),
    );

    return totalWeight > 0 ? (completedWeight / totalWeight) : 0.0;
  }
}
