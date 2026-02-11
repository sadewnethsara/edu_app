import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PastPaperPdfViewerScreen extends StatefulWidget {
  final String title;
  final String pdfUrl;

  const PastPaperPdfViewerScreen({
    super.key,
    required this.title,
    required this.pdfUrl,
  });

  @override
  State<PastPaperPdfViewerScreen> createState() =>
      _PastPaperPdfViewerScreenState();
}

class _PastPaperPdfViewerScreenState extends State<PastPaperPdfViewerScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  String? _localPdfPath;
  int _pageCount = 0;
  int _currentPage = 0;

  // Appearance settings
  Color _backgroundColor = Colors.grey.shade200;
  double _brightness = 1.0;
  bool _nightMode = false;

  @override
  void initState() {
    super.initState();
    _loadSettings().then((_) {
      _loadPdf();
    });
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _brightness = prefs.getDouble('pdf_brightness') ?? 1.0;
        _nightMode = prefs.getBool('pdf_nightMode') ?? false;
        final colorValue = prefs.getInt('pdf_backgroundColor');
        if (colorValue != null) {
          _backgroundColor = Color(colorValue);
        }
      });
    } catch (e) {
      logger.e('Error loading PDF settings', error: e);
    }
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('pdf_brightness', _brightness);
      await prefs.setBool('pdf_nightMode', _nightMode);
      await prefs.setInt('pdf_backgroundColor', _backgroundColor.value);
    } catch (e) {
      logger.e('Error saving PDF settings', error: e);
    }
  }

  Future<void> _loadPdf() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      logger.i('Downloading PDF from: ${widget.pdfUrl}');
      final response = await http.get(Uri.parse(widget.pdfUrl));

      if (response.statusCode == 200) {
        final dir = await getTemporaryDirectory();
        final fileName = widget.pdfUrl.split('/').last;
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          _localPdfPath = file.path;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load PDF (Code: ${response.statusCode})');
      }
    } catch (e, s) {
      logger.e('Error loading PDF', error: e, stackTrace: s);
      setState(() {
        _errorMessage = 'Failed to load PDF. Please check your connection.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'download') {
                _downloadPdf();
              } else if (value == 'open_external') {
                _openInBrowser();
              } else if (value == 'appearance') {
                _showAppearanceSettings();
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'appearance',
                child: Row(
                  children: [
                    const Icon(Icons.palette_rounded),
                    SizedBox(width: 12.w),
                    const Text('Appearance'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'download',
                child: Row(
                  children: [
                    const Icon(Icons.download_rounded),
                    SizedBox(width: 12.w),
                    const Text('Download PDF'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'open_external',
                child: Row(
                  children: [
                    const Icon(Icons.open_in_browser_rounded),
                    SizedBox(width: 12.w),
                    const Text('Open in External App'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Container(
        color: _backgroundColor,
        child: Stack(
          children: [
            // PDF View
            if (_localPdfPath != null && !_isLoading && _errorMessage == null)
              PDFView(
                key: Key('pdf_view_$_nightMode'),
                filePath: _localPdfPath,
                enableSwipe: true,
                swipeHorizontal: false,
                autoSpacing: false,
                pageFling: true,
                pageSnap: false,
                nightMode: _nightMode,
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

            // Brightness & Tint Overlay
            if (_localPdfPath != null && !_isLoading)
              IgnorePointer(
                child: Container(
                  color: Colors.black.withValues(alpha: 1 - _brightness),
                ),
              ),

            // Error message
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
                      SizedBox(height: 24.h),
                      ElevatedButton.icon(
                        onPressed: _loadPdf,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 24.w,
                            vertical: 12.h,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

            // Loading indicator
            if (_isLoading)
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(color: theme.primaryColor),
                    SizedBox(height: 16.h),
                    Text('Loading PDF...', style: TextStyle(fontSize: 14.sp)),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Download PDF to device
  Future<void> _downloadPdf() async {
    try {
      // Request storage permission
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission required to download'),
            ),
          );
        }
        return;
      }

      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Downloading PDF...')));
      }

      // Download the file
      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        // Get downloads directory
        final dir = await getExternalStorageDirectory();
        final downloadsPath = '${dir!.path}/Download';
        final downloadsDir = Directory(downloadsPath);

        // Create directory if it doesn't exist
        if (!await downloadsDir.exists()) {
          await downloadsDir.create(recursive: true);
        }

        // Save file
        final fileName = widget.pdfUrl.split('/').last;
        final file = File('$downloadsPath/$fileName');
        await file.writeAsBytes(response.bodyBytes);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Downloaded to: ${file.path}'),
              duration: const Duration(seconds: 3),
            ),
          );
        }
        logger.i('PDF downloaded to: ${file.path}');
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      logger.e('Error downloading PDF', error: e);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Download failed: $e')));
      }
    }
  }

  // Show appearance settings bottom sheet
  void _showAppearanceSettings() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.black : Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : theme.primaryColor.withValues(alpha: 0.3),
                  width: 3,
                ),
              ),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Drag Handle
                  Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(top: 12.h, bottom: 8.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.3)
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  ),

                  // Title
                  Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 20.w,
                      vertical: 12.h,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.palette_rounded,
                          color: theme.primaryColor,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'Appearance',
                          style: TextStyle(
                            fontSize: 20.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.titleLarge?.color,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: Icon(
                            Icons.close_rounded,
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.7)
                                : Colors.grey.shade700,
                            size: 24.sp,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Divider(
                    height: 1,
                    thickness: 1,
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.1)
                        : Colors.grey.shade200,
                  ),

                  // Settings
                  Padding(
                    padding: EdgeInsets.all(20.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Night Mode Toggle
                        _buildSettingRow(
                          icon: Icons.dark_mode_rounded,
                          title: 'Night Mode',
                          subtitle: 'Invert PDF colors for dark reading',
                          trailing: Switch(
                            value: _nightMode,
                            onChanged: (value) {
                              setState(() => _nightMode = value);
                              setModalState(() {});
                              _saveSettings();
                            },
                            activeThumbColor: theme.primaryColor,
                          ),
                          isDark: isDark,
                        ),

                        SizedBox(height: 20.h),

                        // Brightness Slider
                        _buildSliderSetting(
                          icon: Icons.brightness_6_rounded,
                          title: 'Brightness',
                          subtitle: '${(_brightness * 100).toInt()}%',
                          value: _brightness,
                          onChanged: (value) {
                            setState(() => _brightness = value);
                            setModalState(() {});
                            _saveSettings();
                          },
                          isDark: isDark,
                          theme: theme,
                        ),

                        SizedBox(height: 20.h),

                        // Background Color
                        Text(
                          'Background Color',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                        ),
                        SizedBox(height: 12.h),
                        Row(
                          children: [
                            Expanded(
                              child: _buildColorOption(
                                Colors.grey.shade200,
                                'Light',
                                setModalState,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildColorOption(
                                Colors.grey.shade800,
                                'Dark',
                                setModalState,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildColorOption(
                                const Color(0xFFFFF8E1),
                                'Sepia',
                                setModalState,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildColorOption(
                                Colors.white,
                                'White',
                                setModalState,
                              ),
                            ),
                            SizedBox(width: 8.w),
                            Expanded(
                              child: _buildColorOption(
                                Colors.black,
                                'Black',
                                setModalState,
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: 24.h),

                        // Reset Button
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () {
                              setState(() {
                                _backgroundColor = Colors.grey.shade200;
                                _brightness = 1.0;
                                _nightMode = false;
                              });
                              setModalState(() {});
                              _saveSettings();
                            },
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: theme.primaryColor,
                                width: 1.5,
                              ),
                              foregroundColor: theme.primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 16.h),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16.r),
                              ),
                            ),
                            child: Text(
                              'Reset to Default',
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget trailing,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          width: 48.w,
          height: 48.w,
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            icon,
            color: isDark
                ? Colors.white.withValues(alpha: 0.7)
                : Colors.grey.shade700,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 16.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        trailing,
      ],
    );
  }

  Widget _buildSliderSetting({
    required IconData icon,
    required String title,
    required String subtitle,
    required double value,
    required ValueChanged<double> onChanged,
    required bool isDark,
    required ThemeData theme,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 48.w,
              height: 48.w,
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Icon(
                icon,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.7)
                    : Colors.grey.shade700,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.5)
                          : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        SizedBox(height: 8.h),
        Slider(
          value: value,
          onChanged: onChanged,
          activeColor: theme.primaryColor,
          min: 0.3,
          max: 1.0,
        ),
      ],
    );
  }

  Widget _buildColorOption(
    Color color,
    String label,
    StateSetter setModalState,
  ) {
    final isSelected = _backgroundColor == color;
    return GestureDetector(
      onTap: () {
        setState(() => _backgroundColor = color);
        setModalState(() {});
        _saveSettings();
      },
      child: Column(
        children: [
          Container(
            width: double.infinity,
            height: 56.w,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isSelected
                    ? Theme.of(context).primaryColor
                    : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
            ),
            child: isSelected
                ? Icon(
                    Icons.check_rounded,
                    color: color.computeLuminance() > 0.5
                        ? Colors.black
                        : Colors.white,
                  )
                : null,
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // Open PDF in external browser
  Future<void> _openInBrowser() async {
    try {
      final uri = Uri.parse(widget.pdfUrl);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw Exception('Could not launch URL');
      }
    } catch (e) {
      logger.e('Error opening in browser', error: e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to open in browser: $e')),
        );
      }
    }
  }
}
