import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:provider/provider.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/widgets/message_banner.dart';

class SearchUsersScreen extends StatefulWidget {
  const SearchUsersScreen({super.key});

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ApiService _apiService = ApiService();
  Timer? _debounce;
  List<UserModel> _searchResults = [];
  bool _isLoading = false;
  Set<String> _followingIds = {};

  @override
  void initState() {
    super.initState();
    _loadFollowingIds();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowingIds() async {
    final authService = context.read<AuthService>();
    final myUid = authService.user?.uid;
    if (myUid != null) {
      final users = await _apiService.getFollowingList(myUid);
      if (mounted) {
        setState(() {
          _followingIds = users.map((u) => u.uid).toSet();
        });
      }
    }
  }

  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (query.isNotEmpty) {
        _performSearch(query);
      } else {
        setState(() {
          _searchResults = [];
          _isLoading = false;
        });
      }
    });
  }

  Future<void> _performSearch(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    final results = await _apiService.searchUsers(query);

    final myUid = context.read<AuthService>().user?.uid;
    final filtered = results.where((u) => u.uid != myUid).toList();

    if (mounted) {
      setState(() {
        _searchResults = filtered;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleFollow(UserModel user) async {
    final authService = context.read<AuthService>();
    final myUid = authService.user?.uid;
    if (myUid == null) {
      MessageBanner.show(
        context,
        message: 'Please sign in to follow users',
        type: MessageType.warning,
      );
      return;
    }

    final isFollowing = _followingIds.contains(user.uid);

    setState(() {
      if (isFollowing) {
        _followingIds.remove(user.uid);
      } else {
        _followingIds.add(user.uid);
      }
    });

    try {
      if (isFollowing) {
        await _apiService.unfollowUser(myUid, user.uid);
      } else {
        await _apiService.followUser(myUid, user.uid);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          if (isFollowing) {
            _followingIds.add(user.uid);
          } else {
            _followingIds.remove(user.uid);
          }
        });
        MessageBanner.show(
          context,
          message: 'Failed to update follow status',
          type: MessageType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : Colors.white24,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: theme.iconTheme.color,
              size: 20.sp,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Find Friends",
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.textTheme.headlineSmall?.color,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                      : [const Color(0xFFF5F7FA), const Color(0xFFFFFFFF)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                SizedBox(height: 10.h),
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 8.h,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.cardColor,
                      borderRadius: BorderRadius.circular(24.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                      border: Border.all(
                        color: theme.dividerColor.withValues(alpha: 0.5),
                      ),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      style: theme.textTheme.bodyLarge,
                      decoration: InputDecoration(
                        hintText: "Search for users...",
                        hintStyle: TextStyle(
                          color: theme.hintColor,
                          fontSize: 14.sp,
                        ),
                        prefixIcon: Icon(
                          EvaIcons.search_outline,
                          color: theme.primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20.w,
                          vertical: 16.h,
                        ),
                        suffixIcon: _isLoading
                            ? Transform.scale(
                                scale: 0.4,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: theme.hintColor,
                                  size: 20.sp,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  _onSearchChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child:
                      _searchResults.isEmpty &&
                          _searchController.text.isNotEmpty &&
                          !_isLoading
                      ? _buildEmptyState(
                          theme,
                          EvaIcons.person_delete_outline,
                          "No users found",
                          "Try searching for a different name",
                        )
                      : _searchResults.isEmpty && _searchController.text.isEmpty
                      ? _buildEmptyState(
                          theme,
                          EvaIcons.people_outline,
                          "Discover People",
                          "Search for friends, teachers, and classmates",
                        )
                      : ListView.builder(
                          padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 20.h),
                          itemCount: _searchResults.length,
                          itemBuilder: (context, index) {
                            final user = _searchResults[index];
                            final isFollowing = _followingIds.contains(
                              user.uid,
                            );

                            return _buildUserTile(user, isFollowing, theme);
                          },
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(
    ThemeData theme,
    IconData icon,
    String title,
    String subtitle,
  ) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 48.sp, color: theme.primaryColor),
          ),
          SizedBox(height: 24.h),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user, bool isFollowing, ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.5)),
      ),
      child: Row(
        children: [
          Container(
            width: 56.w,
            height: 56.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: theme.scaffoldBackgroundColor,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(28.r),
              child: user.photoURL != null && user.photoURL!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.photoURL!,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: theme.disabledColor.withValues(alpha: 0.1),
                      ),
                      errorWidget: (context, url, error) =>
                          Icon(Icons.person, color: theme.disabledColor),
                    )
                  : Container(
                      color: theme.primaryColor.withValues(alpha: 0.1),
                      child: Center(
                        child: Text(
                          user.displayName.isNotEmpty
                              ? user.displayName[0].toUpperCase()
                              : '?',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.bold,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    if (user.grades.isNotEmpty) ...[
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 2.h,
                        ),
                        decoration: BoxDecoration(
                          color: theme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          user.grades.first,
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: theme.primaryColor,
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                    ],
                    Icon(EvaIcons.star, size: 14.sp, color: Colors.amber),
                    SizedBox(width: 4.w),
                    Text(
                      '${user.points}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: () => _toggleFollow(user),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              padding: EdgeInsets.symmetric(
                horizontal: isFollowing ? 16.w : 20.w,
                vertical: 10.h,
              ),
              decoration: BoxDecoration(
                color: isFollowing ? Colors.transparent : theme.primaryColor,
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: isFollowing ? theme.dividerColor : theme.primaryColor,
                  width: 1.5,
                ),
                boxShadow: isFollowing
                    ? []
                    : [
                        BoxShadow(
                          color: theme.primaryColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Text(
                isFollowing ? "Following" : "Follow",
                style: TextStyle(
                  color: isFollowing
                      ? theme.textTheme.bodyMedium?.color
                      : Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
