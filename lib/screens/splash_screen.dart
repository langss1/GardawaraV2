import 'dart:async';
import 'package:flutter/material.dart';
import 'package:gardawara_ai/common/services/notification_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import 'guardian_home_screen.dart';
import 'new_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late VideoPlayerController _controller;
  bool _isNavigating = false;
  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  void _initializeVideo() {
    // Menggunakan video loading asli untuk splash screen
    _controller =
        VideoPlayerController.asset("assets/video/loading_garda.mp4")
          ..initialize().then((_) {
            setState(() {});
            _controller.play();
          })
          ..addListener(_checkVideoEnd);
  }

  void _checkVideoEnd() {
    // Navigasi ketika video selesai dan belum navigasi
    if (_controller.value.isInitialized &&
        !_controller.value.isPlaying &&
        _controller.value.position >= _controller.value.duration &&
        !_isNavigating) {
      _navigateToNextScreen();
    }
  }

  Future<void> _navigateToNextScreen() async {
    if (_isNavigating) return;
    _isNavigating = true;

    // if (NotificationService.isHandlingNotification) {
    //   debugPrint("Navigasi dibatalkan karena ada notifikasi.");
    //   return;
    // }

    final prefs = await SharedPreferences.getInstance();
    bool isSetupDone = prefs.getBool('isProtected') ?? false;

    // ALUR BARU:
    // Jika sudah setup -> GuardianHomeScreen (New Main)
    // Jika belum setup -> NewScreen (Welcome) -> Setup
    Widget targetScreen =
        isSetupDone ? const GuardianHomeScreen() : const NewScreen();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 800),
          pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(0.0, 1.0); // From Bottom
            const end = Offset.zero;
            const curve = Curves.easeInOutQuart;

            var tween = Tween(
              begin: begin,
              end: end,
            ).chain(CurveTween(curve: curve));

            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
        ),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Centered Content (Mascot + Title)
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_controller.value.isInitialized)
                  SizedBox(
                    // Increased size to 95% of screen width to make mascot look bigger
                    width: MediaQuery.of(context).size.width * 0.95,
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: VideoPlayer(_controller),
                    ),
                  )
                else
                  SizedBox(
                    width: MediaQuery.of(context).size.width * 0.95,
                    height: MediaQuery.of(context).size.width * 0.95,
                  ),

                const SizedBox(height: 30),
                Text(
                  'Gardawara AI',
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.black,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
          ),

          // 2. Footer (Pinned to bottom)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Mendukung kampanye nasional lawan judi online',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.leagueSpartan(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1E1E1E),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Image.asset(
                  //   'assets/images/judi pasti rugi.png',
                  //   height: 40,
                  //   filterQuality: FilterQuality.high,
                  // ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
