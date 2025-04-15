import 'package:flutter/material.dart';
import 'package:flutter_vkr/screens/clients/add_edit_client_screen.dart';
import 'package:flutter_vkr/screens/projects/add_edit_project_screen.dart';
import 'package:flutter_vkr/screens/projects/projects_screen.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';

// Импортируем будущие экраны (вы их создадите позже)
// import 'project_details_screen.dart';
// import 'client_details_screen.dart';
// import 'task_details_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  DashboardScreenState createState() => DashboardScreenState();
}

class DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  // Демо-данные
  final String _username = "Администратор";
  final int _activeProjects = 8;
  final int _completedProjects = 15;
  final int _clients = 24;
  final double _monthRevenue = 420000;
  final List<Task> _upcomingTasks = [
    Task(
      id: '1',
      title: 'Подготовить маркетинговый план для Клиента Нурболот',
      dueDate: DateTime.now().add(Duration(days: 2)),
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
    ),
    Task(
      id: '2',
      title: 'Обновить дизайн для веб-сайта Клиента Миррадов Эгемберди',
      dueDate: DateTime.now().add(Duration(days: 1)),
      priority: TaskPriority.medium,
      status: TaskStatus.inProgress,
    ),
    Task(
      id: '3',
      title: 'Составить финансовый отчет за квартал',
      dueDate: DateTime.now().add(Duration(hours: 5)),
      priority: TaskPriority.high,
      status: TaskStatus.inProgress,
    ),
    Task(
      id: '4',
      title: 'Встреча с потенциальным клиентом',
      dueDate: DateTime.now().add(Duration(days: 3)),
      priority: TaskPriority.medium,
      status: TaskStatus.notStarted,
    ),
  ];

  final List<Project> _recentProjects = [
    Project(
      id: '1',
      name: 'Редизайн веб-сайта для ООО "Прогресс"',
      client: 'ООО "Прогресс"',
      progress: 0.75,
      dueDate: DateTime.now().add(Duration(days: 7)),
    ),
    Project(
      id: '2',
      name: 'Разработка мобильного приложения для ИП Иванов',
      client: 'ИП Иванов',
      progress: 0.3,
      dueDate: DateTime.now().add(Duration(days: 14)),
    ),
    Project(
      id: '3',
      name: 'Маркетинговая кампания для ООО "Ритейл+"',
      client: 'ООО "Ритейл+"',
      progress: 0.9,
      dueDate: DateTime.now().add(Duration(days: 2)),
    ),
  ];

  final List<Activity> _recentActivities = [
    Activity(
      type: ActivityType.projectUpdate,
      message:
          'Завершен этап "Дизайн макетов" для проекта "Редизайн веб-сайта"',
      timestamp: DateTime.now().subtract(Duration(hours: 2)),
    ),
    Activity(
      type: ActivityType.clientAdded,
      message: 'Добавлен новый клиент: ООО "ТехноСервис"',
      timestamp: DateTime.now().subtract(Duration(hours: 5)),
    ),
    Activity(
      type: ActivityType.paymentReceived,
      message: 'Получен платеж 120 000 сом от ООО "Ритейл+"',
      timestamp: DateTime.now().subtract(Duration(hours: 8)),
    ),
    Activity(
      type: ActivityType.taskCompleted,
      message: 'Завершена задача "Разработка логотипа" для ООО "Прогресс"',
      timestamp: DateTime.now().subtract(Duration(days: 1)),
    ),
  ];

  // Данные для графика доходов
  final List<FlSpot> _revenueData = [
    FlSpot(0, 300000),
    FlSpot(1, 280000),
    FlSpot(2, 320000),
    FlSpot(3, 360000),
    FlSpot(4, 400000),
    FlSpot(5, 420000),
  ];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dateFormat = DateFormat('dd.MM.yyyy');
    final timeFormat = DateFormat('HH:mm', 'ru_RU');
    final formattedDate = dateFormat.format(now);
    final formattedTime = timeFormat.format(now);

    return Scaffold(
      backgroundColor: Color(0xFFF5F7FF),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
            children: [
              // Приветствие и информация о дате
              _buildGreetingSection(formattedDate, formattedTime),
              SizedBox(height: 24),

              // KPI (Ключевые показатели)
              _buildKpiSection(),
              SizedBox(height: 24),

              // График доходов
              _buildRevenueChart(),
              SizedBox(height: 24),

              // Быстрые действия
              _buildQuickActions(),
              SizedBox(height: 24),

              // Предстоящие задачи
              _buildUpcomingTasks(),
              SizedBox(height: 24),

              // Последние проекты
              _buildRecentProjects(),
              SizedBox(height: 24),

              // Последние активности
              _buildRecentActivities(),
              SizedBox(height: 24),
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
      padding: EdgeInsets.all(20),
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
            offset: Offset(0, 4),
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
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    _username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    Text(
                      date,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
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
          SizedBox(height: 16),
          Text(
            'Сегодня у вас $_activeProjects активных проектов и ${_upcomingTasks.where((task) => task.dueDate.day == DateTime.now().day).length} задач на сегодня',
            style: TextStyle(color: Colors.white, fontSize: 16),
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
        Text(
          'Ключевые показатели',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 12),
        GridView.count(
          physics: NeverScrollableScrollPhysics(),
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
              color: Color(0xFF26A69A),
            ),
            _buildKpiCard(
              title: 'Завершенные проекты',
              value: '$_completedProjects',
              icon: Icons.check_circle,
              color: Color(0xFF66BB6A),
            ),
            _buildKpiCard(
              title: 'Доход за месяц',
              value:
                  '${NumberFormat.currency(locale: 'ru_RU', symbol: 'сом', decimalDigits: 0).format(_monthRevenue)}',
              icon: Icons.monetization_on,
              color: Color(0xFFFFB74D),
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
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
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
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            ],
          ),
          Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // График доходов
  Widget _buildRevenueChart() {
    final months = ['Январь', 'Февраль', 'Март', 'Апрель', 'Май', 'Июнь'];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Доходы компании',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF333333),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '2025 год',
                  style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Container(
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
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() >= 0 &&
                            value.toInt() < months.length) {
                          return SideTitleWidget(
                            fitInside: SideTitleFitInsideData(
                              enabled: true,
                              axisPosition: meta.axisPosition,
                              distanceFromEdge: 0,
                              parentAxisSize: meta.parentAxisSize,
                            ),
                            meta: meta,
                            child: Text(
                              months[value.toInt()],
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
                          meta: meta,
                          child: Text(''),
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
                minY: 200000,
                maxY: 500000,
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
                    dotData: FlDotData(show: true),
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
          SizedBox(height: 12),
        ],
      ),
    );
  }

  // Быстрые действия
  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Быстрые действия',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 12),
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
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Новый клиент',
                icon: Icons.person_add_rounded,
                color: Color(0xFF26A69A),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddEditClientScreen(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                title: 'Новая задача',
                icon: Icons.add_task_rounded,
                color: Color(0xFF66BB6A),
                onTap: () {
                  // Показать модальное окно для создания задачи
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Создание новой задачи'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                title: 'Новый платеж',
                icon: Icons.payments_rounded,
                color: Color(0xFFFFB74D),
                onTap: () {
                  // Показать модальное окно для создания платежа
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Создание нового платежа'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
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
        padding: EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF333333),
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
            Text(
              'Предстоящие задачи',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
              ),
            ),
            TextButton(
              onPressed: () {
                // Переход на экран всех задач
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Переход к списку всех задач'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(
                'Все задачи',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ListView.separated(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _upcomingTasks.length,
          separatorBuilder: (context, index) => SizedBox(height: 8),
          itemBuilder: (context, index) {
            final task = _upcomingTasks[index];
            return _buildTaskItem(task);
          },
        ),
      ],
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
        // Переход на экран детальной информации о задаче
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Просмотр задачи: ${task.title}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 16,
              height: 16,
              margin: EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: priorityColor,
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),
                  SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: isOverdue ? Colors.red : Colors.grey[600],
                      ),
                      SizedBox(width: 4),
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
              padding: EdgeInsets.all(8),
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
            Text(
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
                );
              },
              child: Text(
                'Все проекты',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
            ),
          ],
        ),
        SizedBox(height: 12),
        ListView.separated(
          physics: NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: _recentProjects.length,
          separatorBuilder: (context, index) => SizedBox(height: 12),
          itemBuilder: (context, index) {
            final project = _recentProjects[index];
            return _buildProjectItem(project);
          },
        ),
      ],
    );
  }

  // Элемент проекта
  Widget _buildProjectItem(Project project) {
    // Форматируем дату дедлайна
    final dateFormat = DateFormat('dd.MM.yyyy', 'ru_RU');
    final formattedDueDate = dateFormat.format(project.dueDate);

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
    final daysLeft = project.dueDate.difference(DateTime.now()).inDays;

    return InkWell(
      onTap: () {
        // Переход на экран детальной информации о проекте
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Просмотр проекта: ${project.name}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: Offset(0, 2),
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
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF333333),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Клиент: ${project.client}',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
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
                ),
              ],
            ),
            SizedBox(height: 16),
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
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
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
                SizedBox(width: 16),
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
        Text(
          'Последние активности',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        SizedBox(height: 12),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: ListView.separated(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: _recentActivities.length,
            separatorBuilder: (context, index) => Divider(height: 24),
            itemBuilder: (context, index) {
              final activity = _recentActivities[index];
              return _buildActivityItem(activity);
            },
          ),
        ),
      ],
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
        iconColor = Color(0xFF26A69A);
        break;
      case ActivityType.paymentReceived:
        activityIcon = Icons.payments;
        iconColor = Color(0xFFFFB74D);
        break;
      case ActivityType.taskCompleted:
        activityIcon = Icons.task_alt;
        iconColor = Color(0xFF66BB6A);
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
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(activityIcon, size: 16, color: iconColor),
        ),
        SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activity.message,
                style: TextStyle(fontSize: 14, color: Color(0xFF333333)),
              ),
              SizedBox(height: 4),
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

  Task({
    required this.id,
    required this.title,
    required this.dueDate,
    required this.priority,
    required this.status,
  });
}

class Project {
  final String id;
  final String name;
  final String client;
  final double progress;
  final DateTime dueDate;

  Project({
    required this.id,
    required this.name,
    required this.client,
    required this.progress,
    required this.dueDate,
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
