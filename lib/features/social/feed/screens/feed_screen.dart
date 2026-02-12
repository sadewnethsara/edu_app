import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/features/settings/presentation/screens/social_settings_screen.dart';
import 'package:math/core/services/api_service.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/utils/avatar_color_generator.dart';
import 'package:math/features/social/shared/widgets/user_profile_bottom_sheet.dart';
import 'package:math/features/social/community/widgets/community_filter_bottom_sheet.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  List<PostModel> _posts = [];

  String _feedFilter = 'all'; // 'all', 'following', 'trending', 'subject'
  String? _selectedSubjectId;
  String? _selectedSubjectName;

  String? _gradeId;
  String? _medium;

  final ValueNotifier<bool> _showTitle = ValueNotifier<bool>(true);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadFeed();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.offset > 60 && _showTitle.value) {
      _showTitle.value = false;
    } else if (_scrollController.offset <= 60 && !_showTitle.value) {
      _showTitle.value = true;
    }
  }

  Future<void> _loadFeed() async {
    if (_posts.isEmpty && mounted) setState(() => _isLoading = true);

    try {
      final authService = context.read<AuthService>();
      final user = authService.user;

      if (user == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data();

      setState(() {
        _medium = userData?['learningMedium'] as String?;
        final List<dynamic>? grades = userData?['grades'] as List<dynamic>?;
        _gradeId = (grades != null && grades.isNotEmpty)
            ? grades.first.toString()
            : null;
      });

      List<PostModel> posts = [];

      if (_feedFilter == 'trending') {
        posts = await _apiService.getTrendingPosts(
          gradeId: _gradeId,
          medium: _medium,
          limit: 50,
        );
      } else if (_feedFilter == 'subject' && _selectedSubjectId != null) {
        posts = await _apiService.getPostsBySubject(
          subjectId: _selectedSubjectId!,
          gradeId: _gradeId,
          medium: _medium,
          limit: 50,
        );
      } else {
        posts = await _apiService.getFeedPosts(
          gradeId: _gradeId,
          medium: _medium,
          limit: 50,
        );

        if (_feedFilter == 'following') {
          final followingSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('following')
              .get();
          final followingIds = followingSnapshot.docs
              .map((doc) => doc.id)
              .toSet();
          posts = posts
              .where((post) => followingIds.contains(post.authorId))
              .toList();
        }
      }

      _posts = posts;
    } catch (e, s) {
      logger.e('Failed to load Community', error: e, stackTrace: s);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: RefreshIndicator(
          onRefresh: _loadFeed,
          color: theme.primaryColor,
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverAppBar(
                expandedHeight: 120.h,
                floating: false,
                pinned: true,
                backgroundColor: isDark
                    ? Colors.black
                    : const Color(0xFF0B1C2C),
                flexibleSpace: FlexibleSpaceBar(
                  centerTitle: true,
                  title: ValueListenableBuilder<bool>(
                    valueListenable: _showTitle,
                    builder: (context, show, child) {
                      return AnimatedOpacity(
                        opacity: show ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: Text(
                          "Community",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    },
                  ),
                  background: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isDark
                            ? [
                                const Color(0xFF0F172A), // Slate 900
                                const Color(0xFF000000), // Pure Black
                              ]
                            : [
                                const Color(0xFF0B1C2C),
                                const Color(0xFF0B1C2C).withValues(alpha: 0.8),
                              ],
                      ),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          left: -30,
                          top: -30,
                          child: Icon(
                            Icons.school_rounded,
                            size: 160.sp,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                leading: Consumer<AuthService>(
                  builder: (context, auth, _) {
                    final userId = auth.user?.uid ?? '';
                    final bgColor = AvatarColorGenerator.getColorForUser(
                      userId,
                    );
                    final photoUrl = auth.user?.photoURL;
                    final hasPhoto = photoUrl != null && photoUrl.isNotEmpty;

                    return Center(
                      child: GestureDetector(
                        onTap: () {
                          if (auth.user != null) {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              useRootNavigator: true,
                              backgroundColor: Colors.transparent,
                              builder: (context) => UserProfileBottomSheet(
                                userId: auth.user!.uid,
                              ),
                            );
                          }
                        },
                        child: CircleAvatar(
                          radius: 16.sp,
                          backgroundColor: bgColor,
                          backgroundImage: hasPhoto
                              ? CachedNetworkImageProvider(photoUrl)
                              : null,
                          child: !hasPhoto
                              ? Icon(
                                  Iconsax.user_outline,
                                  size: 20.sp,
                                  color:
                                      AvatarColorGenerator.getTextColorForBackground(
                                        bgColor,
                                      ),
                                )
                              : null,
                        ),
                      ),
                    );
                  },
                ),
                actions: [
                  IconButton(
                    icon: Icon(
                      Iconsax.archive_tick_outline,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                    onPressed: () => context.push(AppRouter.favoritesPath),
                    tooltip: 'Saved Posts',
                  ),
                  IconButton(
                    icon: Icon(
                      Iconsax.search_status_outline,
                      color: Colors.white,
                      size: 26.sp,
                    ),
                    onPressed: () {
                      context.push(AppRouter.searchUsersPath);
                    },
                    tooltip: 'Search',
                  ),
                  IconButton(
                    icon: Icon(
                      Iconsax.filter_outline,
                      color: Colors.white,
                      size: 24.sp,
                    ),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        useRootNavigator: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CommunityFilterBottomSheet(
                          currentFilter: _feedFilter,
                          onFilterSelected: (value) async {
                            setState(() {
                              _feedFilter = value;
                              if (value != 'subject') {
                                _selectedSubjectId = null;
                                _selectedSubjectName = null;
                              }
                            });
                            await _loadFeed();
                          },
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(
                      Iconsax.setting_outline,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                          builder: (context) => const SocialSettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),

              if (_feedFilter != 'all' || _selectedSubjectId != null)
                SliverToBoxAdapter(
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 8.h,
                    ),
                    child: Wrap(
                      spacing: 8.w,
                      runSpacing: 4.h,
                      children: [
                        if (_feedFilter == 'trending')
                          Chip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Iconsax.trend_up_outline, size: 16.sp),
                                SizedBox(width: 4.w),
                                const Text('Trending'),
                              ],
                            ),
                            deleteIcon: const Icon(
                              Iconsax.close_circle_outline,
                              size: 18,
                            ),
                            onDeleted: () {
                              setState(() => _feedFilter = 'all');
                              _loadFeed();
                            },
                            backgroundColor: theme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        if (_feedFilter == 'following')
                          Chip(
                            label: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Iconsax.profile_2user_outline,
                                  size: 16.sp,
                                ),
                                SizedBox(width: 4.w),
                                const Text('Following'),
                              ],
                            ),
                            deleteIcon: const Icon(
                              Iconsax.close_circle_outline,
                              size: 18,
                            ),
                            onDeleted: () {
                              setState(() => _feedFilter = 'all');
                              _loadFeed();
                            },
                            backgroundColor: theme.primaryColor.withValues(
                              alpha: 0.1,
                            ),
                          ),
                        if (_selectedSubjectId != null)
                          Chip(
                            label: Text(_selectedSubjectName ?? 'Subject'),
                            deleteIcon: const Icon(
                              Iconsax.close_circle_outline,
                              size: 18,
                            ),
                            onDeleted: () {
                              setState(() {
                                _selectedSubjectId = null;
                                _selectedSubjectName = null;
                              });
                              _loadFeed();
                            },
                            backgroundColor:
                                theme.colorScheme.secondaryContainer,
                          ),
                      ],
                    ),
                  ),
                ),

              _buildFeedContent(theme, _gradeId, _medium),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedContent(ThemeData theme, String? gradeId, String? medium) {
    if (_isLoading) return _buildShimmerList(theme);

    if (_feedFilter == 'all' ||
        (_feedFilter == 'subject' && _selectedSubjectId != null) ||
        ['question', 'resource', 'poll', 'verified'].contains(_feedFilter)) {
      Stream<List<PostModel>> stream;

      switch (_feedFilter) {
        case 'question':
        case 'resource':
          stream = _apiService.getPostsByCategoryStream(
            category: _feedFilter,
            gradeId: gradeId,
            medium: medium,
          );
          break;
        case 'poll':
          stream = _apiService.getPollPostsStream(
            gradeId: gradeId,
            medium: medium,
          );
          break;
        case 'verified':
          stream = _apiService.getVerifiedPostsStream(
            gradeId: gradeId,
            medium: medium,
          );
          break;
        case 'subject':
          stream = _apiService.getPostsBySubjectStream(
            subjectId: _selectedSubjectId!,
            gradeId: gradeId,
            medium: medium,
          );
          break;
        default:
          stream = _apiService.getFeedPostsStream(
            gradeId: gradeId,
            medium: medium,
          );
      }

      return StreamBuilder<List<PostModel>>(
        stream: stream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              _posts.isEmpty) {
            return _buildShimmerList(theme);
          }
          if (snapshot.hasError) {
            return SliverToBoxAdapter(
              child: Center(child: Text('Error: ${snapshot.error}')),
            );
          }

          final posts = snapshot.data ?? [];
          if (posts.isEmpty) return _buildEmptyState(theme);

          return SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final post = posts[index];
              return Column(
                children: [
                  TweetPostWidget(
                    post: post,
                    onTap: () async {
                      await context.push(
                        AppRouter.postDetailPath.replaceFirst(
                          ':postId',
                          post.postId,
                        ),
                      );
                      if (mounted && _feedFilter != 'all') {
                        _loadFeed();
                      }
                    },
                  ),
                  Divider(height: 1, thickness: 1, color: theme.dividerColor),
                ],
              );
            }, childCount: posts.length),
          );
        },
      );
    }

    if (_posts.isEmpty) return _buildEmptyState(theme);

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final post = _posts[index];
        return Column(
          children: [
            TweetPostWidget(
              post: post,
              onTap: () async {
                await context.push(
                  AppRouter.postDetailPath.replaceFirst(':postId', post.postId),
                );
                if (mounted) _loadFeed();
              },
            ),
            Divider(height: 1, thickness: 1, color: theme.dividerColor),
          ],
        );
      }, childCount: _posts.length),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    return SliverFillRemaining(
      hasScrollBody: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 40.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 200.w,
                  height: 200.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        theme.primaryColor.withValues(alpha: 0.15),
                        theme.primaryColor.withValues(alpha: 0.0),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 140.w,
                  height: 140.w,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? Colors.grey.shade900 : Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: theme.primaryColor.withValues(alpha: 0.1),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Icon(
                    Iconsax.messages_2_outline,
                    size: 60.sp,
                    color: theme.primaryColor,
                  ),
                ),
                Positioned(
                  right: 10.w,
                  top: 10.h,
                  child: Container(
                    padding: EdgeInsets.all(8.sp),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Iconsax.add_outline,
                      size: 20.sp,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 48.h),

            Text(
              'No Posts Yet',
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -1,
                color: isDark ? Colors.white : const Color(0xFF0B1C2C),
              ),
              textAlign: TextAlign.center,
            ),

            SizedBox(height: 16.h),

            Text(
              'Be the first one to start a conversation in your community! Share your thoughts or ask a question.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                height: 1.5,
                fontSize: 15.sp,
              ),
            ),

            SizedBox(height: 48.h),

            Container(
              width: double.infinity,
              height: 56.h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12.r),
                gradient: LinearGradient(
                  colors: [
                    theme.primaryColor,
                    theme.primaryColor.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () async {
                  final result = await context.push(AppRouter.createPostPath);
                  if (result == true && mounted) {
                    _loadFeed();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Iconsax.edit_2_outline, size: 20.sp),
                    SizedBox(width: 12.w),
                    Text(
                      'Create New Post',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SizedBox(height: 16.h),

            OutlinedButton(
              onPressed: () => context.push(AppRouter.searchUsersPath),
              style: OutlinedButton.styleFrom(
                minimumSize: Size(double.infinity, 56.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                side: BorderSide(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                ),
              ),
              child: Text(
                'Explore Everything',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmerList(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade900 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => Shimmer.fromColors(
          baseColor: baseColor,
          highlightColor: highlightColor,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(backgroundColor: Colors.white, radius: 20.r),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            height: 12.h,
                            width: 100.w,
                            color: Colors.white,
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            height: 12.h,
                            width: 60.w,
                            color: Colors.white,
                          ),
                        ],
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        height: 10.h,
                        width: double.infinity,
                        color: Colors.white,
                      ),
                      SizedBox(height: 4.h),
                      Container(
                        height: 10.h,
                        width: 200.w,
                        color: Colors.white,
                      ),
                      SizedBox(height: 12.h),
                      if (index % 2 == 0) ...[
                        Container(
                          height: 150.h,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        SizedBox(height: 12.h),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: List.generate(
                          4,
                          (i) => Container(
                            height: 16.h,
                            width: 16.w,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
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
        ),
        childCount: 6,
      ),
    );
  }
}
