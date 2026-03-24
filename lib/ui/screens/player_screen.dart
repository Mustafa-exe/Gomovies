import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../services/video_controller_factory.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    required this.title,
    required this.source,
    this.isLocal = false,
  });

  final String title;
  final String source;
  final bool isLocal;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _initPlayer();
  }

  Future<void> _initPlayer() async {
    try {
      final controller = createVideoController(
        source: widget.source,
        isLocal: widget.isLocal,
      );

      await controller.initialize();

      final chewie = ChewieController(
        videoPlayerController: controller,
        autoPlay: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        allowFullScreen: true,
      );

      if (!mounted) return;
      setState(() {
        _videoController = controller;
        _chewieController = chewie;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Center(
        child: _error != null
            ? Padding(
                padding: const EdgeInsets.all(16),
                child: Text('Playback failed: $_error'),
              )
            : _chewieController == null
                ? const CircularProgressIndicator()
                : AspectRatio(
                    aspectRatio: _videoController!.value.aspectRatio,
                    child: Chewie(controller: _chewieController!),
                  ),
      ),
    );
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }
}
