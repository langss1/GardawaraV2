class AppConfig {
  /// URL Backend API
  /// 
  /// SECURITY NOTE:
  /// Jangan simpan .env di dalam aset aplikasi (pubspec.yaml) karena mudah diekstrak.
  
  static const String apiUrl = String.fromEnvironment(
    'API_URL',
    defaultValue: 'https://api-judi-guard.onrender.com',
  );

  static const String geminiApiKey = String.fromEnvironment(
    'GEMINI_API_KEY',
    defaultValue: 'AIzaSyCzJJwVivJ5okbHHGfNdn8a-OTPBBvdHwI',
  );
}
