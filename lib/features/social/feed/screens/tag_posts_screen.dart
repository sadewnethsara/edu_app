import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';

class TagPostsScreen extends StatefulWidget {
  final String tag;
  const TagPostsScreen({super.key, required this.tag});

  @override
  State<TagPostsScreen> createState() => _TagPostsScreenState();
}

class _TagPostsScreenState extends State<TagPostsScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Map<String, dynamic>> _suggestedTags = [];
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() async {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final results = await SocialService().searchTags(query);
      if (mounted) {
        setState(() {
          _suggestedTags = results;
          _isSearching = true;
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _suggestedTags = [];
          _isSearching = false;
        });
      }
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
                  hintText: 'Search tags...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                ),
                style: TextStyle(
                  fontSize: 16.sp,
                  color: theme.textTheme.bodyLarge?.color,
                ),
              )
            : Text('#${widget.tag}'),
        actions: [
          IconButton(
            icon: Icon(
              _isSearching ? Icons.close : Iconsax.search_normal_1_outline,
            ),
            onPressed: () {
              if (_isSearching) {
                _searchController.clear();
                setState(() => _isSearching = false);
              } else {
                setState(() => _isSearching = true);
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: SocialService().getPostsByTag(widget.tag),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Iconsax.hashtag_outline,
                        size: 64.sp,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'No posts found for #${widget.tag}',
                        style: TextStyle(color: Colors.grey, fontSize: 16.sp),
                      ),
                    ],
                  ),
                );
              }

              return ListView.separated(
                itemCount: docs.length,
                separatorBuilder: (context, index) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final post = PostModel.fromSnapshot(docs[index]);
                  return TweetPostWidget(post: post);
                },
              );
            },
          ),
          if (_isSearching && _suggestedTags.isNotEmpty)
            Container(
              color: theme.scaffoldBackgroundColor,
              child: ListView.builder(
                itemCount: _suggestedTags.length,
                itemBuilder: (context, index) {
                  final tagData = _suggestedTags[index];
                  final tag = tagData['tag'] as String;
                  final count = tagData['useCount'] as int? ?? 0;

                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.primaryColor.withValues(
                        alpha: 0.1,
                      ),
                      child: Icon(
                        Iconsax.hashtag_outline,
                        size: 20.sp,
                        color: theme.primaryColor,
                      ),
                    ),
                    title: Text('#$tag'),
                    subtitle: Text('$count posts'),
                    onTap: () {
                      _searchController.clear();
                      setState(() => _isSearching = false);
                      context.pushReplacement('/tags/$tag');
                    },
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
