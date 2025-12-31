import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import '../model/chatbot_model.dart';

class ChatController extends ChangeNotifier {
  // --- MULAI POLA SINGLETON ---
  static final ChatController _instance = ChatController._internal();
  factory ChatController() => _instance;
  ChatController._internal() {
    _loadHistoryAndInit();
  }
  // --- SELESAI POLA SINGLETON ---

  final String? _apiKey = dotenv.env['GEMINI_API_KEY'];
  late final GenerativeModel _model;
  late final ChatSession _chatSession;
  final String _backendUrl = dotenv.env['API_URL'] ?? "";

  List<ChatMessage> messages = [];
  bool isTyping = false;
  final ScrollController scrollController = ScrollController();
  final TextEditingController textController = TextEditingController();

  final Completer<void> _initCompleter = Completer<void>();
  Future<void> get initializationDone => _initCompleter.future;

  Future<void> _loadHistoryAndInit() async {
    if (_initCompleter.isCompleted) return; // Mencegah load ganda

    try {
      final prefs = await SharedPreferences.getInstance();
      final List<String>? savedChats = prefs.getStringList('chat_history');

      List<ChatMessage> loadedMessages = [];
      if (savedChats != null && savedChats.isNotEmpty) {
        loadedMessages =
            savedChats.map((e) => ChatMessage.fromJson(e)).toList();
      } else {
        loadedMessages = [
          ChatMessage(
            text:
                "Halo 👋 saya Garda AI! Saya bantu kamu menjaga diri dari paparan situs dan aplikasi judi.",
            isBot: true,
          ),
        ];
      }
      messages = [...loadedMessages, ...messages];
      _initGemini();
    } finally {
      if (!_initCompleter.isCompleted) _initCompleter.complete();
      notifyListeners();
      _scrollToBottom();
    }
  }

  // Fungsi untuk menambah pesan dari notifikasi
  Future<void> addMessageFromNotification(Map<String, dynamic> data) async {
    // JANGAN nunggu initializationDone di sini untuk push data pertama kali
    // agar data langsung masuk ke list 'messages' sebelum history selesai
    
    final String content = data['content'] ?? data['body'] ?? "Pesan baru";
    final String type = data['type'] ?? "text";
    final String? url = data['url'];

    // Cek duplikasi
    if (messages.any((m) => m.text == content)) return;

    final botMsg = ChatMessage(
      text: content,
      isBot: true,
      videoUrl: type == 'video' ? url : null,
    );

    messages.add(botMsg);
    notifyListeners();

    // Simpan ke memori HP (tunggu history beres dulu sebelum save ke disk)
    await initializationDone;
    await _saveMessages();
  }

  void _initGemini() {
    _model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: _apiKey!,
      systemInstruction: Content.text(
        "Kamu adalah Garda AI, seorang asisten psikologi digital yang empatik, sabar, dan profesional. "
        "Tugas utamamu adalah membantu pengguna yang kecanduan judi online (judol). "
        "Gunakan bahasa Indonesia yang santai dan suportif.",
      ),
    );

    // Filter history agar hanya teks yang dikirim ke Gemini (Gemini tidak bisa baca video url mentah)
    final history =
        messages.map((m) {
          return Content(m.isBot ? 'model' : 'user', [TextPart(m.text)]);
        }).toList();

    _chatSession = _model.startChat(history: history);
  }

  Future<void> sendMessage() async {
    final text = textController.text.trim();
    if (text.isEmpty) return;

    messages.add(ChatMessage(text: text, isBot: false));
    _saveMessages();

    textController.clear();
    isTyping = true;
    notifyListeners();
    _scrollToBottom();

    try {
      final response = await _chatSession.sendMessage(Content.text(text));
      final botReply =
          response.text ?? "Maaf, saya sedang mengalami gangguan jaringan.";

      messages.add(ChatMessage(text: botReply, isBot: true));
      _saveMessages();
    } catch (e) {
      messages.add(
        ChatMessage(text: "Terjadi kesalahan koneksi: $e", isBot: true),
      );
    } finally {
      isTyping = false;
      notifyListeners();
      _scrollToBottom();
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String> jsonList = messages.map((e) => e.toJson()).toList();
    await prefs.setStringList('chat_history', jsonList);
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (scrollController.hasClients) {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    scrollController.dispose();
    textController.dispose();
    super.dispose();
  }
}
