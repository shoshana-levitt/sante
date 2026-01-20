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
  final Map<String, dynamic>? activityData; // Changed from ActivityData? to Map<String, dynamic>?

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
    this.activityData,
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
      activityData: data['activityData'] as Map<String, dynamic>?, // Cast to Map
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
      'activityData': activityData,
    };
  }
}
