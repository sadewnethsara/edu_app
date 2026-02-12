import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/constants/achievements_data.dart';
import 'package:math/core/models/user_model.dart';

import 'package:math/features/shared/presentation/screens/follow_list_screen.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/features/settings/presentation/screens/settings_screen.dart';
import 'package:math/core/services/logger_service.dart';
import 'package:math/core/services/streak_service.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:math/features/profile/presentation/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = true;
  UserModel? _userModel;
  Map<String, int> _userAchievements = {};
  String _joinDate = '';

  late String _profileUserId; // The ID of the profile being viewed
  late String _currentUserId; // The ID of the person using the app
  bool _isCurrentUserProfile = false;
  bool _isFollowing = false;
  bool _isFollowLoading = false; // For the follow button

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final auth = Provider.of<AuthService>(context, listen: false);
      final currentUser = auth.user;

      if (currentUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      _currentUserId = currentUser.uid;
      _profileUserId = widget.userId ?? _currentUserId;
      _isCurrentUserProfile = (_profileUserId == _currentUserId);

      final userDoc = await _firestore
          .collection('users')
          .doc(_profileUserId)
          .get();
      if (!userDoc.exists) {
        setState(() => _isLoading = false);
        return;
      }

      final userData = userDoc.data()!;
      _userModel = UserModel.fromJson(userData);

      _userAchievements = _userModel!.achievements;
      _joinDate = _userModel!.createdAt != null
          ? DateFormat('MMMM yyyy').format(_userModel!.createdAt!.toDate())
          : 'Unknown';

      final results = await Future.wait([
        _apiService.getUserRank(_userModel!.points),
        _checkIfFollowing(),
      ]);

      _isFollowing = results[1] as bool;
    } catch (e) {
      logger.e('Error loading profile', error: e);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<bool> _checkIfFollowing() async {
    if (_isCurrentUserProfile) return false; // Can't follow self

    try {
      final followDoc = await _firestore
          .collection('users')
          .doc(_currentUserId)
          .collection('following')
          .doc(_profileUserId)
          .get();
      return followDoc.exists;
    } catch (e) {
      return false;
    }
  }

  Future<void> _toggleFollow() async {
    setState(() => _isFollowLoading = true);
    final authService = context.read<AuthService>();

    String? error;
    if (_isFollowing) {
      error = await authService.unfollowUser(_profileUserId);
      if (error == null) {
        setState(() => _isFollowing = false);
      }
    } else {
      error = await authService.followUser(_profileUserId);
      if (error == null) {
        setState(() => _isFollowing = true);
      }
    }

    if (error != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error), backgroundColor: Colors.red),
      );
    }

    if (mounted) setState(() => _isFollowLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        top: false,
        bottom: true,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildProfileBody(theme),
      ),
    );
  }

  Widget _buildProfileBody(ThemeData theme) {
    if (_userModel == null) {
      return CustomScrollView(
        slivers: [
          _buildEmptyState(theme, 'User Not Found', 'Could not load profile.'),
        ],
      );
    }

    final user = _userModel!;
    final streakService = context.watch<StreakService>();

    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(theme, user),
        SliverList(
          delegate: SliverChildListDelegate([
            Padding(
              padding: EdgeInsets.all(20.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeaderInfo(theme, user),
                  SizedBox(height: 24.h),

                  _buildStatsSection(theme, streakService, user),
                  SizedBox(height: 24.h),

                  _buildSectionHeader(
                    theme,
                    'Achievements',
                    EvaIcons.award_outline,
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(height: 12.h),
                  _buildAchievementsList(theme),
                  SizedBox(height: 24.h),

                  if (_isCurrentUserProfile) ...[],
                ],
              ),
            ),
          ]),
        ),
      ],
    );
  }

  Widget _buildSliverAppBar(ThemeData theme, UserModel user) {
    final isDark = theme.brightness == Brightness.dark;

    return SliverAppBar(
      expandedHeight: 120.h,
      floating: false,
      pinned: true,
      backgroundColor: isDark ? Colors.black : const Color(0xFF0B1C2C),
      leading: null,
      automaticallyImplyLeading: false, // Ensure no back button
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _isCurrentUserProfile ? "My Profile" : user.displayName,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
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
                right: -30,
                bottom: -30,
                child: Icon(
                  Icons.person,
                  size: 160.sp,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        if (_isCurrentUserProfile)
          IconButton(
            icon: const Icon(EvaIcons.settings_2_outline, color: Colors.white),
            tooltip: 'Settings',
            onPressed: () => Navigator.of(
              context,
              rootNavigator: true,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
      ],
    );
  }

  Widget _buildStatsSection(
    ThemeData theme,
    StreakService streakService,
    UserModel user,
  ) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            icon: EvaIcons
                .smiling_face_outline, // Use generic 'reward' or similar
            label: 'Streak',
            value: _isCurrentUserProfile
                ? '${streakService.currentStreak} 🔥'
                : '-',
            color: Colors.orange,
            theme: theme,
          ),
        ),
        SizedBox(width: 12.w),

        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FollowListScreen(
                    userId: _profileUserId,
                    listType: FollowListType.following,
                    initialUsername: user.displayName,
                  ),
                ),
              );
            },
            child: _StatCard(
              icon: EvaIcons.person_add_outline,
              label: 'Following',
              value: '${user.followingCount}',
              color: Colors.blue,
              theme: theme,
            ),
          ),
        ),
        SizedBox(width: 12.w),

        Expanded(
          child: GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => FollowListScreen(
                    userId: _profileUserId,
                    listType: FollowListType.followers,
                    initialUsername: user.displayName,
                  ),
                ),
              );
            },
            child: _StatCard(
              icon: EvaIcons.people_outline,
              label: 'Followers',
              value: '${user.followersCount}',
              color: Colors.purple,
              theme: theme,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: theme.primaryColor, size: 24.sp),
        SizedBox(width: 8.w),
        Text(
          title,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard(ThemeData theme, {required Widget child}) {
    final isDark = theme.brightness == Brightness.dark;
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.white.withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
          ),
          child: child,
        ),
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme, String title, String subtitle) {
    return SliverFillRemaining(
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_off_rounded,
              size: 80.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16.h),
            Text(
              title,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            Text(
              subtitle,
              style: theme.textTheme.titleMedium?.copyWith(
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeaderInfo(ThemeData theme, UserModel user) {
    return Column(
      children: [
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 50.r,
            backgroundColor: theme.canvasColor,
            child: CircleAvatar(
              radius: 46.r,
              backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
              backgroundImage: (user.photoURL != null)
                  ? CachedNetworkImageProvider(user.photoURL!)
                  : null,
              child: (user.photoURL == null)
                  ? Icon(
                      EvaIcons.person,
                      size: 46.sp,
                      color: theme.primaryColor,
                    )
                  : null,
            ),
          ),
        ),
        SizedBox(height: 16.h),

        Text(
          user.displayName,
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 4.h),
        Text(
          "Joined $_joinDate",
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.disabledColor,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: 24.h),

        Padding(
          padding: EdgeInsets.symmetric(horizontal: 40.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isCurrentUserProfile) ...[
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const EditProfileScreen(),
                        ),
                      ).then((_) => _loadData());
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text("Edit Profile"),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text("Share"),
                  ),
                ),
              ] else ...[
                Expanded(
                  child: FilledButton(
                    onPressed: _isFollowLoading ? null : _toggleFollow,
                    style: FilledButton.styleFrom(
                      backgroundColor: _isFollowing
                          ? theme.disabledColor
                          : theme.primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: _isFollowLoading
                        ? SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isFollowing ? "Following" : "Follow"),
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.primaryColor,
                      side: BorderSide(color: theme.primaryColor),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    child: const Text("Message"),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: 24.h),

        Container(
          padding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
          decoration: BoxDecoration(
            color: theme.cardColor.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: theme.dividerColor.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(theme, "${user.points}", "Points"),
              _buildVerticalDivider(theme),
              _buildStatItem(
                theme,
                "${user.followersCount}",
                "Followers",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FollowListScreen(
                        userId: _profileUserId,
                        listType: FollowListType.followers,
                        initialUsername: user.displayName,
                      ),
                    ),
                  );
                },
              ),
              _buildVerticalDivider(theme),
              _buildStatItem(
                theme,
                "${user.followingCount}",
                "Following",
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => FollowListScreen(
                        userId: _profileUserId,
                        listType: FollowListType.following,
                        initialUsername: user.displayName,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider(ThemeData theme) {
    return Container(
      height: 30.h,
      width: 1,
      color: theme.dividerColor.withValues(alpha: 0.5),
    );
  }

  Widget _buildStatItem(
    ThemeData theme,
    String value,
    String label, {
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(label, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }

  Widget _buildShimmerPlaceholder({
    double? width,
    required double height,
    double borderRadius = 16.0,
    bool isCircle = false,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: isCircle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: isCircle ? null : BorderRadius.circular(borderRadius.r),
      ),
    );
  }

  Widget _buildAchievementsList(ThemeData theme) {
    final streakService = context.watch<StreakService>();
    final user = _userModel!;
    final achievements = [
      {
        'type': 'points',
        'value': user.points,
        'level': _userAchievements['points'] ?? 0,
      },
      {
        'type': 'streak',
        'value': _isCurrentUserProfile ? streakService.currentStreak : 0,
        'level': _userAchievements['streak'] ?? 0,
      },
      {
        'type': 'lessons',
        'value': (user.completionPercent * 10).toInt(),
        'level': _userAchievements['lessons'] ?? 0,
      },
    ];

    return Column(
      children: achievements.map((data) {
        return _buildDuolingoAchievementCard(
          theme,
          data['type'] as String,
          data['value'] as int,
          data['level'] as int,
        );
      }).toList(),
    );
  }

  Widget _buildDuolingoAchievementCard(
    ThemeData theme,
    String type,
    int currentValue,
    int currentLevel,
  ) {
    final nextLevel = AchievementsData.getNextAchievement(type, currentLevel);
    Achievement? displayLevel = AchievementsData.getAchievement(
      type,
      currentLevel,
    );
    if (currentLevel == 0) {
      displayLevel = AchievementsData.getNextAchievement(type, 0);
    }
    if (displayLevel == null) return const SizedBox.shrink();

    double progress = 0.0;
    String progressText = "";

    if (nextLevel != null) {
      progress = currentValue / nextLevel.threshold;
      progressText = '$currentValue / ${nextLevel.threshold}';
    } else {
      progress = 1.0;
      progressText = "Max Level!";
    }

    progress = progress.clamp(0.0, 1.0);

    return Container(
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [theme.cardColor, theme.cardColor.withValues(alpha: 0.8)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56.r,
            height: 56.r,
            decoration: BoxDecoration(
              color: theme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.primaryColor.withValues(alpha: 0.2),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Icon(
              displayLevel.icon,
              color: theme.primaryColor,
              size: 28.sp,
            ),
          ),
          SizedBox(width: 16.w),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      displayLevel.name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      progressText,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  displayLevel.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.disabledColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12.h),

                Stack(
                  children: [
                    Container(
                      height: 6.h,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.disabledColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(3.r),
                      ),
                    ),
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 500),
                      height: 6.h,
                      width:
                          (MediaQuery.of(context).size.width - 120.w) *
                          progress,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            theme.primaryColor,
                            theme.primaryColor.withValues(alpha: 0.5),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(3.r),
                        boxShadow: [
                          BoxShadow(
                            color: theme.primaryColor.withValues(alpha: 0.4),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final ThemeData theme;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.05)],
        ),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28.sp),
          SizedBox(height: 8.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: theme.disabledColor),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? value;
  final bool isLast;

  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool hasValue = (value != null && value!.isNotEmpty);

    return Column(
      children: [
        Row(
          children: [
            Icon(icon, color: theme.primaryColor, size: 20.sp),
            SizedBox(width: 16.w),
            Text(
              title,
              style: TextStyle(
                fontSize: 14.sp,
                color: theme.textTheme.bodyMedium?.color,
              ),
            ),
            const Spacer(),
            Text(
              hasValue ? value! : 'Not Set',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: hasValue
                    ? theme.textTheme.bodyLarge?.color
                    : Colors.grey.shade500,
                fontStyle: hasValue ? FontStyle.normal : FontStyle.italic,
              ),
            ),
          ],
        ),
        if (!isLast)
          Divider(
            height: 24.h,
            color: theme.dividerColor.withValues(alpha: 0.5),
          ),
      ],
    );
  }
}
