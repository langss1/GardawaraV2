import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_fonts/google_fonts.dart';

import '../common/services/heartbeat_service.dart';
import '../common/services/notification_service.dart';
import 'guardian_home_screen.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _chatIdController = TextEditingController();

  final String botUsername = "JudiGuard_bot";
  final Color primaryDark = const Color(0xFF138066);
  final Color primaryLight = const Color(0xFF00E5C5);

  late AnimationController _animController;
  late Animation<double> _headerFadeAnimation;
  late Animation<Offset> _headerSlideAnimation;
  late Animation<double> _contentFadeAnimation;
  late Animation<Offset> _contentSlideAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _headerFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _headerSlideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.2),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutQuart),
      ),
    );

    _contentFadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
      ),
    );
    _contentSlideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.3, 1.0, curve: Curves.easeOutQuart),
      ),
    );

    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _chatIdController.dispose();
    super.dispose();
  }

  // --- Helpers ---

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: isError ? Colors.red : const Color(0xFF138066),
        content: Text(message),
      ),
    );
  }

  Future<void> _openTelegramBot() async {
    final Uri url = Uri.parse("https://t.me/$botUsername");
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnackBar("Tidak bisa membuka Telegram", isError: true);
    }
  }

  // --- Main Logic (FIXED) ---

  void _activateProtection() async {
    if (!_formKey.currentState!.validate()) return;

    // Tampilkan Loading Dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final prefs = await SharedPreferences.getInstance();

      // Setup User ID
      String userId = prefs.getString('userId') ?? "";
      if (userId.isEmpty) {
        userId = "user_${DateTime.now().millisecondsSinceEpoch}";
        await prefs.setString('userId', userId);
      }

      // 1. Verifikasi ID Telegram (dengan timeout 10 detik)
      bool isValid = await HeartbeatService.verifyGuard(
        _chatIdController.text,
      ).timeout(const Duration(seconds: 10));

      if (!mounted) return;

      if (!isValid) {
        Navigator.pop(context); // Tutup loading
        _showSnackBar(
          "ID Telegram tidak ditemukan! Klik /start di bot.",
          isError: true,
        );
        return;
      }

      // 2. Jalankan proteksi (dengan timeout 10 detik)
      bool success = await HeartbeatService.startProtection(
        userId,
        _chatIdController.text,
        _nameController.text,
      ).timeout(const Duration(seconds: 10));

      if (success && mounted) {
        // 3. OPTIMASI: Jalankan updateToken di background (tanpa await)
        // Agar user tidak menunggu proses notifikasi yang seringkali lambat
        NotificationService().updateToken(userId).catchError((e) {
          print("FCM Token update failed in background: $e");
        });

        // 4. Tutup loading SEGERA sebelum navigasi
        Navigator.pop(context);

        _showSnackBar("Proteksi Aktif! ID tervalidasi.");

        // 5. Navigasi ke Dashboard
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            transitionDuration: const Duration(milliseconds: 800),
            pageBuilder:
                (context, animation, secondaryAnimation) =>
                    const GuardianHomeScreen(),
            transitionsBuilder: (
              context,
              animation,
              secondaryAnimation,
              child,
            ) {
              var fadeAnimation = Tween(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeIn),
              );
              var slideAnimation = Tween<Offset>(
                begin: const Offset(0, 0.1),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOut),
              );
              return SlideTransition(
                position: slideAnimation,
                child: FadeTransition(opacity: fadeAnimation, child: child),
              );
            },
          ),
        );
      } else {
        if (mounted) Navigator.pop(context);
        _showSnackBar("Gagal mengaktifkan proteksi. Coba lagi.", isError: true);
      }
    } catch (e) {
      if (mounted) Navigator.pop(context);
      _showSnackBar("Koneksi bermasalah atau server sibuk.", isError: true);
      print("Error: $e");
    }
  }

  // --- UI Layout ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SlideTransition(
              position: _headerSlideAnimation,
              child: FadeTransition(
                opacity: _headerFadeAnimation,
                child: _buildHeader(),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: FadeTransition(
                opacity: _contentFadeAnimation,
                child: SlideTransition(
                  position: _contentSlideAnimation,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle("Langkah 1: Koneksi"),
                        const SizedBox(height: 12),
                        _buildGuideCard(),
                        const SizedBox(height: 32),
                        _buildSectionTitle("Langkah 2: Data Penjamin"),
                        const SizedBox(height: 12),
                        _buildFormCard(),
                        const SizedBox(height: 40),
                        _buildActivateButton(),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        bottom: 30,
        left: 24,
        right: 24,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryDark),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
          Center(
            child: Column(
              children: [
                const SizedBox(height: 10),
                Hero(
                  tag: 'shield_icon',
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryDark.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.shield_rounded,
                      color: primaryDark,
                      size: 40,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  "Aktivasi Penjamin",
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Hubungkan akun Telegram Anda untuk\nmemulai proteksi real-time.",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 14,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.leagueSpartan(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primaryDark,
        letterSpacing: 0.5,
      ),
    );
  }

  Widget _buildGuideCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildStepTile("1", "Buka Bot Telegram Guardian"),
          _buildDivider(),
          _buildStepTile("2", "Klik 'START' di chat room"),
          _buildDivider(),
          _buildStepTile("3", "Salin dan tempel ID yang muncul"),
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _openTelegramBot,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF229ED9),
                  side: const BorderSide(color: Color(0xFF229ED9), width: 1),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  backgroundColor: const Color(0xFF229ED9).withOpacity(0.05),
                ),
                child: Text(
                  "Buka Telegram Bot",
                  style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepTile(String step, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: primaryLight.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              step,
              style: GoogleFonts.leagueSpartan(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: primaryDark,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.leagueSpartan(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      color: Colors.grey.withOpacity(0.05),
    );
  }

  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildCleanInput(
            _nameController,
            "Nama Panggilan",
            Icons.person_outline,
          ),
          const SizedBox(height: 20),
          _buildCleanInput(
            _chatIdController,
            "ID Telegram",
            Icons.vpn_key_outlined,
            isNumber: true,
          ),
        ],
      ),
    );
  }

  Widget _buildCleanInput(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.leagueSpartan(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: isNumber ? TextInputType.number : TextInputType.text,
            style: GoogleFonts.leagueSpartan(
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              prefixIcon: Icon(icon, color: Colors.grey[400], size: 20),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              hintText: isNumber ? "Contoh: 12345678" : "Nama Kamu",
              hintStyle: GoogleFonts.leagueSpartan(color: Colors.grey[300]),
            ),
            validator: (value) => value!.isEmpty ? "Wajib diisi" : null,
          ),
        ),
      ],
    );
  }

  Widget _buildActivateButton() {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [primaryLight, primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryDark.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _activateProtection,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(
          "Mulai Proteksi",
          style: GoogleFonts.leagueSpartan(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
