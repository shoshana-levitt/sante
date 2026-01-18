import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Check if email is already in use
Future<bool> isEmailInUse(String email) async {
  try {
    QuerySnapshot query = await _db
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  } catch (e) {
    print('Error checking email: $e');
    return false;
  }
}

// Check if username is already taken
Future<bool> isUsernameTaken(String username) async {
  try {
    QuerySnapshot query = await _db
        .collection('users')
        .where('username', isEqualTo: username.trim().toLowerCase())
        .limit(1)
        .get();
    return query.docs.isNotEmpty;
  } catch (e) {
    print('Error checking username: $e');
    return false;
  }
}

  // Create a new user profile
  Future<void> createUser({
    required String userId,
    required String email,
    required String username,
    required String name,
  }) async {
    await _db.collection('users').doc(userId).set({
      'username': username.toLowerCase(),
      'name': name,
      'email': email.toLowerCase(),
      'photoUrl': '',
      'bio': '',
      'followerCount': 0,
      'followingCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // Get user profile
  Future<DocumentSnapshot> getUser(String userId) async {
    return await _db.collection('users').doc(userId).get();
  }

  // Create a new post
  Future<String> createPost({
    required String userId,
    required String imageUrl,
    required String type,
    required String caption,
  }) async {
    DocumentReference docRef = await _db.collection('posts').add({
      'userId': userId,
      'imageUrl': imageUrl,
      'type': type,
      'caption': caption,
      'likeCount': 0,
      'commentCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Update post
  Future<void> updatePost({
  required String postId,
  required String caption,
  required String type,
}) async {
  await _db.collection('posts').doc(postId).update({
    'caption': caption,
    'type': type,
  });
}

  // Get all posts (for feed)
  Stream<QuerySnapshot> getPosts() {
    return _db
        .collection('posts')
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // Get posts by a specific user
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Like a post
  Future<void> likePost(String postId, String userId) async {
    // Add to likes collection
    await _db.collection('likes').add({
      'postId': postId,
      'userId': userId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment like count on post
    await _db.collection('posts').doc(postId).update({
      'likeCount': FieldValue.increment(1),
    });
  }

  // Unlike a post
  Future<void> unlikePost(String postId, String userId) async {
    // Find and delete the like
    QuerySnapshot likeQuery = await _db
        .collection('likes')
        .where('postId', isEqualTo: postId)
        .where('userId', isEqualTo: userId)
        .get();

    for (var doc in likeQuery.docs) {
      await doc.reference.delete();
    }

    // Decrement like count on post
    await _db.collection('posts').doc(postId).update({
      'likeCount': FieldValue.increment(-1),
    });
  }

  // Check if user has liked a post
  Future<bool> hasLikedPost(String postId, String userId) async {
    QuerySnapshot likeQuery = await _db
        .collection('likes')
        .where('postId', isEqualTo: postId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return likeQuery.docs.isNotEmpty;
  }

  // Follow a user
  Future<void> followUser(String followerId, String followingId) async {
    // Add to follows collection
    await _db.collection('follows').add({
      'followerId': followerId,
      'followingId': followingId,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Update follower count
    await _db.collection('users').doc(followingId).update({
      'followerCount': FieldValue.increment(1),
    });

    // Update following count
    await _db.collection('users').doc(followerId).update({
      'followingCount': FieldValue.increment(1),
    });
  }

  // Unfollow a user
  Future<void> unfollowUser(String followerId, String followingId) async {
    // Find and delete the follow
    QuerySnapshot followQuery = await _db
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .get();

    for (var doc in followQuery.docs) {
      await doc.reference.delete();
    }

    // Update follower count
    await _db.collection('users').doc(followingId).update({
      'followerCount': FieldValue.increment(-1),
    });

    // Update following count
    await _db.collection('users').doc(followerId).update({
      'followingCount': FieldValue.increment(-1),
    });
  }

  // Check if user is following another user
  Future<bool> isFollowing(String followerId, String followingId) async {
    QuerySnapshot followQuery = await _db
        .collection('follows')
        .where('followerId', isEqualTo: followerId)
        .where('followingId', isEqualTo: followingId)
        .limit(1)
        .get();

    return followQuery.docs.isNotEmpty;
  }

  // Add a comment
  Future<void> addComment({
    required String postId,
    required String userId,
    required String text,
  }) async {
    // Add to comments collection
    await _db.collection('comments').add({
      'postId': postId,
      'userId': userId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Increment comment count on post
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(1),
    });
  }

  // Get comments for a post
  Stream<QuerySnapshot> getComments(String postId) {
    return _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }
}
