import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/core/services/api_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/features/social/community/screens/add_community_resource_screen.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/features/social/community/models/community_resource_model.dart';
import 'package:math/core/models/content_model.dart';
import 'package:math/features/shared/presentation/screens/pdf_viewer_screen.dart';
import 'package:math/features/lessons/presentation/screens/video_player_screen.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';
import 'package:provider/provider.dart';
import 'package:math/core/router/app_router.dart';
import 'package:math/core/services/zen_mode_service.dart';

class CommunityScreen extends StatefulWidget {
  final String communityId;
  const CommunityScreen({super.key, required this.communityId});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CommunityService _communityService = CommunityService();
  final ApiService _apiService = ApiService();

  CommunityModel? _community;
  bool _isLoadingCommunity = true;
  bool _isMember = false;
  bool _isCheckingMember = true;

  bool get _isCreator =>
      _community?.creatorId == context.read<AuthService>().user?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([_fetchCommunity(), _checkMembership()]);
  }

  Future<void> _fetchCommunity() async {
    try {
      final community = await _communityService.getCommunity(
        widget.communityId,
      );
      if (mounted) {
        setState(() {
          _community = community;
          _isLoadingCommunity = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingCommunity = false);
        MessageBanner.show(
          context,
          message: 'Failed to load community',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _checkMembership() async {
    try {
      final user = context.read<AuthService>().user;
      if (user != null) {
        final isMember = await _communityService.isMember(
          widget.communityId,
          user.uid,
        );
        if (mounted) {
          setState(() {
            _isMember = isMember;
            _isCheckingMember = false;
          });
        }
      } else {
        if (mounted) setState(() => _isCheckingMember = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isCheckingMember = false);
    }
  }

  Future<void> _toggleJoin() async {
    final user = context.read<AuthService>().user;
    if (user == null) {
      MessageBanner.show(
        context,
        message: 'Please Login to join',
        type: MessageType.warning,
      );
      return;
    }

    setState(() => _isCheckingMember = true);

    try {
      if (_isMember) {
        await _communityService.leaveCommunity(widget.communityId, user.uid);
        if (mounted) {
          MessageBanner.show(
            context,
            message: 'Left community',
            type: MessageType.success,
          );
          setState(() {
            _isMember = false;
            if (_community != null) {
              _community = _community!.copyWith(
                memberCount: _community!.memberCount - 1,
              );
            }
          });
        }
      } else {
        await _communityService.joinCommunity(widget.communityId, user.uid);
        if (mounted) {
          MessageBanner.show(
            context,
            message: 'Joined community!',
            type: MessageType.success,
          );
          setState(() {
            _isMember = true;
            if (_community != null) {
              _community = _community!.copyWith(
                memberCount: _community!.memberCount + 1,
              );
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Action failed: $e',
          type: MessageType.error,
        );
      }
    } finally {
      if (mounted) setState(() => _isCheckingMember = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final zenService = Provider.of<ZenModeService>(context);

    if (_isLoadingCommunity) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_community == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text("Community not found")),
      );
    }

    return Scaffold(
      body: NestedScrollView(
        headerSliverBuilder: (context, innerBoxIsScrolled) {
          return [
            SliverAppBar(
              expandedHeight: 220.h,
              pinned: true,
              backgroundColor: theme.scaffoldBackgroundColor,
              leading: Container(
                margin: EdgeInsets.all(8.w),
                decoration: BoxDecoration(
                  color: theme.scaffoldBackgroundColor.withValues(alpha: 0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Iconsax.arrow_left_outline),
                  onPressed: () => context.pop(),
                ),
              ),
              actions: [
                if (_community?.creatorId ==
                    context.read<AuthService>().user?.uid) ...[
                  IconButton(
                    icon: const Icon(Iconsax.document_text_outline),
                    tooltip: 'Review Posts',
                    onPressed: () => context.pushNamed(
                      AppRouter.communityReviewName,
                      pathParameters: {'communityId': widget.communityId},
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Iconsax.edit_2_outline),
                    tooltip: 'Edit Community',
                    onPressed: () => context
                        .pushNamed(
                          AppRouter.editCommunityName,
                          pathParameters: {'communityId': widget.communityId},
                        )
                        .then((val) {
                          if (val == true) _fetchCommunity();
                        }),
                  ),
                  Padding(
                    padding: EdgeInsets.only(right: 8.w),
                    child: IconButton(
                      icon: const Icon(Iconsax.setting_outline),
                      tooltip: 'Settings',
                      onPressed: () => context.pushNamed(
                        AppRouter.communitySettingsName,
                        pathParameters: {'communityId': widget.communityId},
                      ),
                    ),
                  ),
                ],
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    _community!.bannerUrl != null
                        ? CachedNetworkImage(
                            imageUrl: _community!.bannerUrl!,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            color: theme.primaryColor.withValues(alpha: 0.2),
                            child: const Icon(
                              Iconsax.image_outline,
                              size: 50,
                              color: Colors.grey,
                            ),
                          ),
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.8),
                          ],
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 16.h,
                      left: 16.w,
                      right: 16.w,
                      child: Row(
                        children: [
                          Container(
                            width: 64.w,
                            height: 64.w,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                              image: _community!.iconUrl != null
                                  ? DecorationImage(
                                      image: CachedNetworkImageProvider(
                                        _community!.iconUrl!,
                                      ),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                              color: theme.cardColor,
                            ),
                            child: _community!.iconUrl == null
                                ? Icon(
                                    Iconsax.people_outline,
                                    color: theme.iconTheme.color,
                                  )
                                : null,
                          ),
                          SizedBox(width: 12.w),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  _community!.name,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 22.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                InkWell(
                                  onTap: () => context.pushNamed(
                                    AppRouter.communityMembersName,
                                    pathParameters: {
                                      'communityId': widget.communityId,
                                    },
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Iconsax.user_outline,
                                        size: 12,
                                        color: Colors.white70,
                                      ),
                                      SizedBox(width: 4.w),
                                      Text(
                                        '${_community!.memberCount} Scholars',
                                        style: TextStyle(
                                          color: Colors.white70,
                                          fontSize: 14.sp,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (zenService.isEnabled)
              SliverToBoxAdapter(
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.symmetric(
                    vertical: 8.h,
                    horizontal: 16.w,
                  ),
                  color: theme.primaryColor.withValues(alpha: 0.1),
                  child: Row(
                    children: [
                      const Icon(
                        Iconsax.timer_1_outline,
                        size: 16,
                        color: Colors.blue,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "Deep Focus Active: ${zenService.formattedTime}",
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _isCheckingMember ? null : _toggleJoin,
                        icon: Icon(
                          _isMember
                              ? Iconsax.tick_circle_outline
                              : Iconsax.add_circle_outline,
                          size: 18,
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isMember
                              ? theme.cardColor
                              : theme.primaryColor,
                          foregroundColor: _isMember
                              ? theme.textTheme.bodyLarge?.color
                              : Colors.white,
                          side: _isMember
                              ? BorderSide(color: theme.dividerColor)
                              : null,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                          ),
                          elevation: 0,
                        ),
                        label: _isCheckingMember
                            ? SizedBox(
                                width: 16.w,
                                height: 16.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(_isMember ? 'Member' : 'Join Elite'),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    IconButton(
                      onPressed: () {},
                      icon: const Icon(Iconsax.export_3_outline),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.cardColor,
                        shape: const CircleBorder(),
                        side: BorderSide(
                          color: theme.dividerColor.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPersistentHeader(
              delegate: _SliverTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  labelColor: theme.primaryColor,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: theme.primaryColor,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14.sp,
                  ),
                  tabs: const [
                    Tab(text: 'FEEDS'),
                    Tab(text: 'RESOURCES'),
                    Tab(text: 'RULES'),
                  ],
                ),
                theme.scaffoldBackgroundColor,
              ),
              pinned: true,
            ),
          ];
        },
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPostsTab(),
            _buildResourcesTab(theme),
            _buildAboutTab(theme),
          ],
        ),
      ),
      floatingActionButton: (_isMember || !_community!.isPrivate)
          ? FloatingActionButton(
              onPressed: () async {
                await context.pushNamed(
                  AppRouter.createPostName,
                  extra: {
                    'communityId': _community!.id,
                    'communityName': _community!.name,
                    'communityIcon': _community!.iconUrl,
                  },
                );
              },
              backgroundColor: theme.primaryColor,
              child: const Icon(Iconsax.add_outline, color: Colors.white),
            )
          : null,
    );
  }

  Widget _buildPostsTab() {
    if (_community!.isPrivate && !_isMember) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Iconsax.lock_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16.h),
            Text(
              'Elite Access Only',
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            const Text('Join this community to see insights'),
          ],
        ),
      );
    }

    return StreamBuilder<List<PostModel>>(
      stream: _apiService.getCommunityPostsStream(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final posts = snapshot.data ?? [];

        if (posts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.ghost_outline,
                  size: 48,
                  color: Colors.grey.withValues(alpha: 0.5),
                ),
                SizedBox(height: 8.h),
                const Text('No insights shared here yet.'),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.only(bottom: 80.h),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return TweetPostWidget(post: posts[index]);
          },
        );
      },
    );
  }

  Widget _buildResourcesTab(ThemeData theme) {
    return StreamBuilder<List<CommunityResourceModel>>(
      stream: _communityService.getApprovedResources(widget.communityId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final resources = snapshot.data ?? [];
        final videos = resources
            .where((r) => r.type == ResourceType.video)
            .toList();
        final documents = resources
            .where((r) => r.type == ResourceType.document)
            .toList();
        final links = resources
            .where((r) => r.type == ResourceType.link)
            .toList();

        return ListView(
          padding: EdgeInsets.all(16.w),
          children: [
            if (_isCreator) _buildAdminResourceSection(theme),

            _buildResourceHeader(
              theme,
              "Featured Lessons",
              Iconsax.video_circle_outline,
              onAdd: _showAddResourceDialog,
            ),
            if (videos.isEmpty)
              _buildEmptyResource(theme, "No lessons shared yet.")
            else
              ...videos.map((r) => _buildResourceItem(theme, r)),

            SizedBox(height: 24.h),
            _buildResourceHeader(
              theme,
              "Past Papers & Solutions",
              Iconsax.document_text_outline,
              onAdd: _showAddResourceDialog,
            ),
            if (documents.isEmpty)
              _buildEmptyResource(theme, "No papers shared yet.")
            else
              ...documents.map((r) => _buildResourceItem(theme, r)),

            if (links.isNotEmpty) ...[
              SizedBox(height: 24.h),
              _buildResourceHeader(
                theme,
                "External Links",
                Iconsax.link_outline,
                onAdd: _showAddResourceDialog,
              ),
              ...links.map((r) => _buildResourceItem(theme, r)),
            ],
            SizedBox(height: 80.h),
          ],
        );
      },
    );
  }

  Widget _buildAdminResourceSection(ThemeData theme) {
    return FutureBuilder<List<CommunityResourceModel>>(
      future: _communityService.getPendingResources(widget.communityId),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }

        final pending = snapshot.data!;
        return Container(
          margin: EdgeInsets.only(bottom: 24.h),
          padding: EdgeInsets.all(12.w),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: theme.primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Iconsax.security_safe_outline,
                    size: 18,
                    color: theme.primaryColor,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    "Pending Approvals (${pending.length})",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.primaryColor,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 12.h),
              ...pending.map(
                (r) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    r.title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  subtitle: Text(r.type.name.toUpperCase()),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(
                          Iconsax.tick_circle_outline,
                          color: Colors.green,
                        ),
                        onPressed: () => _handleApproveResource(r),
                      ),
                      IconButton(
                        icon: const Icon(
                          Iconsax.close_circle_outline,
                          color: Colors.red,
                        ),
                        onPressed: () => _handleRejectResource(r),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyResource(ThemeData theme, String message) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 20.h),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: theme.disabledColor, fontSize: 13.sp),
        ),
      ),
    );
  }

  Widget _buildResourceHeader(
    ThemeData theme,
    String title,
    IconData icon, {
    VoidCallback? onAdd,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: theme.primaryColor),
              SizedBox(width: 8.w),
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (_isMember)
            IconButton(
              onPressed: onAdd,
              icon: Icon(
                Iconsax.add_square_outline,
                size: 20,
                color: theme.primaryColor,
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  Widget _buildResourceItem(ThemeData theme, CommunityResourceModel resource) {
    IconData icon;
    switch (resource.type) {
      case ResourceType.video:
        icon = Iconsax.video_circle_outline;
        break;
      case ResourceType.document:
        icon = Iconsax.document_text_outline;
        break;
      case ResourceType.link:
        icon = Iconsax.link_outline;
        break;
    }

    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        onTap: () => _handleResourceClick(resource),
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: theme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, size: 20, color: theme.primaryColor),
        ),
        title: Text(
          resource.title,
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14.sp),
        ),
        subtitle: Text(
          resource.description,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 12.sp, color: theme.disabledColor),
        ),
        trailing: Icon(
          Iconsax.arrow_right_3_outline,
          size: 16,
          color: theme.disabledColor,
        ),
      ),
    );
  }

  void _handleResourceClick(CommunityResourceModel resource) {
    if (resource.type == ResourceType.video) {
      final item = ContentItem(
        id: resource.id,
        name: resource.title,
        url: resource.url,
        type: 'url',
        thumbnail: resource.thumbnailUrl,
        language: 'en',
        uploadedAt: resource.addedAt.toDate().toIso8601String(),
        description: resource.description,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => VideoPlayerScreen(playlist: [item]),
        ),
      );
    } else if (resource.type == ResourceType.document) {
      final item = ContentItem(
        id: resource.id,
        name: resource.title,
        url: resource.url,
        type: 'url',
        language: 'en',
        uploadedAt: resource.addedAt.toDate().toIso8601String(),
        description: resource.description,
      );

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfViewerScreen(itemList: [item]),
        ),
      );
    } else if (resource.type == ResourceType.link) {
      MessageBanner.show(context, message: 'Opening link: ${resource.url}');
    }
  }

  Future<void> _handleApproveResource(CommunityResourceModel resource) async {
    try {
      final adminId = context.read<AuthService>().user?.uid;
      if (adminId == null) return;

      await _communityService.approveResource(
        widget.communityId,
        resource.id,
        adminId,
      );
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Resource approved',
          type: MessageType.success,
        );
        setState(() {}); // Refresh pending list
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Approval failed',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _handleRejectResource(CommunityResourceModel resource) async {
    try {
      await _communityService.rejectResource(widget.communityId, resource.id);
      if (mounted) {
        MessageBanner.show(context, message: 'Resource rejected');
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        MessageBanner.show(
          context,
          message: 'Reject failed',
          type: MessageType.error,
        );
      }
    }
  }

  void _showAddResourceDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddCommunityResourceScreen(
          communityId: widget.communityId,
          isCreator: _isCreator,
        ),
      ),
    ).then((value) {
      if (value == true && mounted) {
        setState(() {}); // Refresh if needed
      }
    });
  }

  Widget _buildAboutTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Iconsax.info_circle_outline,
                size: 20,
                color: Colors.grey,
              ),
              SizedBox(width: 8.w),
              Text(
                'Mission Statement',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            _community!.description,
            style: TextStyle(
              fontSize: 15.sp,
              height: 1.6,
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
            ),
          ),
          SizedBox(height: 32.h),
          if (_community!.rules.isNotEmpty) ...[
            Row(
              children: [
                const Icon(Iconsax.judge_outline, size: 20, color: Colors.grey),
                SizedBox(width: 8.w),
                Text(
                  'Community Rules',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16.h),
            ..._community!.rules.asMap().entries.map((entry) {
              return Container(
                margin: EdgeInsets.only(bottom: 12.h),
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: theme.cardColor,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${entry.key + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: theme.primaryColor,
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        entry.value,
                        style: TextStyle(fontSize: 14.sp),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
          SizedBox(height: 24.h),
          Divider(color: theme.dividerColor.withValues(alpha: 0.5)),
          SizedBox(height: 12.h),
          Row(
            children: [
              const Icon(
                Iconsax.calendar_1_outline,
                size: 16,
                color: Colors.grey,
              ),
              SizedBox(width: 8.w),
              Text(
                'Established ${_formatDate(_community!.createdAt)}',
                style: TextStyle(color: Colors.grey, fontSize: 13.sp),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return "Unknown";
    final date = timestamp.toDate();
    final months = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec",
    ];
    return '${months[date.month - 1]} ${date.year}';
  }
}

class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverTabBarDelegate(this._tabBar, this._backgroundColor);

  final TabBar _tabBar;
  final Color _backgroundColor;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return Container(color: _backgroundColor, child: _tabBar);
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
