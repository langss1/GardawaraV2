import 'dart:async';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:gardawara_ai/common/services/gamification_service.dart';
import 'package:google_fonts/google_fonts.dart';

class AchievementScreen extends StatefulWidget {
  const AchievementScreen({super.key});

  @override
  State<AchievementScreen> createState() => _AchievementScreenState();
}

class _AchievementScreenState extends State<AchievementScreen>
    with TickerProviderStateMixin {
  late Future<Map<String, dynamic>> _dataFuture;
  AnimationController? _animController;
  AnimationController? _entryController; // Made nullable
  final ScrollController _scrollController = ScrollController();
  bool _hasScrolled = false;

  @override
  void initState() {
    super.initState();
    _refreshData();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // Init Entry Controller safely
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _entryController?.forward();
  }

  void _refreshData() {
    setState(() {
      _dataFuture = GamificationService().getProgress();
    });
  }

  @override
  void dispose() {
    _animController?.dispose();
    _entryController?.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_animController == null) {
      _animController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 3),
      )..repeat();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          "Pencapaian Rehabilitasi",
          style: GoogleFonts.leagueSpartan(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        toolbarHeight: 90, // Spacious
        iconTheme: const IconThemeData(color: Colors.black87),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, size: 28),
            onPressed: _showGuidelineDialog,
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _dataFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = snapshot.data!;
          final Duration currentStreak = data['streakDuration'];
          final List<Milestone> milestones = GamificationService().milestones;

          // Auto Scroll Logic (Center the Active Card)
          int activeIndex = 0;
          for (int i = 0; i < milestones.length; i++) {
            if (currentStreak < milestones[i].duration) {
              if (i == 0 || currentStreak >= milestones[i - 1].duration) {
                activeIndex = i;
                break;
              }
            }
          }

          if (!_hasScrolled && activeIndex > 0) {
            _hasScrolled = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (_scrollController.hasClients) {
                final double screenHeight = MediaQuery.of(context).size.height;
                // Estimate items before active (avg 110px)
                final double itemTop = activeIndex * 110.0;
                // Calculate center position
                // Offset = ItemTop - (ScreenHeight/2) + (ItemHeight/2)
                // Active Item Height ~180px
                final double offset = itemTop - (screenHeight / 2) + 90;

                _scrollController.animateTo(
                  offset.clamp(0.0, _scrollController.position.maxScrollExtent),
                  duration: const Duration(
                    milliseconds: 1500,
                  ), // Slower animation "dari awal"
                  curve: Curves.easeInOutCubic,
                );
              }
            });
          }

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
            itemCount: milestones.length,
            itemBuilder: (context, index) {
              final milestone = milestones[index];
              final isPassed = currentStreak >= milestone.duration;

              bool isActive = false;
              if (!isPassed) {
                if (index == 0 ||
                    currentStreak >= milestones[index - 1].duration) {
                  isActive = true;
                }
              }
              // Immortal Logic
              bool isImmortal = (index == milestones.length - 1);

              return _buildAnimatedItem(
                index: index,
                child: _buildCard(milestone, isPassed, isActive, isImmortal),
              );
            },
          );
        },
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _showDevTools,
      //   backgroundColor: Colors.black87,
      //   child: const Icon(Icons.developer_mode, color: Colors.white),
      // ),
    );
  }

  // ... inside AchievementScreen class

  // Define Primary Green
  final Color _primaryGreen = const Color(0xFF138066);

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    // Safe init for Hot Reload
    if (_entryController == null) {
      _entryController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1000),
      );
      _entryController!.forward();
    }

    return AnimatedBuilder(
      animation: _entryController!,
      builder: (context, _) {
        final double delay = index * 100.0;
        final double start = (delay / 1000).clamp(0.0, 1.0);
        final double end = ((delay + 500) / 1000).clamp(0.0, 1.0);

        final animation = CurvedAnimation(
          parent: _entryController!,
          curve: Interval(start, end, curve: Curves.easeOut),
        );

        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }

  Widget _buildCard(
    Milestone milestone,
    bool isCompleted,
    bool isActive,
    bool isImmortal,
  ) {
    // 1. COMPLETED STAGE (GREEN)
    if (isCompleted) {
      if (isImmortal) return _buildImmortalCard(milestone, true);

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(
            0xFFE8F5E9,
          ), // Standard Light Green 50 (Green Lain)
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.green.shade200,
            width: 1.5,
          ), // Soft Green Border
          boxShadow: [
            BoxShadow(
              color: Colors.green.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: _primaryGreen,
              ), // Dark Green Icon (maintained)
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  milestone.title,
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.black87, // Black Text
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Selesai (${_formatDuration(milestone.duration)})",
                  style: GoogleFonts.leagueSpartan(
                    color: Colors.black54,
                    fontSize: 12,
                  ), // Grey Text
                ),
              ],
            ),
          ],
        ),
      );
    }

    // 2. ACTIVE STAGE (Green/Yellow Border Cycle)
    if (isActive && _animController != null) {
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 30, top: 8),
        child: CustomPaint(
          foregroundPainter: _SnakeBorderPainter(
            _animController!,
            color: Colors.green,
            secondaryColor: Colors.yellowAccent,
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              boxShadow: [
                BoxShadow(
                  color: Colors.green.withOpacity(0.2),
                  blurRadius: 15,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                AnimatedBuilder(
                  animation: _animController!,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        0,
                        -3 + (3 * sin(_animController!.value * 2 * pi)),
                      ),
                      child: Container(
                        height: 54,
                        width: 54,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(
                            0xFF138066,
                          ).withOpacity(0.1), // Dark Green bg
                        ),
                        child: const Icon(
                          Icons.directions_run_rounded,
                          color: Color(0xFF138066),
                          size: 28,
                        ), // Dark Green Icon
                      ),
                    );
                  },
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            "TARGET SAAT INI",
                            style: GoogleFonts.leagueSpartan(
                              color: Colors.black87, // Black Label
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          const Icon(
                            Icons.timelapse_rounded,
                            color: Colors.black54,
                            size: 16,
                          ), // Black/Grey Icon
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        milestone.title,
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.black87, // Black Title
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        "Capai dalam ${_formatDuration(milestone.duration)}",
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.black54,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ), // Grey Subtitle
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // 3. THE IMMORTAL
    if (isImmortal) {
      return _buildImmortalCard(milestone, false);
    }

    // 4. LOCKED STAGE (Default)
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.lock_rounded, color: Colors.grey[400]),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                milestone.title,
                style: GoogleFonts.leagueSpartan(
                  color: Colors.grey[400],
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _formatDuration(milestone.duration),
                style: GoogleFonts.leagueSpartan(
                  color: Colors.grey[400],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showGuidelineDialog() {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Tutup",
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: FadeTransition(
              // Face Animation
              opacity: anim1,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.85,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF138066).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Color(0xFF138066),
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Cara Kerja",
                      style: GoogleFonts.leagueSpartan(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildGuideItem(
                      "🔥",
                      "Api Streak",
                      "Api menandakan durasi.",
                    ),
                    const SizedBox(height: 16),
                    _buildGuideItem(
                      "🟢",
                      "Stage Selesai",
                      "Kartu hijau berarti tuntas.",
                    ),
                    const SizedBox(height: 16),
                    _buildGuideItem(
                      "🏃",
                      "Target Saat Ini",
                      "Kejar target yang sedang berjalan!",
                    ),
                    const SizedBox(height: 16),
                    _buildGuideItem(
                      "⚠️",
                      "Reset",
                      "Konten judi mereset streak.",
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF138066),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          "Paham",
                          style: GoogleFonts.leagueSpartan(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  // IMMORTAL CARD LOGIC
  Widget _buildImmortalCard(Milestone milestone, bool unlocked) {
    if (_animController == null) return const SizedBox();

    if (unlocked) {
      // COMPLETED (GOLD)
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFF8C00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.orange.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.emoji_events_rounded,
              color: Colors.white,
              size: 36,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    milestone.title,
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  Text(
                    "SANG LEGENDA (Final)",
                    style: GoogleFonts.leagueSpartan(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // PENDING (GREY BODY + ANIMATED COLORFUL BORDER)
      return Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 16),
        child: CustomPaint(
          foregroundPainter: _SnakeBorderPainter(
            _animController!,
            color: Colors.orange,
            secondaryColor: Colors.amberAccent,
          ),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[100], // GREY BODY
              borderRadius: BorderRadius.circular(23),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.emoji_events_rounded,
                  color: Colors.grey,
                  size: 36,
                ), // Grey Trophy
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        milestone.title,
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.grey[400], // GREY TEXT
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                      Text(
                        "Locked (Legenda)",
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.grey[400],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  // ... Guide and Update methods ...

  Widget _buildGuideItem(String icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.leagueSpartan(fontWeight: FontWeight.bold),
              ),
              Text(
                desc,
                style: GoogleFonts.leagueSpartan(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showDevTools() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text("Developer Tools"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  title: const Text("Reset to 0"),
                  onTap: () => _updateTime(Duration.zero),
                ),
                ListTile(
                  title: const Text("Set 1 Minggu"),
                  onTap: () => _updateTime(const Duration(days: 7, minutes: 5)),
                ),
                ListTile(
                  title: const Text("Set 1 BULAN"),
                  onTap:
                      () => _updateTime(const Duration(days: 30, minutes: 5)),
                ),
                ListTile(
                  title: const Text("Set 1 Tahun (Legenda)"),
                  onTap: () => _updateTime(const Duration(days: 366)),
                ),
              ],
            ),
          ),
    );
  }

  void _updateTime(Duration d) async {
    Navigator.pop(context);
    await GamificationService().debugSetStartDate(d);
    _refreshData();
  }

  String _formatDuration(Duration d) {
    if (d.inDays >= 365) return "${(d.inDays / 365).toStringAsFixed(1)} Thn";
    if (d.inDays >= 30) return "${(d.inDays / 30).toStringAsFixed(1)} Bln";
    if (d.inDays > 0) return "${d.inDays} Hari";
    if (d.inHours > 0) return "${d.inHours} Jam";
    return "${d.inMinutes} Mnt";
  }
}

class _SnakeBorderPainter extends CustomPainter {
  final Animation<double> animation;
  final Color color;
  final Color secondaryColor;

  _SnakeBorderPainter(
    this.animation, {
    this.color = Colors.green,
    this.secondaryColor = Colors.white,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(23),
    );

    final paint =
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3
          ..shader = SweepGradient(
            colors: [
              Colors.transparent,
              color,
              secondaryColor, // Cycle Secondary (Yellow/Amber)
              color,
              Colors.transparent,
            ],
            stops: const [0.0, 0.4, 0.5, 0.6, 1.0],
            transform: GradientRotation(animation.value * 2 * pi),
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(covariant _SnakeBorderPainter oldDelegate) => true;
}
