import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

const MethodChannel _nativeChannel = MethodChannel('com.hams.salawat/native');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HamsApp());
}

class HamsApp extends StatelessWidget {
  const HamsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'هَمْس | Hams',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF065F46)),
        scaffoldBackgroundColor: const Color(0xFFF4F7F5),
        useMaterial3: true,
      ),
      home: const Directionality(
        textDirection: TextDirection.rtl,
        child: HamsSplashScreen(),
      ),
    );
  }
}

class HamsSplashScreen extends StatefulWidget {
  const HamsSplashScreen({super.key});

  @override
  State<HamsSplashScreen> createState() => _HamsSplashScreenState();
}

class _HamsSplashScreenState extends State<HamsSplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => const Directionality(
              textDirection: TextDirection.rtl,
              child: HamsMainScreen(),
            ),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF044E38), Color(0xFF065F46), Color(0xFF047857)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  color: const Color(0xFF064E3B),
                  border: Border.all(color: const Color(0xFFF59E0B), width: 3),
                ),
                alignment: Alignment.center,
                child: const Text('ﷺ', style: TextStyle(fontSize: 54, color: Color(0xFFFBBF24))),
              ),
              const SizedBox(height: 22),
              const Text('هَمْس | Hams', style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '« رَفِيقُكَ الدَّائِمُ لِلتَّذْكِيرِ بِالصَّلَاةِ عَلَى النَّبِيِّ ﷺ »',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFFFEF3C7), fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 40),
              const CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFFBBF24))),
            ],
          ),
        ),
      ),
    );
  }
}

class HamsMainScreen extends StatefulWidget {
  const HamsMainScreen({super.key});

  @override
  State<HamsMainScreen> createState() => _HamsMainScreenState();
}

class _HamsMainScreenState extends State<HamsMainScreen> with WidgetsBindingObserver {
  final Random _random = Random();

  int _currentIndex = 0;
  bool _isEnabled = true;
  bool _unlockRemind = true;
  bool _notificationsEnabled = true;
  bool _randomMode = true;
  bool _fridayDouble = true;
  bool _quietHours = false;
  int _intervalMinutes = 15;
  int _dailyGoal = 100;
  int _volumePct = 80;
  int _quietStart = 23;
  int _quietEnd = 6;

  int _todayCount = 0;
  int _tasbihCount = 0;
  int _totalCount = 0;

  bool _permNotif = false;
  bool _permBattery = false;
  bool _permOverlay = false;

  final List<String> _adhkarList = [
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ عَبْدِكَ وَرَسُولِكَ',
    'صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ',
    'اللَّهُمَّ صَلِّ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'صَلِّ عَلَى النَّبِيِّ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ عَبْدِكَ وَرَسُولِكَ، كَمَا صَلَّيْتَ عَلَى إِبْرَاهِيمَ، وَبَارِكْ عَلَى مُحَمَّدٍ، وَعَلَى آلِ مُحَمَّدٍ، كَمَا بَارَكْتَ عَلَى إِبْرَاهِيمَ وَآلِ إِبْرَاهِيمَ',
    'صَلِّ عَلَى رَسُولِ اللهِ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى أَزْوَاجِهِ وَذُرِّيَّتِهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ وَعَلَى آلِ مُحَمَّدٍ',
    'الصَّلَاةُ وَالسَّلَامُ عَلَيْكَ يَا رَسُولَ اللهِ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ',
    'اللَّهُمَّ صَلِّ عَلَى مُحَمَّدٍ النَّبِيِّ الْأُمِّيِّ وَعَلَى آلِهِ وَصَحْبِهِ وَسَلِّمْ',
  ];

  Set<int> _selectedIndices = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11};
  final List> _last7DaysStats = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initApp();
  }

  Future<void> _initApp() async {
    await _loadData();
    await _saveData();
    await _requestInitialNotif();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadData();
      _refreshPermissions();
    }
  }

  Future<void> _requestInitialNotif() async {
    try {
      await _nativeChannel.invokeMethod('requestNotificationPermission');
      await _refreshPermissions();
    } catch (_) {}
  }

  Future<void> _refreshPermissions() async {
    try {
      final res = await _nativeChannel.invokeMethod('checkPermissions');
      if (res is Map && mounted) {
        setState(() {
          _permNotif = res['notif'] == true;
          _permBattery = res['battery'] == true;
          _permOverlay = res['overlay'] == true;
        });
      }
    } catch (_) {}
  }

  String _getTodayKey() {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}";
  }

  String _formatDayName(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    if (target == today) return 'اليوم';
    if (target == today.subtract(const Duration(days: 1))) return 'أمس';
    const days = ['الإثنين', 'الثلاثاء', 'الأربعاء', 'الخميس', 'الجمعة', 'السبت', 'الأحد'];
    return days[date.weekday - 1];
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final csv = prefs.getString('selectedCsv_v10') ?? '0,1,2,3,4,5,6,7,8,9,10,11';
    final parsedSet = csv.split(',').map((e) => int.tryParse(e.trim()) ?? -1).where((i) => i >= 0 && i < _adhkarList.length).toSet();

    final todayKey = _getTodayKey();
    final savedDayKey = prefs.getString('last_day_key') ?? todayKey;

    int total = prefs.getInt('totalCount_v10') ?? 0;
    int today = prefs.getInt('todayCount_v10') ?? 0;

    if (savedDayKey != todayKey) {
      await prefs.setInt('day_$savedDayKey', today);
      today = 0;
      await prefs.setString('last_day_key', todayKey);
      await prefs.setInt('todayCount_v10', 0);
    } else {
      today = prefs.getInt('day_$todayKey') ?? today;
    }

    int loadedGoal = prefs.getInt('dailyGoal_v10') ?? 100;
    if (loadedGoal != 100 && loadedGoal != 300 && loadedGoal != 500 && loadedGoal != 1000 && loadedGoal != 10000) {
      loadedGoal = 100;
    }

    if (!mounted) return;
    setState(() {
      _isEnabled = prefs.getBool('enabled_v10') ?? true;
      _unlockRemind = prefs.getBool('unlockRemind_v10') ?? true;
      _notificationsEnabled = prefs.getBool('notificationsEnabled_v10') ?? true;
      _randomMode = prefs.getBool('randomMode_v10') ?? true;
      _fridayDouble = prefs.getBool('fridayDouble_v10') ?? true;
      _quietHours = prefs.getBool('quietHours_v10') ?? false;
      _intervalMinutes = prefs.getInt('interval_v10') ?? 15;
      _dailyGoal = loadedGoal;
      _volumePct = prefs.getInt('volumePct_v10') ?? 80;
      _quietStart = prefs.getInt('quietStart_v10') ?? 23;
      _quietEnd = prefs.getInt('quietEnd_v10') ?? 6;
      _todayCount = today;
      _tasbihCount = prefs.getInt('tasbihCount_v10') ?? 0;
      _totalCount = total;
      _selectedIndices = parsedSet.isEmpty ? {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11} : parsedSet;

      _last7DaysStats.clear();
      final now = DateTime.now();
      for (int i = 0; i < 7; i++) {
        final d = now.subtract(Duration(days: i));
        final k = "${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}";
        final count = i == 0 ? today : (prefs.getInt('day_$k') ?? 0);
        _last7DaysStats.add({
          'key': k,
          'label': _formatDayName(d),
          'dateStr': '${d.year}/${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}',
          'count': count,
        });
      }
    });
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _getTodayKey();
    await prefs.setBool('enabled_v10', _isEnabled);
    await prefs.setBool('unlockRemind_v10', _unlockRemind);
    await prefs.setBool('notificationsEnabled_v10', _notificationsEnabled);
    await prefs.setBool('randomMode_v10', _randomMode);
    await prefs.setBool('fridayDouble_v10', _fridayDouble);
    await prefs.setBool('quietHours_v10', _quietHours);
    await prefs.setInt('interval_v10', _intervalMinutes);
    await prefs.setInt('dailyGoal_v10', _dailyGoal);
    await prefs.setInt('volumePct_v10', _volumePct);
    await prefs.setInt('quietStart_v10', _quietStart);
    await prefs.setInt('quietEnd_v10', _quietEnd);
    await prefs.setInt('todayCount_v10', _todayCount);
    await prefs.setInt('day_$todayKey', _todayCount);
    await prefs.setInt('tasbihCount_v10', _tasbihCount);
    await prefs.setInt('totalCount_v10', _totalCount);
    await prefs.setString('selectedCsv_v10', _selectedIndices.join(','));
    await prefs.setString('last_day_key', todayKey);
    try {
      await _nativeChannel.invokeMethod('startOrUpdateService', {'enabled': _isEnabled});
    } catch (_) {}
  }

  Future<void> _playRealMp3Dhikr(int index) async {
    final text = _adhkarList[index];
    HapticFeedback.mediumImpact();
    setState(() {
      _todayCount++;
      _totalCount++;
    });
    await _saveData();
    await _loadData();
    try {
      await _nativeChannel.invokeMethod('playDhikrNow', {
        'index': index,
        'volumePct': _volumePct,
        'showNotif': _notificationsEnabled,
      });
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: const Color(0xFF065F46),
          content: Text('🔊 « $text »', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _triggerRandomSalawat() async {
    final pool = _selectedIndices.isNotEmpty ? _selectedIndices.toList() : List.generate(_adhkarList.length, (i) => i);
    final chosenIndex = _randomMode ? pool[_random.nextInt(pool.length)] : pool.first;
    await _playRealMp3Dhikr(chosenIndex);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildHomeTab(),
      _buildTasbihTab(),
      _buildStatsTab(),
      _buildSettingsTab(),
      _buildPrivacyTab(),
    ];
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7F5),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(64),
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            bottom: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(color: const Color(0xFF064E3B), borderRadius: BorderRadius.circular(12)),
                      alignment: Alignment.center,
                      child: const Text('ﷺ', style: TextStyle(color: Color(0xFFFBBF24), fontSize: 22)),
                    ),
                    const SizedBox(width: 10),
                    const Text('هَمْس | Hams', style: TextStyle(color: Color(0xFF064E3B), fontSize: 20, fontWeight: FontWeight.w900)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: const Color(0xFFECFDF5), borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFA7F3D0))),
                  child: Text('🔊 صوت مستقل: $_volumePct%', style: const TextStyle(color: Color(0xFF065F46), fontSize: 11.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFECFDF5),
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.notifications_active_outlined), selectedIcon: Icon(Icons.notifications_active, color: Color(0xFF065F46)), label: 'الرئيسية'),
          NavigationDestination(icon: Icon(Icons.radio_button_checked), selectedIcon: Icon(Icons.touch_app, color: Color(0xFF065F46)), label: 'المسبحة'),
          NavigationDestination(icon: Icon(Icons.bar_chart_outlined), selectedIcon: Icon(Icons.bar_chart, color: Color(0xFF065F46)), label: 'الإحصائيات'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), selectedIcon: Icon(Icons.settings, color: Color(0xFF065F46)), label: 'الإعدادات'),
          NavigationDestination(icon: Icon(Icons.shield_outlined), selectedIcon: Icon(Icons.shield, color: Color(0xFF065F46)), label: 'الخصوصية'),
        ],
      ),
    );
  }

  Widget _buildHomeTab() {
    final progress = (_todayCount / _dailyGoal).clamp(0.0, 1.0);
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF064E3B), Color(0xFF047857)], begin: Alignment.topRight, end: Alignment.bottomLeft),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Column(
            children: [
              const Text('﴿ إِنَّ اللَّهَ وَمَلَائِكَتَهُ يُصَلُّونَ عَلَى النَّبِيِّ ﴾', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              const Text('صَلِّ عَلَى مُحَمَّدٍ ﷺ', style: TextStyle(color: Color(0xFFFDE68A), fontSize: 15, fontWeight: FontWeight.w600)),
              const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(color: Colors.white24, height: 1)),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_isEnabled ? 'التذكير الصوتي نشط (كل $_intervalMinutes د)' : 'التذكير الصوتي متوقف مؤقتاً', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                        const SizedBox(height: 2),
                        Text(_unlockRemind ? 'يعمل دورياً + عند فتح قفل الشاشة' : 'يعمل دورياً في الخلفية', style: const TextStyle(color: Color(0xFFA7F3D0), fontSize: 12)),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isEnabled,
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFFD97706),
                    onChanged: (val) {
                      setState(() => _isEnabled = val);
                      _saveData();
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('صلواتك اليوم على النبي ﷺ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1F2937))),
                  Text('$_todayCount / $_dailyGoal', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF065F46))),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(value: progress, minHeight: 10, backgroundColor: const Color(0xFFF3F4F6), valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF15803D))),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF064E3B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 13), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  onPressed: () => _triggerRandomSalawat(),
                  child: const Text('♥ صلِّ على النبي الآن (مع سماع الهمسة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(child: Text('🎙️ صيغ الصلاة والأذكار الصوتية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF065F46)))),
                  TextButton(
                    onPressed: () {
                      setState(() => _selectedIndices = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11});
                      _saveData();
                    },
                    child: const Text('تحديد الكل', style: TextStyle(fontSize: 12)),
                  ),
                ],
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('🎲 التشغيل العشوائي بين الصيغ المحددة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                subtitle: Text('محدد حالياً ${_selectedIndices.length} من 12 صيغة صوتية', style: const TextStyle(fontSize: 11.5)),
                value: _randomMode,
                activeColor: const Color(0xFF065F46),
                onChanged: (val) {
                  setState(() => _randomMode = val);
                  _saveData();
                },
              ),
              const SizedBox(height: 6),
              ...List.generate(_adhkarList.length, (i) {
                final isSelected = _selectedIndices.contains(i);
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFFECFDF5) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isSelected ? const Color(0xFF065F46) : const Color(0xFFE5E7EB), width: isSelected ? 1.5 : 1.0),
                  ),
                  child: Row(
                    children: [
                      Checkbox(
                        value: isSelected,
                        activeColor: const Color(0xFF065F46),
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedIndices.add(i);
                            } else if (_selectedIndices.length > 1) {
                              _selectedIndices.remove(i);
                            }
                          });
                          _saveData();
                        },
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => _playRealMp3Dhikr(i),
                          child: Text('${isSelected ? "✓ " : ""}« ${_adhkarList[i]} »', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF065F46), height: 1.4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () => _playRealMp3Dhikr(i),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF064E3B)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.play_arrow, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTasbihTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('الهدف اليومي: $_dailyGoal', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF4B5563))),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _tasbihCount = 0;
                      });
                      _saveData();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: const Color(0xFFFEE2E2), borderRadius: BorderRadius.circular(10)),
                      child: const Text('تصفير عداد المسبحة ↺', style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              const Text('اللَّهُمَّ صَلِّ وَسَلِّمْ وَبَارِكْ عَلَى نَبِيِّنَا مُحَمَّدٍ ﷺ', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF064E3B), height: 1.5)),
              const SizedBox(height: 6),
              const Text('اضغط على الدائرة للتسبيح والصلاة على النبي ﷺ', style: TextStyle(fontSize: 12, color: Colors.grey)),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() {
                    _tasbihCount++;
                    _todayCount++;
                    _totalCount++;
                  });
                  _saveData();
                  _loadData();
                },
                child: Container(
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(colors: [Color(0xFF15803D), Color(0xFF064E3B)]),
                    border: Border.all(color: const Color(0xFFD97706), width: 6),
                    boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 16, offset: Offset(0, 8))],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$_tasbihCount', style: const TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.w900)),
                      const SizedBox(height: 4),
                      const Text('اضغط للصلاة على النبي ﷺ', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatsTab() {
    int maxVal = _dailyGoal > 10 ? _dailyGoal : 10;
    for (int i = 0; i < _last7DaysStats.length; i++) {
      final int c = (_last7DaysStats[i]['count'] as int?) ?? 0;
      if (c > maxVal) maxVal = c;
    }

    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Column(
                  children: [
                    const Text('حصاد اليوم', style: TextStyle(color: Colors.grey, fontSize: 12.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('$_todayCount', style: const TextStyle(color: Color(0xFF065F46), fontSize: 30, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text('الهدف اليومي: $_dailyGoal', style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE5E7EB))),
                child: Column(
                  children: [
                    const Text('الحصاد منذ تثبيت التطبيق', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey, fontSize: 11.5, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('$_totalCount', style: const TextStyle(color: Color(0xFFB45309), fontSize: 30, fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    const Text('إجمالي الحصاد الكلي', style: TextStyle(color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('📊 نشاطك خلال آخر 7 أيام', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF065F46))),
                  Text('تحديث فوري', style: TextStyle(color: Color(0xFF15803D), fontSize: 11.5, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 14),
              ..._last7DaysStats.map((item) {
                final int count = (item['count'] as int?) ?? 0;
                final double ratio = (count / maxVal).clamp(0.0, 1.0);
                final bool isToday = item['key'] == _getTodayKey();
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: isToday ? const EdgeInsets.symmetric(horizontal: 8, vertical: 6) : EdgeInsets.zero,
                  decoration: isToday ? BoxDecoration(color: const Color(0xFFF0FDF4), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFFBBF7D0))) : null,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 105,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item['label']}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5, color: isToday ? const Color(0xFF065F46) : const Color(0xFF1F2937))),
                            Text('${item['dateStr']}', style: const TextStyle(fontSize: 10, color: Colors.grey)),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: LinearProgressIndicator(
                            value: ratio,
                            minHeight: 11,
                            backgroundColor: const Color(0xFFF3F4F6),
                            valueColor: AlwaysStoppedAnimation<Color>(isToday ? const Color(0xFFD97706) : const Color(0xFF065F46)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        width: 48,
                        child: Text('$count', textAlign: TextAlign.left, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 12.5, color: Color(0xFF065F46))),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('⚙️ طريقة التذكير والتكرار', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF065F46))),
              const SizedBox(height: 10),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF065F46),
                value: _unlockRemind,
                title: const Text('التذكير عند فتح قفل الشاشة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('تشغيل الهمسة الصوتية فور فتح شاشة الهاتف', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                onChanged: (v) {
                  setState(() => _unlockRemind = v ?? true);
                  _saveData();
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('معدل التكرار الدوري', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('يعمل في الخلفية بانتظام', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                trailing: DropdownButton<int>(
                  value: _intervalMinutes,
                  items: const [
                    DropdownMenuItem(value: 2, child: Text('كل دقيقتين')),
                    DropdownMenuItem(value: 5, child: Text('كل 5 دقائق')),
                    DropdownMenuItem(value: 15, child: Text('كل 15 دقيقة')),
                    DropdownMenuItem(value: 30, child: Text('كل 30 دقيقة')),
                    DropdownMenuItem(value: 60, child: Text('كل ساعة')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _intervalMinutes = v);
                      _saveData();
                    }
                  },
                ),
              ),
              const Divider(),
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF065F46),
                value: _fridayDouble,
                title: const Text('مضاعفة التذكير يوم الجمعة', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('تقليص الفترة الزمنية للنصف يوم الجمعة المبارك', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                onChanged: (v) {
                  setState(() => _fridayDouble = v ?? true);
                  _saveData();
                },
              ),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('الهدف اليومي من الصلوات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('تخصيص هدفك في المسبحة والشاشة الرئيسية', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                trailing: DropdownButton<int>(
                  value: _dailyGoal,
                  items: const [
                    DropdownMenuItem(value: 100, child: Text('100 صلاة')),
                    DropdownMenuItem(value: 300, child: Text('300 صلاة')),
                    DropdownMenuItem(value: 500, child: Text('500 صلاة')),
                    DropdownMenuItem(value: 1000, child: Text('1000 صلاة')),
                    DropdownMenuItem(value: 10000, child: Text('10000 صلاة')),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() => _dailyGoal = v);
                      _saveData();
                    }
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('🔊 مستوى صوت الهمسة المستقل', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF065F46))),
                  Text('$_volumePct%', style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF065F46))),
                ],
              ),
              Slider(
                value: _volumePct.toDouble(),
                min: 10,
                max: 100,
                activeColor: const Color(0xFF065F46),
                onChanged: (val) {
                  setState(() => _volumePct = val.round());
                  _saveData();
                },
              ),
              const Text('يتحكم بقوة صوت التذكير بشكل مستقل عن مستوى وسائط الهاتف مع خفض الأصوات الأخرى بلطف أثناء الهمسة.', style: TextStyle(fontSize: 11.5, color: Colors.grey, height: 1.5)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: const Color(0xFF065F46),
            value: _quietHours,
            title: const Text('🌙 أوقات الهدوء (عدم الإزعاج)', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14.5, color: Color(0xFF065F46))),
            subtitle: Text(_quietHours ? 'يتم كتم الصوت تلقائياً من $_quietStart:00 إلى $_quietEnd:00' : 'التطبيق يعمل حالياً 24 ساعة بدون توقف', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
            onChanged: (v) {
              setState(() => _quietHours = v ?? false);
              _saveData();
            },
          ),
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('🛡️ أذونات الهاتف والعمل في الخلفية', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: Color(0xFF065F46))),
              const SizedBox(height: 10),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF065F46),
                value: _permOverlay,
                title: const Text('العرض فوق التطبيقات الأخرى', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('يسمح هذا الإذن للتطبيق بالظهور فوق التطبيقات الأخرى . وقد يؤثر ذلك في كيفية عرض التطبيقات الأخرى .', style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309), height: 1.5)),
                ),
                onChanged: (_) async {
                  try {
                    await _nativeChannel.invokeMethod('requestOverlayPermission');
                  } catch (_) {}
                },
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF065F46),
                value: _permNotif && _notificationsEnabled,
                title: const Text('إذن الإشعارات والتنبيهات الصوتية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: Text(_permNotif ? 'مفعل ويعرض إشعار الذكر مع كل همسة' : 'اضغط لمنح إذن الإشعارات للتطبيق', style: const TextStyle(fontSize: 11.5, color: Colors.grey)),
                onChanged: (val) async {
                  try {
                    await _nativeChannel.invokeMethod('requestNotificationPermission');
                    setState(() => _notificationsEnabled = val);
                    await _saveData();
                    await _refreshPermissions();
                  } catch (_) {}
                },
              ),
              const Divider(),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                activeColor: const Color(0xFF065F46),
                value: _permBattery,
                title: const Text('العمل في الخلفية دون قيود البطارية', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5)),
                subtitle: const Text('يضمن استمرار نطق الذكر عند فتح الشاشة وفي الخلفية', style: TextStyle(fontSize: 11.5, color: Colors.grey)),
                onChanged: (_) async {
                  try {
                    await _nativeChannel.invokeMethod('requestBatteryExemption');
                  } catch (_) {}
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyTab() {
    return ListView(
      padding: const EdgeInsets.all(14),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE5E7EB))),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('1. عدم جمع أو مشاركة البيانات الشخصية:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF064E3B))),
              SizedBox(height: 4),
              Text('صُمم تطبيق «هَمْس | Hams» ليكون صدقة جارية ورفيقاً روحانياً خالصاً؛ لذا فإن التطبيق لا يجمع، ولا يخزن في خوادم خارجية، ولا يشارك أي بيانات شخصية أو موقع جغرافي أو جهات اتصال مع أي طرف ثالث.', style: TextStyle(fontSize: 12.5, height: 1.6)),
              SizedBox(height: 14),
              Text('2. التخزين المحلي فقط (On-Device Storage):', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF064E3B))),
              SizedBox(height: 4),
              Text('جميع إحصائيات صلواتك على النبي ﷺ، وعداد المسبحة، وتفضيلات الصوت ومعدل التكرار تُحفظ محلياً داخل ذاكرة هاتفك فقط (SharedPreferences)، ويمكنك تصفيرها أو حذفها في أي وقت.', style: TextStyle(fontSize: 12.5, height: 1.6)),
              SizedBox(height: 14),
              Text('3. الأذونات المطلوبة وسبب استخدامها:', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF064E3B))),
              SizedBox(height: 4),
              Text(
                '• مستشعر حالة الشاشة (SCREEN_STATE): لتشغيل التذكير الصوتي بالصلاة على النبي ﷺ فور فتح قفل شاشة الهاتف فقط دون تسجيل أي نشاط.\n'
                '• الخدمة الأمامية والإشعارات (FOREGROUND_SERVICE): لضمان استمرار عمل المؤقت الصوتي الدوري في الخلفية في الأوقات التي تحددها.\n'
                '• العرض فوق التطبيقات الأخرى (SYSTEM_ALERT_WINDOW): لتمكين ظهور التنبيه التذكيري أثناء استخدام الهاتف.',
                style: TextStyle(fontSize: 12.5, height: 1.6),
              ),
              SizedBox(height: 14),
              Text('4. العمل بدون إنترنت (100% Offline):', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: Color(0xFF064E3B))),
              SizedBox(height: 4),
              Text('يعمل التطبيق وجميع ملفاته الصوتية البشرية (MP3) بالكامل بدون الحاجة إلى اتصال بالإنترنت، ولا يتضمن أي برمجيات تتبع إعلانية.', style: TextStyle(fontSize: 12.5, height: 1.6)),
            ],
          ),
        ),
      ],
    );
  }
}
