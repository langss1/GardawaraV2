import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../controller/chatbot_controller.dart';

class NotificationService {
  static bool isHandlingNotification = false;

  static final ValueNotifier<int?> tabNotifier = ValueNotifier<int?>(null);
  static int? pendingTabIndex;

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

    RemoteMessage? initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      _handleNavigation(initialMessage);
    }

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      _handleNavigation(message);
    });
  }

  void _handleNavigation(RemoteMessage message) {
    if (message.data['screen'] == 'chatbot') {
      // UBAH KE 3: Sesuai dengan index chatbot di GuardianHomeScreen
      pendingTabIndex = 3;
      tabNotifier.value =
          3; // TAMBAHKAN INI: Trigger perubahan tab secara realtime

      Future.microtask(() async {
        await ChatController().addMessageFromNotification(message.data);
      });
    }
  }

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
