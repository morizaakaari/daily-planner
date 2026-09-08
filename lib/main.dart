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
      title: 'VibeFlow Command Center',
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
    const HackathonRadarScreen(),
    const AiVocabularyScreen(),
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
            label: 'برنامه و ریپلای',
          ),
          NavigationDestination(
            icon: Icon(Icons.code, color: Colors.white70),
            selectedIcon: Icon(Icons.code, color: Color(0xFFF59E0B)),
            label: 'هکاتون‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.style, color: Colors.white70),
            selectedIcon: Icon(Icons.style, color: Color(0xFF10B981)),
            label: 'زبان و اصطلاحات',
          ),
          NavigationDestination(
            icon: Icon(Icons.school_outlined, color: Colors.white70),
            selectedIcon: Icon(Icons.school, color: Color(0xFF38BDF8)),
            label: 'دوره‌ها',
          ),
        ],
      ),
    );
  }
}

// ==================== بخش ۱: برنامه روزانه و ریپلای توییتر ====================
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
      TaskItem(id: '7', title: 'تمرکز عمیق: هکاتون / ایجنت‌سازی', startTime: '08:10', durationMinutes: 170, category: 'deepwork'),
      TaskItem(id: '8', title: 'اسپرینت ۲: ریپلای Blink (۱۵ عدد)', startTime: '11:00', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '9', title: 'ادیت ویدیوی تست ایجنت Shegtory', startTime: '11:20', durationMinutes: 60, category: 'content'),
      TaskItem(id: '10', title: 'اسپرینت ۳: ریپلای Shegtory (۲۰ عدد)', startTime: '12:20', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '11', title: 'فلش‌کارت و زبان تخصصی AI', startTime: '12:40', durationMinutes: 30, category: 'learning'),
      TaskItem(id: '12', title: 'دوره معتبر با مدرک', startTime: '13:10', durationMinutes: 60, category: 'learning'),
      TaskItem(id: '13', title: 'اسپرینت ۳: ریپلای Blink (۱۵ عدد)', startTime: '14:10', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '14', title: 'استراتژی امبسدوری Blink', startTime: '14:30', durationMinutes: 60, category: 'content'),
      TaskItem(id: '15', title: 'اسپرینت ۴: ریپلای Shegtory (۲۰ عدد)', startTime: '15:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '16', title: 'تمرکز عمیق ۲: توسعه فنی هکاتون', startTime: '15:50', durationMinutes: 150, category: 'deepwork'),
      TaskItem(id: '17', title: 'اسپرینت ۴: ریپلای Blink (۱۵ عدد)', startTime: '18:20', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '18', title: 'استراحت و پیاده‌روی آزاد', startTime: '18:40', durationMinutes: 50, category: 'routine'),
      TaskItem(id: '19', title: 'اسپرینت ۵: ریپلای Shegtory (۲۰ عدد)', startTime: '19:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '20', title: 'کارهای سبک و تست پرامپت', startTime: '19:50', durationMinutes: 70, category: 'routine'),
      TaskItem(id: '21', title: 'شام و آرامش ذهنی', startTime: '21:00', durationMinutes: 60, category: 'meal'),
      TaskItem(id: '22', title: 'اسپرینت ۵: ریپلای Blink (۱۵ عدد)', startTime: '22:00', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '23', title: 'اسپرینت ۶: ریپلای Shegtory (۲۰ عدد)', startTime: '22:20', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '24', title: 'اسپرینت ۶: ریپلای Blink (۱۵ عدد)', startTime: '22:40', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '25', title: 'جمع‌بندی و خواب', startTime: '23:00', durationMinutes: 30, category: 'routine'),
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
                decoration: const InputDecoration(labelText: 'عنوان تسک (مثلاً هکاتون یا پروژه کلاینت)'),
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
                decoration: const InputDecoration(labelText: 'مدت (دقیقه)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => task.isEnabled = !task.isEnabled);
              _saveData();
              Navigator.pop(ctx);
            },
            child: Text(task.isEnabled ? 'غیرفعال کردن' : 'فعال کردن',
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
            child: const Text('ذخیره'),
          ),
        ],
      ),
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
        title: const Text('برنامه روزانه و اسپرینت‌ها'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                _buildCounterRow('Shegtory (تخصصی AI)', shegtoryCount, shegtoryTarget, const Color(0xFF6366F1), (v) {
                  setState(() => shegtoryCount = (shegtoryCount + v).clamp(0, 200));
                  _saveData();
                }),
                const SizedBox(height: 10),
                _buildCounterRow('Blink (سبک و GM)', blinkCount, blinkTarget, const Color(0xFF06B6D4), (v) {
                  setState(() => blinkCount = (blinkCount + v).clamp(0, 150));
                  _saveData();
                }),
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
                    margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    color: const Color(0xFF1E293B),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: color.withOpacity(0.4), width: 1.2),
                    ),
                    child: ListTile(
                      leading: Text(task.startTime, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
                      title: Text(task.title, style: const TextStyle(color: Colors.white, fontSize: 13)),
                      subtitle: Text('${task.durationMinutes} دقیقه', style: const TextStyle(color: Colors.white54, fontSize: 11)),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.white54, size: 18),
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

  Widget _buildCounterRow(String title, int count, int target, Color color, Function(int) onInc) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            Text('$count / $target', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(value: (count / target).clamp(0.0, 1.0), backgroundColor: Colors.white12, color: color, minHeight: 6),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _btn('-1', () => onInc(-1)),
            const SizedBox(width: 6),
            _btn('+1', () => onInc(1)),
            const SizedBox(width: 6),
            _btn('+5', () => onInc(5)),
          ],
        )
      ],
    );
  }

  Widget _btn(String label, VoidCallback onTap) {
    return SizedBox(
      height: 26,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), padding: const EdgeInsets.symmetric(horizontal: 8)),
        onPressed: onTap,
        child: Text(label, style: const TextStyle(fontSize: 11, color: Colors.white)),
      ),
    );
  }
}

// ==================== بخش ۲: رادار هکاتون‌های هوش مصنوعی (حداقل ۱۰ روز مانده) ====================
class HackathonModel {
  final String title;
  final String platform;
  final String prize;
  final String daysLeft;
  final String focusType; // AI Agent, AI Video, Vibecoding
  final String description;

  HackathonModel({
    required this.title,
    required this.platform,
    required this.prize,
    required this.daysLeft,
    required this.focusType,
    required this.description,
  });

  factory HackathonModel.fromJson(Map<String, dynamic> json) => HackathonModel(
        title: json['title'] ?? '',
        platform: json['platform'] ?? 'Devpost / Lablab.ai',
        prize: json['prize'] ?? 'جوایز نقدی + گرنت ابری',
        daysLeft: json['daysLeft'] ?? '۱۰+ روز مانده',
        focusType: json['focusType'] ?? 'AI Agent / Video',
        description: json['description'] ?? '',
      );
}

class HackathonRadarScreen extends StatefulWidget {
  const HackathonRadarScreen({super.key});

  @override
  State<HackathonRadarScreen> createState() => _HackathonRadarScreenState();
}

class _HackathonRadarScreenState extends State<HackathonRadarScreen> {
  bool isLoading = false;
  List<HackathonModel> hackathons = [];

  Future<void> _fetchHackathons() async {
    final prefs = await SharedPreferences.getInstance();
    final apiKey = prefs.getString('geminiApiKey') ?? '';

    if (apiKey.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('لطفاً ابتدا API Key جمنای را در تب دوره‌ها وارد کنید.')),
      );
      return;
    }

    setState(() => isLoading = true);

    final prompt = '''
You are an expert AI Hackathon Scout.
Find 5 credible, active AI hackathons (from LabLab.ai, Devpost, DoraHacks, Kaggle, Hugging Face) specifically focused on:
- AI Agents & Autonomous Workflows
- AI Video Generation / Multimodal AI
- Vibecoding & Rapid Prototyping
CRITICAL REQUIREMENT: There MUST be at least 10 days remaining to build and submit the project.

Return ONLY a valid JSON array of objects (no markdown, no backticks):
[
  {
    "title": "Hackathon Name",
    "platform": "e.g. Lablab.ai / Devpost",
    "prize": "Prize pool or Grants (e.g. \$20,000 + Cloud Credits)",
    "daysLeft": "Estimated remaining days (e.g. 14 Days Left)",
    "focusType": "AI Agents or AI Video",
    "description": "Short explanation in Persian: Why this is perfect to build with AI in under 10 days."
  }
]
''';

    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}]
        }),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String raw = data['candidates'][0]['content']['parts'][0]['text'];
        raw = raw.replaceAll('```json', '').replaceAll('```', '').trim();
        final List list = jsonDecode(raw);
        setState(() {
          hackathons = list.map((item) => HackathonModel.fromJson(item)).toList();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: ${res.statusCode}')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: $e')));
    } finally {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رادار هکاتون‌های AI (حداقل ۱۰ روز مهلت)'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF59E0B), foregroundColor: Colors.black),
                onPressed: isLoading ? null : _fetchHackathons,
                icon: isLoading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black)) : const Icon(Icons.radar),
                label: Text(isLoading ? 'در حال کاوش هکاتون‌های معتبر...' : 'اسکن و دریافت هکاتون‌های جدید'),
              ),
            ),
          ),
          Expanded(
            child: hackathons.isEmpty
                ? const Center(
                    child: Text('برای یافتن جدیدترین هکاتون‌های ایجنت و ویدیو، دکمه اسکن را بزنید.', style: TextStyle(color: Colors.white54)),
                  )
                : ListView.builder(
                    itemCount: hackathons.length,
                    itemBuilder: (ctx, idx) {
                      final h = hackathons[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: Color(0xFFF59E0B), width: 0.8)),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(h.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                    child: Text(h.daysLeft, style: const TextStyle(color: Colors.amberAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(h.platform, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 12)),
                                  const Spacer(),
                                  Text(h.prize, style: const TextStyle(color: Colors.greenAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              const Divider(color: Colors.white12, height: 16),
                              Text(h.description, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }
}

// ==================== بخش ۳: فلش‌کارت زبان تخصصی با حافظه و ELI5 ====================
class VocabItem {
  final String term;
  final String level; // Basic, Intermediate, Advanced
  final String translation;
  final String eli5; // Explain Like I'm 5 (توضیح ساده)

  VocabItem({required this.term, required this.level, required this.translation, required this.eli5});
}

class AiVocabularyScreen extends StatefulWidget {
  const AiVocabularyScreen({super.key});

  @override
  State<AiVocabularyScreen> createState() => _AiVocabularyScreenState();
}

class _AiVocabularyScreenState extends State<AiVocabularyScreen> {
  final int maxDailyNewLearned = 5; // سقف معقول لغات جدید در روز برای جلوگیری از خستگی ذهنی
  int todayLearnedCount = 0;
  List<String> knownWords = [];
  List<String> learningWords = [];
  int currentIndex = 0;
  bool showEli5 = false;

  // بانک جامع و تدریجی از صفر و بیسیک تا فوق پیشرفته
  final List<VocabItem> allVocab = [
    VocabItem(
      term: 'Token',
      level: 'Basic',
      translation: 'توکن (واحد خرد متن برای مدل)',
      eli5: 'مغز هوش مصنوعی متن را کلمه‌به‌کلمه نمی‌خواند، بلکه آن را به لقمه‌های کوچک‌تر به نام توکن خرد می‌کند (تقریباً هر ۴ حرف یا یک کلمه انگلیسی یک توکن است).',
    ),
    VocabItem(
      term: 'Prompt',
      level: 'Basic',
      translation: 'پرامپت (دستور ورودی)',
      eli5: 'همان سوال یا دستوری است که در چت‌باکس می‌نویسی تا هوش مصنوعی بر اساس آن شروع به فکر کردن و جواب دادن کند.',
    ),
    VocabItem(
      term: 'Context Window',
      level: 'Basic',
      translation: 'پنجره بافت یا حافظه کاری',
      eli5: 'حافظه کوتاه‌مدت مدل است! یعنی در یک گفتگو چقدر متن و پیام قبلی را می‌تواند همزمان در مغزش نگه دارد بدون اینکه آن‌ها را فراموش کند.',
    ),
    VocabItem(
      term: 'Hallucination',
      level: 'Basic',
      translation: 'توهم زدن مدل',
      eli5: 'وقتی هوش مصنوعی جوابی را نمی‌داند ولی با اعتمادبه‌نفس بالا یک دروغ شاخ‌دار سرهم می‌کند و تحویلت می‌دهد!',
    ),
    VocabItem(
      term: 'AI Agent',
      level: 'Intermediate',
      translation: 'عامل خودمختار هوش مصنوعی',
      eli5: 'یک هوش مصنوعی معمولی فقط حرف می‌زند، اما یک Agent مثل یک کارمند است: خودش هدف را می‌گیرد، تصمیم می‌گیرد، در وب سرچ می‌کند، کد می‌زند و کار را کامل تحویل می‌دهد.',
    ),
    VocabItem(
      term: 'Vibecoding',
      level: 'Intermediate',
      translation: 'برنامه‌نویسی با حس‌وحال و هوش مصنوعی',
      eli5: 'روشی جدید که تو به جای نوشتن خط‌به‌خط سینتکس کد، با جملات انگلیسی با هوش مصنوعی حرف می‌زنی و آن کل معماری و کد برنامه را برایت می‌سازد.',
    ),
    VocabItem(
      term: 'Tool Calling / Function Calling',
      level: 'Intermediate',
      translation: 'استفاده از ابزارهای خارجی',
      eli5: 'وقتی هوش مصنوعی دست و پا پیدا می‌کند! مثلاً به جای اینکه فقط متن بنویسد، دسترسی دارد که ماشین‌حساب باز کند یا وضعیت آب‌وهوا را با API چک کند.',
    ),
    VocabItem(
      term: 'RAG (Retrieval-Augmented Generation)',
      level: 'Advanced',
      translation: 'تولید مبتنی بر بازیابی اطلاعات',
      eli5: 'امتحان با کتاب باز! مدل قبل از اینکه به تو جواب دهد، می‌رود فایل‌های پی‌دی‌اف یا دیتابیس اختصاصی تو را ورق می‌زند و از روی آن جواب دقیق می‌دهد تا توهم نزند.',
    ),
    VocabItem(
      term: 'Deterministic Routing',
      level: 'Advanced',
      translation: 'مسیریابی قطعی و بدون خطا در ایجنت‌ها',
      eli5: 'به جای اینکه همیشه تصمیم‌گیری را به شانس مدل بسپاری، کد شبیه چراغ راهنمایی عمل می‌کند: اگر کاربر A گفت ۱۰۰٪ برو مسیر ۱، اگر B گفت برو مسیر ۲.',
    ),
    VocabItem(
      term: 'Chain of Thought (CoT)',
      level: 'Advanced',
      translation: 'زنجیره تفکر مرحله‌به‌مرحله',
      eli5: 'به جای پریدن سریع به جواب، هوش مصنوعی مرحله‌به‌مرحله با صدای بلند فکر می‌کند تا در مسائل منطقی و کدنویسی پیچیده اشتباه نکند.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadVocabState();
  }

  Future<void> _loadVocabState() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('vocab_date') ?? '';

    setState(() {
      knownWords = prefs.getStringList('known_words') ?? [];
      learningWords = prefs.getStringList('learning_words') ?? [];

      if (lastDate == today) {
        todayLearnedCount = prefs.getInt('today_learned_count') ?? 0;
      } else {
        todayLearnedCount = 0; // روز جدید، ریست شدن سقف کلمات جدید
        prefs.setString('vocab_date', today);
        prefs.setInt('today_learned_count', 0);
      }

      // پیدا کردن اولین کلمه‌ای که کاربر هنوز تعیین تکلیف نکرده
      currentIndex = allVocab.indexWhere((v) => !knownWords.contains(v.term) && !learningWords.contains(v.term));
      if (currentIndex == -1) currentIndex = 0;
    });
  }

  Future<void> _handleKnown() async {
    final prefs = await SharedPreferences.getInstance();
    final current = allVocab[currentIndex];
    knownWords.add(current.term);
    await prefs.setStringList('known_words', knownWords);

    // دکمه بلدم هیچ محدودیتی ندارد؛ سریع کلمه بعدی می‌آید
    setState(() {
      showEli5 = false;
      currentIndex = (currentIndex + 1) % allVocab.length;
    });
  }

  Future<void> _handleNeedToLearn() async {
    if (todayLearnedCount >= maxDailyNewLearned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎯 سقف یادگیری لغات جدید امروز (۵ لغت) پر شد! برای تثبیت، فردا کلمات جدید را ادامه بده.')),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final current = allVocab[currentIndex];
    learningWords.add(current.term);
    todayLearnedCount++;

    await prefs.setStringList('learning_words', learningWords);
    await prefs.setInt('today_learned_count', todayLearnedCount);

    setState(() {
      showEli5 = false;
      currentIndex = (currentIndex + 1) % allVocab.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    final current = allVocab[currentIndex];

    return Scaffold(
      appBar: AppBar(
        title: const Text('فلش‌کارت زبان تخصصی AI'),
        backgroundColor: const Color(0xFF1E293B),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // نشانگر سقف یادگیری روزانه
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(10)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('لغات جدید امروز:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text(
                    '$todayLearnedCount از $maxDailyNewLearned (سقف ضد خستگی)',
                    style: TextStyle(color: todayLearnedCount >= maxDailyNewLearned ? Colors.redAccent : Colors.greenAccent, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // کارت اصلی لغت
            Expanded(
              child: Card(
                color: const Color(0xFF1E293B),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFF10B981), width: 1.2)),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.purple.withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                        child: Text(current.level, style: const TextStyle(color: Colors.purpleAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                      ),
                      const SizedBox(height: 16),
                      Text(current.term, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(current.translation, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 16)),
                      const SizedBox(height: 24),

                      // دکمه ELI5
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), foregroundColor: Colors.amberAccent),
                        onPressed: () => setState(() => showEli5 = !showEli5),
                        icon: const Icon(Icons.child_care),
                        label: Text(showEli5 ? 'بستن توضیح ساده' : 'توضیح به زبان ساده (ELI5)'),
                      ),
                      if (showEli5) ...[
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.black26, borderRadius: BorderRadius.circular(10), border: BorderSide(color: Colors.amber.withOpacity(0.3))),
                          child: Text(current.eli5, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // دکمه‌های اقدام
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      onPressed: _handleKnown,
                      child: const Text('بلدم (بدون محدودیت بعدی)', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                      onPressed: todayLearnedCount >= maxDailyNewLearned ? null : _handleNeedToLearn,
                      child: const Text('یاد می‌گیرم (ثبت جدید)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ==================== بخش ۴: کاوشگر دوره‌های رایگان ====================
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
        title: json['title'] ?? '',
        provider: json['provider'] ?? '',
        platform: json['platform'] ?? '',
        certificateStatus: json['certificateStatus'] ?? '',
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
  ];

  @override
  void initState() {
    super.initState();
    _loadApiKey();
  }

  Future<void> _loadApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() => apiKey = prefs.getString('geminiApiKey') ?? '');
  }

  Future<void> _saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('geminiApiKey', key);
    setState(() => apiKey = key);
  }

  void _showApiKeyDialog() {
    final controller = TextEditingController(text: apiKey);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('تنظیم Gemini API Key', style: TextStyle(color: Colors.white)),
        content: TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: const InputDecoration(hintText: 'AIzaSy...')),
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

  Future<void> _fetchCourses() async {
    if (apiKey.isEmpty) {
      _showApiKeyDialog();
      return;
    }
    setState(() => isLoading = true);

    final prompt = 'Find 5 strictly top-tier FREE courses or courses with high-value certificates on "$selectedTopic". Return ONLY JSON array of objects with keys: title, provider, platform, certificateStatus, description (in Persian). No markdown.';
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey');
      final res = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [{'parts': [{'text': prompt}]}]
        }),
      );
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        String raw = data['candidates'][0]['content']['parts'][0]['text'];
        raw = raw.replaceAll('```json', '').replaceAll('```', '').trim();
        final List list = jsonDecode(raw);
        setState(() => courses = list.map((item) => CourseModel.fromJson(item)).toList());
      }
    } catch (_) {}
    setState(() => isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('کاوشگر دوره‌های رایگان AI'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(apiKey.isEmpty ? Icons.key_off : Icons.vpn_key, color: apiKey.isEmpty ? Colors.amber : Colors.greenAccent),
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: selectedTopic,
                    dropdownColor: const Color(0xFF1E293B),
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    items: topics.map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => selectedTopic = val!),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF38BDF8), foregroundColor: Colors.black),
                  onPressed: isLoading ? null : _fetchCourses,
                  child: const Text('جستجو'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (ctx, idx) {
                final c = courses[idx];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: const Color(0xFF1E293B),
                  child: ListTile(
                    title: Text(c.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    subtitle: Text('${c.provider} • ${c.certificateStatus}\n${c.description}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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
