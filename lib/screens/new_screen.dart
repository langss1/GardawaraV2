import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'setup_screen.dart';
import 'user_screen.dart';

// ... (existing imports)

class NewScreen extends StatefulWidget {
  const NewScreen({super.key});

  @override
  State<NewScreen> createState() => _NewScreenState();
}

class _NewScreenState extends State<NewScreen>
    with SingleTickerProviderStateMixin {
  late VideoPlayerController _videoController;
  late AnimationController _animationController;
  bool _isInitialized = false;

  // Colors based on SetupScreen palette
  final Color primaryDark = const Color(0xFF138066);
  final Color primaryLight = const Color(0xFF00E5C5);

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  void _initializeVideo() {
    _videoController = VideoPlayerController.asset("assets/video/welcome.mp4")
      ..initialize().then((_) {
        _videoController.setLooping(true);
        _videoController.play();
        setState(() {
          _isInitialized = true;
          _animationController.forward(); // Start animation after video loads
        });
      });
  }

  @override
  void dispose() {
    if (_isInitialized) {
      _videoController.dispose();
    }
    _animationController.dispose();
    super.dispose();
  }

  void _navigateToSetup() {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 600),
        pageBuilder:
            (context, animation, secondaryAnimation) => const SetupScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          var curve = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutQuart,
          );
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.0, 0.1),
              end: Offset.zero,
            ).animate(curve),
            child: FadeTransition(opacity: curve, child: child),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Dapatkan tinggi layar
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // 1. Header Video - Increased Size
                    if (_isInitialized)
                      _buildAnimatedWidget(
                        delay: 0,
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(
                              // Increased max height significantly as requested
                              maxHeight: isSmallScreen ? 250 : 350,
                              maxWidth: isSmallScreen ? 250 : 350,
                            ),
                            child: AspectRatio(
                              aspectRatio: _videoController.value.aspectRatio,
                              child: VideoPlayer(_videoController),
                            ),
                          ),
                        ),
                      )
                    else
                      SizedBox(height: isSmallScreen ? 250 : 350),

                    // 2. Branding Text
                    _buildAnimatedWidget(
                      delay: 200,
                      child: Column(
                        children: [
                          Text(
                            'Gardawara AI',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: isSmallScreen ? 32 : 40,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF1E1E1E),
                              height: 1.1,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'Bagaimana Gardawara melindungi anda?',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.leagueSpartan(
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[700],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 3. Feature Cards (Refined Design)
                    Column(
                      children: [
                        _buildAnimatedWidget(
                          delay: 400,
                          child: _buildFeatureCard(
                            icon: Icons.shield,
                            title: 'Proteksi Maksimal',
                            subtitle: 'Blokir akses judi online otomatis',
                            isSmall: isSmallScreen,
                            cardColor: Colors.white,
                            iconColor: const Color(0xFF22C55E),
                            borderColor: const Color(0xFF22C55E),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        _buildAnimatedWidget(
                          delay: 500,
                          child: _buildFeatureCard(
                            icon: Icons.family_restroom,
                            title: 'Kontrol Keluarga',
                            subtitle:
                                'Pantau aktivitas digital orang tersayang',
                            isSmall: isSmallScreen,
                            cardColor: Colors.white,
                            iconColor: const Color(0xFF22C55E),
                            borderColor: const Color(0xFF22C55E),
                          ),
                        ),
                        SizedBox(height: isSmallScreen ? 10 : 12),
                        _buildAnimatedWidget(
                          delay: 600,
                          child: _buildFeatureCard(
                            icon: Icons.verified_user,
                            title: 'Privasi Terjamin',
                            subtitle: 'Data pengguna aman dan terenkripsi',
                            isSmall: isSmallScreen,
                            cardColor: Colors.white,
                            iconColor: const Color(0xFF22C55E),
                            borderColor: const Color(0xFF22C55E),
                          ),
                        ),
                      ],
                    ),

                    // 4. Action Button & Terms
                    _buildAnimatedWidget(
                      delay: 800,
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            height: 55,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryDark.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              gradient: LinearGradient(
                                colors: [
                                  const Color(0xFF4ADE80),
                                  const Color(0xFF22C55E),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                            ),
                            child: ElevatedButton(
                              onPressed: _navigateToSetup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: Text(
                                'Mulai Sekarang',
                                style: GoogleFonts.leagueSpartan(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            'Dengan melanjutkan, Anda menyetujui syarat kami',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.leagueSpartan(
                              fontSize: 10,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // 5. Footer Logo
                    _buildAnimatedWidget(
                      delay: 1000,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          children: [
                            Text(
                              'Mendukung kampanye nasional lawan judi online',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.leagueSpartan(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            SizedBox(height: isSmallScreen ? 4 : 8),
                            // Image.asset(
                            //   'assets/images/judi pasti rugi.png',
                            //   height: isSmallScreen ? 30 : 40,
                            //   filterQuality: FilterQuality.high,
                            // ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedWidget({required Widget child, required int delay}) {
    // Simple staggered fade and slide animation
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.2), // Start slightly below
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _animationController,
          curve: Interval(
            delay /
                1500, // Normalize start time based on total duration + buffer
            (delay + 500) / 1500 > 1.0 ? 1.0 : (delay + 500) / 1500,
            curve: Curves.easeOutQuart,
          ),
        ),
      ),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Interval(
              delay / 1500,
              (delay + 500) / 1500 > 1.0 ? 1.0 : (delay + 500) / 1500,
              curve: Curves.easeOut,
            ),
          ),
        ),
        child: child,
      ),
    );
  }

  Widget _buildFeatureCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSmall,
    required Color cardColor,
    required Color iconColor,
    Color? borderColor,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        vertical: isSmall ? 12 : 16,
        horizontal: 16,
      ),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor ?? iconColor.withOpacity(0.1),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: isSmall ? 20 : 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: isSmall ? 13 : 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.leagueSpartan(
                    fontSize: isSmall ? 10 : 11,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
