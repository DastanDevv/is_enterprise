import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../models/finance.dart';

class CategoryPieChart extends StatelessWidget {
  final Map<TransactionCategory, double> data;
  final TransactionType type;
  final double totalAmount;

  const CategoryPieChart({
    super.key,
    required this.data,
    required this.type,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          'Нет данных для отображения',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }
    // Форматер для валюты
    final currencyFormat = NumberFormat.currency(
      locale: 'ru_RU',
      symbol: 'сом',
      decimalDigits: 0,
    );

    // Подготовка данных для диаграммы
    final List<PieChartSectionData> sections = [];
    final List<Widget> indicators = [];

    final entries = data.entries.toList();
    // Сортируем категории по убыванию суммы
    entries.sort((a, b) => b.value.compareTo(a.value));

    // Определяем цвета для секций
    final colors = [
      Colors.blue[400]!,
      Colors.green[400]!,
      Colors.amber[400]!,
      Colors.red[400]!,
      Colors.purple[400]!,
      Colors.cyan[400]!,
      Colors.orange[400]!,
      Colors.teal[400]!,
    ];

    for (int i = 0; i < entries.length; i++) {
      final entry = entries[i];
      final category = entry.key;
      final value = entry.value;
      final percentage = totalAmount > 0 ? (value / totalAmount * 100) : 0;

      // Цвет для секции
      final color = colors[i % colors.length];

      // Добавляем секцию
      sections.add(
        PieChartSectionData(
          color: color,
          value: value,
          title: '',
          radius: 60,
          titleStyle: const TextStyle(
            fontSize: 0,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      );

      // Добавляем индикатор
      indicators.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  currencyFormat.format(value),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          type == TransactionType.income
              ? 'Доходы по категориям'
              : 'Расходы по категориям',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Диаграмма
            SizedBox(
              height: 180,
              width: 180,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                  startDegreeOffset: 270,
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Легенда
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: indicators,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
