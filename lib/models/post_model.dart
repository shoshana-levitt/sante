// lib/models/post_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String userId;
  final String imageUrl;
  final String caption;
  final String type;
  final int likeCount;
  final int commentCount;
  final DateTime? createdAt;
  final bool isArchived;
  final bool isDraft;
  final Map<String, dynamic>? activityData;
  final Map<String, dynamic>? recipeData;

  PostModel({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.caption,
    required this.type,
    required this.likeCount,
    required this.commentCount,
    this.createdAt,
    this.isArchived = false,
    this.isDraft = false,
    this.activityData,
    this.recipeData,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    return PostModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      caption: data['caption'] ?? '',
      type: data['type'] ?? 'freeform',
      likeCount: data['likeCount'] ?? 0,
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      isArchived: data['isArchived'] ?? false,
      isDraft: data['isDraft'] ?? false,
      activityData: data['activityData'] as Map<String, dynamic>?,
      recipeData: data['recipeData'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'imageUrl': imageUrl,
      'caption': caption,
      'type': type,
      'likeCount': likeCount,
      'commentCount': commentCount,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'isArchived': isArchived,
      'isDraft': isDraft,
      'activityData': activityData,
      'recipeData': recipeData,
    };
  }
}
