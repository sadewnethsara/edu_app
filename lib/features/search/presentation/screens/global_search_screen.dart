import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:animate_do/animate_do.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/core/models/lesson_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:provider/provider.dart';

class GlobalSearchScreen extends StatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  State<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends State<GlobalSearchScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  final CommunityService _communityService = CommunityService();
  final SocialService _socialService = SocialService();

  late TabController _tabController;
  Timer? _debounce;

  // Search States
  List<PostModel> _posts = [];
  List<UserModel> _people = [];
  List<CommunityModel> _communities = [];
  List<LessonModel> _lessons = [];
  List<Map<String, dynamic>> _tags = [];

  bool _isLoading = false;
  String _selectedContentType = 'All'; // All, Text, Images, Videos, Polls
  String _selectedSort = 'Newest'; // Newest, Popular, Helpful

  final List<String> _categories = [
    'All',
    'Posts',
    'Communities',
    'People',
    'Lessons',
    'Tags',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _categories.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        FocusScope.of(context).unfocus();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () {
      _performSearch(query);
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _apiService.searchPosts(
          query: query,
          contentType: _selectedContentType == 'All'
              ? null
              : _selectedContentType.toLowerCase(),
          sortBy: _selectedSort.toLowerCase(),
        ),
        _apiService.searchUsers(query),
        _communityService.searchCommunities(query),
        _apiService.searchLessons(
          query,
          'en',
        ), // Default to en or get from prefs
        _socialService.searchTags(query),
      ]);

      if (mounted) {
        setState(() {
          _posts = results[0] as List<PostModel>;
          _people = results[1] as List<UserModel>;
          _communities = results[2] as List<CommunityModel>;
          _lessons = results[3] as List<LessonModel>;
          _tags = results[4] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildFilterBottomSheet(),
    ).then((_) => _performSearch(_searchController.text));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        toolbarHeight: 56.h,
        leadingWidth: 40.w,
        leading: IconButton(
          icon: const Icon(Iconsax.arrow_left_outline, size: 20),
          onPressed: () => context.pop(),
        ),
        title: _buildSearchBar(theme),
        actions: [
          IconButton(
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            icon: Icon(
              Iconsax.filter_edit_outline,
              color: theme.primaryColor,
              size: 20.sp,
            ),
            onPressed: _showFilterSheet,
          ),
          SizedBox(width: 12.w),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(40.h),
          child: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: theme.primaryColor,
                unselectedLabelColor: theme.disabledColor,
                indicatorColor: theme.primaryColor,
                indicatorWeight: 2,
                labelPadding: EdgeInsets.symmetric(horizontal: 16.w),
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Outfit',
                ),
                unselectedLabelStyle: TextStyle(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Outfit',
                ),
                tabs: _categories
                    .map((cat) => Tab(text: cat, height: 35.h))
                    .toList(),
                dividerColor: Colors.transparent,
              ),
              const Divider(height: 1, thickness: 0.5),
            ],
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildAllResults(theme),
          _buildPostsResults(theme),
          _buildCommunitiesResults(theme),
          _buildPeopleResults(theme),
          _buildLessonsResults(theme),
          _buildTagsResults(theme),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ThemeData theme) {
    return Container(
      height: 40.h,
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(10.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.08)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        autofocus: true,
        style: TextStyle(fontSize: 14.sp),
        decoration: InputDecoration(
          hintText: "Search anything...",
          hintStyle: TextStyle(color: theme.disabledColor, fontSize: 14.sp),
          prefixIcon: Icon(
            Iconsax.search_normal_outline,
            size: 18.sp,
            color: theme.primaryColor,
          ),
          suffixIcon: _isLoading
              ? Transform.scale(
                  scale: 0.4,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                )
              : _searchController.text.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.close_rounded, size: 18.sp),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(vertical: 10.h),
        ),
      ),
    );
  }

  Widget _buildFilterBottomSheet() {
    final theme = Theme.of(context);
    return StatefulBuilder(
      builder: (context, setModalState) {
        return Container(
          padding: EdgeInsets.all(24.w),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32.r)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2.r),
                  ),
                ),
              ),
              SizedBox(height: 24.h),
              Text(
                "Filter Search",
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 24.h),
              _buildFilterSection(
                theme,
                "Content Type",
                ['All', 'Text', 'Images', 'Videos', 'Polls'],
                _selectedContentType,
                (val) => setModalState(() => _selectedContentType = val!),
              ),
              SizedBox(height: 24.h),
              _buildFilterSection(
                theme,
                "Sort By",
                ['Newest', 'Popular', 'Helpful'],
                _selectedSort,
                (val) => setModalState(() => _selectedSort = val!),
              ),
              SizedBox(height: 32.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.primaryColor,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: 16.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  child: const Text("Apply Filters"),
                ),
              ),
              SizedBox(height: 16.h),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilterSection(
    ThemeData theme,
    String title,
    List<String> options,
    String selected,
    void Function(String?) onSelected,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.disabledColor,
          ),
        ),
        SizedBox(height: 12.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: options.map((opt) {
            final isSelected = opt == selected;
            return ChoiceChip(
              label: Text(opt),
              selected: isSelected,
              onSelected: (s) => onSelected(s ? opt : null),
              selectedColor: theme.primaryColor.withValues(alpha: 0.1),
              checkmarkColor: theme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected
                    ? theme.primaryColor
                    : theme.textTheme.bodyMedium?.color,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              backgroundColor: theme.cardColor,
              side: BorderSide.none,
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
            );
          }).toList(),
        ),
      ],
    );
  }

  // --- Result Builders ---

  Widget _buildAllResults(ThemeData theme) {
    if (_searchController.text.isEmpty) return _buildInitialState(theme);
    if (_isLoading) return const Center(child: CircularProgressIndicator());

    final hasResults =
        _posts.isNotEmpty ||
        _communities.isNotEmpty ||
        _people.isNotEmpty ||
        _lessons.isNotEmpty;
    if (!hasResults) return _buildNoResults(theme);

    return ListView(
      padding: EdgeInsets.all(16.w),
      children: [
        if (_communities.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            "Communities",
            () => _tabController.animateTo(2),
          ),
          _buildHorizontalCommunities(theme),
          SizedBox(height: 24.h),
        ],
        if (_people.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            "People",
            () => _tabController.animateTo(3),
          ),
          _buildHorizontalPeople(theme),
          SizedBox(height: 24.h),
        ],
        if (_posts.isNotEmpty) ...[
          _buildSectionHeader(
            theme,
            "Top Posts",
            () => _tabController.animateTo(1),
          ),
          ..._posts
              .take(5)
              .map(
                (p) => Column(
                  children: [
                    TweetPostWidget(post: p, isMinimal: true),
                    _buildDivider(theme),
                  ],
                ),
              ),
        ],
      ],
    );
  }

  Widget _buildPostsResults(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_posts.isEmpty) return _buildNoResults(theme);
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      itemCount: _posts.length,
      itemBuilder: (c, i) => Column(
        children: [
          TweetPostWidget(post: _posts[i], isMinimal: true),
          if (i < _posts.length - 1) _buildDivider(theme),
        ],
      ),
    );
  }

  Widget _buildCommunitiesResults(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_communities.isEmpty) return _buildNoResults(theme);
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _communities.length,
      separatorBuilder: (c, i) => SizedBox(height: 12.h),
      itemBuilder: (c, i) => _buildCommunityTile(theme, _communities[i]),
    );
  }

  Widget _buildPeopleResults(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_people.isEmpty) return _buildNoResults(theme);
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _people.length,
      separatorBuilder: (c, i) => SizedBox(height: 12.h),
      itemBuilder: (c, i) => _buildUserTile(theme, _people[i]),
    );
  }

  Widget _buildLessonsResults(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_lessons.isEmpty) return _buildNoResults(theme);
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _lessons.length,
      separatorBuilder: (c, i) => SizedBox(height: 12.h),
      itemBuilder: (c, i) => _buildLessonTile(theme, _lessons[i]),
    );
  }

  Widget _buildTagsResults(ThemeData theme) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_tags.isEmpty) return _buildNoResults(theme);
    return ListView.separated(
      padding: EdgeInsets.all(16.w),
      itemCount: _tags.length,
      separatorBuilder: (c, i) =>
          Divider(height: 1, color: theme.dividerColor.withValues(alpha: 0.1)),
      itemBuilder: (c, i) {
        final tagData = _tags[i];
        final tagName = tagData['tag'] as String;
        final count = tagData['useCount'] as int? ?? 0;
        return ListTile(
          onTap: () => context.push('/tags/$tagName'),
          leading: Container(
            padding: EdgeInsets.all(8.r),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.hashtag_outline,
              color: theme.primaryColor,
              size: 20.sp,
            ),
          ),
          title: Text(
            "#$tagName",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(
            "$count posts",
            style: TextStyle(color: theme.disabledColor, fontSize: 12.sp),
          ),
          trailing: const Icon(Icons.arrow_forward_ios, size: 14),
        );
      },
    );
  }

  // --- Sub UI Elements ---

  Widget _buildSectionHeader(
    ThemeData theme,
    String title,
    VoidCallback onSeeAll,
  ) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          TextButton(
            onPressed: onSeeAll,
            child: Text("See All", style: TextStyle(color: theme.primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalCommunities(ThemeData theme) {
    return SizedBox(
      height: 150.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _communities.length,
        itemBuilder: (context, index) {
          final community = _communities[index];
          return FadeInRight(
            delay: Duration(milliseconds: index * 100),
            child: GestureDetector(
              onTap: () => context.push('/community/${community.id}'),
              child: Container(
                width: 130.w,
                margin: EdgeInsets.only(right: 12.w),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(16.r),
                  border: Border.all(
                    color: theme.dividerColor.withValues(alpha: 0.1),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 30.r,
                      backgroundImage: community.iconUrl != null
                          ? CachedNetworkImageProvider(community.iconUrl!)
                          : null,
                      child: community.iconUrl == null
                          ? const Icon(Iconsax.people_outline)
                          : null,
                    ),
                    SizedBox(height: 12.h),
                    Text(
                      community.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      "${community.memberCount} members",
                      style: TextStyle(
                        color: theme.disabledColor,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHorizontalPeople(ThemeData theme) {
    return SizedBox(
      height: 100.h,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _people.length,
        itemBuilder: (context, index) {
          final user = _people[index];
          return Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Column(
              children: [
                CircleAvatar(
                  radius: 30.r,
                  backgroundImage:
                      user.photoURL != null && user.photoURL!.isNotEmpty
                      ? CachedNetworkImageProvider(user.photoURL!)
                      : null,
                  child: user.photoURL == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                SizedBox(height: 8.h),
                SizedBox(
                  width: 70.w,
                  child: Text(
                    user.displayName,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommunityTile(ThemeData theme, CommunityModel community) {
    return ListTile(
      onTap: () => context.push('/community/${community.id}'),
      leading: CircleAvatar(
        radius: 24.r,
        backgroundImage: community.iconUrl != null
            ? CachedNetworkImageProvider(community.iconUrl!)
            : null,
        child: community.iconUrl == null
            ? const Icon(Iconsax.people_outline)
            : null,
      ),
      title: Text(
        community.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "${community.memberCount} members • ${community.description}",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 12.sp),
      ),
      trailing: Consumer<AuthService>(
        builder: (context, auth, _) {
          final user = auth.user;
          if (user == null) {
            return _buildJoinButton(theme, "Join", () {});
          }
          return FutureBuilder<bool>(
            future: _communityService.isMember(community.id, user.uid),
            builder: (context, snapshot) {
              final isJoined = snapshot.data ?? false;
              return _buildJoinButton(
                theme,
                isJoined ? "Joined" : "Join",
                isJoined
                    ? null
                    : () async {
                        await _communityService.joinCommunity(
                          community.id,
                          user.uid,
                        );
                        _performSearch(_searchController.text);
                      },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildJoinButton(ThemeData theme, String label, VoidCallback? onTap) {
    final isJoined = label == "Joined";
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: isJoined
            ? theme.disabledColor.withValues(alpha: 0.1)
            : theme.primaryColor,
        foregroundColor: isJoined ? theme.disabledColor : Colors.white,
        elevation: 0,
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        minimumSize: Size(70.w, 32.h),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
          side: isJoined
              ? BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))
              : BorderSide.none,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: isJoined ? FontWeight.normal : FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildDivider(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          const Spacer(),
          Container(
            width: 0.6.sw,
            height: 0.5,
            color: theme.dividerColor.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(ThemeData theme, UserModel user) {
    return ListTile(
      leading: CircleAvatar(
        radius: 24.r,
        backgroundImage: user.photoURL != null && user.photoURL!.isNotEmpty
            ? CachedNetworkImageProvider(user.photoURL!)
            : null,
        child: user.photoURL == null ? const Icon(Icons.person) : null,
      ),
      title: Text(
        user.displayName,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(
        "${user.points} points",
        style: TextStyle(fontSize: 12.sp),
      ),
      trailing: IconButton(
        icon: const Icon(Iconsax.user_add_outline),
        onPressed: () {}, // Follow logic
      ),
    );
  }

  Widget _buildLessonTile(ThemeData theme, LessonModel lesson) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(10.r),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(Iconsax.book_1_outline, color: theme.primaryColor),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lesson.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  lesson.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12.sp, color: theme.disabledColor),
                ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 14),
        ],
      ),
    );
  }

  Widget _buildInitialState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_status_outline,
            size: 80.sp,
            color: theme.disabledColor.withValues(alpha: 0.2),
          ),
          SizedBox(height: 24.h),
          Text(
            "Search for anything",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Posts, People, Communities, and more",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoResults(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.search_favorite_outline,
            size: 80.sp,
            color: theme.disabledColor.withValues(alpha: 0.2),
          ),
          SizedBox(height: 24.h),
          Text(
            "No results found",
            style: theme.textTheme.titleLarge?.copyWith(
              color: theme.disabledColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Try adjusting your filters or search terms",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.disabledColor,
            ),
          ),
        ],
      ),
    );
  }
}
