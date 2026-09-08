import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

void main() {
  runApp(const RoutineMasterApp());
}

class RoutineMasterApp extends StatelessWidget {
  const RoutineMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VibeFlow Master',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        primaryColor: const Color(0xFF6366F1),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF6366F1),
          secondary: Color(0xFF38BDF8),
        ),
      ),
      home: const MainNavigationScreen(),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  final List<Widget> _screens = [
    const ScheduleScreen(),
    const CourseFinderScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: const Color(0xFF1E293B),
        indicatorColor: const Color(0xFF6366F1).withOpacity(0.3),
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.schedule, color: Colors.white70),
            selectedIcon: Icon(Icons.schedule, color: Color(0xFF6366F1)),
            label: 'برنامه و ریپلای‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.school, color: Color(0xFF38BDF8)),
            label: 'کاوشگر دوره‌های AI',
          ),
        ],
      ),
    );
  }
}

// ==================== بخش اول: برنامه روزانه و ریپلای‌ها ====================
class TaskItem {
  String id;
  String title;
  String startTime;
  int durationMinutes;
  String category;
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
      TaskItem(id: '20', title: 'تست پرامپت‌ها و کارهای شبانه', startTime: '19:50', durationMinutes: 70, category: 'routine'),
      TaskItem(id: '21', title: 'شام و آرامش ذهنی', startTime: '21:00', durationMinutes: 60, category: 'meal'),
      TaskItem(id: '22', title: 'اسپرینت ۵: ریپلای Blink (۱۵ عدد)', startTime: '22:00', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '23', title: 'اسپرینت ۶: ریپلای Shegtory (۲۰ عدد نهایی)', startTime: '22:20', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '24', title: 'اسپرینت ۶: ریپلای Blink (۱۵ عدد Good Night)', startTime: '22:40', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '25', title: 'جمع‌بندی روز و خواب', startTime: '23:00', durationMinutes: 30, category: 'routine'),
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
      SnackBar(content: Text('برنامه‌ها $minutes دقیقه شیفت پیدا کردند')),
    );
  }

  Color _getCategoryColor(String cat) {
    switch (cat) {
      case 'sprint-shegtory':
        return const Color(0xFF6366F1);
      case 'sprint-blink':
        return const Color(0xFF06B6D4);
      case 'deepwork':
        return const Color(0xFFF59E0B);
      case 'workout':
        return const Color(0xFF10B981);
      case 'meal':
        return const Color(0xFFEC4899);
      case 'learning':
        return const Color(0xFF8B5CF6);
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
          PopupMenuButton<int>(
            icon: const Icon(Icons.more_time),
            tooltip: 'شیفت زمانی',
            onSelected: _shiftSchedule,
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 15, child: Text('+۱۵ دقیقه شیفت')),
              const PopupMenuItem(value: 30, child: Text('+۳۰ دقیقه شیفت')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
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
                    setState(() => shegtoryCount = (shegtoryCount + val).clamp(0, 200));
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
                    setState(() => blinkCount = (blinkCount + val).clamp(0, 150));
                    _saveData();
                  },
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: tasks.length,
              itemBuilder: (ctx, idx) {
                final task = tasks[idx];
                final color = _getCategoryColor(task.category);

                return Opacity(
                  opacity: task.isEnabled ? 1.0 : 0.35,
                  child: Card(
                    margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                      side: BorderSide(color: color.withOpacity(0.4), width: 1.2),
                    ),
                    child: ListTile(
                      leading: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
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
                        icon: const Icon(Icons.edit, color: Colors.white70, size: 18),
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
        LinearProgressIndicator(value: progress, backgroundColor: Colors.white12, color: color, minHeight: 6),
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
      height: 26,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          backgroundColor: const Color(0xFF334155),
        ),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ),
    );
  }
}

// ==================== بخش دوم: کاوشگر دوره‌های رایگان با Gemini API ====================
class CourseModel {
  final String title;
  final String provider;
  final String platform;
  final String certificateStatus;
  final String description;

  CourseModel({
    required this.title,
    required this.provider,
    required this.platform,
    required this.certificateStatus,
    required this.description,
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        title: json['title'] ?? 'عنوان دوره',
        provider: json['provider'] ?? 'دانشگاه / کمپانی',
        platform: json['platform'] ?? 'پلتفرم',
        certificateStatus: json['certificateStatus'] ?? 'رایگان',
        description: json['description'] ?? '',
      );
}

class CourseFinderScreen extends StatefulWidget {
  const CourseFinderScreen({super.key});

  @override
  State<CourseFinderScreen> createState() => _CourseFinderScreenState();
}

class _CourseFinderScreenState extends State<CourseFinderScreen> {
  String apiKey = '';
  bool isLoading = false;
  List<CourseModel> courses = [];
  String selectedTopic = 'AI Agents & Multi-Agent';

  final List<String> topics = [
    'AI Agents & Multi-Agent',
    'Vibecoding & Code Generation',
    'LangChain & CrewAI Practical',
    'LLM Fine-tuning & Hugging Face',
    'Prompt Engineering for Devs',
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      apiKey = prefs.getString('geminiApiKey') ?? '';
    });
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiApiKey', key);
    setState(() {
      apiKey = key;
    });
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تنظیم Gemini API Key', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'کلید رایگان خود را از aistudio.google.com دریافت و اینجا وارد کنید:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'AIzaSy...',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
          ElevatedButton(
            onPressed: () {
              _saveApiKey(controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('ذخیره'),
          )
        ],
      ),
    );
  }

  Future<void> _fetchCoursesWithGemini() async {
    if (apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }

    setState(() {
      isLoading = true;
      courses = [];
    });

    final prompt = '''
You are an expert AI Education Curator.
Find 5 strictly top-tier FREE courses or courses with high-value certificates (from Hugging Face, DeepLearning.AI, Coursera with financial-aid/audit, Google Cloud, Stanford Online, Kaggle) on the topic: "$selectedTopic".

You MUST return ONLY a valid JSON array of objects (no markdown, no backticks, no extra text).
Each object must have these exact keys:
"title": Course name in English
"provider": University or Institution (e.g., Hugging Face, Stanford, Google, Andrew Ng)
"platform": Platform name (e.g., Coursera, Kaggle, edX, HuggingFace Learn)
"certificateStatus": (e.g., "Free Certificate", "Certificate with Financial Aid", "Free Badge for LinkedIn")
"description": A concise Persian (Farsi) explanation of why this course is essential and what skills it covers (2 sentences).
''';

    try {
      final url = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String rawText = data['candidates'][0]['content']['parts'][0]['text'];
        rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

        final List parsedList = jsonDecode(rawText);
        setState(() {
          courses = parsedList.map((item) => CourseModel.fromJson(item)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطا در ارتباط با جمنای: کد ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کاوشگر دوره‌های رایگان AI'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(apiKey.isEmpty ? Icons.key_off : Icons.vpn_key,
                color: apiKey.isEmpty ? Colors.amber : Colors.greenAccent),
            tooltip: 'تنظیم API Key جمنای',
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                DropdownButtonFormField<String>(
                  value: selectedTopic,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    labelText: 'موضوع تخصصی جهت کاوش',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: topics
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (val) => setState(() => selectedTopic = val!),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF38BDF8),
                      foregroundColor: const Color(0xFF0F172A),
                    ),
                    onPressed: isLoading ? null : _fetchCoursesWithGemini,
                    icon: isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.auto_awesome),
                    label: Text(
                      isLoading ? 'در حال جستجو و اعتبارسنجی با Gemini...' : 'یافتن دوره‌های معتبر و رایگان',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: courses.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Text(
                        apiKey.isEmpty
                            ? 'ابتدا از آیکون کلید بالا، Gemini API Key خود را وارد کنید.'
                            : 'موضوع را انتخاب کرده و دکمه جستجو با هوش مصنوعی را بزنید.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: courses.length,
                    itemBuilder: (ctx, idx) {
                      final c = courses[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Color(0xFF38BDF8), width: 0.8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      c.title,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      c.certificateStatus,
                                      style: const TextStyle(color: Colors.greenAccent, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    'ارائه‌دهنده: ${c.provider}',
                                    style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12),
                                  ),
                                  const Spacer(),
                                  Text(
                                    'پلتفرم: ${c.platform}',
                                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  ),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 16),
                              Text(
                                c.description,
                                style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
                              ),
                            ],
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
}
