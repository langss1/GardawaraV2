import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

class ClassifierService {
  static const platform = MethodChannel(
    'com.example.gardawara_ai/accessibility',
  );
  Interpreter? _interpreter;
  Map<String, int> _vocab = {};
  final int _sentenceLength = 30;
  final int _vocabSize = 1050; // Sesuai hasil Netron kamu

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_safe.tflite',
      );
      await _loadDictionary();
      print("✅ AI Model Loaded (Vocab Size: $_vocabSize)");
    } catch (e) {
      print("⚠️ Gagal load AI: $e");
    }
  }

  Future<void> _loadDictionary() async {
    final vocabString = await rootBundle.loadString(
      'assets/models/vocab_safe.txt',
    );
    final lines = vocabString.split('\n');
    _vocab = {};
    for (var i = 0; i < lines.length; i++) {
      String word = lines[i].trim();
      if (word.isNotEmpty) _vocab[word] = i;
    }
  }

  Future<bool> predict(String text) async {
    String cleanText = text.toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

    // 1. Cek Keyword (Main Thread - Instan & Ganas)
    // HANYA BLOKIR FRASA JELAS. Kata tunggal (hoki, zeus) diserahkan ke AI.
    final blacklist = [
      "situs judi",
      "judi online",
      "bandar slot",
      "slot gacor", // Frasa 2 kata aman
      "agen bola",
      "zeus slot",  // Frasa 2 kata aman
      "mahjong ways",
      "pragmatic play",
      "link alternatif",
      "rtp live",
    ];
    for (var phrase in blacklist) {
      if (cleanText.contains(phrase)) {
        _aksiBlokirGanas();
        return true;
      }
    }

    // 2. AI Inference (Background Thread)
    if (_interpreter != null && cleanText.length > 3) {
      try {
        // Ambil token untuk akses root isolate dari background
        RootIsolateToken rootToken = RootIsolateToken.instance!;

        final isJudi = await compute(_runInferenceInIsolate, {
          'token': rootToken,
          'text': cleanText,
          'vocab': _vocab,
          'vocabSize': _vocabSize,
          'sentenceLength': _sentenceLength,
        });

        if (isJudi) {
          _aksiBlokirGanas();
        }
        return isJudi;
      } catch (e) {
        // Error di isolate tidak akan menghentikan aplikasi utama
      }
    }
    return false;
  }

  void _aksiBlokirGanas() async {
    print("🚨 AI Mendeteksi Judi: Mengirim perintah blokir ke Native...");
    try {
      await platform.invokeMethod('triggerNativeBlock');
    } on PlatformException catch (e) {
      print("Gagal lapor ke Native: ${e.message}");
    }
  }
}

// FUNGSI TOP-LEVEL (Harus di luar class agar compute bekerja)
Future<bool> _runInferenceInIsolate(Map<String, dynamic> params) async {
  // Inisialisasi komunikasi ke Root Isolate untuk akses Asset
  BackgroundIsolateBinaryMessenger.ensureInitialized(params['token']);

  final String text = params['text'];
  final Map<String, int> vocab = params['vocab'];
  final int vocabSize = params['vocabSize'];
  final int sentenceLength = params['sentenceLength'];

  try {
    // Load model di dalam Isolate
    final interpreter = await Interpreter.fromAsset(
      'assets/models/model_safe.tflite',
    );

    // Tokenisasi
    final words = text
        .toLowerCase()
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .split(' ');
    List<int> inputIds = List.filled(sentenceLength, 0);

    for (var i = 0; i < words.length && i < sentenceLength; i++) {
      int index = vocab[words[i]] ?? 1;
      if (index >= vocabSize) index = 1; // Proteksi index out of bounds
      inputIds[i] = index;
    }

    var input = [inputIds];
    var output = List.filled(1 * 1, 0.0).reshape([1, 1]);
    interpreter.run(input, output);

    double probability = output[0][0];
    interpreter.close();

    return probability > 0.45;
  } catch (e) {
    return false;
  }
}
