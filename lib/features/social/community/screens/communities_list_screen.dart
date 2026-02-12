import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:math/core/router/app_router.dart';
import 'package:provider/provider.dart';

class CommunitiesListScreen extends StatefulWidget {
  const CommunitiesListScreen({super.key});

  @override
  State<CommunitiesListScreen> createState() => _CommunitiesListScreenState();
}

class _CommunitiesListScreenState extends State<CommunitiesListScreen> {
  final CommunityService _communityService = CommunityService();

  List<CommunityModel> _myCommunities = [];
  List<CommunityModel> _recommendedCommunities = [];
  List<CommunityModel> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final user = context.read<AuthService>().user;
      final futures = <Future>[];

      futures.add(
        _communityService.getRecommendedCommunities().then((list) {
          _recommendedCommunities = list;
        }),
      );

      if (user != null) {
        futures.add(
          _communityService.getUserCommunities(user.uid).then((list) {
            _myCommunities = list;
          }),
        );
      }

      await Future.wait(futures);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        MessageBanner.show(
          context,
          message: 'Failed to load communities',
          type: MessageType.error,
        );
      }
    }
  }

  Future<void> _onSearch(String query) async {
    if (query.isEmpty) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
      return;
    }

    setState(() {
      _isSearching = true;
    });

    final results = await _communityService.searchCommunities(query);

    if (mounted) {
      setState(() {
        _searchResults = results;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: 'Search communities...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.white70),
                ),
                style: TextStyle(color: Colors.white),
                onChanged: _onSearch,
              )
            : Text('Communities'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isSearching ? Icons.close : Icons.search),
            onPressed: () {
              setState(() {
                if (_isSearching) {
                  _isSearching = false;
                  _searchController.clear();
                  _searchResults = [];
                } else {
                  _isSearching = true;
                }
              });
            },
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingState()
          : RefreshIndicator(
              onRefresh: _loadData,
              child: CustomScrollView(
                slivers: [
                  if (_isSearching) ...[
                    if (_searchResults.isEmpty &&
                        _searchController.text.isNotEmpty)
                      SliverFillRemaining(
                        child: Center(child: Text('No results found')),
                      )
                    else
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildCommunityTile(_searchResults[index]),
                          childCount: _searchResults.length,
                        ),
                      ),
                  ] else ...[
                    if (_myCommunities.isNotEmpty) ...[
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                          child: Text(
                            'My Communities',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) =>
                              _buildCommunityTile(_myCommunities[index]),
                          childCount: _myCommunities.length,
                        ),
                      ),
                    ],

                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16.w, 24.h, 16.w, 8.h),
                        child: Text(
                          'Discover',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    _recommendedCommunities.isEmpty
                        ? SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.all(32.w),
                              child: Center(
                                child: Text('No communities found'),
                              ),
                            ),
                          )
                        : SliverGrid(
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  childAspectRatio: 0.8,
                                  crossAxisSpacing: 12.w,
                                  mainAxisSpacing: 12.h,
                                ),
                            delegate: SliverChildBuilderDelegate(
                              (context, index) => _buildDiscoverCard(
                                _recommendedCommunities[index],
                              ),
                              childCount: _recommendedCommunities.length,
                            ),
                          ).sliverPadding(
                            EdgeInsets.symmetric(horizontal: 16.w),
                          ),
                  ],

                  SliverToBoxAdapter(child: SizedBox(height: 80.h)),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await context.push(AppRouter.createCommunityPath);
          if (result == true) {
            _loadData();
          }
        },
        label: Text('Create'),
        icon: Icon(Icons.add),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(child: CircularProgressIndicator());
  }

  Widget _buildCommunityTile(CommunityModel community) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: community.iconUrl != null
            ? CachedNetworkImageProvider(community.iconUrl!)
            : null,
        child: community.iconUrl == null ? Icon(Icons.groups) : null,
      ),
      title: Text(community.name, overflow: TextOverflow.ellipsis),
      subtitle: Text('${community.memberCount} members'),
      onTap: () => context.push(
        AppRouter.communityPath.replaceAll(':communityId', community.id),
      ),
    );
  }

  Widget _buildDiscoverCard(CommunityModel community) {
    final theme = Theme.of(context);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.push(
          AppRouter.communityPath.replaceAll(':communityId', community.id),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              flex: 3,
              child: community.bannerUrl != null
                  ? CachedNetworkImage(
                      imageUrl: community.bannerUrl!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: theme.primaryColor.withValues(alpha: 0.2),
                      child: Icon(Icons.image, color: Colors.grey),
                    ),
            ),
            Expanded(
              flex: 4,
              child: Padding(
                padding: EdgeInsets.all(8.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 20.w,
                      backgroundImage: community.iconUrl != null
                          ? CachedNetworkImageProvider(community.iconUrl!)
                          : null,
                      child: community.iconUrl == null
                          ? Icon(Icons.groups, size: 20)
                          : null,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      community.name,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14.sp,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    Text(
                      '${community.memberCount} members',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

extension SliverPaddingExt on Widget {
  Widget sliverPadding(EdgeInsets padding) {
    return SliverPadding(padding: padding, sliver: this);
  }
}
