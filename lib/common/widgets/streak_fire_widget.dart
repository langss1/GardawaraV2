import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../common/services/gamification_service.dart';

class StreakFireWidget extends StatefulWidget {
  const StreakFireWidget({super.key});

  @override
  State<StreakFireWidget> createState() => _StreakFireWidgetState();
}

class _StreakFireWidgetState extends State<StreakFireWidget>
    with SingleTickerProviderStateMixin {
  late Future<Map<String, dynamic>> _progressFuture;
  late AnimationController _controller;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _progressFuture = GamificationService().getProgress();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      setState(() {
        _progressFuture = GamificationService().getProgress();
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _refreshTimer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    if (d.inDays > 0) return "${d.inDays} Hari";
    if (d.inHours > 0) return "${d.inHours} Jam";
    if (d.inMinutes > 0) return "${d.inMinutes} Menit";
    return "${d.inSeconds} Detik";
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _progressFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();

        final data = snapshot.data!;
        final Milestone currentMilestone = data['currentMilestone'];
        final Milestone? nextMilestone = data['nextMilestone'];
        final Duration streak = data['streakDuration'];
        final double progress = data['progress'];

        Color primaryColor = currentMilestone.fireColor;
        if (streak.inMinutes < 1) primaryColor = Colors.grey;

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withOpacity(0.15),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              const BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.05),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
            border: Border.all(color: Colors.grey.withOpacity(0.1), width: 1),
          ),
          child: Row(
            children: [
              // 1. ANIMATED FIRE (Horizontal Linear Fill Gradient)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return ShaderMask(
                    shaderCallback: (bounds) {
                      // Create dynamic variations
                      final Color dark =
                          Color.lerp(primaryColor, Colors.black, 0.3) ??
                          primaryColor;
                      final Color light =
                          Color.lerp(primaryColor, Colors.white, 0.5) ??
                          primaryColor;

                      return LinearGradient(
                        colors: [dark, primaryColor, light, primaryColor, dark],
                        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        transform: GradientRotation(_controller.value * 2 * pi),
                      ).createShader(bounds);
                    },
                    child: const Icon(
                      Icons.local_fire_department_rounded,
                      size: 58,
                      color: Colors.white,
                    ),
                  );
                },
              ),
              const SizedBox(width: 20),

              // 2. TEXT INFO
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Api Rehabilitasi",
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.grey[500],
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDuration(streak),
                      style: GoogleFonts.leagueSpartan(
                        color: Colors.black87,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Progress Bar
                    if (nextMilestone != null) ...[
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Stack(
                                children: [
                                  // Background
                                  Container(height: 8, color: Colors.grey[100]),
                                  // Animated Foreground
                                  LayoutBuilder(
                                    builder: (context, constraints) {
                                      final width =
                                          constraints.maxWidth * progress;
                                      if (width <= 0) return const SizedBox();
                                      return AnimatedBuilder(
                                        animation: _controller,
                                        builder: (context, child) {
                                          return Container(
                                            height: 8,
                                            width: width,
                                            decoration: BoxDecoration(
                                              gradient: LinearGradient(
                                                colors: [
                                                  primaryColor,
                                                  Color.lerp(
                                                    primaryColor,
                                                    Colors.white,
                                                    0.7,
                                                  )!, // Muda (Light)
                                                  primaryColor,
                                                ],
                                                stops: const [0.0, 0.5, 1.0],
                                                begin: Alignment(
                                                  -2.0 +
                                                      (4.0 * _controller.value),
                                                  0.0,
                                                ),
                                                end: Alignment(
                                                  -1.0 +
                                                      (4.0 * _controller.value),
                                                  0.0,
                                                ),
                                                tileMode: TileMode.clamp,
                                              ),
                                            ),
                                          );
                                        },
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${(progress * 100).toInt()}%",
                            style: GoogleFonts.leagueSpartan(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Next: ${nextMilestone.title}",
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.grey[400],
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ] else
                      Text(
                        "LEGENDARY STATUS",
                        style: GoogleFonts.leagueSpartan(
                          color: Colors.amber,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
