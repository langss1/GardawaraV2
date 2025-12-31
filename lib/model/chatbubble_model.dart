import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:video_player/video_player.dart';

class ChatBubble extends StatelessWidget {
  final String message;
  final bool isBot;
  final String robotIconPath;
  final String? videoUrl; // Tambahkan parameter videoUrl

  const ChatBubble({
    super.key,
    required this.message,
    required this.isBot,
    required this.robotIconPath,
    this.videoUrl, // Inisialisasi videoUrl
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
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF00C6AE),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Image.asset(
                robotIconPath,
                width: 20,
                height: 20,
                errorBuilder:
                    (c, o, s) => const Icon(
                      Icons.smart_toy,
                      color: Colors.white,
                      size: 20,
                    ),
              ),
            ),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(isBot ? 5 : 20),
                  topRight: Radius.circular(isBot ? 20 : 5),
                  bottomLeft: const Radius.circular(20),
                  bottomRight: const Radius.circular(20),
                ),
                border: Border.all(color: Colors.black12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  MarkdownBody(
                    data: message,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Colors.black87,
                        fontSize: 14,
                        height: 1.4,
                      ),
                    ),
                  ),
                  // TAMPILKAN VIDEO JIKA ADA URL
                  if (videoUrl != null) ...[
                    const SizedBox(height: 10),
                    VideoStreamingWidget(url: videoUrl!),
                  ],
                ],
              ),
            ),
          ),
          if (!isBot) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Color(0xFF00E5C5),
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ],
        ],
      ),
    );
  }
}

// WIDGET KHUSUS VIDEO STREAMING
class VideoStreamingWidget extends StatefulWidget {
  final String url;
  const VideoStreamingWidget({super.key, required this.url});

  @override
  State<VideoStreamingWidget> createState() => _VideoStreamingWidgetState();
}

class _VideoStreamingWidgetState extends State<VideoStreamingWidget> {
  late VideoPlayerController _videoController;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _videoController = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        setState(() {
          _isInitialized = true;
        });
      });
  }

  @override
  void dispose() {
    _videoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const SizedBox(
        height: 150,
        child: Center(
          child: CircularProgressIndicator(color: Color(0xFF138066)),
        ),
      );
    }

    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: AspectRatio(
            aspectRatio: _videoController.value.aspectRatio,
            child: VideoPlayer(_videoController),
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(
                _videoController.value.isPlaying
                    ? Icons.pause_circle
                    : Icons.play_circle,
                color: const Color(0xFF138066),
                size: 30,
              ),
              onPressed: () {
                setState(() {
                  _videoController.value.isPlaying
                      ? _videoController.pause()
                      : _videoController.play();
                });
              },
            ),
          ],
        ),
      ],
    );
  }
}
