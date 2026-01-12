import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // remove if unused
import 'package:shared_preferences/shared_preferences.dart';
import 'package:gardawara_ai/common/app_config.dart';

import '../model/chatbot_model.dart';

class ChatController extends ChangeNotifier {
  // --- MULAI POLA SINGLETON ---
  static final ChatController _instance = ChatController._internal();
  factory ChatController() => _instance;
  ChatController._internal() {
    _loadHistoryAndInit();
  }
  // --- SELESAI POLA SINGLETON ---

  final String? _apiKey = AppConfig.geminiApiKey;
  late final GenerativeModel _model;
  late final ChatSession _chatSession;

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
      model: 'gemini-1.5-flash',
      apiKey: 'AIzaSyCzJJwVivJ5okbHHGfNdn8a-OTPBBvdHwI', // Hardcoded agar 100% terbaca
      systemInstruction: Content.text(
        """Kamu adalah Garda AI, asisten rehabilitasi digital yang menggunakan pendekatan Cognitive Behavioral Therapy (CBT) untuk membantu pengguna mengatasi kecanduan judi online.

PRINSIP UTAMA KAMU (CBT):
1. **Identifikasi Pikiran Distorsi:** Bantu user mengenali "Automatic Negative Thoughts" atau pembenaran irasional (misal: "Sekali lagi pasti menang", "Saya cuma butuh modal balik").
2. **Tantang Pikiran Tersebut (Cognitive Restructuring):** Ajak user mempertanyakan bukti nyata dari pikiran itu. Gunakan pertanyaan Sokratik (misal: "Apa bukti nyata kamu pasti menang kali ini?").
3. **Fokus pada Dampak Perilaku:** Hubungkan pikiran -> perasaan -> tindakan -> konsekuensi.
4. **Memberikan Coping Skill:** Berikan teknik praktis (distraksi, relaksasi pernapasan, menunda keinginan/urge surfing) daripada hanya melarang.
5. **Empati & Kolaboratif:** Jadilah pendengar yang tidak menghakimi, tapi tegas mengarahkan ke pemulihan.

GAYA KOMUNIKASI:
- Bahasa Indonesia santai namun profesional.
- Jangan menceramahi. Gunakan pertanyaan reflektif.
- Jika user curhat kalah judi, jangan cuma bilang "Sabar", tapi gali: "Apa yang kamu rasakan saat memutuskan deposit tadi? Apa yang kamu pikirkan saat itu?"

CONTOH RESPON CBT:
User: "Saya stres banget kalah 5 juta."
Bot: "Aku mengerti rasa stres dan kecewamu itu valid. Mari kita urai sedikit. Sebelum kamu deposit tadi, apa yang terlintas di pikiranmu? Apakah ada pikiran 'kali ini pasti menang'?"
""",
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
        ChatMessage(
          text: "Maaf, server sedang sibuk. Coba lagi nanti ya.",
          isBot: true,
        ),
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
