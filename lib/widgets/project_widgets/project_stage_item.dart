import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/project_stage.dart';

class ProjectStageItem extends StatelessWidget {
  final ProjectStage stage;
  final ValueChanged<bool> onCompletedChanged;
  final VoidCallback? onEdit;

  const ProjectStageItem({
    Key? key,
    required this.stage,
    required this.onCompletedChanged,
    this.onEdit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Форматер для дат
    final dateFormat = DateFormat('dd.MM.yyyy');

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Чекбокс для отметки выполнения
            Transform.scale(
              scale: 1.2,
              child: Checkbox(
                value: stage.completed,
                onChanged: (value) {
                  onCompletedChanged(value ?? false);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: 8),
            // Основная информация об этапе
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stage.name,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration:
                          stage.completed
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                      color: stage.completed ? Colors.grey[600] : Colors.black,
                    ),
                  ),
                  if (stage.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      stage.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        decoration:
                            stage.completed
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                      ),
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Начало: ${dateFormat.format(stage.startDate)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      if (stage.endDate != null) ...[
                        Icon(Icons.event, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          'До: ${dateFormat.format(stage.endDate!)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.trending_up,
                        size: 14,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Вес этапа: ${(stage.weight * 100).round()}%',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Кнопка редактирования
            if (onEdit != null)
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                onPressed: onEdit,
                splashRadius: 20,
                color: Colors.grey[600],
              ),
          ],
        ),
      ),
    );
  }
}
