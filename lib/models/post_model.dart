import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String type;
  final String caption;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;

  PostModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.type,
    required this.caption,
    required this.likeCount,
    required this.commentCount,
    this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      type: data['type'] ?? '',
      caption: data['caption'] ?? '',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
