import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:math/data/models/content_model.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/services/continue_learning_service.dart';

final logger = Logger();

class NoteViewerScreen extends StatefulWidget {
  final List<ContentItem> itemList;
  final int startIndex;

  const NoteViewerScreen({
    super.key,
    required this.itemList,
    this.startIndex = 0,
  });

  @override
  State<NoteViewerScreen> createState() => _NoteViewerScreenState();
}

class _NoteViewerScreenState extends State<NoteViewerScreen> {
  late int _currentIndex;
  late ContentItem _currentItem;
  WebViewController? _controller;

  bool _isLoading = true;
  String? _errorMessage;
  bool _isLastItem = false;

  // Cache to store downloaded file paths
  static final Map<String, String> _noteCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _updateCurrentItem();
    _loadNote();
  }

  void _updateCurrentItem() {
    _currentItem = widget.itemList[_currentIndex];
    _isLastItem = _currentIndex == widget.itemList.length - 1;
  }

  /// Gets the local file path for a note, downloading it if not in cache.
  Future<String> _getNotePath(String url) async {
    // 1. Check cache
    if (_noteCache.containsKey(url)) {
      logger.i('Loading note from cache');
      return _noteCache[url]!;
    }

    // 2. Download
    logger.i('Downloading note from: $url');
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final dir = await getTemporaryDirectory();
      // Use a unique file name
      final file = File('${dir.path}/note_${_currentItem.id}.html');
      await file.writeAsString(response.body); // Save as HTML/text

      final localPath = file.path;
      _noteCache[url] = localPath; // 3. Save to cache
      return localPath;
    } else {
      throw Exception('Failed to load note (Code: ${response.statusCode})');
    }
  }

  /// Loads the note into the WebView, using the cached file if available.
  Future<void> _loadNote() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _controller = null;
    });

    try {
      // 1. Get the local file path (from your cache/download logic)
      final String localPath = await _getNotePath(_currentItem.url);

      // 🚀 --- THIS IS THE FIX --- 🚀
      // 2. Read the downloaded file into a string
      final String htmlString = await File(localPath).readAsString();
      // 🚀 --- END OF FIX --- 🚀

      // 3. Initialize the controller
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) setState(() => _isLoading = true);
            },
            onPageFinished: (String url) {
              if (mounted) setState(() => _isLoading = false);
            },
            onWebResourceError: (WebResourceError error) {
              logger.e('WebView error: ${error.description}', error: error);
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = error.description;
                });
              }
            },
          ),
        );

      // 4. 🚀 Load the HTML string directly
      await controller.loadHtmlString(htmlString);

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      logger.e('Failed to initialize WebView', error: e);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to load content. Please try again.';
        });
      }
    }
  }

  void _goToNextNote() {
    if (_isLastItem) return;

    setState(() {
      _currentIndex++;
      _updateCurrentItem();
    });
    _loadNote(); // Load the next note
  }

  void _finishViewing() {
    logger.i('Finished viewing notes.');
    // Clear the "Continue Learning" bookmark
    Provider.of<ContinueLearningService>(
      context,
      listen: false,
    ).clearLastViewedItem();
    context.pop();
  }

  void _markAsCompleted() {
    // 1. Award points
    Provider.of<AuthService>(
      context,
      listen: false,
    ).awardPoints(10); // Example: 10 points

    // 2. Mark as complete in Firestore (for percentage)
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
    final itemName = _currentItem.name.isNotEmpty ? _currentItem.name : 'Note';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          itemName,
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
      ),
      body: Stack(
        children: [
          // Show error message if loading failed
          if (_errorMessage != null)
            Center(
              child: Padding(
                padding: EdgeInsets.all(24.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 60.sp,
                    ),
                    SizedBox(height: 16.h),
                    Text(
                      'Failed to load content',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      _errorMessage!,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),

          // Show WebView only if there's no error and controller is initialized
          if (_errorMessage == null && _controller != null)
            WebViewWidget(controller: _controller!),

          // Show loading indicator
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
      // Bottom navigation bar for actions
      bottomNavigationBar: _buildBottomActions(theme),
    );
  }

  Widget _buildBottomActions(ThemeData theme) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 24.w,
        vertical: 16.h,
      ).copyWith(bottom: 32.h), // Padding for home bar
      decoration: BoxDecoration(
        color: theme.cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(top: BorderSide(color: theme.dividerColor, width: 0.5)),
      ),
      child: Row(
        children: [
          // "Mark as Completed" Button
          Expanded(
            child: OutlinedButton(
              onPressed: _markAsCompleted,
              style: OutlinedButton.styleFrom(
                minimumSize: Size.fromHeight(48.h),
                side: BorderSide(color: theme.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Mark as Completed',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SizedBox(width: 16.w),

          // "Next" or "Finish" Button
          Expanded(
            child: ElevatedButton(
              onPressed: _isLastItem ? _finishViewing : _goToNextNote,
              style: ElevatedButton.styleFrom(
                minimumSize: Size.fromHeight(48.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _isLastItem ? 'Finish' : 'Next',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (!_isLastItem)
                    Icon(Icons.arrow_forward_ios_rounded, size: 16.sp),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
