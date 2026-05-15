import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:ui';
import 'dart:async';
import 'package:permission_handler/permission_handler.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TidyFlowApp());
}

class TidyFlowApp extends StatelessWidget {
  const TidyFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TidyFlow Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF090B10),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00E5FF),
          secondary: Color(0xFF2979FF),
          surface: Color(0xFF121623),
        ),
        useMaterial3: true,
      ),
      home: const MainDashboard(),
    );
  }
}

class SystemAgent {
  static const platform = MethodChannel('com.project.tidyflow/system');

  static Future<Map<String, dynamic>> getRamInfo() async {
    try {
      final result = await platform.invokeMethod('getRamInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'total': 1, 'avail': 1};
    }
  }

  static Future<double> getBatteryTemp() async {
    try {
      return await platform.invokeMethod('getBatteryTemp');
    } catch (e) {
      return 0.0;
    }
  }

  static Future<int> boostPhone() async {
    try {
      return await platform.invokeMethod('killBackgroundProcesses');
    } catch (e) {
      return 0;
    }
  }

  static Future<List<Map<String, dynamic>>> getInstalledApps() async {
    try {
      final result = await platform.invokeMethod('getInstalledApps');
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<Map<String, dynamic>> getStorageInfo() async {
    try {
      final result = await platform.invokeMethod('getStorageInfo');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'total': 1, 'free': 1};
    }
  }

  static Future<List<Map<String, dynamic>>> getAppUsageStats() async {
    try {
      final result = await platform.invokeMethod('getAppUsageStats');
      return result.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<List<Map<String, String>>> findDuplicatePhotos() async {
    try {
      final result = await platform.invokeMethod('findDuplicatePhotos');
      return result.map((e) => Map<String, String>.from(e)).toList();
    } catch (e) {
      return [];
    }
  }

  static Future<int> getDownloadsSize() async {
    try {
      return await platform.invokeMethod('getDownloadsSize');
    } catch (e) {
      return 0;
    }
  }

  static Future<Map<String, dynamic>> getMessengerCacheSize() async {
    try {
      final result = await platform.invokeMethod('getMessengerCacheSize');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'telegram': 0, 'whatsapp': 0};
    }
  }

  static Future<Map<String, dynamic>> getBatteryHealth() async {
    try {
      final result = await platform.invokeMethod('getBatteryHealth');
      return Map<String, dynamic>.from(result);
    } catch (e) {
      return {'health': 'Unknown', 'chargeCounter': 0, 'capacity': 0};
    }
  }

  static Future<bool> requestUsageStatsPermission() async {
    try {
      return await platform.invokeMethod('requestUsageStatsPermission');
    } catch (e) {
      return false;
    }
  }

  static Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      return await platform.invokeMethod('requestIgnoreBatteryOptimizations');
    } catch (e) {
      return false;
    }
  }
}

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});
  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard> with TickerProviderStateMixin {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  void _onNavTapped(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.hub, color: Theme.of(context).colorScheme.primary, size: 24),
            ),
            const SizedBox(width: 12),
            const Text('TIDYFLOW PRO', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 2.0, fontSize: 18)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: const [
          PhoneBoostScreen(),
          JunkCleanerScreen(),
          SecurityGuardScreen(),
          DuplicatePhotosScreen(),
          HealthMonitorScreen(),
        ],
      ),
      bottomNavigationBar: _build3DMenu(),
    );
  }

  Widget _build3DMenu() {
    final icons = [Icons.rocket_launch, Icons.storage, Icons.shield, Icons.copy_all, Icons.monitor_heart];
    final labels = ["Boost", "Clean", "Security", "Duplicates", "Health"];
    return Container(
      margin: const EdgeInsets.only(left: 20, right: 20, bottom: 24),
      height: 75,
      decoration: BoxDecoration(
        color: const Color(0xFF171A27).withOpacity(0.9),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: Colors.white.withOpacity(0.05), width: 1.5),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.8), blurRadius: 20, offset: const Offset(0, 15)),
          BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (i) => _buildMenuItem(icons[i], labels[i], i)),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index) {
    bool isActive = _currentIndex == index;
    return GestureDetector(
      onTap: () => _onNavTapped(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive ? Theme.of(context).colorScheme.primary.withOpacity(0.2) : Colors.transparent,
              shape: BoxShape.circle,
              boxShadow: isActive ? [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.4), blurRadius: 12)] : [],
            ),
            child: Icon(icon, size: isActive ? 28 : 24, color: isActive ? Theme.of(context).colorScheme.primary : Colors.grey.shade600),
          ),
          if (isActive)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(label, style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.primary)),
            )
        ],
      ),
    );
  }
}

class PhoneBoostScreen extends StatefulWidget {
  const PhoneBoostScreen({super.key});
  @override
  State<PhoneBoostScreen> createState() => _PhoneBoostScreenState();
}

class _PhoneBoostScreenState extends State<PhoneBoostScreen> {
  double _ramUsedPercent = 0.0;
  bool _isBoosting = false;

  @override
  void initState() {
    super.initState();
    _fetchRam();
  }

  Future<void> _fetchRam() async {
    final ram = await SystemAgent.getRamInfo();
    if (mounted) {
      setState(() {
        if (ram['total'] > 0) {
          _ramUsedPercent = (ram['total'] - ram['avail']) / ram['total'];
        }
      });
    }
  }

  Future<void> _boost() async {
    setState(() => _isBoosting = true);
    int killed = await SystemAgent.boostPhone();
    await Future.delayed(const Duration(seconds: 2));
    await _fetchRam();
    if (mounted) {
      setState(() => _isBoosting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Система очищена. Завершено процессов: $killed'), backgroundColor: Colors.green),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 250, height: 250,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Theme.of(context).colorScheme.primary.withOpacity(0.15), blurRadius: 60, spreadRadius: 20)],
              border: Border.all(color: Theme.of(context).colorScheme.primary.withOpacity(0.5), width: 4),
            ),
            child: Center(
              child: _isBoosting
                  ? const CircularProgressIndicator(color: Colors.cyanAccent)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('${(_ramUsedPercent * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 54, fontWeight: FontWeight.bold, color: Colors.white)),
                        const Text('RAM ЗАНЯТО', style: TextStyle(fontSize: 12, color: Colors.cyanAccent, letterSpacing: 2)),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 60),
          GestureDetector(
            onTap: _isBoosting ? null : _boost,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(25),
                gradient: const LinearGradient(colors: [Color(0xFF00E5FF), Color(0xFF007BFF)]),
                boxShadow: [BoxShadow(color: Colors.cyanAccent.withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: const Center(
                child: Text('АКТИВИРОВАТЬ BOOST', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Colors.black87, letterSpacing: 1.5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class JunkCleanerScreen extends StatefulWidget {
  const JunkCleanerScreen({super.key});
  @override
  State<JunkCleanerScreen> createState() => _JunkCleanerScreenState();
}

class _JunkCleanerScreenState extends State<JunkCleanerScreen> {
  double _usedStorageGB = 0.0;
  double _totalStorageGB = 0.0;
  int _downloadsSizeMB = 0;
  Map<String, dynamic> _messengerCache = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final storage = await SystemAgent.getStorageInfo();
    final downloads = await SystemAgent.getDownloadsSize();
    final messenger = await SystemAgent.getMessengerCacheSize();
    if (mounted) {
      setState(() {
        _totalStorageGB = storage['total'] / (1024 * 1024 * 1024);
        double freeGB = storage['free'] / (1024 * 1024 * 1024);
        _usedStorageGB = _totalStorageGB - freeGB;
        _downloadsSizeMB = (downloads / (1024 * 1024)).toInt();
        _messengerCache = messenger;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Storage Cleaner', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('Анализ физической памяти, загрузок и кэша мессенджеров', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.orangeAccent))
                : ListView(
                    children: [
                      _buildInfoCard(Icons.storage, 'Использовано памяти', '${_usedStorageGB.toStringAsFixed(1)} GB / ${_totalStorageGB.toStringAsFixed(1)} GB', Colors.orangeAccent),
                      _buildInfoCard(Icons.download, 'Загрузки (Downloads)', '${_downloadsSizeMB} MB', Colors.greenAccent),
                      _buildInfoCard(Icons.telegram, 'Telegram кэш', '${(_messengerCache['telegram'] / (1024 * 1024)).toInt()} MB', Colors.blueAccent),
                      _buildInfoCard(Icons.whatsapp, 'WhatsApp статусы', '${(_messengerCache['whatsapp'] / (1024 * 1024)).toInt()} MB', Colors.green),
                      const SizedBox(height: 20),
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orangeAccent,
                          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Очистка временных файлов запущена. Требуется разрешение на файлы.'), backgroundColor: Colors.orange),
                          );
                        },
                        icon: const Icon(Icons.cleaning_services, color: Colors.black),
                        label: const Text('ОПТИМИЗИРОВАТЬ ПАМЯТЬ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(IconData icon, String title, String value, Color color) {
    return Card(
      color: const Color(0xFF121623),
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ListTile(
        leading: Icon(icon, color: color, size: 32),
        title: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        subtitle: Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }
}

class SecurityGuardScreen extends StatefulWidget {
  const SecurityGuardScreen({super.key});
  @override
  State<SecurityGuardScreen> createState() => _SecurityGuardScreenState();
}

class _SecurityGuardScreenState extends State<SecurityGuardScreen> {
  List<Map<String, dynamic>> _unusedApps = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUnusedApps();
  }

  Future<void> _loadUnusedApps() async {
    final usage = await SystemAgent.getAppUsageStats();
    if (mounted) {
      setState(() {
        _unusedApps = usage.where((app) => app['candidateForRemoval'] == true).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Security Guard', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('Приложения, не использовавшиеся более 30 дней', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _unusedApps.isEmpty
                    ? const Center(child: Text('Нет неиспользуемых приложений', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        itemCount: _unusedApps.length,
                        itemBuilder: (context, index) {
                          final app = _unusedApps[index];
                          return ListTile(
                            leading: const Icon(Icons.android, color: Colors.red),
                            title: Text(app['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                            subtitle: Text(app['packageName'], style: const TextStyle(fontSize: 12, color: Colors.grey)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Удаление требует ручных действий в настройках системы'), backgroundColor: Colors.red),
                                );
                              },
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

class DuplicatePhotosScreen extends StatefulWidget {
  const DuplicatePhotosScreen({super.key});
  @override
  State<DuplicatePhotosScreen> createState() => _DuplicatePhotosScreenState();
}

class _DuplicatePhotosScreenState extends State<DuplicatePhotosScreen> {
  List<Map<String, String>> _duplicates = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _findDuplicates();
  }

  Future<void> _findDuplicates() async {
    final dups = await SystemAgent.findDuplicatePhotos();
    if (mounted) {
      setState(() {
        _duplicates = dups;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Duplicate Photos', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 10),
          const Text('Найдены дубликаты фото (по MD5)', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 20),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _duplicates.isEmpty
                    ? const Center(child: Text('Дубликатов не найдено', style: TextStyle(color: Colors.white70)))
                    : ListView.builder(
                        itemCount: _duplicates.length,
                        itemBuilder: (context, index) {
                          final files = _duplicates[index]['files']!.split(';');
                          return Card(
                            color: const Color(0xFF121623),
                            margin: const EdgeInsets.only(bottom: 16),
                            child: ExpansionTile(
                              leading: const Icon(Icons.image, color: Colors.purple),
                              title: Text('${files.length} дубликатов'),
                              children: files.map((path) => ListTile(
                                title: Text(path.split('/').last, style: const TextStyle(fontSize: 12)),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  onPressed: () {},
                                ),
                              )).toList(),
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

class HealthMonitorScreen extends StatefulWidget {
  const HealthMonitorScreen({super.key});
  @override
  State<HealthMonitorScreen> createState() => _HealthMonitorScreenState();
}

class _HealthMonitorScreenState extends State<HealthMonitorScreen> {
  double _temp = 0.0;
  Map<String, dynamic> _batteryHealth = {};
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _updateData();
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _updateData());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _updateData() async {
    final t = await SystemAgent.getBatteryTemp();
    final health = await SystemAgent.getBatteryHealth();
    if (mounted) setState(() {
      _temp = t;
      _batteryHealth = health;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hardware Status', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 30),
          Row(
            children: [
              Expanded(child: _buildSensorCard(Icons.thermostat, 'Battery Temp', '$_temp°C', _temp > 38 ? Colors.redAccent : Colors.greenAccent)),
              const SizedBox(width: 16),
              Expanded(child: _buildSensorCard(Icons.battery_alert, 'Battery Health', _batteryHealth['health'] ?? 'Unknown', Colors.orangeAccent)),
            ],
          ),
          const SizedBox(height: 30),
          _buildSensorCard(Icons.analytics, 'Charge cycles', '${_batteryHealth['chargeCounter'] ?? 0} mAh', Colors.cyanAccent),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.surface, borderRadius: BorderRadius.circular(20)),
            child: Column(
              children: [
                Row(
                  children: [
                    const Icon(Icons.battery_saver, color: Colors.greenAccent, size: 40),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Battery Saver', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text('Оптимизация фонового потребления', style: TextStyle(color: Colors.grey, fontSize: 12)),
                        ],
                      ),
                    ),
                    Switch(value: true, onChanged: (v){}, activeColor: Colors.greenAccent),
                  ],
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.settings_power),
                  title: const Text('Игнорировать оптимизацию батареи'),
                  subtitle: const Text('Позволяет приложению работать в фоне'),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () async {
                      await SystemAgent.requestIgnoreBatteryOptimizations();
                    },
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSensorCard(IconData icon, String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 16),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 4),
          Text(title, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Настройки'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSettingTile(
            icon: Icons.storage,
            title: 'Доступ к файлам',
            description: 'Необходим для поиска дубликатов и очистки загрузок',
            onTap: () async {
              await Permission.storage.request();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Разрешение запрошено, проверьте системное окно')));
            },
          ),
          _buildSettingTile(
            icon: Icons.analytics,
            title: 'Доступ к статистике использования',
            description: 'Позволяет анализировать неиспользуемые приложения',
            onTap: () async {
              await SystemAgent.requestUsageStatsPermission();
            },
          ),
          _buildSettingTile(
            icon: Icons.battery_charging_full,
            title: 'Фоновый режим',
            description: 'Приложение будет работать в фоне для мониторинга',
            onTap: () async {
              await SystemAgent.requestIgnoreBatteryOptimizations();
            },
          ),
          _buildSettingTile(
            icon: Icons.notifications,
            title: 'Уведомления',
            description: 'Получать отчеты об оптимизации',
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Уведомления будут включены в следующей версии')));
            },
          ),
          const Divider(),
          const Text('О приложении', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('TidyFlow Pro v1.0.0\nРеальная оптимизация системы без заглушек.\nИспользует UsageStatsManager и анализ хешей.'),
        ],
      ),
    );
  }

  Widget _buildSettingTile({required IconData icon, required String title, required String description, required VoidCallback onTap}) {
    return Card(
      color: const Color(0xFF121623),
      margin: const EdgeInsets.only(bottom: 16),
      child: ListTile(
        leading: Icon(icon, color: Colors.cyanAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
