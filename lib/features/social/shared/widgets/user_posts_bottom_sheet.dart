import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:math/features/social/feed/models/post_model.dart';
import 'package:math/features/social/feed/widgets/tweet_post_widget.dart';
import 'package:math/widgets/standard_bottom_sheet.dart';

class UserPostsBottomSheet extends StatelessWidget {
  final String userId;

  const UserPostsBottomSheet({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return StandardBottomSheet(
      title: 'Posts',
      icon: Icons.grid_view_rounded,
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('posts')
            .where('authorId', isEqualTo: userId)
            .orderBy('createdAt', descending: true)
            .limit(50)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 40.h),
                child: Text(
                  'No posts yet',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final posts = docs.map((doc) => PostModel.fromSnapshot(doc)).toList();

          return ListView.separated(
            itemCount: posts.length,
            padding: EdgeInsets.zero,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            separatorBuilder: (context, index) =>
                Divider(height: 1, color: Theme.of(context).dividerColor),
            itemBuilder: (context, index) {
              final post = posts[index];
              return TweetPostWidget(post: post);
            },
          );
        },
      ),
    );
  }
}
