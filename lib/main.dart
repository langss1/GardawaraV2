import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:gardawara_ai/common/services/notification_service.dart';
import 'screens/splash_screen.dart';
import 'common/services/heartbeat_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  print("Handling a background message: ${message.messageId}");
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // dotenv removed for security. Config via AppConfig.
  await HeartbeatService.initialize();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  // Panggil init SEGERA, tidak perlu nunggu userId dulu untuk navigasi
  await NotificationService().initNotification();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gardawara AI',

      navigatorKey: NotificationService.navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF138066)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
    );
  }
}
