import 'package:uuid/uuid.dart';
import '../models/project.dart';
import '../models/project_stage.dart';
import 'database_helper.dart';

class ProjectDao {
  final dbHelper = DatabaseHelper.instance;
  final uuid = Uuid();

  // Создание нового проекта
  Future<String> createProject(Project project) async {
    final db = await dbHelper.database;

    // Генерируем уникальный ID, если не задан
    final projectId = project.id.isEmpty ? uuid.v4() : project.id;

    // Создаем проект с обновленным ID
    final projectWithId = project.copyWith(id: projectId);

    // Вставляем проект в базу данных
    await db.insert('projects', projectWithId.toMap());

    // Сохраняем этапы проекта
    for (var stage in project.stages) {
      final stageId = stage.id.isEmpty ? uuid.v4() : stage.id;
      final stageWithIds = stage.copyWith(id: stageId, projectId: projectId);
      await db.insert('project_stages', stageWithIds.toMap());
    }

    return projectId;
  }

  // Получение всех проектов
  Future<List<Project>> getAllProjects({String? statusFilter}) async {
    final db = await dbHelper.database;

    // Формируем запрос с учетом фильтра статуса
    String whereClause = '';
    List<dynamic> whereArgs = [];

    if (statusFilter != null && statusFilter.isNotEmpty) {
      final statusIndex = ProjectStatus.values.indexWhere(
        (status) => status.name.toLowerCase() == statusFilter.toLowerCase(),
      );

      if (statusIndex >= 0) {
        whereClause = 'status = ?';
        whereArgs = [statusIndex];
      }
    }

    final projectMaps = await db.query(
      'projects',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'start_date DESC',
    );

    return Future.wait(
      projectMaps.map((projectMap) async {
        final stages = await getProjectStages(projectMap['id'] as String);
        return Project.fromMap(projectMap, stages);
      }).toList(),
    );
  }

  // Получение проекта по ID
  Future<Project?> getProjectById(String id) async {
    final db = await dbHelper.database;

    final projectMaps = await db.query(
      'projects',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (projectMaps.isEmpty) return null;

    final stages = await getProjectStages(id);
    return Project.fromMap(projectMaps.first, stages);
  }

  // Получение этапов проекта
  Future<List<ProjectStage>> getProjectStages(String projectId) async {
    final db = await dbHelper.database;

    final stageMaps = await db.query(
      'project_stages',
      where: 'project_id = ?',
      whereArgs: [projectId],
      orderBy: '"order" ASC',
    );

    return stageMaps.map((map) => ProjectStage.fromMap(map)).toList();
  }

  // Обновление проекта
  Future<int> updateProject(Project project) async {
    final db = await dbHelper.database;
    double progress = project.calculateProgress();
    project.copyWith(progress: progress);

    // Обновляем информацию о проекте
    final result = await db.update(
      'projects',
      project.toMap(),
      where: 'id = ?',
      whereArgs: [project.id],
    );

    // Получаем существующие этапы из базы данных
    final existingStages = await getProjectStages(project.id);
    final existingStageIds = existingStages.map((s) => s.id).toSet();
    final updatedStageIds = project.stages.map((s) => s.id).toSet();

    // Удаляем этапы, которых нет в обновленном проекте
    final stagesToDelete = existingStageIds.difference(updatedStageIds);
    for (final stageId in stagesToDelete) {
      await db.delete('project_stages', where: 'id = ?', whereArgs: [stageId]);
    }

    // Обновляем или добавляем этапы
    for (final stage in project.stages) {
      final stageId = stage.id.isEmpty ? uuid.v4() : stage.id;
      final stageWithIds = stage.copyWith(id: stageId, projectId: project.id);

      // Проверяем, существует ли этап
      final exists = existingStageIds.contains(stageId);

      if (exists) {
        // Обновляем существующий этап
        await db.update(
          'project_stages',
          stageWithIds.toMap(),
          where: 'id = ?',
          whereArgs: [stageId],
        );
      } else {
        // Создаем новый этап
        await db.insert('project_stages', stageWithIds.toMap());
      }
    }

    return result;
  }

  // Удаление проекта
  Future<int> deleteProject(String id) async {
    final db = await dbHelper.database;

    // Удаляем проект (каскадное удаление также удалит этапы)
    return await db.delete('projects', where: 'id = ?', whereArgs: [id]);
  }

  // Получение проектов по клиенту
  Future<List<Project>> getProjectsByClient(String clientId) async {
    final db = await dbHelper.database;

    final projectMaps = await db.query(
      'projects',
      where: 'client_id = ?',
      whereArgs: [clientId],
      orderBy: 'start_date DESC',
    );

    return Future.wait(
      projectMaps.map((projectMap) async {
        final stages = await getProjectStages(projectMap['id'] as String);
        return Project.fromMap(projectMap, stages);
      }).toList(),
    );
  }

  // Обновление статуса этапа проекта
  Future<void> updateStageStatus(String stageId, bool completed) async {
    // Обновляем статус этапа
    final db = await dbHelper.database;
    await db.update(
      'project_stages',
      {'completed': completed ? 1 : 0},
      where: 'id = ?',
      whereArgs: [stageId],
    );

    // Находим, к какому проекту относится этап
    final stageData = await db.query(
      'project_stages',
      where: 'id = ?',
      whereArgs: [stageId],
    );

    if (stageData.isNotEmpty) {
      final projectId = stageData.first['project_id'] as String;

      // Получаем проект с обновленными этапами
      final project = await getProjectById(projectId);

      // Пересчитываем прогресс
      if (project != null) {
        final newProgress = project.calculateProgress();

        // Обновляем прогресс в БД
        await db.update(
          'projects',
          {'progress': newProgress},
          where: 'id = ?',
          whereArgs: [projectId],
        );
      }
    }
  }

  // Получение проектов с фильтрацией и сортировкой
  Future<List<Project>> getFilteredProjects({
    String? search,
    ProjectStatus? status,
    DateTime? startDateFrom,
    DateTime? startDateTo,
    String? sortBy,
    bool ascending = true,
  }) async {
    final db = await dbHelper.database;

    // Формируем условия для фильтрации
    List<String> whereConditions = [];
    List<dynamic> whereArgs = [];

    if (search != null && search.isNotEmpty) {
      whereConditions.add(
        '(name LIKE ? OR description LIKE ? OR client_name LIKE ?)',
      );
      whereArgs.addAll(['%$search%', '%$search%', '%$search%']);
    }

    if (status != null) {
      whereConditions.add('status = ?');
      whereArgs.add(status.index);
    }

    if (startDateFrom != null) {
      whereConditions.add('start_date >= ?');
      whereArgs.add(startDateFrom.toIso8601String());
    }

    if (startDateTo != null) {
      whereConditions.add('start_date <= ?');
      whereArgs.add(startDateTo.toIso8601String());
    }

    // Формируем строку WHERE
    String whereClause =
        whereConditions.isNotEmpty ? whereConditions.join(' AND ') : '';

    // Определяем поле для сортировки
    String orderByField = 'start_date';
    if (sortBy != null) {
      switch (sortBy) {
        case 'name':
          orderByField = 'name';
          break;
        case 'budget':
          orderByField = 'budget';
          break;
        case 'progress':
          orderByField = 'progress';
          break;
        case 'client':
          orderByField = 'client_name';
          break;
      }
    }

    // Формируем сортировку
    String orderBy = '$orderByField ${ascending ? 'ASC' : 'DESC'}';

    // Выполняем запрос
    final projectMaps = await db.query(
      'projects',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: orderBy,
    );

    return Future.wait(
      projectMaps.map((projectMap) async {
        final stages = await getProjectStages(projectMap['id'] as String);
        return Project.fromMap(projectMap, stages);
      }).toList(),
    );
  }
}
