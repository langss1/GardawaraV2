import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../service/services/classifier_service.dart';
import 'chatbot_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  // 1. Setup Method Channel
  static const platform = MethodChannel(
    'com.example.gardawara_ai/accessibility',
  );

  // 2. Setup Classifier Service
  final ClassifierService _classifier = ClassifierService();

  bool isProtected = false;
  int blockedCount = 0;

  // 3. List Dinamis untuk Riwayat Blokir
  List<Map<String, String>> _blockedHistory = [];

  // Variabel untuk debounce sederhana
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Load AI Model
    _classifier.loadModel();

    // Setup Listener dari Android Native
    platform.setMethodCallHandler(_nativeMethodCallHandler);

    // Cek status izin saat awal buka
    _checkPermission();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Saat user kembali dari menu Settings, cek ulang status izin
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  // ------------------------------------------------------------------------
  // LOGIKA UTAMA (Optimasi agar tidak freeze UI)
  // ------------------------------------------------------------------------
  Future<dynamic> _nativeMethodCallHandler(MethodCall call) async {
    if (call.method == "onTextDetected") {
      // Jika sedang memproses teks sebelumnya, skip dulu (Debounce sederhana)
      if (_isProcessing) return;
      _isProcessing = true;

      final String text = call.arguments;

      // Jangan proses jika proteksi belum aktif
      if (!isProtected) {
        _isProcessing = false;
        return;
      }

      // Prediksi AI (Jalankan di background sebisa mungkin)
      bool isGambling = await _classifier.predict(text);

      if (isGambling) {
        debugPrint("⚠️ JUDI TERDETEKSI: $text");

        // Kirim Perintah Blokir (Back) ke Android
        await platform.invokeMethod('performGlobalActionBack');

        // Update UI hanya jika mounted
        if (mounted) {
          setState(() {
            blockedCount++;
            // Tambahkan ke riwayat
            _blockedHistory.insert(0, {
              'url': text.length > 25 ? "${text.substring(0, 25)}..." : text,
              'time': DateFormat('HH:mm, dd/MM').format(DateTime.now()),
            });
            // Batasi riwayat
            if (_blockedHistory.length > 10) {
              _blockedHistory.removeLast();
            }
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Gardawara memblokir konten mencurigakan!"),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }

      // Beri jeda sedikit sebelum bisa memproses lagi (mengurangi beban UI)
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
        });
      }
    } on PlatformException catch (_) {
      // Abaikan jika method belum siap
    }
  }

  Future<void> _openSettings() async {
    try {
      // Panggil native method untuk buka settings aksesibilitas
      await platform.invokeMethod('requestAccessibilityPermission');
    } on PlatformException catch (_) {}
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
    return SizedBox(
      height: 550,
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Image.asset(
                isProtected
                    ? 'assets/images/Peta_Locked.png'
                    : 'assets/images/Peta_Unlocked.png',
                key: ValueKey<bool>(isProtected),
                fit: BoxFit.cover,
                alignment: const Alignment(0.0, -0.2),
                width: double.infinity,
                height: double.infinity,
              ),
            ),
          ),
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
          Positioned(
            top: 50,
            left: 0,
            right: 0,
            child:
                !isProtected
                    ? Column(
                      children: [
                        Image.asset(
                          'assets/images/unlock.png',
                          width: 40,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anda tidak terproteksi',
                          style: GoogleFonts.leagueSpartan(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                    : Column(
                      children: [
                        const Icon(
                          Icons.verified_user_outlined,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Anda Terproteksi',
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
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
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
                // LOGIKA SWITCH YANG DIPERBAIKI
                Transform.scale(
                  scale: 0.8,
                  child: Switch(
                    value: isProtected,
                    onChanged: (val) {
                      // Selalu buka setting, status akan update saat kembali ke app
                      _openSettings();
                    },
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

          // Disclaimer Info
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
                        color: Colors.black,
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
                              color: Colors.black,
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
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Colors.black87),
                const SizedBox(height: 16),

                Text(
                  'Riwayat Pemblokiran',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                if (isProtected && _blockedHistory.isNotEmpty)
                  _buildBlockedList()
                else if (isProtected)
                  _buildEmptyStateProtected()
                else
                  _buildEmptyStateUnprotected(),

                if (isProtected && _blockedHistory.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () {},
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

  Widget _buildEmptyStateUnprotected() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset('assets/images/nosafe.png', width: 100, height: 100),
          const SizedBox(height: 16),
          Text(
            'Segera Aktifkan Gardawara!',
            style: GoogleFonts.leagueSpartan(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyStateProtected() {
    return Center(
      child: Column(
        children: [
          const SizedBox(height: 20),
          Image.asset('assets/images/safe.png', width: 100, height: 100),
          const SizedBox(height: 16),
          Text(
            'Gardawara tidak mendeteksi apapun',
            style: GoogleFonts.leagueSpartan(
              color: Colors.black54,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildBlockedList() {
    return Column(
      children:
          _blockedHistory.map((site) {
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
          }).toList(),
    );
  }

  Widget _buildChatBotButton() {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const GardaChatScreen()),
        );
      },
      child: Image.asset('assets/images/chatbot.png', width: 80, height: 80),
    );
  }
}
