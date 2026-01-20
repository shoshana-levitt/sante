// lib/services/firestore_service.dart
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

  // Update user profile
  Future<void> updateUser({
    required String userId,
    required String username,
    required String bio,
    String? photoUrl,
  }) async {
    Map<String, dynamic> updateData = {
      'username': username.toLowerCase(),
      'bio': bio,
    };

    if (photoUrl != null) {
      updateData['photoUrl'] = photoUrl;
    }

    await _db.collection('users').doc(userId).update(updateData);
  }

  // Create a new post
  Future<String> createPost({
    required String userId,
    required String imageUrl,
    required String caption,
    required String type,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? recipeData,
  }) async {
    Map<String, dynamic> postData = {
      'userId': userId,
      'imageUrl': imageUrl,
      'caption': caption,
      'type': type,
      'likeCount': 0,
      'commentCount': 0,
      'isArchived': false,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add activity data if type is activity
    if (type == 'activity' && activityData != null) {
      postData['activityData'] = activityData;
    }

    // Add recipe data if type is meal
    if (type == 'meal' && recipeData != null) {
      postData['recipeData'] = recipeData;
    }

    DocumentReference docRef = await _db.collection('posts').add(postData);
    return docRef.id;
  }

  // Update post
  Future<void> updatePost({
    required String postId,
    required String caption,
    required String type,
    Map<String, dynamic>? activityData,
    Map<String, dynamic>? recipeData,
  }) async {
    Map<String, dynamic> updateData = {
      'caption': caption,
      'type': type,
    };

    if (type == 'activity' && activityData != null) {
      updateData['activityData'] = activityData;
      updateData['recipeData'] = FieldValue.delete(); // Remove recipe data if switching to activity
    } else if (type == 'meal' && recipeData != null) {
      updateData['recipeData'] = recipeData;
      updateData['activityData'] = FieldValue.delete(); // Remove activity data if switching to meal
    } else {
      // Remove both if switching to freeform
      updateData['activityData'] = FieldValue.delete();
      updateData['recipeData'] = FieldValue.delete();
    }

    await _db.collection('posts').doc(postId).update(updateData);
  }

  // Delete post
  Future<void> deletePost(String postId) async {
    // Delete the post document
    await _db.collection('posts').doc(postId).delete();

    // Delete all likes for this post
    QuerySnapshot likesQuery = await _db
        .collection('likes')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in likesQuery.docs) {
      await doc.reference.delete();
    }

    // Delete all comments for this post
    QuerySnapshot commentsQuery = await _db
        .collection('comments')
        .where('postId', isEqualTo: postId)
        .get();

    for (var doc in commentsQuery.docs) {
      await doc.reference.delete();
    }
  }

  // Archive/Unarchive post
  Future<void> toggleArchivePost(String postId, bool isArchived) async {
    await _db.collection('posts').doc(postId).update({
      'isArchived': isArchived,
    });
  }

  // Get archived posts
  Stream<QuerySnapshot> getArchivedPosts(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Get all posts (for feed)
  Stream<QuerySnapshot> getPosts() {
    return _db
        .collection('posts')
        .where('isArchived', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots();
  }

  // Get posts by a specific user
  Stream<QuerySnapshot> getUserPosts(String userId) {
    return _db
        .collection('posts')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: false)
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

  // Delete a comment
  Future<void> deleteComment(String commentId, String postId) async {
    // Delete the comment
    await _db.collection('comments').doc(commentId).delete();

    // Decrement comment count
    await _db.collection('posts').doc(postId).update({
      'commentCount': FieldValue.increment(-1),
    });
  }
}
