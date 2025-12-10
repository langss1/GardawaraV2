import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart'; // Nyalakan lagi ini

class ClassifierService {
  Interpreter? _interpreter;
  Map<String, int> _vocab = {};

  final int _sentenceLength = 30;
  int _vocabSize = 0;

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/models/model_safe.tflite',
      );
      await _loadDictionary();
      print("✅ AI Model Loaded (Siap mendeteksi)");
    } catch (e) {
      print("⚠️ Gagal load AI (Pindah ke Mode Manual): $e");
    }
  }

  Future<void> _loadDictionary() async {
    try {
      final vocabString = await rootBundle.loadString(
        'assets/models/vocab_safe.txt',
      );
      final lines = vocabString.split('\n');
      _vocab = {};
      for (var i = 0; i < lines.length; i++) {
        String word = lines[i].trim();
        if (word.isNotEmpty) _vocab[word] = i;
      }
      _vocabSize = lines.length;
    } catch (e) {
      print("Error vocab: $e");
    }
  }

  List<int> _tokenize(String text) {
    final cleanText = text.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '');
    final words = cleanText.split(' ');
    List<int> tokenized = List.filled(_sentenceLength, 0);

    for (var i = 0; i < words.length && i < _sentenceLength; i++) {
      String word = words[i];
      int index = 1;
      if (_vocab.containsKey(word)) index = _vocab[word]!;

      // Safety: Jika index di luar nalar, paksa 1
      if (index >= _vocabSize) index = 1;

      tokenized[i] = index;
    }
    return tokenized;
  }

  Future<bool> predict(String text) async {
    String lowerText = text.toLowerCase();

    if (lowerText.contains("slot") ||
        lowerText.contains("gacor") ||
        lowerText.contains("pragmatic") ||
        lowerText.contains("judi") ||
        lowerText.contains("bet88") ||
        lowerText.contains("zeus")) {
      print("🚨 JUDI TERDETEKSI (Keyword): $text");
      return true;
    }

    if (_interpreter != null) {
      try {
        List<int> inputIds = _tokenize(text);
        var input = [inputIds];
        var output = List.filled(1 * 1, 0.0).reshape([1, 1]);

        _interpreter!.run(input, output);
        double probability = output[0][0];

        if (probability > 0.5) {
          print(
            "🤖 JUDI TERDETEKSI (AI - ${(probability * 100).toStringAsFixed(1)}%): $text",
          );
          return true;
        }
      } catch (e) {
        // Jika AI error, abaikan saja (karena sudah lolos cek keyword)
        // print("⚠️ AI Error (Ignored): $e");
      }
    }

    return false;
  }
}
