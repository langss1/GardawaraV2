import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

import '../controller/chatbot_controller.dart';

class GardaChatScreen extends StatefulWidget {
  final String? initialMessage;
  const GardaChatScreen({super.key, this.initialMessage});

  @override
  State<GardaChatScreen> createState() => _GardaChatScreenState();
}

class _GardaChatScreenState extends State<GardaChatScreen>
    with TickerProviderStateMixin {
  // SISTEM LAMA
  final ChatController _controller = ChatController();
  final String robotAssetPath = 'assets/images/hello_garda.png';

  // UI BARU: Animasi
  AnimationController? _entryController;

  final Color primaryDark = const Color(0xFF138066);
  final Color primaryLight = const Color(0xFF00E5C5);

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _entryController!.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _controller.notifyListeners();
        if (widget.initialMessage != null) {
          _controller.textController.text = widget.initialMessage!;
          _controller.sendMessage();
        }
      }
    });
  }

  @override
  void dispose() {
    _entryController?.dispose();
    super.dispose();
  }

  Widget _buildAnimatedItem({required int index, required Widget child}) {
    if (_entryController == null) return child;
    return AnimatedBuilder(
      animation: _entryController!,
      builder: (context, _) {
        final double delay = index * 100.0;
        final double start = (delay / 1000).clamp(0.0, 1.0);
        final double end = ((delay + 500) / 1000).clamp(0.0, 1.0);
        final animation = CurvedAnimation(
          parent: _entryController!,
          curve: Interval(start, end, curve: Curves.easeOut),
        );
        return Opacity(
          opacity: animation.value,
          child: Transform.translate(
            offset: Offset(0, 30 * (1 - animation.value)),
            child: child,
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, child) {
                if (_controller.messages.isEmpty) {
                  return _buildEmptyState();
                }
                return ListView.builder(
                  controller: _controller.scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
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
                    return _buildAnimatedItem(
                      index: index,
                      child: ChatBubble(
                        message: msg.text,
                        isBot: msg.isBot,
                        robotIconPath: robotAssetPath,
                        videoUrl:
                            msg.videoUrl, // Pakai videoUrl dari sistem lama
                      ),
                    );
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        left: 20,
        right: 20,
        bottom: 16,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: primaryDark, width: 2),
            ),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: primaryLight.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  robotAssetPath,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) =>
                          Icon(Icons.smart_toy, color: primaryDark, size: 30),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Garda AI",
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  "Asisten Psikologi Virtual",
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 13,
                    color: primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Image.asset(
              robotAssetPath,
              width: 80,
              height: 80,
              color: primaryDark.withOpacity(0.8),
              colorBlendMode: BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            "Mulai percakapan dengan Garda AI",
            style: GoogleFonts.leagueSpartan(
              fontSize: 16,
              color: Colors.grey[400],
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: TextField(
                  controller: _controller.textController,
                  style: GoogleFonts.leagueSpartan(),
                  decoration: InputDecoration(
                    hintText: "Ketik pesan...",
                    hintStyle: GoogleFonts.leagueSpartan(
                      color: Colors.grey[400],
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onSubmitted: (_) => _controller.sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _controller.sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryLight, primaryDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 16, bottom: 16),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: Colors.white,
            radius: 12,
            child: Image.asset(
              robotAssetPath,
              width: 20,
              height: 20,
              errorBuilder:
                  (_, __, ___) =>
                      Icon(Icons.smart_toy, size: 16, color: primaryDark),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 12,
                  height: 12,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFF138066),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "Garda AI sedang mengetik...",
                  style: GoogleFonts.leagueSpartan(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// --- BUBBLE CHAT ---
class ChatBubble extends StatelessWidget {
  final String message;
  final bool isBot;
  final String robotIconPath;
  final String? videoUrl; // Kembali ke videoUrl sistem lama

  const ChatBubble({
    super.key,
    required this.message,
    required this.isBot,
    required this.robotIconPath,
    this.videoUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (isBot) ...[
            Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF138066), width: 1.5),
              ),
              child: CircleAvatar(
                backgroundColor: Colors.white,
                radius: 14,
                child: ClipOval(
                  child: Image.asset(
                    robotIconPath,
                    width: 28,
                    height: 28,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: isBot ? Colors.white : const Color(0xFF138066),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomRight: Radius.circular(isBot ? 20 : 4),
                  bottomLeft: Radius.circular(isBot ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message,
                    styleSheet: MarkdownStyleSheet(
                      p: GoogleFonts.leagueSpartan(
                        color: isBot ? Colors.black87 : Colors.white,
                        fontSize: 15,
                        height: 1.4,
                      ),
                    ),
                  ),
                  // SISTEM LAMA: Pakai _VideoPreview
                  if (videoUrl != null && videoUrl!.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _VideoPreview(url: videoUrl!),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- WIDGET VIDEO LAMA (SISTEM LAMA) ---
class _VideoPreview extends StatefulWidget {
  final String url;
  const _VideoPreview({required this.url});

  @override
  State<_VideoPreview> createState() => _VideoPreviewState();
}

class _VideoPreviewState extends State<_VideoPreview> {
  late VideoPlayerController _vController;
  bool _isPlaying = false;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _vController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) => setState(() => _isInitialized = true));
  }

  @override
  void dispose() {
    _vController.dispose();
    super.dispose();
  }

  void _togglePlay() {
    setState(() {
      _vController.value.isPlaying ? _vController.pause() : _vController.play();
      _isPlaying = _vController.value.isPlaying;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized)
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF138066)),
        ),
      );
    return Container(
      width: 250,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          alignment: Alignment.center,
          children: [
            AspectRatio(
              aspectRatio: _vController.value.aspectRatio,
              child: VideoPlayer(_vController),
            ),
            GestureDetector(
              onTap: _togglePlay,
              child: Center(
                child: AnimatedOpacity(
                  opacity: _isPlaying ? 0.0 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.black45,
                      shape: BoxShape.circle,
                    ),
                    padding: const EdgeInsets.all(12),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  _vController.pause();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (context) => FullScreenVideoPlayer(url: widget.url),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.fullscreen_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- FULLSCREEN PLAYER LAMA ---
class FullScreenVideoPlayer extends StatefulWidget {
  final String url;
  const FullScreenVideoPlayer({super.key, required this.url});

  @override
  State<FullScreenVideoPlayer> createState() => _FullScreenVideoPlayerState();
}

class _FullScreenVideoPlayerState extends State<FullScreenVideoPlayer> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.portraitUp,
    ]);
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {});
        _controller.play();
      });
  }

  @override
  void dispose() {
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child:
            _controller.value.isInitialized
                ? AspectRatio(
                  aspectRatio: _controller.value.aspectRatio,
                  child: VideoPlayer(_controller),
                )
                : const CircularProgressIndicator(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pop(context),
        child: const Icon(Icons.close),
      ),
    );
  }
}
