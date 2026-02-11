import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:math/data/models/content_model.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:math/services/auth_service.dart';
import 'package:math/services/continue_learning_service.dart';

final logger = Logger();

class PdfViewerScreen extends StatefulWidget {
  final List<ContentItem> itemList;
  final int startIndex;

  const PdfViewerScreen({
    super.key,
    required this.itemList,
    this.startIndex = 0,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  late int _currentIndex;
  late ContentItem _currentItem;
  bool _isLastItem = false;

  bool _isLoading = true;
  String? _errorMessage;
  String? _localPdfPath;
  int _pageCount = 0;
  int _currentPage = 0;

  // Cache to avoid re-downloading
  static final Map<String, String> _downloadCache = {};

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.startIndex;
    _updateCurrentItem();
    _loadPdf();
  }

  void _updateCurrentItem() {
    _currentItem = widget.itemList[_currentIndex];
    _isLastItem = _currentIndex == widget.itemList.length - 1;
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _localPdfPath = null;
      _pageCount = 0;
      _currentPage = 0;
    });

    try {
      // Check cache first
      if (_downloadCache.containsKey(_currentItem.url)) {
        logger.i('Loading PDF from cache...');
        setState(() {
          _localPdfPath = _downloadCache[_currentItem.url];
          _isLoading = false;
        });
        return;
      }

      logger.i('Downloading PDF from: ${_currentItem.url}');
      final response = await http.get(Uri.parse(_currentItem.url));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        // Use a stable file name based on ID
        final file = File('${dir.path}/pdf_${_currentItem.id}.pdf');
        await file.writeAsBytes(response.bodyBytes);

        final localPath = file.path;
        _downloadCache[_currentItem.url] = localPath; // Save to cache

        setState(() {
          _localPdfPath = localPath;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF (Code: ${response.statusCode})');
      }
    } catch (e, s) {
      logger.e('Error loading PDF', error: e, stackTrace: s);
      setState(() {
        _errorMessage = 'Failed to load PDF. Please try again.';
        _isLoading = false;
      });
    }
  }

  void _goToNextPdf() {
    if (_isLastItem) return;

    setState(() {
      _currentIndex++;
      _updateCurrentItem();
    });
    _loadPdf();
  }

  void _finishViewing() {
    logger.i('Finished viewing PDFs.');
    // Clear the "Continue Learning" bookmark
    Provider.of<ContinueLearningService>(
      context,
      listen: false,
    ).clearLastViewedItem();
    context.pop();
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
    final itemName = _currentItem.name.isNotEmpty
        ? _currentItem.name
        : 'PDF Document';

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              itemName,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            // Show page count if PDF is loaded
            if (_pageCount > 0 && !_isLoading)
              Text(
                'Page ${_currentPage + 1} of $_pageCount',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.normal,
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Show PDF View
          if (_localPdfPath != null && !_isLoading && _errorMessage == null)
            PDFView(
              filePath: _localPdfPath,
              enableSwipe: true,
              swipeHorizontal: false,
              autoSpacing: false,
              pageFling: true,
              onRender: (pages) {
                if (mounted) {
                  setState(() {
                    _pageCount = pages ?? 0;
                  });
                }
              },
              onError: (error) {
                logger.e('PDFView Error: $error');
                setState(() {
                  _errorMessage = 'Error displaying PDF.';
                });
              },
              onPageError: (page, error) {
                logger.e('PDFView Page Error: $page, $error');
              },
              onPageChanged: (page, total) {
                if (mounted) {
                  setState(() {
                    _currentPage = page ?? 0;
                    _pageCount = total ?? 0;
                  });
                }
              },
            ),

          // Show error message
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
                      'Failed to load PDF',
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

          // Show loading indicator
          if (_isLoading)
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  SizedBox(height: 16.h),
                  Text('Loading PDF...', style: TextStyle(fontSize: 14.sp)),
                ],
              ),
            ),
        ],
      ),
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
              onPressed: _isLastItem ? _finishViewing : _goToNextPdf,
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
