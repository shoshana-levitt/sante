// lib/widgets/post_card.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../screens/edit_post_screen.dart';
import '../screens/comments_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _postUser;
  bool _isLiked = false;
  int _likeCount = 0;

  @override
  void initState() {
    super.initState();
    _loadPostUser();
    _checkIfLiked();
    _likeCount = widget.post.likeCount;
  }

  Future<void> _loadPostUser() async {
    try {
      DocumentSnapshot userDoc = await _firestoreService.getUser(widget.post.userId);
      if (userDoc.exists) {
        setState(() {
          _postUser = UserModel.fromFirestore(userDoc);
        });
      }
    } catch (e) {
      print('Error loading user: $e');
    }
  }

  Future<void> _checkIfLiked() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId != null) {
      bool liked = await _firestoreService.hasLikedPost(widget.post.id, currentUserId);
      setState(() {
        _isLiked = liked;
      });
    }
  }

  Future<void> _toggleLike() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    setState(() {
      if (_isLiked) {
        _isLiked = false;
        _likeCount--;
      } else {
        _isLiked = true;
        _likeCount++;
      }
    });

    try {
      if (_isLiked) {
        await _firestoreService.likePost(widget.post.id, currentUserId);
      } else {
        await _firestoreService.unlikePost(widget.post.id, currentUserId);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        if (_isLiked) {
          _isLiked = false;
          _likeCount--;
        } else {
          _isLiked = true;
          _likeCount++;
        }
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showPostOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit Post'),
                onTap: () async {
                  Navigator.pop(context);
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostScreen(post: widget.post),
                    ),
                  );
                  if (result == 'success' && mounted) {
                    setState(() {});
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Post updated successfully!'),
                        backgroundColor: Colors.green,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Icon(
                  widget.post.isArchived ? Icons.unarchive : Icons.archive,
                ),
                title: Text(widget.post.isArchived ? 'Unarchive' : 'Archive'),
                onTap: () async {
                  Navigator.pop(context);
                  await _toggleArchive();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Delete Post', style: TextStyle(color: Colors.red)),
                onTap: () {
                  Navigator.pop(context);
                  _showDeleteDialog(context);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _toggleArchive() async {
    try {
      await _firestoreService.toggleArchivePost(
        widget.post.id,
        !widget.post.isArchived,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.post.isArchived ? 'Post unarchived' : 'Post archived',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Post'),
          content: const Text('Are you sure you want to delete this post? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deletePost();
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deletePost() async {
    try {
      await _firestoreService.deletePost(widget.post.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Post deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting post: $e')),
        );
      }
    }
  }

  Widget _buildActivityDetail(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey[700]),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUserId = _authService.currentUser?.uid;
    final isOwnPost = currentUserId == widget.post.userId;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with user info
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Profile picture
                CircleAvatar(
                  radius: 20,
                  backgroundColor: Colors.greenAccent[700],
                  backgroundImage: _postUser?.photoUrl.isNotEmpty == true
                      ? NetworkImage(_postUser!.photoUrl)
                      : null,
                  child: _postUser?.photoUrl.isEmpty ?? true
                      ? Text(
                          _postUser?.username[0].toUpperCase() ?? 'U',
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                // Username and timestamp
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _postUser?.username ?? 'Loading...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (widget.post.createdAt != null)
                        Text(
                          _formatTimestamp(widget.post.createdAt!),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                // Options menu (only for own posts)
                if (isOwnPost)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                    onPressed: () => _showPostOptions(context),
                  ),
              ],
            ),
          ),

          // Post image
          Image.network(
            widget.post.imageUrl,
            width: double.infinity,
            fit: BoxFit.cover,
          ),

          // Action buttons (like, comment, share)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : null,
                  ),
                  onPressed: _toggleLike,
                ),
                Text('$_likeCount'),
                const SizedBox(width: 16),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => CommentsScreen(post: widget.post),
                      ),
                    );
                  },
                ),
                Text('${widget.post.commentCount}'),
              ],
            ),
          ),

          // Caption
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle.of(context).style,
                  children: [
                    TextSpan(
                      text: '${_postUser?.username ?? ''} ',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextSpan(text: widget.post.caption),
                  ],
                ),
              ),
            ),

          // Activity data section (if post type is activity)
          if (widget.post.type == 'activity' && widget.post.activityData != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.greenAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.greenAccent),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Activity Type Header
                    if (widget.post.activityData!['activityType'] != null)
                      Row(
                        children: [
                          Icon(Icons.fitness_center, size: 20, color: Colors.greenAccent[700]),
                          const SizedBox(width: 8),
                          Text(
                            widget.post.activityData!['activityType'],
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.greenAccent[700],
                            ),
                          ),
                        ],
                      ),

                    // Commentary
                    if (widget.post.activityData!['commentary'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.post.activityData!['commentary'],
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Exercises
                    if (widget.post.activityData!['exercises'] != null &&
                        (widget.post.activityData!['exercises'] as List).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Exercises',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...(widget.post.activityData!['exercises'] as List).map((exercise) {
                        final ex = exercise as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      ex['name'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    if ([ex['sets'], ex['reps'], ex['weight']].any((e) => e != null))
                                      Text(
                                        [
                                          if (ex['sets'] != null) '${ex['sets']} sets',
                                          if (ex['reps'] != null) '${ex['reps']} reps',
                                          if (ex['weight'] != null) '${ex['weight']} lbs',
                                        ].join(' • '),
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 13,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],

                    // Location & Distance
                    if (widget.post.activityData!['location'] != null ||
                        widget.post.activityData!['distance'] != null) ...[
                      const SizedBox(height: 8),
                      if (widget.post.activityData!['location'] != null)
                        _buildActivityDetail(
                          Icons.location_on,
                          widget.post.activityData!['location'],
                        ),
                      if (widget.post.activityData!['distance'] != null)
                        _buildActivityDetail(
                          Icons.straighten,
                          widget.post.activityData!['distance'],
                        ),
                    ],
                  ],
                ),
              ),
            ),

          // Recipe data section (if post type is meal)
          if (widget.post.type == 'meal' && widget.post.recipeData != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Recipe Header
                    Row(
                      children: [
                        Icon(Icons.restaurant, size: 20, color: Colors.orange[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Recipe',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),

                    // Commentary
                    if (widget.post.recipeData!['commentary'] != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        widget.post.recipeData!['commentary'],
                        style: TextStyle(
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                    ],

                    // Difficulty & Cook Time
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.bar_chart, size: 16, color: Colors.grey[700]),
                        const SizedBox(width: 6),
                        Text(
                          widget.post.recipeData!['difficulty'] ?? 'Easy',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (widget.post.recipeData!['cookTime'] != null) ...[
                          const SizedBox(width: 16),
                          Icon(Icons.timer, size: 16, color: Colors.grey[700]),
                          const SizedBox(width: 6),
                          Text(
                            widget.post.recipeData!['cookTime'],
                            style: TextStyle(color: Colors.grey[700]),
                          ),
                        ],
                      ],
                    ),

                    // Ingredients
                    if (widget.post.recipeData!['ingredients'] != null &&
                        (widget.post.recipeData!['ingredients'] as List).isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Ingredients',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ...(widget.post.recipeData!['ingredients'] as List).map((ingredient) {
                        final ing = ingredient as Map<String, dynamic>;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.circle, size: 6, color: Colors.grey[600]),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  ing['amount'] != null
                                      ? '${ing['amount']} ${ing['name']}'
                                      : ing['name'],
                                  style: TextStyle(
                                    color: Colors.grey[700],
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ],

                    // Instructions
                    if (widget.post.recipeData!['instructions'] != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        widget.post.recipeData!['instructions'],
                        style: TextStyle(
                          color: Colors.grey[700],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.day}/${timestamp.month}/${timestamp.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
