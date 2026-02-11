import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:math/core/models/user_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:icons_plus/icons_plus.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  List<UserModel> _topUsers = [];
  UserModel? _currentUserModel;
  int _currentUserRank = 0;

  @override
  void initState() {
    super.initState();
    _loadLeaderboardData();
  }

  Future<void> _loadLeaderboardData() async {
    if (mounted) setState(() => _isLoading = true);

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.user;
      if (currentUser == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      // 1. Get current user's full data (for points)
      final userDoc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get();
      if (!userDoc.exists) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      final userData = userDoc.data()!;
      _currentUserModel = UserModel.fromJson(userData);
      final int currentUserPoints = _currentUserModel?.points ?? 0;

      // 2. Fetch leaderboard and rank in parallel
      final results = await Future.wait([
        _apiService.getLeaderboard(),
        _apiService.getUserRank(currentUserPoints),
      ]);

      if (mounted) {
        setState(() {
          _topUsers = results[0] as List<UserModel>;
          _currentUserRank = results[1] as int;
          _isLoading = false;
        });
      }
    } catch (e, s) {
      logger.e('Failed to load leaderboard data', error: e, stackTrace: s);
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final String currentUserId =
        Provider.of<AuthService>(context, listen: false).user?.uid ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              // 🚀 UPDATED: App Bar with Theme Style
              SliverAppBar(
                expandedHeight: 380.h,
                floating: false,
                pinned: true,
                backgroundColor: isDark
                    ? const Color(0xFF0F172A)
                    : theme.primaryColor,
                leading: IconButton(
                  icon: const Icon(
                    Icons.arrow_back_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () => context.pop(),
                ),
                title: Text(
                  'Leaderboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 20.sp,
                  ),
                ),
                centerTitle: true,
                flexibleSpace: FlexibleSpaceBar(
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
                                theme.primaryColor,
                                theme.primaryColor.withValues(alpha: 0.8),
                              ],
                      ),
                    ),
                    child: Stack(
                      alignment: Alignment.bottomCenter,
                      children: [
                        // Decorative Background Icon
                        Positioned(
                          right: -40,
                          top: -40,
                          child: Icon(
                            Iconsax.cup_outline,
                            size: 300.sp,
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),

                        // Podium for Top 3
                        if (!_isLoading && _topUsers.isNotEmpty)
                          Padding(
                            padding: EdgeInsets.only(bottom: 40.h),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                if (_topUsers.length >= 2) ...[
                                  _buildPodiumUser(
                                    context,
                                    _topUsers[1],
                                    2,
                                    140.h,
                                  ),
                                  SizedBox(width: 12.w),
                                ],
                                _buildPodiumUser(
                                  context,
                                  _topUsers[0],
                                  1,
                                  180.h,
                                ),
                                if (_topUsers.length >= 3) ...[
                                  SizedBox(width: 12.w),
                                  _buildPodiumUser(
                                    context,
                                    _topUsers[2],
                                    3,
                                    120.h,
                                  ),
                                ],
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),

              // Title Header
              if (!_isLoading && _topUsers.length > 3)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 12.h),
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.ranking_outline,
                          color: theme.primaryColor,
                          size: 24.sp,
                        ),
                        SizedBox(width: 12.w),
                        Text(
                          'All Rankings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              if (_isLoading)
                _buildShimmerBody(theme)
              else if (_topUsers.isEmpty)
                _buildEmptyStateBody(theme)
              else
                SliverPadding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
                      if (index <
                          (_topUsers.length < 3 ? _topUsers.length : 3)) {
                        return const SizedBox.shrink(); // Already in podium
                      }
                      final user = _topUsers[index];
                      final rank = index + 1;
                      final bool isCurrentUser = (user.uid == currentUserId);

                      return Padding(
                        padding: EdgeInsets.only(bottom: 12.h),
                        child: _buildRankTile(theme, user, rank, isCurrentUser),
                      );
                    }, childCount: _topUsers.length),
                  ),
                ),

              SliverToBoxAdapter(child: SizedBox(height: 120.h)),
            ],
          ),

          // User's Floating Rank Card
          if (!_isLoading && _currentUserModel != null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _buildFloatingUserCard(
                theme,
                _currentUserModel!,
                _currentUserRank,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumUser(
    BuildContext context,
    UserModel user,
    int rank,
    double height,
  ) {
    Color crownColor = rank == 1
        ? const Color(0xFFFFD700) // Gold
        : (rank == 2
              ? const Color(0xFFC0C0C0)
              : const Color(0xFFCD7F32)); // Silver, Bronze

    double avatarSize = rank == 1 ? 40.r : 30.r;

    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Stack(
          alignment: Alignment.topCenter,
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: crownColor, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: crownColor.withValues(alpha: 0.3),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: CircleAvatar(
                radius: avatarSize,
                backgroundImage: user.photoURL != null
                    ? CachedNetworkImageProvider(user.photoURL!)
                    : null,
                child: user.photoURL == null
                    ? Icon(
                        Icons.person,
                        color: Colors.grey.shade400,
                        size: avatarSize,
                      )
                    : null,
              ),
            ),
            if (rank == 1)
              Positioned(
                top: -24.h,
                child: Icon(
                  Iconsax.crown_bold,
                  color: Colors.amber,
                  size: 32.sp,
                ),
              ),
          ],
        ),
        SizedBox(height: 8.h),
        SizedBox(
          width: 90.w,
          child: Text(
            user.displayName.split(' ')[0],
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 13.sp,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Text(
            '${user.points} pts',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        SizedBox(height: 12.h),

        // Podium Block
        Container(
          width: 80.w,
          height: height,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withValues(alpha: 0.25),
                Colors.white.withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(16.r),
              topRight: Radius.circular(16.r),
            ),
            border: Border(
              top: BorderSide(
                color: Colors.white.withValues(alpha: 0.3),
                width: 1,
              ),
              left: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
          ),
          child: Center(
            child: Text(
              '$rank',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 48.sp,
                fontWeight: FontWeight.w900,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingUserCard(ThemeData theme, UserModel user, int rank) {
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 30.h),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.98)
            : Colors.white.withValues(alpha: 0.98),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(32.r),
          topRight: Radius.circular(32.r),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : theme.primaryColor.withValues(alpha: 0.1),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            decoration: BoxDecoration(
              color: theme.primaryColor,
              borderRadius: BorderRadius.circular(16.r),
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Text(
                  '#',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                ),
                Text(
                  '$rank',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18.sp,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          CircleAvatar(
            radius: 24.r,
            backgroundImage: user.photoURL != null
                ? CachedNetworkImageProvider(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Icon(Icons.person, color: Colors.white)
                : null,
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Standing',
                  style: TextStyle(
                    color: theme.disabledColor,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  '${user.points} Points',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(8.w),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Iconsax.trend_up_outline,
              color: Colors.green,
              size: 20.sp,
            ),
          ),
        ],
      ),
    );
  }

  // --- 🚀 SHIMMER WIDGETS 🚀 ---

  Widget _buildShimmerBody(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final baseColor = isDark ? Colors.grey.shade900 : Colors.grey.shade300;
    final highlightColor = isDark ? Colors.grey.shade800 : Colors.grey.shade100;

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          return Shimmer.fromColors(
            baseColor: baseColor,
            highlightColor: highlightColor,
            child: Container(
              margin: EdgeInsets.only(bottom: 12.h),
              padding: EdgeInsets.all(4.w), // Simulate the border/padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Row(
                children: [
                  // Left Box Shimmer
                  Container(
                    width: 60.w,
                    height: 80.h,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                  ),
                  SizedBox(width: 16.w),

                  // Avatar Shimmer
                  Container(
                    width: 40.r,
                    height: 40.r,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 12.w),

                  // Text Shimmer
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 100.w,
                          height: 16.h,
                          color: Colors.white,
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          width: 60.w,
                          height: 12.h,
                          color: Colors.white,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }, childCount: 8),
      ),
    );
  }

  Widget _buildEmptyStateBody(ThemeData theme) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.profile_2user_outline,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              'No Players Yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              'Be the first to get on the leaderboard!',
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRankTile(
    ThemeData theme,
    UserModel user,
    int rank,
    bool isCurrentUser,
  ) {
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E293B).withValues(alpha: 0.5)
            : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isCurrentUser
              ? theme.primaryColor
              : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.transparent),
          width: isCurrentUser ? 1.5 : 1,
        ),
        boxShadow: [
          if (!isDark && !isCurrentUser)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          if (isCurrentUser)
            BoxShadow(
              color: theme.primaryColor.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        children: [
          // Left Visual: Rank Box
          Container(
            width: 60.w,
            height: 80.h,
            decoration: BoxDecoration(
              color: isCurrentUser
                  ? theme.primaryColor.withValues(alpha: 0.1)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(16.r),
                bottomLeft: Radius.circular(16.r),
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '#$rank',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18.sp,
                      color: isCurrentUser
                          ? theme.primaryColor
                          : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  if (rank <= 10)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Icon(
                        Iconsax.medal_star_bold,
                        size: 14.sp,
                        color: rank == 1
                            ? Colors.amber
                            : (rank == 2 ? Colors.grey : Colors.orangeAccent),
                      ),
                    ),
                ],
              ),
            ),
          ),

          SizedBox(width: 16.w),

          // User Info
          CircleAvatar(
            radius: 20.r,
            backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: user.photoURL != null
                ? CachedNetworkImageProvider(user.photoURL!)
                : null,
            child: user.photoURL == null
                ? Icon(
                    Iconsax.user_outline,
                    size: 20.sp,
                    color: theme.primaryColor,
                  )
                : null,
          ),

          SizedBox(width: 12.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (isCurrentUser)
                  Text(
                    'You',
                    style: TextStyle(
                      color: theme.primaryColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    'Learner',
                    style: TextStyle(
                      color: theme.disabledColor,
                      fontSize: 11.sp,
                    ),
                  ),
              ],
            ),
          ),

          // Points
          Padding(
            padding: EdgeInsets.only(right: 16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${user.points}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16.sp,
                    color: theme.primaryColor,
                  ),
                ),
                Text(
                  'pts',
                  style: TextStyle(fontSize: 10.sp, color: theme.disabledColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
