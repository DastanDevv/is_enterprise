import 'package:flutter/material.dart';
import 'package:flutter_vkr/database/client_dao.dart';
import 'package:flutter_vkr/database/project_dao.dart';
import 'package:flutter_vkr/database/transaction_dao.dart';
import 'package:flutter_vkr/models/project.dart';
import 'package:flutter_vkr/models/finance.dart';
import 'package:flutter_vkr/screens/clients/add_edit_client_screen.dart';
import 'package:flutter_vkr/screens/projects/add_edit_project_screen.dart';
import 'package:flutter_vkr/screens/projects/projects_screen.dart';
import 'package:flutter_vkr/screens/projects/project_details_screen.dart';
import 'package:flutter_vkr/screens/finances/add_edit_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();
  final ProjectDao _projectDao = ProjectDao();
  final ClientDao _clientDao = ClientDao();
  final TransactionDao _transactionDao = TransactionDao();

  // Данные для отображения
  final String _username = "Администратор";
  int _activeProjects = 0;
  int _completedProjects = 0;
  int _clients = 0;
  double _monthRevenue = 0;
  List<Task> _upcomingTasks = [];
  List<Project> _recentProjects = [];
  List<Activity> _recentActivities = [];
  List<FlSpot> _revenueData = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Получаем имя пользователя из настроек (если реализовано)
      // В этой версии используем фиксированное значение

      // Загружаем данные о проектах
      final allProjects = await _projectDao.getAllProjects();
      final activeProjects =
          allProjects
              .where(
                (p) =>
                    p.status == ProjectStatus.inProgress ||
                    p.status == ProjectStatus.planning,
              )
              .toList();
      final completedProjects =
          allProjects
              .where((p) => p.status == ProjectStatus.completed)
              .toList();

      // Последние проекты (3 или меньше)
      final recentProjects = activeProjects.take(3).toList();

      // Загружаем данные о клиентах
      final allClients = await _clientDao.getAllClients();

      // Загружаем данные о финансах
      // Получаем доход за текущий месяц
      final startOfMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        1,
      );
      final endOfMonth = DateTime(
        DateTime.now().year,
        DateTime.now().month + 1,
        0,
        23,
        59,
        59,
      );

      final monthIncome = await _transactionDao.getTotalIncome(
        startDate: startOfMonth,
        endDate: endOfMonth,
      );

      // Генерируем данные для графика доходов за 6 месяцев
      final revenueData = await _generateRevenueData();

      // Генерируем задачи из этапов проектов
      final upcomingTasks = await _generateTasksFromProjectStages(allProjects);

      // Генерируем последние активности на основе транзакций и изменений проектов
      final recentActivities = await _generateRecentActivities();

      if (mounted) {
        setState(() {
          _activeProjects = activeProjects.length;
          _completedProjects = completedProjects.length;
          _clients = allClients.length;
          _monthRevenue = monthIncome;
          _recentProjects = recentProjects;
          _upcomingTasks = upcomingTasks;
          _recentActivities = recentActivities;
          _revenueData = revenueData;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Ошибка при загрузке данных дашборда: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Генерирует данные о доходах за последние 6 месяцев
  Future<List<FlSpot>> _generateRevenueData() async {
    List<FlSpot> revenueData = [];

    final now = DateTime.now();
    // Получаем данные за последние 6 месяцев
    for (int i = 5; i >= 0; i--) {
      final month = now.month - i;
      final year = now.year + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final startDate = DateTime(year, adjustedMonth, 1);
      final endDate = DateTime(year, adjustedMonth + 1, 0, 23, 59, 59);

      final monthlyIncome = await _transactionDao.getTotalIncome(
        startDate: startDate,
        endDate: endDate,
      );

      revenueData.add(FlSpot(5 - i.toDouble(), monthlyIncome));
    }

    return revenueData;
  }

  // Генерирует задачи на основе этапов проектов
  Future<List<Task>> _generateTasksFromProjectStages(
    List<Project> projects,
  ) async {
    List<Task> tasks = [];

    for (var project in projects) {
      // Только активные проекты
      if (project.status == ProjectStatus.inProgress ||
          project.status == ProjectStatus.planning) {
        // Только невыполненные этапы
        final incompleteStages =
            project.stages.where((stage) => !stage.completed).toList();

        for (var stage in incompleteStages) {
          // Создаем задачу на основе этапа
          final task = Task(
            id: stage.id,
            title: '${stage.name} (${project.name})',
            dueDate:
                stage.endDate ??
                DateTime.now().add(
                  const Duration(days: 7),
                ), // Если нет даты окончания, устанавливаем +7 дней
            priority: _determinePriority(stage.endDate),
            status: TaskStatus.inProgress,
            projectId: project.id,
            projectName: project.name,
          );

          tasks.add(task);
        }
      }
    }

    // Сортировка задач по дате
    tasks.sort((a, b) => a.dueDate.compareTo(b.dueDate));

    // Ограничиваем количество задач
    return tasks.take(4).toList();
  }

  // Определяет приоритет задачи на основе даты окончания
  TaskPriority _determinePriority(DateTime? endDate) {
    if (endDate == null) return TaskPriority.medium;

    final now = DateTime.now();
    final difference = endDate.difference(now).inDays;

    if (difference < 0) return TaskPriority.high; // Просрочено
    if (difference < 3) return TaskPriority.high; // Меньше 3 дней
    if (difference < 7) return TaskPriority.medium; // Меньше недели
    return TaskPriority.low; // Больше недели
  }

  // Генерирует последние активности на основе транзакций и изменений в проектах
  Future<List<Activity>> _generateRecentActivities() async {
    List<Activity> activities = [];

    // Получаем последние транзакции
    final transactions = await _transactionDao.getAllTransactions();
    final recentTransactions = transactions.take(2).toList();

    for (var transaction in recentTransactions) {
      ActivityType type;
      String message;

      if (transaction.type == TransactionType.income) {
        type = ActivityType.paymentReceived;
        message = 'Получен платеж ${transaction.getFormattedAmount()}';
        if (transaction.clientName != null) {
          message += ' от ${transaction.clientName}';
        }
      } else {
        type = ActivityType.taskCompleted; // Используем этот тип для расходов
        message =
            'Оплачено ${transaction.getFormattedAmount()} за ${transaction.category.name}';
      }

      activities.add(
        Activity(type: type, message: message, timestamp: transaction.date),
      );
    }

    // Добавляем активности на основе последних проектов и клиентов
    try {
      final projects = await _projectDao.getAllProjects();
      if (projects.isNotEmpty) {
        final latestProject = projects.first;
        activities.add(
          Activity(
            type: ActivityType.projectUpdate,
            message:
                'Обновлен проект "${latestProject.name}" (${latestProject.status.name})',
            timestamp: DateTime.now().subtract(const Duration(hours: 3)),
          ),
        );
      }

      final clients = await _clientDao.getAllClients();
      if (clients.isNotEmpty) {
        final latestClient = clients.first;
        activities.add(
          Activity(
            type: ActivityType.clientAdded,
            message: 'Добавлен новый клиент: ${latestClient.name}',
            timestamp: DateTime.now().subtract(const Duration(hours: 6)),
          ),
        );
      }
    } catch (e) {
      print('Ошибка при генерации активностей: $e');
    }

    // Сортировка активностей по дате (сначала новые)
    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    // Ограничиваем количество активностей
    return activities.take(4).toList();
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm', 'ru_RU');
    final formattedDate = dateFormat.format(now);
    final formattedTime = timeFormat.format(now);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FF),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Scrollbar(
                  controller: _scrollController,
                  child: ListView(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 20,
                    ),
                    children: [
                      // Приветствие и информация о дате
                      _buildGreetingSection(formattedDate, formattedTime),
                      const SizedBox(height: 24),

                      // KPI (Ключевые показатели)
                      _buildKpiSection(),
                      const SizedBox(height: 24),

                      // График доходов
                      _buildRevenueChart(),
                      const SizedBox(height: 24),

                      // Быстрые действия
                      _buildQuickActions(),
                      const SizedBox(height: 24),

                      // Предстоящие задачи
                      _buildUpcomingTasks(),
                      const SizedBox(height: 24),

                      // Последние проекты
                      _buildRecentProjects(),
                      const SizedBox(height: 24),

                      // Последние активности
                      _buildRecentActivities(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
      ),
    );
  }

  // Секция приветствия
  Widget _buildGreetingSection(String date, String time) {
    String greeting;
    final hour = DateTime.now().hour;

    if (hour < 12) {
      greeting = 'Доброе утро';
    } else if (hour < 17) {
      greeting = 'Добрый день';
    } else {
      greeting = 'Добрый вечер';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$greeting,',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _username,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      date,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      time,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Сегодня у вас $_activeProjects активных проектов и ${_upcomingTasks.where((task) => task.dueDate.day == DateTime.now().day).length} задач на сегодня',
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // Секция KPI (Ключевые показатели)
  Widget _buildKpiSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ключевые показатели',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        GridView.count(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          crossAxisCount: 2,
          childAspectRatio: 1.5,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            _buildKpiCard(
              title: 'Активные проекты',
              value: '$_activeProjects',
              icon: Icons.folder_open,
              color: Theme.of(context).colorScheme.primary,
            ),
            _buildKpiCard(
              title: 'Клиенты',
              value: '$_clients',
              icon: Icons.people,
              color: const Color(0xFF26A69A),
            ),
            _buildKpiCard(
              title: 'Завершенные проекты',
              value: '$_completedProjects',
              icon: Icons.check_circle,
              color: const Color(0xFF66BB6A),
            ),
            _buildKpiCard(
              title: 'Доход за месяц',
              value:
                  '${NumberFormat.currency(locale: 'ru_RU', symbol: 'сом', decimalDigits: 0).format(_monthRevenue)}',
              icon: Icons.monetization_on,
              color: const Color(0xFFFFB74D),
            ),
          ],
        ),
      ],
    );
  }

  // Карточка для KPI
  Widget _buildKpiCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // График доходов
  Widget _buildRevenueChart() {
    // Определяем последние 6 месяцев для отображения на графике
    final currentMonth = DateTime.now().month;
    final currentYear = DateTime.now().year;
    final monthLabels = <String>[];

    for (int i = 5; i >= 0; i--) {
      final month = currentMonth - i;
      final year = currentYear + (month <= 0 ? -1 : 0);
      final adjustedMonth = month <= 0 ? month + 12 : month;

      final monthName = DateFormat(
        'MMMM',
        'ru_RU',
      ).format(DateTime(year, adjustedMonth, 1));
      monthLabels.add(monthName);
    }

    // Находим максимальное и минимальное значения для оси Y
    double maxY = 0;
    double minY = double.infinity;

    for (var spot in _revenueData) {
      if (spot.y > maxY) maxY = spot.y;
      if (spot.y < minY) minY = spot.y;
    }

    // Корректируем минимальное значение для лучшего отображения
    minY = minY > 0 ? (minY * 0.8) : 0;

    // Корректируем максимальное значение
    maxY = maxY * 1.2;

    return Container(
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Доходы компании',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${DateTime.now().year} год',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 100000,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(color: Colors.grey[200], strokeWidth: 1);
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < monthLabels.length) {
                          return SideTitleWidget(
                            fitInside: SideTitleFitInsideData(
                              enabled: true,
                              axisPosition: meta.axisPosition,
                              distanceFromEdge: 0,
                              parentAxisSize: meta.parentAxisSize,
                            ),
                            meta: meta,
                            child: Text(
                              monthLabels[value.toInt()],
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          );
                        }
                        return SideTitleWidget(
                          fitInside: SideTitleFitInsideData(
                            enabled: true,
                            axisPosition: meta.axisPosition,
                            distanceFromEdge: 0,
                            parentAxisSize: meta.parentAxisSize,
                          ),
                          space: 8,
                          meta: meta,
                          child: const Text(''),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 100000,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return SideTitleWidget(
                          fitInside: SideTitleFitInsideData(
                            enabled: true,
                            axisPosition: meta.axisPosition,
                            distanceFromEdge: 0,
                            parentAxisSize: meta.parentAxisSize,
                          ),
                          meta: meta,
                          child: Text(
                            '${(value / 1000).round()} сом',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minX: 0,
                maxX: 5,
                minY: minY,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: _revenueData,
                    isCurved: true,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                        Theme.of(context).colorScheme.primary,
                      ],
                    ),
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.3),
                          Theme.of(
                            context,
                          ).colorScheme.primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // Быстрые действия
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Быстрые действия',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Новый проект',
                icon: Icons.add_box_rounded,
                color: Theme.of(context).colorScheme.primary,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditProjectScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Новый клиент',
                icon: Icons.person_add_rounded,
                color: const Color(0xFF26A69A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditClientScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Новая задача',
                icon: Icons.add_task_rounded,
                color: const Color(0xFF66BB6A),
                onTap: () async {
                  // Показываем диалог выбора проекта
                  final projects = await _projectDao.getAllProjects();
                  if (!context.mounted) return;

                  if (projects.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Создайте сначала проект для добавления задачи',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }

                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditProjectScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Новый платеж',
                icon: Icons.payments_rounded,
                color: const Color(0xFFFFB74D),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditTransactionScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Кнопка быстрого действия
  Widget _buildActionButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF333333),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Предстоящие задачи
  Widget _buildUpcomingTasks() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Предстоящие задачи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            TextButton(
              onPressed: () {
                // Переход на экран всех проектов, так как задачи - это этапы проектов
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ProjectsScreen(),
                  ),
                ).then((_) => _loadDashboardData());
              },
              child: Text(
                'Все задачи',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _upcomingTasks.isEmpty
            ? _buildEmptyTasksState()
            : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _upcomingTasks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final task = _upcomingTasks[index];
                return _buildTaskItem(task);
              },
            ),
      ],
    );
  }

  // Пустое состояние для задач
  Widget _buildEmptyTasksState() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Center(
        child: Column(
          children: [
            Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет предстоящих задач',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Завершите этапы проектов или добавьте новые',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Элемент задачи
  Widget _buildTaskItem(Task task) {
    // Определяем цвет в зависимости от приоритета
    Color priorityColor;
    switch (task.priority) {
      case TaskPriority.high:
        priorityColor = Colors.red[400]!;
        break;
      case TaskPriority.medium:
        priorityColor = Colors.orange[400]!;
        break;
      case TaskPriority.low:
        priorityColor = Colors.green[400]!;
        break;
    }

    // Форматируем дату выполнения
    final dateFormat = DateFormat('dd.MM.yyyy', 'ru_RU');
    final timeFormat = DateFormat('HH:mm', 'ru_RU');
    final now = DateTime.now();
    final dueDate = task.dueDate;

    String dueDateText;
    if (dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day) {
      dueDateText = 'Сегодня, ${timeFormat.format(dueDate)}';
    } else if (dueDate.year == now.year &&
        dueDate.month == now.month &&
        dueDate.day == now.day + 1) {
      dueDateText = 'Завтра, ${timeFormat.format(dueDate)}';
    } else {
      dueDateText =
          '${dateFormat.format(dueDate)}, ${timeFormat.format(dueDate)}';
    }

    // Определяем, просрочена ли задача
    final isOverdue =
        dueDate.isBefore(now) && task.status != TaskStatus.completed;

    return InkWell(
      onTap: () {
        // Переход на экран детальной информации о проекте
        if (task.projectId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => ProjectDetailsScreen(projectId: task.projectId!),
            ),
          ).then((_) => _loadDashboardData());
        }
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dueDateText,
                        style: TextStyle(
                          fontSize: 12,
                          color: isOverdue ? Colors.red : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.chevron_right,
                size: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Последние проекты
  Widget _buildRecentProjects() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Текущие проекты',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (BuildContext context) => const ProjectsScreen(),
                  ),
                ).then((_) => _loadDashboardData());
              },
              child: Text(
                'Все проекты',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _recentProjects.isEmpty
            ? _buildEmptyProjectsState()
            : ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: _recentProjects.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final project = _recentProjects[index];
                return _buildProjectItem(project);
              },
            ),
      ],
    );
  }

  // Пустое состояние для проектов
  Widget _buildEmptyProjectsState() {
    return Container(
      padding: const EdgeInsets.all(24),
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
      child: Center(
        child: Column(
          children: [
            Icon(Icons.folder_outlined, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              'Нет активных проектов',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Создайте новый проект, чтобы начать работу',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Элемент проекта
  Widget _buildProjectItem(Project project) {
    // Форматируем дату дедлайна
    final dateFormat = DateFormat('dd.MM.yyyy', 'ru_RU');
    final formattedDueDate =
        project.endDate != null
            ? dateFormat.format(project.endDate!)
            : 'Не указан';

    // Определяем цвет прогресса
    Color progressColor;
    if (project.progress < 0.3) {
      progressColor = Colors.red[400]!;
    } else if (project.progress < 0.7) {
      progressColor = Colors.orange[400]!;
    } else {
      progressColor = Colors.green[400]!;
    }

    // Рассчитываем оставшиеся дни
    int daysLeft = 0;

    if (project.endDate != null) {
      final difference = project.endDate!.difference(DateTime.now());
      daysLeft = difference.inDays;
    }

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProjectDetailsScreen(projectId: project.id),
          ),
        ).then((_) => _loadDashboardData());
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        project.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Клиент: ${project.clientName}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                project.endDate != null
                    ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        daysLeft > 0 ? 'Осталось $daysLeft дн.' : 'Срок истек!',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color:
                              daysLeft > 0
                                  ? Theme.of(context).colorScheme.primary
                                  : Colors.red,
                        ),
                      ),
                    )
                    : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Без срока',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Прогресс',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '${(project.progress * 100).round()}%',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: project.progress,
                          backgroundColor: Colors.grey[200],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            progressColor,
                          ),
                          minHeight: 8,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Text(
                  'До: $formattedDueDate',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Последние активности
  Widget _buildRecentActivities() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Последние активности',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        Container(
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
          child:
              _recentActivities.isEmpty
                  ? _buildEmptyActivitiesState()
                  : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: _recentActivities.length,
                    separatorBuilder:
                        (context, index) => const Divider(height: 24),
                    itemBuilder: (context, index) {
                      final activity = _recentActivities[index];
                      return _buildActivityItem(activity);
                    },
                  ),
        ),
      ],
    );
  }

  // Пустое состояние для активностей
  Widget _buildEmptyActivitiesState() {
    return Center(
      child: Column(
        children: [
          Icon(Icons.notifications_none, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Нет последних активностей',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Здесь будут отображаться события в системе',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Элемент активности
  Widget _buildActivityItem(Activity activity) {
    // Определяем иконку активности
    IconData activityIcon;
    Color iconColor;

    switch (activity.type) {
      case ActivityType.projectUpdate:
        activityIcon = Icons.update;
        iconColor = Theme.of(context).colorScheme.primary;
        break;
      case ActivityType.clientAdded:
        activityIcon = Icons.person_add;
        iconColor = const Color(0xFF26A69A);
        break;
      case ActivityType.paymentReceived:
        activityIcon = Icons.payments;
        iconColor = const Color(0xFFFFB74D);
        break;
      case ActivityType.taskCompleted:
        activityIcon = Icons.task_alt;
        iconColor = const Color(0xFF66BB6A);
        break;
    }

    // Форматируем время активности
    String timeText;
    final now = DateTime.now();
    final difference = now.difference(activity.timestamp);

    if (difference.inMinutes < 60) {
      timeText = '${difference.inMinutes} мин. назад';
    } else if (difference.inHours < 24) {
      timeText = '${difference.inHours} ч. назад';
    } else {
      timeText = '${difference.inDays} дн. назад';
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(activityIcon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.message,
                style: const TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              const SizedBox(height: 4),
              Text(
                timeText,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// Классы моделей данных
enum TaskPriority { low, medium, high }

enum TaskStatus { notStarted, inProgress, completed }

class Task {
  final String id;
  final String title;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskStatus status;
  final String? projectId;
  final String? projectName;

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.priority,
    required this.status,
    this.projectId,
    this.projectName,
  });
}

enum ActivityType { projectUpdate, clientAdded, paymentReceived, taskCompleted }

class Activity {
  final ActivityType type;
  final String message;
  final DateTime timestamp;

  Activity({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}
