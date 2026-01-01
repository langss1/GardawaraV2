import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gardawara_ai/common/services/classifier_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert'; // Untuk JSON
import 'package:gardawara_ai/common/services/history_service.dart';
import 'package:gardawara_ai/common/services/notification_service.dart';

import 'settings_subscreens.dart';
import 'chatbot_screen.dart';

class GuardianHomeScreen extends StatefulWidget {
  const GuardianHomeScreen({super.key});

  @override
  State<GuardianHomeScreen> createState() => _GuardianHomeScreenState();
}

class _GuardianHomeScreenState extends State<GuardianHomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  // --- LOGIC & SERVICES ---
  static const platform = MethodChannel(
    'com.example.gardawara_ai/accessibility',
  );
  final ClassifierService _classifier = ClassifierService();

  // LOGIC STATES
  bool _systemPermissionGranted = false;
  bool _appProtectionActive = true;

  bool get _isProtected => _systemPermissionGranted && _appProtectionActive;

  bool _isProcessing = false;
  int blockedCount = 0;
  int _accessAttempts = 0;
  DateTime? _startTime;
  Timer? _activeTimer;
  String _activeDuration = "0j 0m";
  List<Map<String, String>> _blockedHistory = [];

  // --- UI STATE ---
  int _currentIndex = 0;
  VideoPlayerController? _videoController; // Ubah jadi nullable untuk keamanan
  late AnimationController _animController;

  final Color primaryDark = const Color(0xFF138066);
  final Color primaryLight = const Color(0xFF00E5C5);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _classifier.loadModel();
    platform.setMethodCallHandler(_nativeMethodCallHandler);

    _loadPreferences();
    _loadStoredData(); // Load history & stats
    _initializeVideo();
    _checkPermission();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animController.forward();

    _startUiTimer();

    // Check for pending notification navigation
    if (NotificationService.pendingTabIndex != null) {
      _currentIndex = NotificationService.pendingTabIndex!;
      NotificationService.pendingTabIndex = null; // Reset after consuming
    }
  }

  void _startUiTimer() {
    _activeTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (_isProtected && _startTime != null) {
        final duration = DateTime.now().difference(_startTime!);
        if (mounted) {
          setState(() {
            _activeDuration =
                "${duration.inHours}j ${duration.inMinutes % 60}m";
          });
        }
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeTimer?.cancel();
    _videoController?.dispose(); // Dispose controller dengan benar
    _animController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  // --- CORE LOGIC METHODS ---

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _appProtectionActive = prefs.getBool('user_protection_active') ?? true;
      });
    }
  }

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        blockedCount = prefs.getInt('blockedCount') ?? 0;
        String? historyRaw = prefs.getString('blockedHistory');
        if (historyRaw != null) {
          List<dynamic> decoded = jsonDecode(historyRaw);
          _blockedHistory =
              decoded.map((item) => Map<String, String>.from(item)).toList();
        }
        // Load start time
        String? timeRaw = prefs.getString('protectionStartTime');
        if (timeRaw != null) {
          _startTime = DateTime.parse(timeRaw);
        }
      });
    }
  }

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('blockedCount', blockedCount);
    await prefs.setString('blockedHistory', jsonEncode(_blockedHistory));
  }

  Future<void> _checkPermission() async {
    try {
      final bool result = await platform.invokeMethod('isAccessibilityEnabled');
      if (mounted) {
        if (_systemPermissionGranted != result) {
          setState(() {
            _systemPermissionGranted = result;
            _handleStatusChange();
          });
        }
      }
    } on PlatformException catch (e) {
      debugPrint("Error checking permission: $e");
    }
  }

  void _handleStatusChange() {
    if (_isProtected) {
      if (_startTime == null) {
        _startTime = DateTime.now();
        SharedPreferences.getInstance().then(
          (prefs) => prefs.setString(
            'protectionStartTime',
            _startTime!.toIso8601String(),
          ),
        );
      }
    } else {
      _startTime = null;
      _activeDuration = "0j 0m";
      SharedPreferences.getInstance().then(
        (prefs) => prefs.remove('protectionStartTime'),
      );
    }
    _initializeVideo();
  }

  Future<void> _openSettings() async {
    try {
      await platform.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (e) {
      debugPrint("Error opening settings: $e");
    }
  }

  Future<dynamic> _nativeMethodCallHandler(MethodCall call) async {
    if (call.method == "onTextDetected") {
      if (_isProcessing || !_isProtected) return;
      _isProcessing = true;

      final String text = call.arguments;

      if (mounted) {
        setState(() {
          _accessAttempts++;
        });
      }

      bool isGambling = await _classifier.predict(text);

      if (isGambling) {
        await platform.invokeMethod('performGlobalActionBack');

        if (mounted) {
          setState(() {
            blockedCount++;
            _blockedHistory.insert(0, {
              'url': text.length > 25 ? "${text.substring(0, 25)}..." : text,
              'time': DateFormat('HH:mm, dd/MM').format(DateTime.now()),
            });
            if (_blockedHistory.length > 50)
              _blockedHistory.removeLast(); // Naikkan limit jadi 50
          });

          // Simpan & Sync
          await _saveData();
          await HistoryService.syncHistoryToServer(_blockedHistory);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "Gardawara memblokir konten mencurigakan!",
                style: GoogleFonts.leagueSpartan(),
              ),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      _isProcessing = false;
    }
  }

  // --- VIDEO HANDLING (FIXED MEMORY LEAK) ---

  Future<void> _initializeVideo() async {
    final String videoSource =
        _isProtected ? "assets/video/success.mp4" : "assets/video/failed.mp4";

    // Simpan controller lama untuk di-dispose setelah yang baru siap
    final oldController = _videoController;

    final newController = VideoPlayerController.asset(videoSource);

    try {
      await newController.initialize();
      newController.setLooping(true);
      newController.setVolume(0.0);
      newController.play();

      if (mounted) {
        setState(() {
          _videoController = newController;
        });
      }

      // Dispose controller lama setelah UI terupdate
      if (oldController != null) {
        await oldController.dispose();
      }
    } catch (e) {
      debugPrint("Video error: $e");
    }
  }

  // --- UI BUILDING ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: [
            _buildHomeTab(),
            _buildActivityTab(),
            _buildChatbotTab(),
            // _buildSettingsTab(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: primaryLight.withOpacity(0.3),
          labelTextStyle: WidgetStateProperty.all(
            GoogleFonts.leagueSpartan(
              fontSize: 12,
              color: Colors.black54,
              fontWeight: FontWeight.w600,
            ),
          ),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return IconThemeData(color: primaryDark);
            }
            return const IconThemeData(color: Colors.black45);
          }),
        ),
        child: NavigationBar(
          height: 65,
          backgroundColor: Colors.transparent,
          selectedIndex: _currentIndex,
          elevation: 0,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
              if (index == 0 || index == 3) {
                _animController.reset();
                _animController.forward();
              }
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.show_chart),
              label: 'Aktivitas',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_bubble_outline),
              selectedIcon: Icon(Icons.chat_bubble),
              label: 'Chatbot',
            ),
            // NavigationDestination(
            //   icon: Icon(Icons.settings_outlined),
            //   selectedIcon: Icon(Icons.settings),
            //   label: 'Pengaturan',
            // ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 16),
          _buildStatusCard(),
          const SizedBox(height: 20),
          Align(
            alignment: Alignment.centerLeft,
            child: _buildSectionTitle('Ringkasan Statistik'),
          ),
          const SizedBox(height: 12),
          _buildStatsGrid(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    return _buildAnimatedItem(
      delay: 100,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
          border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
        ),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child:
                  (_videoController != null &&
                          _videoController!.value.isInitialized)
                      ? ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: SizedBox(
                            width: _videoController!.value.size.width,
                            height: _videoController!.value.size.height,
                            child: VideoPlayer(_videoController!),
                          ),
                        ),
                      )
                      : const Center(child: CircularProgressIndicator()),
            ),
            const SizedBox(height: 16),
            Text(
              _isProtected ? 'Status: Aman' : 'Status: Tidak Aman',
              style: GoogleFonts.leagueSpartan(
                color: _isProtected ? primaryDark : const Color(0xFFD32F2F),
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _isProtected
                  ? 'AI aktif memblokir konten negatif'
                  : 'Aktifkan proteksi untuk melindungi perangkat.',
              textAlign: TextAlign.center,
              style: GoogleFonts.leagueSpartan(
                color: Colors.grey[500],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            _buildToggleButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleButton() {
    return GestureDetector(
      onTap: () async {
        if (!_systemPermissionGranted) {
          _openSettings();
        } else {
          final prefs = await SharedPreferences.getInstance();
          setState(() {
            _appProtectionActive = !_appProtectionActive;
            prefs.setBool('user_protection_active', _appProtectionActive);
            _handleStatusChange();
          });
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: double.infinity,
        height: 54,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors:
                _isProtected
                    ? [const Color(0xFFEF4444), const Color(0xFFB91C1C)]
                    : [const Color(0xFF10B981), const Color(0xFF047857)],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _isProtected ? Icons.gpp_bad_outlined : Icons.shield_outlined,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Text(
              _isProtected ? 'Nonaktifkan Proteksi' : 'Aktifkan Proteksi',
              style: GoogleFonts.leagueSpartan(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- REUSABLE WIDGETS ---

  Widget _buildHeader() {
    return _buildAnimatedItem(
      delay: 0,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
            ),
            child: Icon(Icons.shield_rounded, color: primaryDark, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            'Gardawara AI',
            style: GoogleFonts.leagueSpartan(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    return _buildAnimatedItem(
      delay: 300,
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.1,
        children: [
          _buildStatCard(
            'Situs Diblokir',
            blockedCount.toString(),
            Icons.block,
            const Color(0xFF6366F1),
          ),
          _buildStatCard(
            'Aktivitas AI',
            _isProtected ? 'Aktif' : 'Nonaktif',
            Icons.psychology,
            _isProtected ? const Color(0xFFF59E0B) : Colors.grey,
          ),
          _buildStatCard(
            'Waktu Aktif',
            _activeDuration,
            Icons.timer,
            const Color(0xFF10B981),
          ),
          _buildStatCard(
            'Upaya Akses',
            '$_accessAttempts',
            Icons.warning_amber_rounded,
            const Color(0xFFEF4444),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color iconColor,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  value,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                title,
                style: GoogleFonts.leagueSpartan(
                  color: Colors.grey[500],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityTab() => ActivityReportScreen(
    history: _blockedHistory,
    blockedCount: blockedCount,
  );
  Widget _buildChatbotTab() => const GardaChatScreen();
  // Widget _buildSettingsTab() =>
  //     const WhitelistBlacklistScreen(); // Atau sesuaikan dengan menu settings Anda

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.leagueSpartan(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildAnimatedItem({required int delay, required Widget child}) {
    return AnimatedBuilder(
      animation: _animController,
      builder: (context, _) {
        final animation = CurvedAnimation(
          parent: _animController,
          curve: Interval(
            (delay / 1000).clamp(0.0, 1.0),
            ((delay + 500) / 1000).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        );
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 20 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }
}
