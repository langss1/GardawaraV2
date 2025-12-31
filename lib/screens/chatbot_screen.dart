import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:gardawara_ai/model/chatbubble_model.dart';
import 'package:video_player/video_player.dart'; // Tambahkan ini
import '../controller/chatbot_controller.dart';

class GardaChatScreen extends StatefulWidget {
  // Kita tidak butuh notificationContent lagi di sini jika menggunakan Singleton
  const GardaChatScreen({super.key});

  @override
  State<GardaChatScreen> createState() => _GardaChatScreenState();
}

class _GardaChatScreenState extends State<GardaChatScreen> {
  // Mengambil instance singleton yang sama dengan yang dipanggil di NotificationService
  final ChatController _controller = ChatController();
  final String robotAssetPath = 'assets/images/robot.png';

  @override
  void initState() {
    super.initState();

    // Memastikan UI melakukan scroll ke bawah dan refresh saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    // Karena _controller adalah Singleton, sebaiknya jangan di-dispose di sini
    // agar datanya tidak hilang saat pindah screen.
    // Cukup hapus _controller.dispose() jika itu Singleton.
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF2F2F2), Color(0xFFD8EBE5)],
          ),
        ),
        child: Column(
          children: [
            _buildHeader(context),
            Expanded(
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, child) {
                  return ListView.builder(
                    controller: _controller.scrollController,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount:
                        _controller.messages.length +
                        (_controller.isTyping ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (index == _controller.messages.length &&
                          _controller.isTyping) {
                        return _buildTypingIndicator();
                      }

                      final msg = _controller.messages[index];
                      return ChatBubble(
                        message: msg.text,
                        isBot: msg.isBot,
                        robotIconPath: robotAssetPath,
                        videoUrl: msg.videoUrl,
                      );
                    },
                  );
                },
              ),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 5,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _controller.textController,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: "Ceritakan masalahmu...",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (_) => _controller.sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => _controller.sendMessage(),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF138066),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send, color: Colors.white, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 10,
        left: 20,
        right: 20,
        bottom: 20,
      ),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF00E5C5), Color(0xFF138066)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Image.asset(
              robotAssetPath,
              width: 30,
              height: 30,
              errorBuilder:
                  (c, o, s) => const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 30,
                  ),
            ),
          ),
          const SizedBox(width: 15),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "GARDA AI",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
              Text(
                "Psikolog Virtual",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: const Color(0xFF00C6AE),
            radius: 16,
            child: Image.asset(
              robotAssetPath,
              width: 20,
              height: 20,
              errorBuilder:
                  (c, o, s) => const Icon(
                    Icons.smart_toy,
                    color: Colors.white,
                    size: 16,
                  ),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(5),
                topRight: Radius.circular(20),
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _dot(Colors.grey[400]!),
                const SizedBox(width: 4),
                _dot(Colors.grey[400]!),
                const SizedBox(width: 4),
                _dot(Colors.grey[400]!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) => Container(
    width: 8,
    height: 8,
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );
}
