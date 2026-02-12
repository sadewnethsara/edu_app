import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/models/content_model.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/continue_learning_service.dart';
import 'package:math/core/services/language_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:math/core/widgets/unified_sliver_app_bar.dart';
import 'package:math/core/widgets/search_bar_widget.dart';
import 'package:math/core/widgets/loading/search_bar_shimmer.dart';
import 'package:math/core/widgets/loading/content_list_shimmer.dart';
import 'package:math/core/widgets/states/empty_state_widget.dart';
import 'package:math/core/widgets/curriculum/content_item_card.dart';
import 'package:math/core/widgets/curriculum/content_filter_chip.dart';
import 'package:shimmer/shimmer.dart';
import 'package:url_launcher/url_launcher.dart';

class LessonContentScreen extends StatefulWidget {
  final String gradeId;
  final String subjectId;
  final String lessonId;

  const LessonContentScreen({
    super.key,
    required this.gradeId,
    required this.subjectId,
    required this.lessonId,
  });

  @override
  State<LessonContentScreen> createState() => _LessonContentScreenState();
}

class _LessonContentScreenState extends State<LessonContentScreen> {
  final ApiService _apiService = ApiService();
  ContentCollection? _content;
  ContentCollection? _filteredContent;
  bool _isLoading = true;
  String _selectedLanguage = 'en';
  String _lessonName = '';
  String _subjectName = '';
  String _gradeName = '';
  String _selectedFilter = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContent();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentLanguage = context
        .watch<LanguageService>()
        .locale
        .languageCode;

    if (currentLanguage != _selectedLanguage && !_isLoading) {
      _selectedLanguage = currentLanguage;
      _loadContent();
    }
  }

  Future<void> _loadContent({bool forceRefresh = false}) async {
    try {
      if (mounted) setState(() => _isLoading = true);

      final gradeNameFuture = FirebaseFirestore.instance
          .collection('curricula')
          .doc(_selectedLanguage)
          .collection('grades')
          .doc(widget.gradeId)
          .get();

      final subjectNameFuture = () async {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('grades')
            .doc(widget.gradeId)
            .collection('subjects')
            .doc(widget.subjectId)
            .get();

        if (!doc.exists) {
          doc = await FirebaseFirestore.instance
              .collection('curricula')
              .doc(_selectedLanguage)
              .collection('grades')
              .doc(widget.gradeId)
              .collection('subjects')
              .doc(widget.subjectId)
              .get();
        }
        return doc;
      }();

      final lessonNameFuture = () async {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('grades')
            .doc(widget.gradeId)
            .collection('subjects')
            .doc(widget.subjectId)
            .collection('lessons')
            .doc(widget.lessonId)
            .get();

        if (!doc.exists) {
          doc = await FirebaseFirestore.instance
              .collection('curricula')
              .doc(_selectedLanguage)
              .collection('grades')
              .doc(widget.gradeId)
              .collection('subjects')
              .doc(widget.subjectId)
              .collection('lessons')
              .doc(widget.lessonId)
              .get();
        }
        return doc;
      }();

      final contentFuture = _apiService.getLessonContent(
        widget.gradeId,
        widget.subjectId,
        widget.lessonId,
        _selectedLanguage,
        forceRefresh: forceRefresh,
      );

      final results = await Future.wait([
        gradeNameFuture,
        subjectNameFuture,
        lessonNameFuture,
        contentFuture,
      ]);

      if (!mounted) return;

      final gradeDoc = results[0] as DocumentSnapshot;
      final subjectDoc = results[1] as DocumentSnapshot;
      final lessonDoc = results[2] as DocumentSnapshot;
      final content = results[3] as ContentCollection?;

      if (gradeDoc.exists) {
        _gradeName = gradeDoc.data() is Map
            ? ((gradeDoc.data() as Map<String, dynamic>)['name'] ??
                  'Grade ${widget.gradeId.replaceAll(RegExp(r'[^0-9]'), '')}')
            : 'Grade ${widget.gradeId.replaceAll(RegExp(r'[^0-9]'), '')}';
      } else {
        _gradeName =
            'Grade ${widget.gradeId.replaceAll(RegExp(r'[^0-9]'), '')}';
      }

      if (subjectDoc.exists) {
        final data = subjectDoc.data() as Map<String, dynamic>?;
        _subjectName = data?['name'] ?? 'Subject';
      } else {
        _subjectName = 'Subject';
      }

      if (lessonDoc.exists) {
        final data = lessonDoc.data() as Map<String, dynamic>?;
        _lessonName = data?['name'] ?? 'Lesson Content';
      } else {
        _lessonName = 'Lesson Content';
      }

      if (mounted) {
        setState(() {
          _content = content;
          _applySearchAndSort();
          _isLoading = false;
        });
      }
    } catch (e) {
      logger.e('Error loading lesson content: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _selectedSort = 'Newest';

  void _applySearchAndSort() {
    if (_content == null) return;

    List<ContentItem> filterList(List<ContentItem> list) {
      if (_searchQuery.isEmpty) {
        return List.from(list);
      }
      return list
          .where(
            (item) =>
                item.name.toLowerCase().contains(_searchQuery.toLowerCase()),
          )
          .toList();
    }

    final filteredVideos = filterList(_content!.videos);
    final filteredNotes = filterList(_content!.notes);
    final filteredPdfs = filterList(_content!.contentPdfs);
    final filteredResources = filterList(_content!.resources);

    void sortList(List<ContentItem> list) {
      switch (_selectedSort) {
        case 'A-Z':
          list.sort(
            (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
          );
          break;
        case 'Z-A':
          list.sort(
            (a, b) => b.name.toLowerCase().compareTo(a.name.toLowerCase()),
          );
          break;
        case 'Newest':
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          break;
        case 'Oldest':
          list.sort((a, b) => a.uploadedAt.compareTo(b.uploadedAt));
          break;
      }
    }

    sortList(filteredVideos);
    sortList(filteredNotes);
    sortList(filteredPdfs);
    sortList(filteredResources);

    setState(() {
      _filteredContent = ContentCollection(
        videos: filteredVideos,
        notes: filteredNotes,
        contentPdfs: filteredPdfs,
        resources: filteredResources,
      );
    });
  }

  void _sortContent() {
    _applySearchAndSort();
  }

  void _filterContent(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applySearchAndSort();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _launchExternalUrl(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await canLaunchUrl(uri)) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Could not open link')));
      }
    } else {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showContentActionModal(
    ContentItem item,
    List<ContentItem> contextList,
    String contentType,
  ) {
    int currentIndex = contextList.indexWhere((i) => i.id == item.id);
    final continueService = Provider.of<ContinueLearningService>(
      context,
      listen: false,
    );

    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black.withValues(alpha: 0.5),
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return _ContentActionModal(
          item: item,
          contentType: contentType,
          onPlay: () {
            Navigator.pop(context);
            const routePath = AppRouter.videoPlayerPath;
            final continueData = ContinueLearningData(
              gradeId: widget.gradeId,
              subjectId: widget.subjectId,
              lessonId: widget.lessonId,
              item: item,
              contextList: contextList,
              contentType: contentType,
              parentName: _lessonName,
              routePath: routePath,
              startIndex: currentIndex,
            );
            continueService.setLastViewedItem(continueData);
            context.push(
              routePath,
              extra: {'playlist': contextList, 'startIndex': currentIndex},
            );
          },
          onOpen: () {
            Navigator.pop(context);
            String routePath = (contentType == 'notes')
                ? AppRouter.noteViewerPath
                : AppRouter.pdfViewerPath;
            final continueData = ContinueLearningData(
              gradeId: widget.gradeId,
              subjectId: widget.subjectId,
              lessonId: widget.lessonId,
              item: item,
              contextList: contextList,
              contentType: contentType,
              parentName: _lessonName,
              routePath: routePath,
              startIndex: currentIndex,
            );
            continueService.setLastViewedItem(continueData);
            context.push(
              routePath,
              extra: {'itemList': contextList, 'startIndex': currentIndex},
            );
          },
          onOpenExternal: () {
            Navigator.pop(context);
            _launchExternalUrl(item.url);
          },
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0, 1), // Slide up from bottom
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
          child: Align(
            alignment: Alignment.bottomCenter, // Anchor to bottom
            child: Material(color: Colors.transparent, child: child),
          ),
        );
      },
    );
  }

  List<Map<String, dynamic>> _getFilteredItems() {
    final contentToUse = _filteredContent ?? _content;
    if (contentToUse == null) return [];
    List<Map<String, dynamic>> items = [];

    void addItems(
      List<ContentItem> list,
      String type,
      IconData icon,
      Color color,
    ) {
      if (_selectedFilter == 'All' || _selectedFilter == type) {
        items.addAll(
          list.map(
            (e) => {
              'item': e,
              'type': type,
              'icon': icon,
              'color': color,
              'list': list,
            },
          ),
        );
      }
    }

    addItems(contentToUse.videos, 'Videos', Icons.videocam_rounded, Colors.red);
    addItems(
      contentToUse.notes,
      'Notes',
      Icons.description_rounded,
      Colors.blue,
    );
    addItems(
      contentToUse.contentPdfs,
      'PDFs',
      Icons.picture_as_pdf_rounded,
      Colors.orange,
    );
    addItems(
      contentToUse.resources,
      'Resources',
      Icons.folder_rounded,
      Colors.green,
    );

    return items;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredItems = _getFilteredItems();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          onRefresh: () => _loadContent(forceRefresh: true),
          color: Theme.of(context).primaryColor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              UnifiedSliverAppBar(
                title: _lessonName,
                isLoading: _isLoading,
                backgroundIcon: Icons.menu_book_rounded,
                breadcrumb: Row(
                  children: [
                    InkWell(
                      onTap: () => context.go('/subjects/${widget.gradeId}'),
                      child: Text(
                        _gradeName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    Text(
                      ' / ',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 12.sp,
                      ),
                    ),
                    InkWell(
                      onTap: () => context.pop(),
                      child: Text(
                        _subjectName,
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12.sp,
                          decoration: TextDecoration.underline,
                          decorationColor: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
                selectedSort: _selectedSort,
                onSortSelected: (value) {
                  setState(() {
                    _selectedSort = value;
                  });
                  _sortContent();
                },
              ),

              SliverToBoxAdapter(
                child: _isLoading
                    ? const SearchBarShimmer()
                    : SearchBarWidget(
                        hintText: 'Search content...',
                        controller: _searchController,
                        onChanged: _filterContent,
                        onClear: () => _filterContent(''),
                      ),
              ),

              if (!_isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        children: [
                          ContentFilterChip(
                            label: 'All',
                            isSelected: _selectedFilter == 'All',
                            onTap: () =>
                                setState(() => _selectedFilter = 'All'),
                          ),
                          ContentFilterChip(
                            label: 'Videos',
                            isSelected: _selectedFilter == 'Videos',
                            onTap: () =>
                                setState(() => _selectedFilter = 'Videos'),
                          ),
                          ContentFilterChip(
                            label: 'Notes',
                            isSelected: _selectedFilter == 'Notes',
                            onTap: () =>
                                setState(() => _selectedFilter = 'Notes'),
                          ),
                          ContentFilterChip(
                            label: 'PDFs',
                            isSelected: _selectedFilter == 'PDFs',
                            onTap: () =>
                                setState(() => _selectedFilter = 'PDFs'),
                          ),
                          ContentFilterChip(
                            label: 'Resources',
                            isSelected: _selectedFilter == 'Resources',
                            onTap: () =>
                                setState(() => _selectedFilter = 'Resources'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              _isLoading
                  ? const ContentListShimmer(itemHeight: 76)
                  : filteredItems.isEmpty
                  ? const SliverFillRemaining(
                      child: EmptyStateWidget(
                        icon: Icons.filter_list_off_rounded,
                        title: 'No content found',
                        subtitle: 'Try adjusting your search or filter.',
                      ),
                    )
                  : SliverPadding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      sliver: SliverList(
                        delegate: SliverChildBuilderDelegate((context, index) {
                          final data = filteredItems[index];
                          return Padding(
                            padding: EdgeInsets.only(bottom: 16.h),
                            child: ContentItemCard(
                              item: data['item'] as ContentItem,
                              icon: data['icon'] as IconData,
                              color: data['color'] as Color,
                              type: data['type'] as String,
                              onTap: () => _showContentActionModal(
                                data['item'] as ContentItem,
                                data['list'] as List<ContentItem>,
                                (data['type'] as String).toLowerCase() == 'pdfs'
                                    ? 'contentPdfs'
                                    : (data['type'] as String).toLowerCase(),
                              ),
                            ),
                          );
                        }, childCount: filteredItems.length),
                      ),
                    ),
              if (!_isLoading)
                SliverPadding(padding: EdgeInsets.only(bottom: 80.h)),
            ],
          ),
        ),
      ),
      floatingActionButton: _isLoading
          ? Container(
              height: 48.h,
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24.r),
                color: theme.primaryColor.withValues(alpha: 0.3),
              ),
              child: Shimmer.fromColors(
                baseColor: theme.primaryColor.withValues(alpha: 0.3),
                highlightColor: theme.primaryColor.withValues(alpha: 0.6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 24.w,
                      height: 24.w,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    Container(
                      width: 100.w,
                      height: 16.h,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4.r),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : FloatingActionButton.extended(
              onPressed: () => context.push(
                '/subjects/${widget.gradeId}/${widget.subjectId}/lessons/${widget.lessonId}/subtopics',
              ),
              backgroundColor: theme.primaryColor,
              elevation: 4,
              icon: const Icon(Iconsax.folder_2_outline, color: Colors.white),
              label: const Text(
                'View Subtopics',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }
}

class _ContentActionModal extends StatelessWidget {
  final ContentItem item;
  final String contentType;
  final VoidCallback onPlay;
  final VoidCallback onOpen;
  final VoidCallback onOpenExternal;

  const _ContentActionModal({
    required this.item,
    required this.contentType,
    required this.onPlay,
    required this.onOpen,
    required this.onOpenExternal,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final itemName = item.name.isNotEmpty
        ? item.name
        : (item.fileName ?? 'Untitled');

    IconData icon;
    String buttonText;
    VoidCallback onPressed;

    switch (contentType) {
      case 'videos':
        icon = Icons.play_circle_fill_rounded;
        buttonText = 'Play Video';
        onPressed = onPlay;
        break;
      case 'notes':
        icon = Icons.note_alt_rounded;
        buttonText = 'Open Note';
        onPressed = onOpen;
        break;
      case 'contentPdfs':
        icon = Icons.picture_as_pdf_rounded;
        buttonText = 'Open PDF';
        onPressed = onOpen;
        break;
      case 'resources':
        icon = Icons.launch_rounded;
        buttonText = 'Open in External App';
        onPressed = onOpenExternal;
        break;
      default:
        icon = Icons.help_outline_rounded;
        buttonText = 'Open';
        onPressed = onOpenExternal;
    }

    final EdgeInsets modalPadding = EdgeInsets.symmetric(
      horizontal: 24.w,
      vertical: 20.h,
    ).copyWith(top: 24.h);

    final BorderRadius modalBorderRadius = BorderRadius.vertical(
      bottom: Radius.circular(20.r),
    );

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 10.w).copyWith(top: 10.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: modalBorderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 20,
            spreadRadius: 5,
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: modalPadding,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (contentType == 'videos')
                Container(
                  width: double.infinity,
                  height: 180.h,
                  margin: EdgeInsets.only(bottom: 16.h),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12.r),
                    color: Colors.grey.shade200,
                  ),
                  child: Builder(
                    builder: (context) {
                      String? thumbnailUrl = item.thumbnail;
                      if (thumbnailUrl == null || thumbnailUrl.isEmpty) {
                        final youtubeRegex = RegExp(
                          r'(?:youtube\.com\/(?:[^\/]+\/.+\/|(?:v|e(?:mbed)?)\/|.*[?&]v=)|youtu\.be\/)([^"&?\/\s]{11})',
                        );
                        final match = youtubeRegex.firstMatch(item.url);
                        if (match != null) {
                          final videoId = match.group(1);
                          thumbnailUrl =
                              'https://img.youtube.com/vi/$videoId/hqdefault.jpg';
                        }
                      }

                      return (thumbnailUrl != null && thumbnailUrl.isNotEmpty)
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12.r),
                              child: Image.network(
                                thumbnailUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Center(
                                      child: Icon(
                                        Icons.videocam_rounded,
                                        size: 60.sp,
                                        color: Colors.grey.shade400,
                                      ),
                                    ),
                              ),
                            )
                          : Center(
                              child: Icon(
                                Icons.videocam_rounded,
                                size: 60.sp,
                                color: Colors.grey.shade400,
                              ),
                            );
                    },
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, color: theme.primaryColor, size: 32.sp),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.textTheme.bodyLarge?.color,
                          ),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4.h),
                        if (item.description != null &&
                            item.description!.isNotEmpty)
                          Text(
                            item.description!,
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: theme.textTheme.bodyMedium?.color,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: 32.h),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: Icon(icon),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50.h),
                  backgroundColor: theme.primaryColor,
                  foregroundColor: theme.colorScheme.onPrimary,
                  textStyle: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
