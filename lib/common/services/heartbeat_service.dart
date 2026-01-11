import 'dart:convert';
import 'package:workmanager/workmanager.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:gardawara_ai/common/app_config.dart';

class HeartbeatService {
  static String get baseUrl => AppConfig.apiUrl;

  static Future<void> initialize() async {
    try {
      await Workmanager().initialize(callbackDispatcher, isInDebugMode: true);
    } catch (e) {
      print("Gagal Inisialisasi Heartbeat: $e");
    }
  }

  static Future<bool> verifyGuard(String chatId) async {
    if (baseUrl.isEmpty) return false;
    try {
      final response = await http
          .get(Uri.parse("$baseUrl/verify-guard/$chatId"))
          .timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['valid'] == true;
      }
      return false;
    } catch (e) {
      print("Verify Error: $e");
      return false;
    }
  }

  static Future<bool> startProtection(
    String uid,
    String chatId,
    String name,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      await prefs.setString('userId', uid);
      await prefs.setString('guardianChatId', chatId);
      await prefs.setString('userName', name);
      await prefs.setBool('isProtected', true);

      // --- PERBAIKAN DI SINI ---
      // Jangan gunakan 'await' agar UI tidak menunggu respon network
      _sendHeartbeatToServer(uid, chatId, name).catchError((e) {
        print("Heartbeat awal gagal tapi tetap lanjut: $e");
      });

      // Langsung daftar task background
      await Workmanager().registerPeriodicTask(
        "unique-heartbeat-id",
        "judiGuardHeartbeat",
        frequency: const Duration(minutes: 30),
        constraints: Constraints(networkType: NetworkType.connected),
        existingWorkPolicy: ExistingWorkPolicy.replace,
      );

      return true;
    } catch (e) {
      print("Error startProtection: $e");
      return false;
    }
  }

  static Future<void> _sendHeartbeatToServer(
    String uid,
    String chatId,
    String name,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse("$baseUrl/heartbeat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "userId": uid,
              "guardianChatId": chatId,
              "userName": name,
            }),
          )
          .timeout(const Duration(seconds: 10));
      print("Respon Awal Server: ${response.statusCode}");
    } catch (e) {
      print("Gagal kirim heartbeat awal: $e");
    }
  }
}

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    // Inisialisasi ulang environment di isolate background
    try {
      final String backgroundBaseUrl = AppConfig.apiUrl;

      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('userId');
      final guardianChatId = prefs.getString('guardianChatId');
      final userName = prefs.getString('userName');

      if (userId == null || backgroundBaseUrl.isEmpty)
        return Future.value(false);

      final response = await http
          .post(
            Uri.parse("$backgroundBaseUrl/heartbeat"),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode({
              "userId": userId,
              "guardianChatId": guardianChatId,
              "userName": userName,
            }),
          )
          .timeout(
            const Duration(seconds: 15),
          ); // Tambahkan timeout di background

      return Future.value(response.statusCode == 200);
    } catch (e) {
      print("Background Task Error: $e");
      return Future.value(false);
    }
  });
}
