import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class HistoryService {
  static String get baseUrl => dotenv.env['API_URL'] ?? "";

  static DateTime? _lastSyncTime;
  static const _syncInterval = Duration(seconds: 15);

  static List<Map<String, String>> _latestBlockedHistory = [];

  static bool _hasUnsyncedChanges = false;

  static bool _isSyncing = false;

  static Timer? _flushTimer;

  static Future<bool> syncHistoryToServer(
    List<Map<String, String>> blockedHistory,
  ) async {
    _latestBlockedHistory = List<Map<String, String>>.from(blockedHistory);
    _hasUnsyncedChanges = true;

    print(
      "🛡️ History: Buffer updated. Total items: ${_latestBlockedHistory.length}",
    );

    if (_isSyncing) {
      print("⏳ History: Sync sedang berjalan. Data antre.");
      return true;
    }

    final now = DateTime.now();
    final canSyncImmediately =
        _lastSyncTime == null ||
        now.difference(_lastSyncTime!) >= _syncInterval;

    if (canSyncImmediately) {
      return _flushBuffer();
    } else {
      print("⏳ History: Throttled. Menunggu jadwal flush berikutnya...");
      _ensureFlushScheduled();
      return true;
    }
  }

  static void _ensureFlushScheduled() {
    if (_flushTimer != null && _flushTimer!.isActive) return;

    // Hitung sisa waktu tunggu
    final now = DateTime.now();
    final timeSinceLast =
        _lastSyncTime != null
            ? now.difference(_lastSyncTime!)
            : _syncInterval; // kalau null, harusnya bisa langsung, tapi fallback logic

    final waitDuration =
        timeSinceLast < _syncInterval
            ? _syncInterval - timeSinceLast
            : const Duration(seconds: 1); // fallback aman

    _flushTimer = Timer(waitDuration, () {
      _flushBuffer();
    });
  }

  static Future<bool> _flushBuffer() async {
    if (!_hasUnsyncedChanges) return true; // Tidak ada yang perlu dikirim
    if (_isSyncing) return false;

    _isSyncing = true;

    try {
      final prefs = await SharedPreferences.getInstance();

      String? userId = prefs.getString('userId');
      String? guardianChatId = prefs.getString('guardianChatId');

      if (userId == null) {
        print("❌ History: UserId null, membatalkan sync.");
        _isSyncing = false;
        return false;
      }

      // Recover Guardian ID jika hilang
      if (guardianChatId == null || guardianChatId.isEmpty) {
        print("🛡️ History: Guardian ID kosong, mencoba recover...");
        guardianChatId = await _recoverGuardianId(userId);

        if (guardianChatId != null) {
          await prefs.setString('guardianChatId', guardianChatId);
        }
      }

      // Ambil snapshot data yang akan dikirim
      final payloadToSend = List<Map<String, String>>.from(
        _latestBlockedHistory,
      );

      // Optimistic clear: Anggap akan berhasil.
      // Jika selama await ada data baru, flag ini akan diset true lagi oleh syncHistoryToServer.
      _hasUnsyncedChanges = false;

      print("🚀 History: Mengirim ${payloadToSend.length} item ke server...");

      final response = await http
          .post(
            Uri.parse('$baseUrl/update-history'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'userId': userId,
              'guardianChatId': guardianChatId,
              'blockedHistory': payloadToSend,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        _lastSyncTime = DateTime.now();
        print("✅ Sinkronisasi Berhasil: $userId");
      } else {
        print("⚠️ Sinkronisasi Gagal: ${response.statusCode}");
        _hasUnsyncedChanges = true; // Restore dirty state agar dikirim ulang
        _ensureFlushScheduled();
        _isSyncing = false;
        return false;
      }

      _isSyncing = false;

      // Jika selama sync ada data baru masuk (flag kembali true), schedule ulang
      if (_hasUnsyncedChanges) {
        _ensureFlushScheduled();
      }

      return true;
    } catch (e) {
      print("❌ Error History Service: $e");
      _hasUnsyncedChanges = true; // Restore dirty state
      _isSyncing = false;
      _ensureFlushScheduled();
      return false;
    }
  }

  static Future<String?> _recoverGuardianId(String userId) async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/user-status/$userId'))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['guardianChatId']?.toString();
      }
    } catch (e) {
      print("Gagal recover ID: $e");
    }
    return null;
  }
}
