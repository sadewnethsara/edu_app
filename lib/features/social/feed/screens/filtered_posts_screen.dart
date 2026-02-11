import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:icons_plus/icons_plus.dart';
import 'package:math/core/models/post_model.dart';
import 'package:math/features/social/feed/services/social_service.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';

enum FilterType { tag, category, subject }

class FilteredPostsScreen extends StatefulWidget {
  final String title;
  final FilterType filterType;
  final String filterValue;

  const FilteredPostsScreen({
    super.key,
    required this.title,
    required this.filterType,
    required this.filterValue,
  });

  @override
  State<FilteredPostsScreen> createState() => _FilteredPostsScreenState();
}

class _FilteredPostsScreenState extends State<FilteredPostsScreen> {
  late Stream<QuerySnapshot> _postsStream;

  @override
  void initState() {
    super.initState();
    _initStream();
  }

  void _initStream() {
    switch (widget.filterType) {
      case FilterType.tag:
        _postsStream = SocialService().getPostsByTag(widget.filterValue);
        break;
      case FilterType.category:
        final category = PostCategory.values.firstWhere(
          (e) => e.name == widget.filterValue,
          orElse: () => PostCategory.general,
        );
        _postsStream = SocialService().getPostsByCategory(category);
        break;
      case FilterType.subject:
        _postsStream = SocialService().getPostsBySubject(widget.filterValue);
        break;
    }
  }

  IconData _getIcon() {
    switch (widget.filterType) {
      case FilterType.tag:
        return Iconsax.hashtag_outline;
      case FilterType.category:
        return Iconsax.category_outline;
      case FilterType.subject:
        return Iconsax.book_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(_getIcon(), size: 20.sp),
            SizedBox(width: 8.w),
            Text(widget.title),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _postsStream,
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
                  Icon(_getIcon(), size: 64.sp, color: Colors.grey),
                  SizedBox(height: 16.h),
                  Text(
                    'No posts found for ${widget.title}',
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
    );
  }
}
