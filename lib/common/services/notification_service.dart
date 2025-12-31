import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../controller/chatbot_controller.dart';
import '../../screens/chatbot_screen.dart';

class NotificationService {
  static bool isHandlingNotification = false; // Flag untuk Splash Screen

  // Buat singleton agar bisa diakses dimana saja
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  static final GlobalKey<NavigatorState> navigatorKey =
      GlobalKey<NavigatorState>();

  Future<void> initNotification() async {
    NotificationSettings settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Izin notifikasi diberikan');
    }

    // 1. Cek notifikasi yang bikin aplikasi kebuka dari mati total (Terminated)
    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }

    // 2. Listen notifikasi saat aplikasi di background (tapi tidak mati)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });
  }

  void _handleNavigation(RemoteMessage message) {
    if (message.data['screen'] == 'chatbot') {
      isHandlingNotification = true; // Kunci Splash Screen!

      // Segera proses datanya ke Controller
      // Gunakan Future.microtask agar jalan secepat mungkin
      Future.microtask(() async {
        await ChatController().addMessageFromNotification(message.data);
        
        // Pindah ke layar chat
        navigatorKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const GardaChatScreen()),
          (route) => route.isFirst,
        );
      });
    }
  }

  // Fungsi terpisah untuk simpan token (panggil saat login/setup selesai)
  Future<void> updateToken(String userId) async {
    try {
      String? token = await _fcm.getToken();
      if (token != null) {
        await _db.collection("users").doc(userId).set({
          "fcmToken": token,
          "lastTokenUpdate": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        print("Token FCM berhasil disimpan: $token");
      }
    } catch (e) {
      print("Gagal simpan token: $e");
    }
  }
}
