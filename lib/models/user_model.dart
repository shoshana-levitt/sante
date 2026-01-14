import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String username;
  final String email;
  final String photoUrl;
  final String bio;
  final int followerCount;
  final int followingCount;
  final DateTime? createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.photoUrl,
    required this.bio,
    required this.followerCount,
    required this.followingCount,
    this.createdAt,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return UserModel(
      id: doc.id,
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
      bio: data['bio'] ?? '',
      followerCount: data['followerCount'] ?? 0,
      followingCount: data['followingCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
