import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:math/features/social/community/models/community_model.dart';
import 'package:math/features/social/community/models/community_member_model.dart';
import 'package:math/features/social/community/services/community_service.dart';
import 'package:math/core/services/auth_service.dart';
import 'package:math/core/widgets/message_banner.dart';
import 'package:provider/provider.dart';

class CommunitySelectionScreen extends StatefulWidget {
  const CommunitySelectionScreen({super.key});

  @override
  State<CommunitySelectionScreen> createState() =>
      _CommunitySelectionScreenState();
}

class _CommunitySelectionScreenState extends State<CommunitySelectionScreen> {
  final CommunityService _communityService = CommunityService();
  final TextEditingController _searchController = TextEditingController();

  List<CommunityModel> _myCommunities = [];
  List<CommunityModel> _recommendedCommunities = [];
  List<CommunityModel> _searchResults = [];
  bool _isLoading = true;
  bool _isSearching = false;

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
      if (user == null) return;

      final futures = await Future.wait([
        _communityService.getUserCommunities(user.uid),
        _communityService.getRecommendedCommunities(limit: 5),
      ]);

      if (mounted) {
        setState(() {
          _myCommunities = futures[0];
          _recommendedCommunities = futures[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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

    setState(() => _isSearching = true);
    final results = await _communityService.searchCommunities(query);
    if (mounted) {
      setState(() => _searchResults = results);
    }
  }

  Future<void> _handleSelect(CommunityModel community) async {
    final user = context.read<AuthService>().user;
    if (user == null) return;

    final isMember = await _communityService.isMember(community.id, user.uid);
    if (!context.mounted) return;
    if (isMember) {
      context.pop(community);
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Join ${community.name}?'),
          content: Text('You must be a member to post in this community.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Join'),
            ),
          ],
        ),
      );

      if (confirmed == true && mounted) {
        try {
          await _communityService.joinCommunity(community.id, user.uid);
          final updatedMember = await _communityService.getMember(
            community.id,
            user.uid,
          );

          if (!context.mounted) return;
          if (updatedMember?.status == MemberStatus.pending) {
            MessageBanner.show(
              context,
              message:
                  'Join request sent. Your post will be saved as a draft until approved.',
              type: MessageType.info,
            );
          }
          context.pop(community);
        } catch (e) {
          if (!context.mounted) return;
          MessageBanner.show(
            context,
            message: 'Failed to join community',
            type: MessageType.error,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        title: Text(
          'Select Community',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearch,
              decoration: InputDecoration(
                hintText: 'Search for a community...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: theme.cardColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.r),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      if (_isSearching) ...[
                        _buildSectionHeader(theme, 'Search Results'),
                        ..._searchResults.map(
                          (c) => _buildCommunityTile(theme, c),
                        ),
                        if (_searchResults.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: Text('No communities found')),
                          ),
                      ] else ...[
                        if (_myCommunities.isNotEmpty) ...[
                          _buildSectionHeader(theme, 'My Communities'),
                          ..._myCommunities.map(
                            (c) => _buildCommunityTile(theme, c),
                          ),
                        ],
                        _buildSectionHeader(theme, 'Discover'),
                        ..._recommendedCommunities.map(
                          (c) => _buildCommunityTile(theme, c),
                        ),
                      ],
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(ThemeData theme, String title) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
      child: Text(
        title.toUpperCase(),
        style: theme.textTheme.labelSmall?.copyWith(
          color: Colors.grey,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildCommunityTile(ThemeData theme, CommunityModel community) {
    return ListTile(
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      leading: CircleAvatar(
        radius: 20.r,
        backgroundColor: theme.primaryColor.withValues(alpha: 0.1),
        backgroundImage: community.iconUrl != null
            ? CachedNetworkImageProvider(community.iconUrl!)
            : null,
        child: community.iconUrl == null
            ? Icon(Icons.groups, color: theme.primaryColor)
            : null,
      ),
      title: Text(
        community.name,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text('${community.memberCount} members'),
      onTap: () => _handleSelect(community),
    );
  }
}
