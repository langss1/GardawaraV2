import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class Milestone {
  final Duration duration;
  final String title;
  final String badgeId;
  final Color fireColor;

  const Milestone({
    required this.duration,
    required this.title,
    required this.badgeId,
    required this.fireColor,
  });
}

class GamificationService {
  static final GamificationService _instance = GamificationService._internal();
  factory GamificationService() => _instance;
  GamificationService._internal();

  static const String keyStartRehab = 'start_rehab_timestamp';
  static const String keyRelapseCount = 'relapse_count';

  // 21 Milestones Definition
  final List<Milestone> milestones = [
    // Phase 1: Ignition (Grey/White)
    Milestone(
      duration: Duration(minutes: 1),
      title: "Sadar Shift",
      badgeId: 'm1',
      fireColor: Colors.grey,
    ),
    Milestone(
      duration: Duration(hours: 1),
      title: "Niat Kuat",
      badgeId: 'h1',
      fireColor: Colors.grey.shade400,
    ),
    Milestone(
      duration: Duration(hours: 3),
      title: "No Depo",
      badgeId: 'h3',
      fireColor: Colors.grey.shade300,
    ),
    Milestone(
      duration: Duration(hours: 8),
      title: "Tidur Nyenyak",
      badgeId: 'h8',
      fireColor: Colors.white,
    ),
    Milestone(
      duration: Duration(hours: 12),
      title: "Fajar Harapan",
      badgeId: 'h12',
      fireColor: Colors.white,
    ),

    // Phase 2: Blue Flame (Blue)
    Milestone(
      duration: Duration(days: 1),
      title: "Anti Rungkad",
      badgeId: 'd1',
      fireColor: Colors.blueAccent,
    ),
    Milestone(
      duration: Duration(days: 2),
      title: "Pawang Nafsu",
      badgeId: 'd2',
      fireColor: Colors.blue,
    ),
    Milestone(
      duration: Duration(days: 3),
      title: "Survivor",
      badgeId: 'd3',
      fireColor: Colors.lightBlue,
    ),
    Milestone(
      duration: Duration(days: 7),
      title: "Minggu Waras",
      badgeId: 'd7',
      fireColor: Colors.cyan,
    ),

    // Phase 3: Green Flame (Green)
    Milestone(
      duration: Duration(days: 12),
      title: "Detox Awal",
      badgeId: 'd12',
      fireColor: Colors.teal,
    ),
    Milestone(
      duration: Duration(days: 14),
      title: "Master Fokus",
      badgeId: 'w2',
      fireColor: Colors.green,
    ),
    Milestone(
      duration: Duration(days: 21),
      title: "Habit Builder",
      badgeId: 'w3',
      fireColor: Colors.lightGreen,
    ),
    Milestone(
      duration: Duration(days: 30),
      title: "Bukan Hamba Slot",
      badgeId: 'm1_badge',
      fireColor: Colors.lime,
    ),

    // Phase 4: Purple/Neon (Purple)
    Milestone(
      duration: Duration(days: 45),
      title: "Mental Baja",
      badgeId: 'm1.5',
      fireColor: Colors.deepPurple,
    ),
    Milestone(
      duration: Duration(days: 60),
      title: "Anti Gacor",
      badgeId: 'm2',
      fireColor: Colors.purple,
    ),
    Milestone(
      duration: Duration(days: 90),
      title: "Investor Diri",
      badgeId: 'm3',
      fireColor: Colors.purpleAccent,
    ),
    Milestone(
      duration: Duration(days: 120),
      title: "Raja Kontrol",
      badgeId: 'm4',
      fireColor: Colors.indigo,
    ),

    // Phase 5: Gold/Legend (Gold/Red)
    Milestone(
      duration: Duration(days: 150),
      title: "Visionary",
      badgeId: 'm5',
      fireColor: Colors.amber,
    ),
    Milestone(
      duration: Duration(days: 180),
      title: "Sultan Waras",
      badgeId: 'm6',
      fireColor: Colors.orange,
    ),
    Milestone(
      duration: Duration(days: 240),
      title: "Grandmaster",
      badgeId: 'm8',
      fireColor: Colors.deepOrange,
    ),
    Milestone(
      duration: Duration(days: 365),
      title: "THE IMMORTAL",
      badgeId: 'y1',
      fireColor: Colors.redAccent,
    ),
  ];

  Future<void> initRehab() async {
    final prefs = await SharedPreferences.getInstance();
    if (!prefs.containsKey(keyStartRehab)) {
      // Start NOW
      await prefs.setInt(keyStartRehab, DateTime.now().millisecondsSinceEpoch);
    }
  }

  Future<void> resetStreak() async {
    final prefs = await SharedPreferences.getInstance();
    // Set start time to NOW (Reset)
    await prefs.setInt(keyStartRehab, DateTime.now().millisecondsSinceEpoch);

    // Increment relapse count
    int relapses = prefs.getInt(keyRelapseCount) ?? 0;
    await prefs.setInt(keyRelapseCount, relapses + 1);
  }

  Future<void> debugSetStartDate(Duration ago) async {
    final prefs = await SharedPreferences.getInstance();
    final targetDate = DateTime.now().subtract(ago);
    await prefs.setInt(keyStartRehab, targetDate.millisecondsSinceEpoch);
  }

  Future<Map<String, dynamic>> getProgress() async {
    final prefs = await SharedPreferences.getInstance();
    final startMillis = prefs.getInt(keyStartRehab);

    if (startMillis == null) {
      await initRehab();
      return getProgress();
    }

    final startDate = DateTime.fromMillisecondsSinceEpoch(startMillis);
    final now = DateTime.now();
    final difference = now.difference(startDate);

    // Find current milestone
    Milestone currentMilestone = milestones.first;
    Milestone? nextMilestone;

    for (int i = 0; i < milestones.length; i++) {
      if (difference >= milestones[i].duration) {
        currentMilestone = milestones[i];
        if (i + 1 < milestones.length) {
          nextMilestone = milestones[i + 1];
        } else {
          nextMilestone = null; // Max level
        }
      } else {
        // First milestone not met yet? (e.g. < 1 min)
        if (i == 0) {
          nextMilestone = milestones[0];
        }
        break;
      }
    }

    // Identify if user is absolutely new (<1 min)
    if (difference < milestones[0].duration) {
      currentMilestone = Milestone(
        duration: Duration.zero,
        title: "Memulai...",
        badgeId: 'start',
        fireColor: Colors.grey.withOpacity(0.5),
      );
      nextMilestone = milestones[0];
    }

    // Calculate progress percentage to next milestone
    double progress = 0.0;
    if (nextMilestone != null) {
      final totalDuration = nextMilestone.duration.inSeconds;
      final currentSeconds = difference.inSeconds;
      progress = (currentSeconds / totalDuration).clamp(0.0, 1.0);
    } else {
      progress = 1.0; // Maxed out
    }

    return {
      'streakDuration': difference,
      'currentMilestone': currentMilestone,
      'nextMilestone': nextMilestone,
      'progress': progress,
      'startDate': startDate,
    };
  }
}
