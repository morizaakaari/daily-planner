import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:convert';
import 'dart:async';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.init();
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
    const AiNewsScreen(),
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
            label: 'برنامه',
          ),
          NavigationDestination(
            icon: Icon(Icons.bolt, color: Colors.white70),
            selectedIcon: Icon(Icons.bolt, color: Color(0xFFE11D48)),
            label: 'اخبار Shegtory',
          ),
          NavigationDestination(
            icon: Icon(Icons.code, color: Colors.white70),
            selectedIcon: Icon(Icons.code, color: Color(0xFFF59E0B)),
            label: 'هکاتون‌ها',
          ),
          NavigationDestination(
            icon: Icon(Icons.style, color: Colors.white70),
            selectedIcon: Icon(Icons.style, color: Color(0xFF10B981)),
            label: 'زبان و لغات',
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

// ==================== سرویس نوتیفیکیشن‌های اندروید ====================
class NotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  static Future<void> init() async {
    if (_isInitialized) return;
    try {
      tz.initializeTimeZones();
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
      );

      await _notificationsPlugin.initialize(initSettings);
      _isInitialized = true;
    } catch (_) {}
  }

  static Future<bool> requestPermissions() async {
    try {
      final android = _notificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (android != null) {
        await android.requestNotificationsPermission();
        await android.requestExactAlarmsPermission();
        return true;
      }
    } catch (_) {}
    return false;
  }

  static Future<void> cancelAll() async {
    await _notificationsPlugin.cancelAll();
  }

  static Future<void> showInstant({
    required int id,
    required String title,
    required String body,
  }) async {
    await init();
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vibeflow_channel',
      'هشدار فوری برنامه',
      channelDescription: 'نوتیفیکیشن هنگام شروع و رسیدن به وقت تسک‌ها',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(id, title, body, details);
  }

  // نوتیفیکیشن ساعت ۴ صبح برای شروع روز. به‌جای recurrence مبتنی بر UTC
  // چند اعلان one-shot می‌سازیم تا ساعت ۴ محلی (حتی اطراف DST) حفظ شود.
  static Future<void> scheduleDailyWakeup() async {
    await init();
    final now = DateTime.now();
    var target = DateTime(now.year, now.month, now.day, 4, 0);
    if (target.isBefore(now)) {
      target = target.add(const Duration(days: 1));
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vibeflow_wakeup',
      'بیدارباش ۴ صبح',
      channelDescription: 'نوتیفیکیشن ساعت ۴ صبح برای آغاز روز کاری',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    for (var day = 0; day < 30; day++) {
      final localTarget = target.add(Duration(days: day));
      final scheduledTz = tz.TZDateTime.from(localTarget.toUtc(), tz.UTC);
      try {
        await _notificationsPlugin.zonedSchedule(
          9900 + day,
        '⏰ وقت بیداری و شروع روز کاری!',
        'ساعت ۴ صبح شد! وارد اپ شو و دکمه «امروزو شروع کردم» را لمس کن 🚀',
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        );
      } catch (_) {
        await _notificationsPlugin.zonedSchedule(
          9900 + day,
        '⏰ وقت بیداری و شروع روز کاری!',
        'ساعت ۴ صبح شد! وارد اپ شو و دکمه «امروزو شروع کردم» را لمس کن 🚀',
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  // تنظیم نوتیفیکیشن سر ساعت شروع هر تسک
  static Future<bool> scheduleTaskNotification({
    required int id,
    required String title,
    required String timeStr,
    required int durationMinutes,
  }) async {
    await init();
    final parts = timeStr.split(':');
    if (parts.length != 2) return false;
    final h = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    if (h == null || m == null || h < 0 || h > 23 || m < 0 || m > 59) {
      return false;
    }

    final now = DateTime.now();
    final target = DateTime(now.year, now.month, now.day, h, m);
    if (!target.isAfter(now)) return false;

    final scheduledTz = tz.TZDateTime.from(target.toUtc(), tz.UTC);

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'vibeflow_tasks',
      'یادآور فعالیت‌ها',
      channelDescription: 'اعلان دقیق در زمان نوبت هر تسک',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
    );
    const NotificationDetails details = NotificationDetails(android: androidDetails);

    try {
      await _notificationsPlugin.zonedSchedule(
        id,
        '🔔 نوبت فعالیت: $title',
        'مدت‌زمان: $durationMinutes دقیقه | الان شروع کن!',
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    } catch (_) {
      await _notificationsPlugin.zonedSchedule(
        id,
        '🔔 نوبت فعالیت: $title',
        'مدت‌زمان: $durationMinutes دقیقه | الان شروع کن!',
        scheduledTz,
        details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }
    return true;
  }
}

// ==================== موتور هوشمند تشخیص خودکار مدل و ارتباط با جمنای ====================
class GeminiService {
  static String? _cachedModel;

  static Future<String> getApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getString('geminiApiKey') ?? '').trim();
  }

  static Future<void> saveApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    _cachedModel = null;
    await prefs.setString('geminiApiKey', key.trim());
  }

  static Future<List<String>> fetchActiveModels(String apiKey) async {
    try {
      final url = Uri.parse('https://generativelanguage.googleapis.com/v1beta/models?key=$apiKey');
      final res = await http.get(url).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        final list = (data['models'] as List?) ?? [];
        final supported = <String>[];
        for (var m in list) {
          final methods = (m['supportedGenerationMethods'] as List?) ?? [];
          if (methods.contains('generateContent')) {
            supported.add(m['name'].toString());
          }
        }
        return supported;
      } else {
        try {
          final errData = jsonDecode(res.body);
          if (errData['error'] != null && errData['error']['message'] != null) {
            throw Exception('گوگل: ${errData['error']['message']}');
          }
        } catch (_) {}
      }
    } catch (e) {
      if (e.toString().contains('گوگل:')) rethrow;
    }
    return [];
  }

  static Future<String> generate(String prompt, {String? apiKeyOverride}) async {
    final apiKey = (apiKeyOverride ?? await getApiKey()).trim();
    if (apiKey.isEmpty) {
      throw Exception('کلید API وارد نشده است. از آیکون کلید بالای صفحه استفاده کنید.');
    }

    List<String> targetModels = [];

    if (_cachedModel != null) {
      targetModels.add(_cachedModel!);
    } else {
      final activeFromGoogle = await fetchActiveModels(apiKey);
      if (activeFromGoogle.isNotEmpty) {
        final flashModels = activeFromGoogle.where((m) => m.toLowerCase().contains('flash')).toList();
        if (flashModels.isNotEmpty) {
          targetModels.addAll(flashModels);
        }
        targetModels.addAll(activeFromGoogle);
      }
    }

    targetModels.addAll([
      'models/gemini-2.0-flash',
      'models/gemini-1.5-flash',
      'models/gemini-2.5-flash',
      'models/gemini-flash-latest',
      'models/gemini-1.5-flash-latest',
    ]);

    targetModels = targetModels.toSet().toList();
    String lastError = '';

    for (final rawModel in targetModels) {
      final modelPath = rawModel.startsWith('models/') ? rawModel : 'models/$rawModel';

      try {
        final url = Uri.parse(
            'https://generativelanguage.googleapis.com/v1beta/$modelPath:generateContent?key=$apiKey');

        final response = await http
            .post(
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
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final candidates = data['candidates'] as List?;
          if (candidates != null && candidates.isNotEmpty) {
            final parts = candidates[0]['content']['parts'] as List?;
            if (parts != null && parts.isNotEmpty) {
              _cachedModel = modelPath;
              return parts[0]['text'] as String;
            }
          }
        } else if (response.statusCode == 404) {
          lastError = 'مدل $modelPath در دسترس نیست (404)';
          continue;
        } else if (response.statusCode == 400 || response.statusCode == 403) {
          try {
            final errData = jsonDecode(response.body);
            final msg = errData['error']['message'] ?? '';
            throw Exception('خطای گوگل (${response.statusCode}): $msg');
          } catch (e) {
            if (e.toString().contains('خطای گوگل')) rethrow;
            throw Exception('خطای گوگل (${response.statusCode}): کلید نامعتبر است یا آی‌پی ایران تحریم است.');
          }
        } else {
          lastError = 'خطای سرور گوگل: ${response.statusCode}';
        }
      } on TimeoutException {
        throw Exception('تایم‌اوت ۱۵ ثانیه: پاسخی دریافت نشد! لطفاً فیلترشکن را بررسی یا عوض کنید.');
      } catch (e) {
        if (e.toString().contains('SocketException')) {
          throw Exception('عدم اتصال به سرور گوگل. از اتصال اینترنت و فیلترشکن مطمئن شوید.');
        }
        rethrow;
      }
    }

    throw Exception(lastError.isNotEmpty ? lastError : 'هیچ مدل فعالی برای این کلید پیدا نشد.');
  }

  static String cleanJsonArray(String raw) {
    final regExp = RegExp(r'\[\s*\{.*\}\s*\]', dotAll: true);
    final match = regExp.firstMatch(raw);
    if (match != null) {
      return match.group(0)!;
    }
    return raw.replaceAll('```json', '').replaceAll('```', '').trim();
  }

  static void showApiKeyDialog(BuildContext context, VoidCallback onSaved) async {
    final currentKey = await getApiKey();
    final controller = TextEditingController(text: currentKey);
    bool isTesting = false;
    String testResult = '';
    bool isSuccess = false;

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: const Row(
            children: [
              Icon(Icons.vpn_key, color: Colors.amberAccent),
              SizedBox(width: 8),
              Text('تنظیم و تست Gemini Key', style: TextStyle(color: Colors.white, fontSize: 16)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'کلید رایگان خود را از aistudio.google.com وارد کنید:',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: controller,
                  obscureText: true,
                  enableSuggestions: false,
                  autocorrect: false,
                  style: const TextStyle(color: Colors.white, fontSize: 13),
                  decoration: const InputDecoration(
                    hintText: 'AIzaSy...',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF38BDF8),
                      side: const BorderSide(color: Color(0xFF38BDF8)),
                    ),
                    onPressed: isTesting
                        ? null
                        : () async {
                            final testKey = controller.text.trim();
                            if (testKey.isEmpty) {
                              setDialogState(() {
                                testResult = 'ابتدا کلید را در کادر پیست کنید.';
                                isSuccess = false;
                              });
                              return;
                            }
                            setDialogState(() {
                              isTesting = true;
                              testResult = 'در حال ارتباط با گوگل و شناسایی مدل‌های فعال...';
                            });

                            try {
                              await generate('Reply with exactly: OK', apiKeyOverride: testKey);
                              setDialogState(() {
                                isTesting = false;
                                isSuccess = true;
                                testResult = 'اتصال ۱۰۰٪ برقرار شد! مدل فعال: $_cachedModel ✅';
                              });
                            } catch (err) {
                              setDialogState(() {
                                isTesting = false;
                                isSuccess = false;
                                testResult = err.toString().replaceAll('Exception:', '').trim();
                              });
                            }
                          },
                    icon: isTesting
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.network_check, size: 18),
                    label: const Text('تست اتصال و مدل خودکار'),
                  ),
                ),
                if (testResult.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isSuccess ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: isSuccess ? Colors.greenAccent : Colors.redAccent),
                    ),
                    child: Text(
                      testResult,
                      style: TextStyle(
                        color: isSuccess ? Colors.greenAccent : Colors.redAccent,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('انصراف')),
            ElevatedButton(
              onPressed: () async {
                await saveApiKey(controller.text.trim());
                onSaved();
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('ذخیره نهایی'),
            )
          ],
        ),
      ),
    );
  }
}

// ==================== بخش ۱: برنامه روزانه و اسپرینت‌ها ====================
class TaskItem {
  String id;
  String title;
  String startTime;
  String originalStartTime;
  int durationMinutes;
  String category;
  bool isEnabled;

  TaskItem({
    required this.id,
    required this.title,
    required this.startTime,
    String? originalStartTime,
    required this.durationMinutes,
    required this.category,
    this.isEnabled = true,
  }) : originalStartTime = originalStartTime ?? startTime;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'startTime': startTime,
        'originalStartTime': originalStartTime,
        'durationMinutes': durationMinutes,
        'category': category,
        'isEnabled': isEnabled,
      };

  factory TaskItem.fromMap(Map<String, dynamic> map) => TaskItem(
        id: map['id'],
        title: map['title'],
        startTime: map['startTime'],
        originalStartTime: map['originalStartTime'] ?? map['startTime'],
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
  bool hasApiKey = false;
  bool isDayStarted = false;
  String startedTimeStr = '';

  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeNotifications();
  }

  Future<void> _initializeNotifications() async {
    await NotificationService.requestPermissions();
    await NotificationService.scheduleDailyWakeup();
  }

  void _loadDefaultTasks() {
    tasks = [
      TaskItem(id: '1', title: 'بیداری و هوشیاری', startTime: '04:00', durationMinutes: 30, category: 'routine'),
      TaskItem(id: '2', title: 'اسپرینت ۱: ریپلای Shegtory (۲۰ عدد)', startTime: '04:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '3', title: 'ورزش و دوش صبحگاهی', startTime: '05:00', durationMinutes: 90, category: 'workout'),
      TaskItem(id: '4', title: 'اسپرینت ۱: ریپلای Blink (۱۵ عدد GM)', startTime: '06:30', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '5', title: 'صبحانه کامل و شارژ انرژی', startTime: '06:50', durationMinutes: 60, category: 'meal'),
      TaskItem(id: '6', title: 'اسپرینت ۲: ریپلای Shegtory (۲۰ عدد)', startTime: '07:50', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '7', title: 'تمرکز عمیق: هکاتون / توسعه ایجنت', startTime: '08:10', durationMinutes: 170, category: 'deepwork'),
      TaskItem(id: '8', title: 'اسپرینت ۲: ریپلای Blink (۱۵ عدد)', startTime: '11:00', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '9', title: 'ادیت ویدیوی تست ایجنت Shegtory', startTime: '11:20', durationMinutes: 60, category: 'content'),
      TaskItem(id: '10', title: 'اسپرینت ۳: ریپلای Shegtory (۲۰ عدد)', startTime: '12:20', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '11', title: 'فلش‌کارت و یادگیری اصطلاحات AI', startTime: '12:40', durationMinutes: 30, category: 'learning'),
      TaskItem(id: '12', title: 'دوره معتبر با مدرک', startTime: '13:10', durationMinutes: 60, category: 'learning'),
      TaskItem(id: '13', title: 'اسپرینت ۳: ریپلای Blink (۱۵ عدد)', startTime: '14:10', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '14', title: 'استراتژی امبسدوری اکانت Blink', startTime: '14:30', durationMinutes: 60, category: 'content'),
      TaskItem(id: '15', title: 'اسپرینت ۴: ریپلای Shegtory (۲۰ عدد)', startTime: '15:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '16', title: 'تمرکز عمیق ۲: ادامه کارهای هکاتون', startTime: '15:50', durationMinutes: 150, category: 'deepwork'),
      TaskItem(id: '17', title: 'اسپرینت ۴: ریپلای Blink (۱۵ عدد)', startTime: '18:20', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '18', title: 'استراحت آزاد دور از مانیتور', startTime: '18:40', durationMinutes: 50, category: 'routine'),
      TaskItem(id: '19', title: 'اسپرینت ۵: ریپلای Shegtory (۲۰ عدد)', startTime: '19:30', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '20', title: 'کارهای سبک و تست پرامپت‌ها', startTime: '19:50', durationMinutes: 70, category: 'routine'),
      TaskItem(id: '21', title: 'شام و آرامش ذهن', startTime: '21:00', durationMinutes: 60, category: 'meal'),
      TaskItem(id: '22', title: 'اسپرینت ۵: ریپلای Blink (۱۵ عدد)', startTime: '22:00', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '23', title: 'اسپرینت ۶: ریپلای Shegtory (۲۰ عدد)', startTime: '22:20', durationMinutes: 20, category: 'sprint-shegtory'),
      TaskItem(id: '24', title: 'اسپرینت ۶: ریپلای Blink (۱۵ عدد GN)', startTime: '22:40', durationMinutes: 20, category: 'sprint-blink'),
      TaskItem(id: '25', title: 'جمع‌بندی و خواب', startTime: '23:00', durationMinutes: 30, category: 'routine'),
    ];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('geminiApiKey') ?? '';
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDay = prefs.getString('active_day_date') ?? '';

    if (!mounted) return;
    setState(() {
      hasApiKey = key.isNotEmpty;
      shegtoryCount = savedDay == today ? (prefs.getInt('shegtoryCount') ?? 0) : 0;
      blinkCount = savedDay == today ? (prefs.getInt('blinkCount') ?? 0) : 0;
      isDayStarted = (savedDay == today);
      startedTimeStr = isDayStarted ? (prefs.getString('active_day_started_time') ?? '') : '';

      final savedTasks = prefs.getString('tasksList');
      if (savedTasks != null) {
        final List decoded = jsonDecode(savedTasks);
        tasks = decoded.map((item) => TaskItem.fromMap(item)).toList();
        if (!isDayStarted) {
          for (final task in tasks) {
            task.startTime = task.originalStartTime;
          }
        }
      } else {
        _loadDefaultTasks();
      }
    });
    if (savedDay != today) await _saveData();
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('shegtoryCount', shegtoryCount);
    await prefs.setInt('blinkCount', blinkCount);
    final encoded = jsonEncode(tasks.map((t) => t.toMap()).toList());
    await prefs.setString('tasksList', encoded);
  }

  // فرآیند دکمه "امروزو شروع کردم 🚀"
  Future<void> _startMyDay() async {
    final now = DateTime.now();
    final currentH = now.hour.toString().padLeft(2, '0');
    final currentM = now.minute.toString().padLeft(2, '0');
    final currentTime = '$currentH:$currentM';

    final shouldShift = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('🚀 شروع رسمی روز کاری', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ساعت ورود شما: $currentTime',
                style: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            const Text(
              'می‌خواهید برنامه‌ها از همین ساعت مرتب شوند یا طبق ساعات جدول اصلی نوتیفیکیشن‌ها ست شوند؟',
              style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('ساعات جدول اصلی', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('شیفت از همین لحظه', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (shouldShift == null) return;

    for (final task in tasks) {
      task.startTime = task.originalStartTime;
    }
    if (shouldShift) {
      int currentMinutes = now.hour * 60 + now.minute;
      for (var t in tasks) {
        if (!t.isEnabled) continue;
        final originalParts = t.originalStartTime.split(':');
        if (originalParts.length != 2) continue;
        final hour = int.tryParse(originalParts[0]);
        final minute = int.tryParse(originalParts[1]);
        if (hour == null || minute == null) continue;
        final originalMinutes = hour * 60 + minute;
        if (originalMinutes < currentMinutes) continue;
        final h = (currentMinutes ~/ 60).toString().padLeft(2, '0');
        final m = (currentMinutes % 60).toString().padLeft(2, '0');
        t.startTime = '$h:$m';
        currentMinutes += t.durationMinutes;
      }
    }

    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await prefs.setString('active_day_date', today);
    await prefs.setString('active_day_started_time', currentTime);
    await _saveData();

    await NotificationService.cancelAll();
    await NotificationService.scheduleDailyWakeup();

    int scheduledCount = 0;
    for (int i = 0; i < tasks.length; i++) {
      final t = tasks[i];
      if (!t.isEnabled) continue;
      final wasScheduled = await NotificationService.scheduleTaskNotification(
        id: i + 100,
        title: t.title,
        timeStr: t.startTime,
        durationMinutes: t.durationMinutes,
      );
      if (wasScheduled) scheduledCount++;
    }

    await NotificationService.showInstant(
      id: 1,
      title: '🚀 روز کاری فعال شد!',
      body: 'ساعت شروع: $currentTime | نوتیفیکیشن برای $scheduledCount تسک با موفقیت فعال شد.',
    );

    if (!mounted) return;
    setState(() {
      isDayStarted = true;
      startedTimeStr = currentTime;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF10B981),
          content: Text('روز کاری آغاز شد! نوتیفیکیشن برای $scheduledCount فعالیت تنظیم شد ✅'),
        ),
      );
    }
  }

  void _editTaskDialog(TaskItem task) {
    final titleController = TextEditingController(text: task.title);
    final durationController = TextEditingController(text: task.durationMinutes.toString());
    final timeController = TextEditingController(text: task.startTime);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ویرایش و تعویض تسک', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'عنوان تسک (مثلاً پروژه دلخواه)'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: timeController,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(labelText: 'ساعت شروع (HH:mm)'),
              ),
              const SizedBox(height: 10),
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
              setState(() => task.isEnabled = !task.isEnabled);
              _saveData();
              Navigator.pop(ctx);
            },
            child: Text(task.isEnabled ? 'غیرفعال کردن' : 'فعال کردن',
                style: TextStyle(color: task.isEnabled ? Colors.redAccent : Colors.greenAccent)),
          ),
          ElevatedButton(
            onPressed: () {
              final time = timeController.text.trim();
              final match = RegExp(r'^(?:[01]\d|2[0-3]):[0-5]\d$').hasMatch(time);
              final duration = int.tryParse(durationController.text);
              if (titleController.text.trim().isEmpty || !match || duration == null || duration <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('عنوان، ساعت با قالب HH:mm و مدت مثبت را درست وارد کنید.')),
                );
                return;
              }
              setState(() {
                task.title = titleController.text.trim();
                task.startTime = time;
                task.originalStartTime = time;
                task.durationMinutes = duration;
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
        title: const Text('برنامه و اسپرینت‌ها'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(hasApiKey ? Icons.vpn_key : Icons.key_off,
                color: hasApiKey ? Colors.greenAccent : Colors.amberAccent),
            tooltip: 'تنظیم کلید هوش مصنوعی',
            onPressed: () => GeminiService.showApiKeyDialog(context, _loadData),
          ),
        ],
      ),
      body: Column(
        children: [
          // بنر دکمه "امروزو شروع کردم 🚀"
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: isDayStarted ? const Color(0xFF064E3B) : const Color(0xFF312E81),
            child: Row(
              children: [
                Icon(
                  isDayStarted ? Icons.check_circle : Icons.rocket_launch,
                  color: isDayStarted ? Colors.greenAccent : Colors.amberAccent,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isDayStarted ? 'روز کاری فعال است' : 'روز کاری هنوز شروع نشده',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      Text(
                        isDayStarted
                            ? 'شروع از ساعت $startedTimeStr | نوتیفیکیشن‌ها فعالند'
                            : 'آلارم ۴ صبح آماده است | هنگام بیداری دکمه را لمس کنید',
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDayStarted ? const Color(0xFF10B981) : Colors.amberAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  onPressed: _startMyDay,
                  child: Text(
                    isDayStarted ? 'تنظیم مجدد' : 'امروزو شروع کردم 🚀',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),

          // بخش آمار ریپلای‌های توییتر
          Container(
            padding: const EdgeInsets.all(12),
            color: const Color(0xFF1E293B),
            child: Column(
              children: [
                _buildCounterRow('Shegtory (تخصصی AI)', shegtoryCount, shegtoryTarget, const Color(0xFF6366F1), (v) {
                  setState(() => shegtoryCount = (shegtoryCount + v).clamp(0, 200));
                  _saveData();
                }),
                const SizedBox(height: 8),
                _buildCounterRow('Blink (سبک و GM)', blinkCount, blinkTarget, const Color(0xFF06B6D4), (v) {
                  setState(() => blinkCount = (blinkCount + v).clamp(0, 150));
                  _saveData();
                }),
              ],
            ),
          ),

          // لیست تسک‌ها
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

// ==================== بخش ۲: اخبار AI و ژنراتور توییت Shegtory ====================
class AiNewsItem {
  final String title;
  final String source;
  final String summaryFa;
  final String category;
  String? generatedTweet;
  bool isGenerating = false;

  AiNewsItem({
    required this.title,
    required this.source,
    required this.summaryFa,
    required this.category,
    this.generatedTweet,
  });

  factory AiNewsItem.fromJson(Map<String, dynamic> json) => AiNewsItem(
        title: json['title'] ?? '',
        source: json['source'] ?? 'AI Ecosystem',
        summaryFa: json['summaryFa'] ?? '',
        category: json['category'] ?? 'Agents / Vibecoding',
      );
}

class AiNewsScreen extends StatefulWidget {
  const AiNewsScreen({super.key});

  @override
  State<AiNewsScreen> createState() => _AiNewsScreenState();
}

class _AiNewsScreenState extends State<AiNewsScreen> {
  bool isLoading = false;
  List<AiNewsItem> newsList = [];
  bool hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final key = await GeminiService.getApiKey();
    if (!mounted) return;
    setState(() => hasApiKey = key.isNotEmpty);
  }

  Future<void> _fetchAiNews() async {
    setState(() => isLoading = true);

    final prompt = '''
You are a top-tier tech journalist and AI insider covering AI Agents, LLMs, Vibecoding, and Open Source AI models.
Give me 5 breakthrough, hot AI news items from the current AI landscape.

Return ONLY a valid JSON array of objects (no markdown, no backticks):
[
  {
    "title": "Short catchy news headline in English",
    "source": "HuggingFace / Anthropic / GitHub",
    "category": "AI Agents OR Vibecoding OR Models",
    "summaryFa": "Two sentences in Persian explaining what happened."
  }
]
''';

    try {
      final rawText = await GeminiService.generate(prompt);
      final cleaned = GeminiService.cleanJsonArray(rawText);
      final List list = jsonDecode(cleaned);
      if (!mounted) return;
      setState(() {
        newsList = list.map((item) => AiNewsItem.fromJson(item)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _generateTweet(AiNewsItem item) async {
    setState(() => item.isGenerating = true);

    final prompt = '''
Write a viral Twitter post for "shegtory" (AI vibecoding expert) based on:
Headline: "${item.title}"
Context: "${item.summaryFa}"
Length: under 260 characters, include 2 hashtags. Return ONLY the tweet.
''';

    try {
      final tweetText = await GeminiService.generate(prompt);
      setState(() {
        item.generatedTweet = tweetText.trim();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(backgroundColor: Colors.redAccent, content: Text(e.toString().replaceAll('Exception:', '').trim())),
        );
      }
    } finally {
      if (mounted) setState(() => item.isGenerating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('اخبار AI و توییت‌ساز Shegtory'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(hasApiKey ? Icons.vpn_key : Icons.key_off,
                color: hasApiKey ? Colors.greenAccent : Colors.amberAccent),
            tooltip: 'تنظیم کلید هوش مصنوعی',
            onPressed: () => GeminiService.showApiKeyDialog(context, _checkKey),
          ),
        ],
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
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFE11D48), foregroundColor: Colors.white),
                onPressed: isLoading ? null : _fetchAiNews,
                icon: isLoading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.bolt),
                label: Text(isLoading ? 'در حال پایش ترندها...' : 'اسکن اخبار و ترندهای داغ AI'),
              ),
            ),
          ),
          Expanded(
            child: newsList.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        isLoading
                            ? 'در حال ارتباط با جمنای...'
                            : 'فیلترشکن را روشن کنید و دکمه اسکن را بزنید.\nاگر کار نکرد، آیکون کلید بالای صفحه را بزنید و دکمه تست را اجرا کنید.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white54, height: 1.5),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: newsList.length,
                    itemBuilder: (ctx, idx) {
                      final item = newsList[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: const Color(0xFF1E293B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: const BorderSide(color: Color(0xFFE11D48), width: 0.8),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(color: const Color(0xFFE11D48).withOpacity(0.2), borderRadius: BorderRadius.circular(6)),
                                    child: Text(item.category, style: const TextStyle(color: Color(0xFFFB7185), fontSize: 11, fontWeight: FontWeight.bold)),
                                  ),
                                  const Spacer(),
                                  Text(item.source, style: const TextStyle(color: Colors.white54, fontSize: 12)),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(item.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                              const SizedBox(height: 6),
                              Text(item.summaryFa, style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.4)),
                              const SizedBox(height: 12),
                              if (item.generatedTweet != null) ...[
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.black38,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.blueAccent.withOpacity(0.4)),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('توییت آماده Shegtory:', style: TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.copy, size: 16, color: Colors.white70),
                                            tooltip: 'کپی متن توییت',
                                            onPressed: () {
                                              Clipboard.setData(ClipboardData(text: item.generatedTweet!));
                                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('متن توییت کپی شد!')));
                                            },
                                          )
                                        ],
                                      ),
                                      Text(item.generatedTweet!, style: const TextStyle(color: Colors.white, fontSize: 12, height: 1.3)),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                              ],
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton.icon(
                                  style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
                                  onPressed: item.isGenerating ? null : () => _generateTweet(item),
                                  icon: item.isGenerating
                                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                                      : const Icon(Icons.auto_awesome, size: 16),
                                  label: Text(item.generatedTweet == null ? 'تولید توییت با Gemini' : 'تولید توییت جایگزین'),
                                ),
                              )
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

// ==================== بخش ۳: رادار هکاتون‌های AI ====================
class HackathonModel {
  final String title;
  final String platform;
  final String prize;
  final String daysLeft;
  final String focusType;
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
  bool hasApiKey = false;

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final key = await GeminiService.getApiKey();
    if (!mounted) return;
    setState(() => hasApiKey = key.isNotEmpty);
  }

  Future<void> _fetchHackathons() async {
    setState(() => isLoading = true);

    final prompt = '''
Find 5 credible, active AI hackathons (Lablab.ai, Devpost, DoraHacks) with AT LEAST 10 days remaining.
Return ONLY valid JSON array (no markdown):
[
  {
    "title": "Hackathon Name",
    "platform": "Lablab.ai / Devpost",
    "prize": "Prize pool",
    "daysLeft": "14 Days Left",
    "focusType": "AI Agents / Video",
    "description": "Short explanation in Persian."
  }
]
''';

    try {
      final rawText = await GeminiService.generate(prompt);
      final cleaned = GeminiService.cleanJsonArray(rawText);
      final List list = jsonDecode(cleaned);
      if (!mounted) return;
      setState(() {
        hackathons = list.map((item) => HackathonModel.fromJson(item)).toList();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('رادار هکاتون‌های AI (۱۰+ روز)'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(hasApiKey ? Icons.vpn_key : Icons.key_off,
                color: hasApiKey ? Colors.greenAccent : Colors.amberAccent),
            tooltip: 'تنظیم کلید هوش مصنوعی',
            onPressed: () => GeminiService.showApiKeyDialog(context, _checkKey),
          ),
        ],
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
                label: Text(isLoading ? 'در حال کاوش...' : 'اسکن و دریافت هکاتون‌ها'),
              ),
            ),
          ),
          Expanded(
            child: hackathons.isEmpty
                ? Center(
                    child: Text(
                      isLoading ? 'در حال دریافت اطلاعات هکاتون‌ها...' : 'فیلترشکن را روشن کرده و دکمه اسکن را بزنید.',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
                    itemCount: hackathons.length,
                    itemBuilder: (ctx, idx) {
                      final h = hackathons[idx];
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        color: const Color(0xFF1E293B),
                        child: ListTile(
                          title: Text(h.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                          subtitle: Text('${h.platform} • ${h.daysLeft}\n${h.prize}\n${h.description}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
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

// ==================== بخش ۴: فلش‌کارت زبان تخصصی با ELI5 ====================
class VocabItem {
  final String term;
  final String level;
  final String translation;
  final String eli5;

  VocabItem({required this.term, required this.level, required this.translation, required this.eli5});
}

class AiVocabularyScreen extends StatefulWidget {
  const AiVocabularyScreen({super.key});

  @override
  State<AiVocabularyScreen> createState() => _AiVocabularyScreenState();
}

class _AiVocabularyScreenState extends State<AiVocabularyScreen> {
  final int maxDailyNewLearned = 5;
  int todayLearnedCount = 0;
  List<String> knownWords = [];
  List<String> learningWords = [];
  int currentIndex = 0;
  bool showEli5 = false;

  final List<VocabItem> allVocab = [
    VocabItem(term: 'Token', level: 'Basic', translation: 'توکن (واحد خرد متن برای مدل)', eli5: 'مغز هوش مصنوعی متن را کلمه‌به‌کلمه نمی‌خواند، بلکه آن را به لقمه‌های کوچک‌تر به نام توکن خرد می‌کند.'),
    VocabItem(term: 'Prompt', level: 'Basic', translation: 'پرامپت (دستور ورودی)', eli5: 'همان سوال یا دستوری است که می‌نویسی تا هوش مصنوعی بر اساس آن شروع به فکر کردن کند.'),
    VocabItem(term: 'Context Window', level: 'Basic', translation: 'پنجره بافت یا حافظه کاری', eli5: 'حافظه کوتاه‌مدت مدل است؛ چقدر متن را همزمان می‌تواند در مغزش نگه دارد.'),
    VocabItem(term: 'Hallucination', level: 'Basic', translation: 'توهم زدن مدل', eli5: 'وقتی هوش مصنوعی جواب را نمی‌داند ولی با اعتمادبه‌نفس یک دروغ سرهم می‌کند!'),
    VocabItem(term: 'AI Agent', level: 'Intermediate', translation: 'عامل خودمختار AI', eli5: 'مثل یک کارمند: خودش هدف را می‌گیرد، در وب سرچ می‌کند، کد می‌زند و کار را تحویل می‌دهد.'),
    VocabItem(term: 'Vibecoding', level: 'Intermediate', translation: 'کدنویسی حسی با AI', eli5: 'به جای نوشتن خط‌به‌خط سینتکس، به زبان محاوره‌ای با هوش مصنوعی حرف می‌زنی و آن کل برنامه را می‌سازد.'),
    VocabItem(term: 'Function Calling', level: 'Intermediate', translation: 'استفاده از ابزارهای خارجی', eli5: 'وقتی هوش مصنوعی دست‌وپادار می‌شود و ماشین‌حساب یا سرچ وب را اجرا می‌کند.'),
    VocabItem(term: 'Deterministic Routing', level: 'Advanced', translation: 'مسیریابی قطعی ایجنت‌ها', eli5: 'مثل چراغ راهنمایی: به جای شانس مدل، با منطق سخت کدنویسی می‌گوییم چه مسیری برود.'),
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

    if (!mounted) return;
    setState(() {
      knownWords = prefs.getStringList('known_words') ?? [];
      learningWords = prefs.getStringList('learning_words') ?? [];
      if (lastDate == today) {
        todayLearnedCount = prefs.getInt('today_learned_count') ?? 0;
      } else {
        todayLearnedCount = 0;
        prefs.setString('vocab_date', today);
        prefs.setInt('today_learned_count', 0);
      }
      currentIndex = allVocab.indexWhere((v) => !knownWords.contains(v.term) && !learningWords.contains(v.term));
      if (currentIndex == -1) currentIndex = 0;
    });
  }

  Future<void> _handleKnown() async {
    final prefs = await SharedPreferences.getInstance();
    final current = allVocab[currentIndex];
    knownWords.add(current.term);
    await prefs.setStringList('known_words', knownWords);
    setState(() {
      showEli5 = false;
      currentIndex = (currentIndex + 1) % allVocab.length;
    });
  }

  Future<void> _handleNeedToLearn() async {
    if (todayLearnedCount >= maxDailyNewLearned) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('🎯 سقف یادگیری لغات جدید امروز (۵ لغت) پر شد! فردا بقیه را مرور کن.')),
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
      appBar: AppBar(title: const Text('فلش‌کارت زبان تخصصی AI'), backgroundColor: const Color(0xFF1E293B)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: const Color(0xFF1E293B), borderRadius: BorderRadius.circular(8)),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('لغات جدید امروز:', style: TextStyle(color: Colors.white70, fontSize: 13)),
                  Text('$todayLearnedCount از $maxDailyNewLearned', style: const TextStyle(color: Colors.greenAccent, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Card(
                color: const Color(0xFF1E293B),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(current.term, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 10),
                      Text(current.translation, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 16)),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF334155), foregroundColor: Colors.amberAccent),
                        onPressed: () => setState(() => showEli5 = !showEli5),
                        icon: const Icon(Icons.child_care),
                        label: Text(showEli5 ? 'بستن توضیح ساده' : 'توضیح ساده (ELI5)'),
                      ),
                      if (showEli5) ...[
                        const SizedBox(height: 14),
                        Text(current.eli5, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
                      ]
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                    onPressed: _handleKnown,
                    child: const Text('بلدم', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFF97316)),
                    onPressed: todayLearnedCount >= maxDailyNewLearned ? null : _handleNeedToLearn,
                    child: const Text('یاد می‌گیرم', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}

// ==================== بخش ۵: کاوشگر دوره‌های معتبر و رایگان ====================
class CourseModel {
  final String title;
  final String provider;
  final String certificateStatus;
  final String description;

  CourseModel({required this.title, required this.provider, required this.certificateStatus, required this.description});

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        title: json['title'] ?? '',
        provider: json['provider'] ?? '',
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
  bool isLoading = false;
  List<CourseModel> courses = [];
  String selectedTopic = 'AI Agents & Multi-Agent';
  bool hasApiKey = false;

  final List<String> topics = ['AI Agents & Multi-Agent', 'Vibecoding & Code Generation', 'LangChain & CrewAI', 'LLM Fine-tuning'];

  @override
  void initState() {
    super.initState();
    _checkKey();
  }

  Future<void> _checkKey() async {
    final key = await GeminiService.getApiKey();
    if (!mounted) return;
    setState(() => hasApiKey = key.isNotEmpty);
  }

  Future<void> _fetchCourses() async {
    setState(() => isLoading = true);
    final prompt = 'Find 5 strictly top-tier FREE courses or courses with high-value certificates on "$selectedTopic". Return ONLY JSON array of objects with keys: title, provider, certificateStatus, description (in Persian). No markdown.';

    try {
      final rawText = await GeminiService.generate(prompt);
      final cleaned = GeminiService.cleanJsonArray(rawText);
      final List list = jsonDecode(cleaned);
      if (!mounted) return;
      setState(() => courses = list.map((item) => CourseModel.fromJson(item)).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 6),
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('دوره‌های رایگان AI'),
        backgroundColor: const Color(0xFF1E293B),
        actions: [
          IconButton(
            icon: Icon(hasApiKey ? Icons.vpn_key : Icons.key_off,
                color: hasApiKey ? Colors.greenAccent : Colors.amberAccent),
            tooltip: 'تنظیم کلید هوش مصنوعی',
            onPressed: () => GeminiService.showApiKeyDialog(context, _checkKey),
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
                  child: isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                      : const Text('جستجو'),
                ),
              ],
            ),
          ),
          Expanded(
            child: courses.isEmpty
                ? Center(
                    child: Text(
                      isLoading ? 'در حال کاوش دوره‌ها از وب...' : 'موضوع را انتخاب کرده و دکمه جستجو را بزنید.',
                      style: const TextStyle(color: Colors.white54),
                    ),
                  )
                : ListView.builder(
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
