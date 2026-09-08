import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

void main() {
  runApp(const RoutineMasterApp());
}

class RoutineMasterApp extends StatelessWidget {
  const RoutineMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeFlow Planner',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF38BDF8),
        ),
      ),
      home: const ScheduleScreen(),
    );
  }
}

class TaskItem {
  String id;
  String title;
  String startTime; // HH:mm format
  int durationMinutes;
  String category; // 'sprint-shegtory', 'sprint-blink', 'deepwork', 'workout', 'meal', 'learning'
  bool isEnabled;

  TaskItem({
    required this.id,
    required this.title,
    required this.startTime,
    required this.durationMinutes,
    required this.category,
    this.isEnabled = true,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startTime': startTime,
        'durationMinutes': durationMinutes,
        'category': category,
        'isEnabled': isEnabled,
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) => TaskItem(
        id: map['id'],
        title: map['title'],
        startTime: map['startTime'],
        durationMinutes: map['durationMinutes'],
        category: map['category'],
        isEnabled: map['isEnabled'] ?? true,
      );
}

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  int shegtoryCount = 0;
  final int shegtoryTarget = 120;

  int blinkCount = 0;
  final int blinkTarget = 90;

  List<TaskItem> tasks = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadDefaultTasks() {
    tasks = [
      TaskItem(id: '1', title: 'بیداری و آماده‌سازی', startTime: '04:00', durationMinutes: 30, category: 'routine'),
      TaskItem(id: '2', title: 'اسپرینت ۱: ریپلای Shegtory (۲۰ عدد)', startTime: '04:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '3', title: 'ورزش و دوش صبحگاهی', startTime: '05:00', durationMinutes: 90, category: 'workout'),
      TaskItem(id: '4', title: 'اسپرینت ۱: ریپلای Blink (۱۵ عدد GM)', startTime: '06:30', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '5', title: 'صبحانه کامل و ریکاوری', startTime: '06:50', durationMinutes: 60, category: 'meal'),
      TaskItem(id: '6', title: 'اسپرینت ۲: ریپلای Shegtory (۲۰ عدد)', startTime: '07:50', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '7', title: 'تمرکز عمیق: هکاتون / معماری ایجنت', startTime: '08:10', durationMinutes: 170, category: 'deepwork'),
      TaskItem(id: '8', title: 'اسپرینت ۲: ریپلای Blink (۱۵ عدد)', startTime: '11:00', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '9', title: 'ادیت ویدیوی تست ایجنت Shegtory', startTime: '11:20', durationMinutes: 60, category: 'content'),
      TaskItem(id: '10', title: 'اسپرینت ۳: ریپلای Shegtory (۲۰ عدد)', startTime: '12:20', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '11', title: 'یادگیری زبان تخصصی AI', startTime: '12:40', durationMinutes: 30, category: 'learning'),
      TaskItem(id: '12', title: 'دوره معتبر با مدرک (HuggingFace/Google)', startTime: '13:10', durationMinutes: 60, category: 'learning'),
      TaskItem(id: '13', title: 'اسپرینت ۳: ریپلای Blink (۱۵ عدد)', startTime: '14:10', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '14', title: 'استراتژی و داستان‌نویسی امبسدوری Blink', startTime: '14:30', durationMinutes: 60, category: 'content'),
      TaskItem(id: '15', title: 'اسپرینت ۴: ریپلای Shegtory (۲۰ عدد)', startTime: '15:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '16', title: 'تمرکز عمیق ۲: توسعه فنی و هکاتون', startTime: '15:50', durationMinutes: 150, category: 'deepwork'),
      TaskItem(id: '17', title: 'اسپرینت ۴: ریپلای Blink (۱۵ عدد)', startTime: '18:20', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '18', title: 'استراحت آزاد دور از مانیتور', startTime: '18:40', durationMinutes: 50, category: 'routine'),
      TaskItem(id: '19', title: 'اسپرینت ۵: ریپلای Shegtory (۲۰ عدد)', startTime: '19:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '20', title: 'تست پرامپت‌ها و کارهای سبک شبانه', startTime: '19:50', durationMinutes: 70, category: 'routine'),
      TaskItem(id: '21', title: 'شام و آرامش ذهنی', startTime: '21:00', durationMinutes: 60, category: 'meal'),
      TaskItem(id: '22', title: 'اسپرینت ۵: ریپلای Blink (۱۵ عدد)', startTime: '22:00', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '23', title: 'اسپرینت ۶: ریپلای Shegtory (۲۰ عدد نهایی)', startTime: '22:20', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '24', title: 'اسپرینت ۶: ریپلای Blink (۱۵ عدد Good Night)', startTime: '22:40', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '25', title: 'جمع‌بندی روز و آماده‌سازی خواب', startTime: '23:00', durationMinutes: 30, category: 'routine'),
    ];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      shegtoryCount = prefs.getInt('shegtoryCount') ?? 0;
      blinkCount = prefs.getInt('blinkCount') ?? 0;
      final savedTasks = prefs.getString('tasksList');
      if (savedTasks != null) {
        final List decoded = jsonDecode(savedTasks);
        tasks = decoded.map((item) => TaskItem.fromMap(item)).toList();
      } else {
        _loadDefaultTasks();
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('shegtoryCount', shegtoryCount);
    await prefs.setInt('blinkCount', blinkCount);
    final encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString('tasksList', encoded);
  }

  void _editTaskDialog(TaskItem task) {
    final titleController = TextEditingController(text: task.title);
    final durationController = TextEditingController(text: task.durationMinutes.toString());
    final timeController = TextEditingController(text: task.startTime);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ویرایش و شخصی‌سازی تسک', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'عنوان تسک (مثلاً پروژه دلخواه یا هکاتون)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'ساعت شروع (HH:mm)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'مدت‌زمان (دقیقه)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                task.isEnabled = !task.isEnabled;
              });
              _saveData();
              Navigator.pop(ctx);
            },
            child: Text(task.isEnabled ? 'غیرفعال کردن موقت' : 'فعال کردن',
                style: TextStyle(color: task.isEnabled ? Colors.redAccent : Colors.greenAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                task.title = titleController.text;
                task.startTime = timeController.text;
                task.durationMinutes = int.tryParse(durationController.text) ?? task.durationMinutes;
              });
              _saveData();
              Navigator.pop(ctx);
            },
            child: const Text('ذخیره تغییرات'),
          ),
        ],
      ),
    );
  }

  void _addNewTaskDialog() {
    final titleController = TextEditingController();
    final timeController = TextEditingController(text: '12:00');
    final durationController = TextEditingController(text: '45');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('افزودن تسک اختصاصی جدید', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'عنوان تسک جدید'),
            ),
            TextField(
              controller: timeController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'ساعت شروع'),
            ),
            TextField(
              controller: durationController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(labelText: 'مدت (دقیقه)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              if (titleController.text.isNotEmpty) {
                setState(() {
                  tasks.add(TaskItem(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    startTime: timeController.text,
                    durationMinutes: int.tryParse(durationController.text) ?? 30,
                    category: 'custom',
                  ));
                });
                _saveData();
              }
              Navigator.pop(ctx);
            },
            child: const Text('افزودن'),
          )
        ],
      ),
    );
  }

  void _shiftSchedule(int minutes) {
    setState(() {
      for (var task in tasks) {
        final parts = task.startTime.split(':');
        if (parts.length == 2) {
          int h = int.parse(parts[0]);
          int m = int.parse(parts[1]);
          int totalM = h * 60 + m + minutes;
          if (totalM >= 1440) totalM -= 1440;
          final newH = (totalM ~/ 60).toString().padLeft(2, '0');
          final newM = (totalM % 60).toString().padLeft(2, '0');
          task.startTime = '$newH:$newM';
        }
      }
    });
    _saveData();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('تمام برنامه‌ها $minutes دقیقه به جلو شیفت پیدا کردند')),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'sprint-shegtory':
        return const Color(0xFF6366F1); // Indigo
      case 'sprint-blink':
        return const Color(0xFF06B6D4); // Cyan
      case 'deepwork':
        return const Color(0xFFF59E0B); // Amber
      case 'workout':
        return const Color(0xFF10B981); // Emerald
      case 'meal':
        return const Color(0xFFEC4899); // Pink
      case 'learning':
        return const Color(0xFF8B5CF6); // Purple
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('روال روزانه و اسپرینت‌ها'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_task),
            tooltip: 'افزودن تسک جدید',
            onPressed: _addNewTaskDialog,
          ),
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_time),
            tooltip: 'شیفت زمانی کل برنامه',
            onSelected: _shiftSchedule,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 15, child: Text('+۱۵ دقیقه شیفت جلو')),
              const PopupMenuItem(value: 30, child: Text('+۳۰ دقیقه شیفت جلو')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // بخش ردیاب ریپلای‌های توییتر
          Container(
            padding: const EdgeInsets.all(16),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                _buildCounterRow(
                  title: 'Shegtory (تخصصی AI)',
                  count: shegtoryCount,
                  target: shegtoryTarget,
                  color: const Color(0xFF6366F1),
                  onIncrement: (val) {
                    setState(() => shegtoryCount = (shegtoryCount + val).clamp(0, shegtoryTarget + 50));
                    _saveData();
                  },
                ),
                const SizedBox(height: 12),
                _buildCounterRow(
                  title: 'Blink (سبک و GM)',
                  count: blinkCount,
                  target: blinkTarget,
                  color: const Color(0xFF06B6D4),
                  onIncrement: (val) {
                    setState(() => blinkCount = (blinkCount + val).clamp(0, blinkTarget + 50));
                    _saveData();
                  },
                ),
              ],
            ),
          ),

          // لیست تسک‌ها با قابلیت ویرایش
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (ctx, idx) {
                final task = tasks[idx];
                final color = _getCategoryColor(task.category);

                return Opacity(
                  opacity: task.isEnabled ? 1.0 : 0.4,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: color.withOpacity(0.4), width: 1.5),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          task.startTime,
                          style: TextStyle(color: color, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        task.title,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          decoration: task.isEnabled ? null : TextDecoration.lineThrough,
                        ),
                      ),
                      subtitle: Text(
                        '${task.durationMinutes} دقیقه',
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white70, size: 20),
                        onPressed: () => _editTaskDialog(task),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterRow({
    required String title,
    required int count,
    required int target,
    required Color color,
    required Function(int) onIncrement,
  }) {
    final progress = (count / target).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            Text('$count / $target', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        LinearProgressIndicator(value: progress, backgroundColor: Colors.white12, color: color, minHeight: 7),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _tinyBtn('-1', () => onIncrement(-1)),
            const SizedBox(width: 8),
            _tinyBtn('+1', () => onIncrement(1)),
            const SizedBox(width: 8),
            _tinyBtn('+5', () => onIncrement(5)),
          ],
        )
      ],
    );
  }

  Widget _tinyBtn(String label, VoidCallback onTap) {
    return SizedBox(
      height: 28,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          backgroundColor: const Color(0xFF334155),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 12, color: Colors.white)),
      ),
    );
  }
}
