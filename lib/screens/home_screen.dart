import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gardawara_ai/common/services/history_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../common/services/classifier_service.dart';
import 'chatbot_screen.dart';
import 'settings_subscreens.dart';
import 'dart:async'; // Untuk Timer

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  static const platform = MethodChannel(
    'com.example.gardawara_ai/accessibility',
  );
  final ClassifierService _classifier = ClassifierService();

  bool isProtected = false;
  int blockedCount = 0;
  List<Map<String, String>> _blockedHistory = [];
  bool _isProcessing = false;

  // Uptime State
  DateTime? _startTime;
  Timer? _activeTimer;
  String _activeDuration = "0j 0m";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _classifier.loadModel();
    platform.setMethodCallHandler(_nativeMethodCallHandler);

    // 1. Load data dari local storage saat start
    _loadStoredData();
    _checkPermission();
    _startUiTimer();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _activeTimer?.cancel();
    super.dispose();
  }

  void _startUiTimer() {
    _activeTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
      if (isProtected && _startTime != null) {
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

  // --- LOGIKA PENYIMPANAN DATA (LOCAL STORAGE) ---

  Future<void> _loadStoredData() async {
    final prefs = await SharedPreferences.getInstance();
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

  Future<void> _saveData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('blockedCount', blockedCount);
    await prefs.setString('blockedHistory', jsonEncode(_blockedHistory));
  }

  // --- NATIVE HANDLER ---

  Future<dynamic> _nativeMethodCallHandler(MethodCall call) async {
    if (call.method == "onTextDetected") {
      if (_isProcessing || !isProtected) return;
      _isProcessing = true;

      final String text = call.arguments;

      // Cek dengan AI
      bool isGambling = await _classifier.predict(text);

      if (isGambling) {
        // 1. Aksi Blokir (Jika native belum sempat blokir)
        await platform.invokeMethod('performGlobalActionBack');

        // 2. Update UI & Local History
        if (mounted) {
          setState(() {
            blockedCount++; // Ini akan sinkron dengan SharedPreferences
            _blockedHistory.insert(0, {
              'url': text.length > 30 ? "${text.substring(0, 30)}..." : text,
              'time': DateFormat('HH:mm, dd/MM').format(DateTime.now()),
            });
          });

          // 3. Simpan & Sync
          await _saveData();
          await HistoryService.syncHistoryToServer(_blockedHistory);
        }
      }

      await Future.delayed(const Duration(milliseconds: 500));
      _isProcessing = false;
    }
  }

  Future<void> _checkPermission() async {
    try {
      final bool result = await platform.invokeMethod('isAccessibilityEnabled');
      if (mounted) {
        setState(() {
          isProtected = result;
          // Handle logic uptime
          if (isProtected) {
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
        });
      }
    } on PlatformException catch (_) {}
  }

  Future<void> _openSettings() async {
    try {
      await platform.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (_) {}
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkPermission();
  }

  // --- UI HELPERS ---

  // Menampilkan Modal Bottom Sheet untuk riwayat lengkap
  void _showFullHistory() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Semua Riwayat Blokir',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: ListView.builder(
                    itemCount: _blockedHistory.length,
                    itemBuilder:
                        (context, index) =>
                            _buildHistoryItem(_blockedHistory[index]),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  // Widget item riwayat yang reusable
  Widget _buildHistoryItem(Map<String, String> site) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              site['url']!,
              style: GoogleFonts.leagueSpartan(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            site['time']!,
            style: GoogleFonts.leagueSpartan(
              fontSize: 12,
              color: Colors.black45,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: _buildChatBotButton(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Transform.translate(
              offset: const Offset(0, -60),
              child: _buildContentBody(),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    // Ambil lebar layar secara eksplisit
    double screenWidth = MediaQuery.of(context).size.width;

    return SizedBox(
      height: 550,
      width: screenWidth, // Gunakan lebar layar eksplisit
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              // Agar child dari AnimatedSwitcher memenuhi ruang yang tersedia
              layoutBuilder: (
                Widget? currentChild,
                List<Widget> previousChildren,
              ) {
                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    ...previousChildren,
                    if (currentChild != null) currentChild,
                  ],
                );
              },
              child: SizedBox(
                // Key harus di level paling atas child AnimatedSwitcher
                key: ValueKey<bool>(isProtected),
                width: screenWidth,
                height: 550,
                child: Image.asset(
                  isProtected
                      ? 'assets/images/Peta_Locked.png'
                      : 'assets/images/Peta_Unlocked.png',
                  fit: BoxFit.cover, // Memastikan gambar menutupi seluruh area
                  alignment: const Alignment(0.0, -0.2),
                ),
              ),
            ),
          ),
          // --- Gradient Overlay Top (tetap sama) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 150,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    isProtected
                        ? const Color(0xFF00C9A7).withOpacity(0.8)
                        : Colors.red.withOpacity(0.8),
                    Colors.transparent,
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // --- Gradient Overlay Bottom (tetap sama) ---
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFFF5F5F5).withOpacity(0.0),
                    const Color(0xFFF5F5F5),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          // --- Status Text (tetap sama) ---
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child: Column(
              children: [
                isProtected
                    ? const Icon(
                      Icons.verified_user_outlined,
                      color: Colors.white,
                      size: 28,
                    )
                    : Image.asset(
                      'assets/images/unlock.png',
                      width: 40,
                      color: Colors.white,
                    ),
                const SizedBox(height: 8),
                Text(
                  isProtected ? 'Anda Terproteksi' : 'Anda tidak terproteksi',
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContentBody() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors:
                    isProtected
                        ? [const Color(0xFF00C9A7), const Color(0xFF00897B)]
                        : [const Color(0xFFFF5252), const Color(0xFFD32F2F)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PERLINDUNGAN GARDA WARA',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isProtected
                            ? 'Perlindungan Aman'
                            : 'Perlindungan Tidak Aktif',
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isProtected,
                    onChanged: (val) => _openSettings(),
                    activeColor: Colors.white,
                    activeTrackColor: const Color(0xFF00B0FF),
                    inactiveThumbColor: Colors.white,
                    inactiveTrackColor: const Color(0xFFFF5252),
                    trackOutlineColor: MaterialStateProperty.all(
                      Colors.transparent,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Info Disclaimer
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 20, color: Colors.black87),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Garda Wara Memerlukan akses izin aksebilitas untuk mencegah membuka situs atau aplikasi judi',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Stats Card
          AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color:
                  isProtected
                      ? const Color(0xFFD0E8E2)
                      : const Color(0xFFFFE0E0),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      blockedCount.toString(),
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 64,
                        fontWeight: FontWeight.w900,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Website Judi Terblokir',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            isProtected
                                ? 'Perlindungan Aman dengan AI'
                                : 'Segera Aktifkan Gardawara',
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isProtected
                                      ? const Color(0xFF00C9A7).withOpacity(0.2)
                                      : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.timer,
                                  size: 14,
                                  color:
                                      isProtected
                                          ? const Color(0xFF00796B)
                                          : Colors.grey,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  "Aktif: $_activeDuration",
                                  style: GoogleFonts.leagueSpartan(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isProtected
                                            ? const Color(0xFF00796B)
                                            : Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.black26),
                const SizedBox(height: 16),
                Text(
                  'Riwayat Pemblokiran',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                // Logika Riwayat
                if (isProtected && _blockedHistory.isNotEmpty)
                  _buildBlockedList()
                else if (isProtected)
                  _buildEmptyStateProtected()
                else
                  _buildEmptyStateUnprotected(),

                // Tombol Lihat Selengkapnya (Hanya jika > 4 data)
                if (isProtected && _blockedHistory.length > 4) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: () {
                        // Navigasi ke ActivityReportScreen
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder:
                                (_) => ActivityReportScreen(
                                  history: _blockedHistory,
                                  blockedCount: blockedCount,
                                ),
                          ),
                        );
                      },
                      child: Text(
                        'Lihat Selengkapnya',
                        style: GoogleFonts.leagueSpartan(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyStateUnprotected() => _buildEmptyPlaceholder(
    'assets/images/nosafe.png',
    'Segera Aktifkan Gardawara!',
  );
  Widget _buildEmptyStateProtected() => _buildEmptyPlaceholder(
    'assets/images/safe.png',
    'Gardawara tidak mendeteksi apapun',
  );

  Widget _buildEmptyPlaceholder(String img, String label) {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 10),
          Image.asset(img, width: 80, height: 80),
          const SizedBox(height: 12),
          Text(
            label,
            style: GoogleFonts.leagueSpartan(
              color: Colors.black54,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildBlockedList() {
    // Ambil maksimal 4 item terbaru untuk tampilan utama
    final displayList = _blockedHistory.take(4).toList();
    return Column(
      children: displayList.map((site) => _buildHistoryItem(site)).toList(),
    );
  }

  Widget _buildChatBotButton() {
    return GestureDetector(
      onTap:
          () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const GardaChatScreen()),
          ),
      child: Image.asset('assets/images/chatbot.png', width: 80, height: 80),
    );
  }
}
