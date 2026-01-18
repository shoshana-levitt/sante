import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../screens/comments_screen.dart';
import '../screens/edit_post_screen.dart';

class PostCard extends StatefulWidget {
  final PostModel post;

  const PostCard({super.key, required this.post});

  @override
  State<PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<PostCard> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
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

  Color _getTypeColor() {
    switch (widget.post.type) {
      case 'activity':
        return Colors.blue;
      case 'meal':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getTypeIcon() {
    switch (widget.post.type) {
      case 'activity':
        return Icons.directions_run;
      case 'meal':
        return Icons.restaurant;
      default:
        return Icons.image;
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
                  Navigator.pop(context); // Close bottom sheet
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditPostScreen(post: widget.post),
                    ),
                  );
                  if (result == true && mounted) {
                    // Refresh the post by rebuilding the widget
                    setState(() {});
                  }
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
      // Delete post document
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .delete();

      // Delete all likes for this post
      QuerySnapshot likes = await FirebaseFirestore.instance
          .collection('likes')
          .where('postId', isEqualTo: widget.post.id)
          .get();

      for (var doc in likes.docs) {
        await doc.reference.delete();
      }

      // Delete all comments for this post
      QuerySnapshot comments = await FirebaseFirestore.instance
          .collection('comments')
          .where('postId', isEqualTo: widget.post.id)
          .get();

      for (var doc in comments.docs) {
        await doc.reference.delete();
      }

      // Delete image from storage
      await _storageService.deleteImage(widget.post.imageUrl);

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

  @override
  Widget build(BuildContext context) {
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
                // Username and post type
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
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(
                            _getTypeIcon(),
                            size: 14,
                            color: _getTypeColor(),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            widget.post.type,
                            style: TextStyle(
                              fontSize: 12,
                              color: _getTypeColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (widget.post.userId == _authService.currentUser?.uid)
                  IconButton(
                    icon: const Icon(Icons.more_vert),
                      onPressed: () => _showPostOptions(context),
                 ),
              ],
            ),
          ),

          // Post image
          AspectRatio(
            aspectRatio: 1,
            child: Image.network(
              widget.post.imageUrl,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Center(
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: Colors.grey[300],
                  child: const Center(
                    child: Icon(Icons.error, size: 50),
                  ),
                );
              },
            ),
          ),

          // Action buttons (like, comment)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    _isLiked ? Icons.favorite : Icons.favorite_border,
                    color: _isLiked ? Colors.red : Colors.black,
                  ),
                  onPressed: _toggleLike,
                ),
                Text(
                  '$_likeCount',
                  style: const TextStyle(fontSize: 14),
                ),
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
                Text(
                  '${widget.post.commentCount}',
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),

          // Caption
          if (widget.post.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black, fontSize: 14),
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

          // Timestamp
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Text(
              _formatTimestamp(widget.post.createdAt),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 7) {
      return '${timestamp.month}/${timestamp.day}/${timestamp.year}';
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
