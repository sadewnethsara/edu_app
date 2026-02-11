import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:provider/provider.dart';
import 'package:math/core/router/app_router.dart';
import 'package:go_router/go_router.dart';
import 'package:animate_do/animate_do.dart';

enum PostSort { latest, oldest, popular, trending }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with TickerProviderStateMixin {
  PostCategory? _selectedCategory;
  PostSort _selectedSort = PostSort.latest;
  late TabController _tabController;

  final List<PostCategory> _categories = [
    PostCategory.general,
    PostCategory.question,
    PostCategory.discussion,
    PostCategory.resource,
    PostCategory.achievement,
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length + 1, vsync: this);
    _tabController.addListener(_handleTabSelection);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      setState(() {
        if (_tabController.index == 0) {
          _selectedCategory = null;
        } else {
          _selectedCategory = _categories[_tabController.index - 1];
        }
      });
    }
  }

  // Sync tab if category changed externally (e.g. filter sheet)
  void _updateTabFromCategory() {
    if (_selectedCategory == null) {
      _tabController.animateTo(0);
    } else {
      final index = _categories.indexOf(_selectedCategory!);
      if (index != -1) {
        _tabController.animateTo(index + 1);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = context.read<AuthService>().user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Saved Posts')),
        body: const Center(child: Text('Please login to view saved posts')),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: isDark ? Colors.black : const Color(0xFF0B1C2C),
        elevation: 0,
        title: Text(
          'Saved Posts',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            onPressed: () => _showFilterSheet(theme),
            icon: Icon(
              _selectedCategory != null || _selectedSort != PostSort.latest
                  ? Iconsax.filter_edit_outline
                  : Iconsax.filter_outline,
              color: Colors.white,
            ),
          ),
          SizedBox(width: 8.w),
        ],
      ),
      body: Column(
        children: [
          _buildTabs(theme),
          Expanded(
            child: StreamBuilder<List<String>>(
              stream: SocialService().getFavoritePostIdsStream(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final ids = snapshot.data ?? [];
                if (ids.isEmpty) {
                  return _buildEmptyState(theme, isDark);
                }

                return FutureBuilder<List<PostModel>>(
                  future: SocialService().getPosts(ids),
                  builder: (context, postSnapshot) {
                    if (postSnapshot.connectionState ==
                            ConnectionState.waiting &&
                        !postSnapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    List<PostModel> posts = postSnapshot.data ?? [];

                    // Apply Category Filter
                    if (_selectedCategory != null) {
                      posts = posts
                          .where((p) => p.category == _selectedCategory)
                          .toList();
                    }

                    // Apply Sorting
                    posts.sort((a, b) {
                      switch (_selectedSort) {
                        case PostSort.latest:
                          return b.createdAt.compareTo(a.createdAt);
                        case PostSort.oldest:
                          return a.createdAt.compareTo(b.createdAt);
                        case PostSort.popular:
                          return b.likeCount.compareTo(a.likeCount);
                        case PostSort.trending:
                          final scoreA = a.likeCount + a.replyCount;
                          final scoreB = b.likeCount + b.replyCount;
                          return scoreB.compareTo(scoreA);
                      }
                    });

                    if (posts.isEmpty && _selectedCategory != null) {
                      return _buildNoResultsState(theme);
                    }

                    return ListView.builder(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      itemCount: posts.length,
                      itemBuilder: (context, index) {
                        final post = posts[index];
                        return FadeInUp(
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          child: TweetPostWidget(
                            post: post,
                            onTap: () => context.push(
                              AppRouter.postDetailPath.replaceFirst(
                                ':postId',
                                post.postId,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabs(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        color:
            theme.appBarTheme.backgroundColor?.withOpacity(0.8) ??
            (theme.brightness == Brightness.dark
                ? Colors.black
                : const Color(0xFF0B1C2C)),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20.r),
          bottomRight: Radius.circular(20.r),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        indicatorColor: theme.primaryColor,
        indicatorWeight: 3,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white60,
        labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.normal,
          fontSize: 14.sp,
        ),
        tabs: [
          const Tab(text: 'All Posts'),
          ..._categories.map((c) => Tab(text: _getCategoryName(c))),
        ],
      ),
    );
  }

  String _getCategoryName(PostCategory c) {
    return c.name[0].toUpperCase() + c.name.substring(1);
  }

  Widget _buildEmptyState(ThemeData theme, bool isDark) {
    return Center(
      child: FadeIn(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.archive_add_outline,
              size: 80.sp,
              color: theme.primaryColor.withValues(alpha: 0.3),
            ),
            SizedBox(height: 16.h),
            Text(
              'No saved posts yet',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Save interesting posts to read them later',
              style: TextStyle(
                fontSize: 14.sp,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_status_outline,
            size: 60.sp,
            color: theme.disabledColor,
          ),
          SizedBox(height: 16.h),
          Text(
            "No saved posts in this category",
            style: TextStyle(color: theme.disabledColor),
          ),
          TextButton(
            onPressed: () => setState(() => _selectedCategory = null),
            child: Text("Clear Filter"),
          ),
        ],
      ),
    );
  }

  void _showFilterSheet(ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: theme.scaffoldBackgroundColor,
                borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
              ),
              padding: EdgeInsets.all(24.w),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Sort & Filter",
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _selectedCategory = null;
                            _selectedSort = PostSort.latest;
                          });
                          _updateTabFromCategory();
                          Navigator.pop(context);
                        },
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text(
                    "Sort By",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.disabledColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    children: PostSort.values.map((sort) {
                      final isSelected = _selectedSort == sort;
                      return ChoiceChip(
                        label: Text(_getSortName(sort)),
                        selected: isSelected,
                        onSelected: (val) {
                          setSheetState(() => _selectedSort = sort);
                          setState(() => _selectedSort = sort);
                        },
                      );
                    }).toList(),
                  ),
                  SizedBox(height: 24.h),
                  Text(
                    "Category",
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: theme.disabledColor,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Wrap(
                    spacing: 8.w,
                    children: [
                      _buildSheetFilterChip(null, "All", setSheetState, theme),
                      ..._categories.map(
                        (c) => _buildSheetFilterChip(
                          c,
                          _getCategoryName(c),
                          setSheetState,
                          theme,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 32.h),
                  SizedBox(
                    width: double.infinity,
                    height: 50.h,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16.r),
                        ),
                      ),
                      child: const Text(
                        "Apply Filters",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: MediaQuery.of(context).padding.bottom),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSheetFilterChip(
    PostCategory? category,
    String label,
    StateSetter setSheetState,
    ThemeData theme,
  ) {
    final isSelected = _selectedCategory == category;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (val) {
        setSheetState(() => _selectedCategory = category);
        setState(() => _selectedCategory = category);
        _updateTabFromCategory();
      },
    );
  }

  String _getSortName(PostSort sort) {
    switch (sort) {
      case PostSort.latest:
        return "Latest";
      case PostSort.oldest:
        return "Oldest";
      case PostSort.popular:
        return "Popular";
      case PostSort.trending:
        return "Trending";
    }
  }
}
