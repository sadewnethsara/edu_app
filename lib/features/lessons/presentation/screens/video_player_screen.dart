import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import 'package:math/app_exports.dart';

class VideoPlayerScreen extends StatefulWidget {
  final List<ContentItem> playlist;
  final int startIndex;

  const VideoPlayerScreen({
    super.key,
    required this.playlist,
    this.startIndex = 0,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  // Player Controllers
  VideoPlayerController? _videoPlayerController;
  ChewieController? _chewieController;
  YoutubePlayerController? _youtubePlayerController;

  // State Management
  late int _currentIndex;
  late ContentItem _currentItem;
  bool _isLoading = true;
  bool _isYoutubeVideo = false;

  // Resume Playback State
  Duration _lastPosition = Duration.zero;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _currentItem = widget.playlist[_currentIndex];
    _loadLastPositionAndInitialize();

    // Hide Status Bar and Navigation Bar
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  // --- Resume Playback Logic ---
  Future<void> _loadLastPositionAndInitialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedId = prefs.getString('last_video_id');
    final savedPos = prefs.getInt('last_video_position');

    if (savedId == _currentItem.id && savedPos != null && savedPos > 0) {
      _lastPosition = Duration(milliseconds: savedPos);
      if (mounted) {
        _showResumeDialog(context);
      }
    } else {
      _initializePlayer(_currentItem.url, startAt: Duration.zero);
    }
  }

  void _showResumeDialog(BuildContext context) {
    String resumeTime = _lastPosition
        .toString()
        .split('.')
        .first
        .padLeft(8, "0");

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Resume Playback?'),
        content: Text('Do you want to resume from $resumeTime?'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _initializePlayer(_currentItem.url, startAt: Duration.zero);
            },
            child: const Text('Start Over'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _initializePlayer(_currentItem.url, startAt: _lastPosition);
            },
            child: const Text('Resume'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveLastPosition() async {
    final prefs = await SharedPreferences.getInstance();
    Duration currentPosition = Duration.zero;

    try {
      if (_isYoutubeVideo && _youtubePlayerController != null) {
        currentPosition = _youtubePlayerController!.value.position;
      } else if (!_isYoutubeVideo && _videoPlayerController != null) {
        currentPosition =
            await _videoPlayerController!.position ?? Duration.zero;
      }

      if (currentPosition.inMilliseconds > 0) {
        await prefs.setString('last_video_id', _currentItem.id);
        await prefs.setInt(
          'last_video_position',
          currentPosition.inMilliseconds,
        );
      } else {
        await prefs.remove('last_video_id');
        await prefs.remove('last_video_position');
      }
    } catch (e) {
      logger.e('Failed to save last position', error: e);
    }
  }
  // --- End Resume Logic ---

  Future<void> _initializePlayer(
    String url, {
    Duration startAt = Duration.zero,
  }) async {
    setState(() {
      _isLoading = true;
    });

    await _saveLastPosition();

    // Dispose old controllers
    await _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubePlayerController?.dispose();

    _videoPlayerController = null;
    _chewieController = null;
    _youtubePlayerController = null;

    try {
      final youtubeId = YoutubePlayer.convertUrlToId(url);

      if (youtubeId != null) {
        // It's a YouTube video
        logger.i('Loading YouTube video with ID: $youtubeId');
        setState(() => _isYoutubeVideo = true);

        _youtubePlayerController = YoutubePlayerController(
          initialVideoId: youtubeId,
          flags: YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
            enableCaption: true,
            controlsVisibleAtStart: true,
            startAt: startAt.inSeconds,
          ),
        );
      } else {
        // It's a regular video URL
        logger.i('Loading regular video from URL: $url');
        setState(() => _isYoutubeVideo = false);

        _videoPlayerController = VideoPlayerController.networkUrl(
          Uri.parse(url),
        );
        await _videoPlayerController!.initialize();

        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          aspectRatio: _videoPlayerController!.value.aspectRatio,
          autoPlay: true,
          looping: false,
          startAt: startAt,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          showControlsOnInitialize: true,
          placeholder: _buildPlayerLoader(),
          errorBuilder: (context, errorMessage) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    color: Colors.white,
                    size: 40,
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'Video could not be played',
                    style: TextStyle(color: Colors.white, fontSize: 16.sp),
                  ),
                ],
              ),
            );
          },
        );
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      logger.e('Error initializing video player: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: Could not load video. ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    // Restore System UI
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _saveLastPosition();
    _videoPlayerController?.dispose();
    _chewieController?.dispose();
    _youtubePlayerController?.dispose();
    super.dispose();
  }

  void _onVideoTapped(int index) {
    if (index == _currentIndex) return;
    setState(() {
      _currentIndex = index;
      _currentItem = widget.playlist[index];
    });
    _initializePlayer(_currentItem.url, startAt: Duration.zero);
  }

  void _downloadVideo(ContentItem item) {
    logger.i('Download button clicked for: ${item.url}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Downloading "${item.name}"... (Not implemented)'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
    );
  }

  void _markAsCompleted() {
    // 1. Award points
    Provider.of<AuthService>(context, listen: false).awardPoints(10);

    // 2. Mark as complete in Firestore
    Provider.of<AuthService>(
      context,
      listen: false,
    ).markContentAsCompleted(_currentItem.id);

    // 3. Clear the "Continue Learning" bookmark
    Provider.of<ContinueLearningService>(
      context,
      listen: false,
    ).clearLastViewedItem();

    // 4. Show success message
    logger.i('Marked as completed: ${_currentItem.name}');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_currentItem.name} marked as completed. +10 points!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _currentItem.name.isNotEmpty ? _currentItem.name : 'Video Player',
          maxLines: 2,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Video Player
          AspectRatio(
            aspectRatio: 16 / 9,
            child: Container(
              color: Colors.black,
              child: _isLoading
                  ? _buildPlayerLoader()
                  : _isYoutubeVideo
                  ? (_youtubePlayerController != null
                        ? YoutubePlayer(
                            controller: _youtubePlayerController!,
                            showVideoProgressIndicator: true,
                            progressIndicatorColor: theme.primaryColor,
                            progressColors: ProgressBarColors(
                              playedColor: theme.primaryColor,
                              handleColor: theme.primaryColor,
                            ),
                          )
                        : _buildPlayerLoader())
                  : (_chewieController != null
                        ? Chewie(controller: _chewieController!)
                        : _buildPlayerLoader()),
            ),
          ),

          // 2. Description Section
          _buildDescriptionSection(theme),

          // 3. "Up Next" Title
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Text(
              'Up Next (${_currentIndex + 1}/${widget.playlist.length})',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.bodyLarge?.color,
              ),
            ),
          ),

          // 4. Playlist
          Expanded(child: _buildPlaylist()),
        ],
      ),
    );
  }

  Widget _buildPlayerLoader() {
    return const Center(child: CircularProgressIndicator(color: Colors.white));
  }

  Widget _buildDescriptionSection(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 8.w),
      child: ExpansionTile(
        key: PageStorageKey(_currentItem.id), // Resets state when item changes
        title: Text(
          _currentItem.name.isNotEmpty ? _currentItem.name : 'Description',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          'Tap to see description...',
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
        ),
        trailing: ElevatedButton.icon(
          onPressed: _markAsCompleted,
          icon: Icon(Icons.check_circle_outline, size: 18.sp),
          label: const Text('Complete'),
          style: ElevatedButton.styleFrom(
            elevation: 0,
            backgroundColor: Colors.green.withValues(alpha: 0.1),
            foregroundColor: Colors.green,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 16.h),
            child: Text(
              _currentItem.description != null &&
                      _currentItem.description!.isNotEmpty
                  ? _currentItem.description!
                  : 'No description available for this video.',
              style: TextStyle(fontSize: 14.sp, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaylist() {
    final theme = Theme.of(context);
    return ListView.separated(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 8.h,
      ).copyWith(bottom: 16.h),
      itemCount: widget.playlist.length,
      separatorBuilder: (context, index) => SizedBox(height: 8.h),
      itemBuilder: (context, index) {
        final item = widget.playlist[index];
        final bool isPlaying = (index == _currentIndex);

        // Get thumbnail URL
        String? thumbnailUrl = item.thumbnail;
        if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
          final youtubeId = YoutubePlayer.convertUrlToId(item.url);
          if (youtubeId != null) {
            thumbnailUrl =
                'https://img.youtube.com/vi/$youtubeId/hqdefault.jpg';
          } else {
            thumbnailUrl = 'https://via.placeholder.com/160x90.png?text=Video';
          }
        }

        return ListTile(
          onTap: () => _onVideoTapped(index),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          tileColor: isPlaying
              ? theme.primaryColor.withValues(alpha: 0.1)
              : theme.cardColor,
          contentPadding: EdgeInsets.all(8.w),
          leading: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8.r),
                child: Image.network(
                  thumbnailUrl,
                  width: 90.w,
                  height: 50.h,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 90.w,
                      height: 50.h,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.videocam_off_outlined,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
              if (isPlaying)
                Container(
                  width: 90.w,
                  height: 50.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 30.sp,
                  ),
                ),
            ],
          ),
          title: Text(
            item.name.isNotEmpty ? item.name : 'Untitled Video',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
              color: isPlaying
                  ? theme.primaryColor
                  : theme.textTheme.bodyLarge?.color,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            icon: Icon(
              Icons.download_outlined,
              color: Colors.grey.shade600,
              size: 24.sp,
            ),
            onPressed: () => _downloadVideo(item),
          ),
        );
      },
    );
  }
}
