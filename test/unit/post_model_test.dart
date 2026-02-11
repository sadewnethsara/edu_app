import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math/data/models/post_model.dart';

void main() {
  group('PostModel', () {
    final timestamp = Timestamp.now();

    final postData = {
      'postId': 'post_123',
      'authorId': 'user_456',
      'authorName': 'John Doe',
      'authorPhotoUrl': 'http://example.com/photo.jpg',
      'text': 'Hello World',
      'imageUrl': 'http://example.com/image.jpg',
      'imageUrls': ['http://example.com/image.jpg'],
      'createdAt': timestamp,
      'likeCount': 10,
      'replyCount': 5,
      'replyPermission': 'everyone',
      'pollData': {
        'options': ['Option 1', 'Option 2'],
        'voteCounts': [0, 0],
        'totalVotes': 0,
        'lengthDays': 1,
        'endsAt': timestamp,
        'allowMultipleVotes': true,
      },
    };

    test('fromJson creates a valid PostModel', () {
      final post = PostModel.fromJson(postData);

      expect(post.postId, 'post_123');
      expect(post.authorName, 'John Doe');
      expect(post.likeCount, 10);
      expect(post.pollData, isNotNull);
      expect(post.pollData!.allowMultipleVotes, true);
    });

    test('toJson serializes correctly', () {
      final post = PostModel.fromJson(postData);
      final json = post.toJson();

      expect(
        json['postId'],
        'post_123',
      ); // Note: toJson might not include ID if it's stored in doc ID, let's check model
      expect(json['authorId'], 'user_456');
      expect(json['pollData']['allowMultipleVotes'], true);
    });
  });
}
