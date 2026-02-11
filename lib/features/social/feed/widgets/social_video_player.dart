import 'package:flutter/material.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';

class SocialVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;

  const SocialVideoPlayer({
    super.key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
  });

  @override
  State<SocialVideoPlayer> createState() => _SocialVideoPlayerState();
}

class _SocialVideoPlayerState extends State<SocialVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    if (widget.videoUrl.startsWith('http')) {
      _videoPlayerController = VideoPlayerController.networkUrl(
        Uri.parse(widget.videoUrl),
      );
    } else {
      _videoPlayerController = VideoPlayerController.file(
        File(widget.videoUrl),
      );
    }
    await _videoPlayerController.initialize();

    _chewieController = ChewieController(
      videoPlayerController: _videoPlayerController,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
      aspectRatio: _videoPlayerController.value.aspectRatio,
      errorBuilder: (context, errorMessage) {
        return Center(
          child: Text(
            errorMessage,
            style: const TextStyle(color: Colors.white),
          ),
        );
      },
    );
    setState(() {});
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_chewieController != null &&
        _chewieController!.videoPlayerController.value.isInitialized) {
      return Chewie(controller: _chewieController!);
    } else {
      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
    }
  }
}
