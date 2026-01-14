import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';

class CommentsScreen extends StatefulWidget {
  final PostModel post;

  const CommentsScreen({super.key, required this.post});

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must be logged in to comment')),
      );
      return;
    }

    setState(() {
      _isPosting = true;
    });

    try {
      await _firestoreService.addComment(
        postId: widget.post.id,
        userId: currentUserId,
        text: _commentController.text.trim(),
      );

      _commentController.clear();
      FocusScope.of(context).unfocus();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment posted!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error posting comment: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPosting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Comments'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Comments list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestoreService.getComments(widget.post.id),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.comment_outlined,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No comments yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Be the first to comment!',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final comments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index].data() as Map<String, dynamic>;
                    final commentId = comments[index].id;
                    final userId = comment['userId'] ?? '';
                    final text = comment['text'] ?? '';
                    final createdAt = (comment['createdAt'] as Timestamp?)?.toDate();

                    return FutureBuilder<DocumentSnapshot>(
                      future: _firestoreService.getUser(userId),
                      builder: (context, userSnapshot) {
                        String username = 'User';
                        String photoUrl = '';

                        if (userSnapshot.hasData && userSnapshot.data!.exists) {
                          final userData = userSnapshot.data!.data() as Map<String, dynamic>;
                          username = userData['username'] ?? 'User';
                          photoUrl = userData['photoUrl'] ?? '';
                        }

                        final isOwnComment = userId == _authService.currentUser?.uid;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Profile picture
                              CircleAvatar(
                                radius: 18,
                                backgroundColor: Colors.greenAccent[700],
                                backgroundImage: photoUrl.isNotEmpty
                                    ? NetworkImage(photoUrl)
                                    : null,
                                child: photoUrl.isEmpty
                                    ? Text(
                                        username[0].toUpperCase(),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              // Comment content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Username and comment
                                    RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '$username ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(text: text),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    // Timestamp
                                    Text(
                                      _formatTimestamp(createdAt),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Delete button (only for own comments)
                              if (isOwnComment)
                                IconButton(
                                  icon: Icon(
                                    Icons.delete_outline,
                                    size: 20,
                                    color: Colors.grey[600],
                                  ),
                                  onPressed: () => _showDeleteDialog(commentId),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),

          // Comment input
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.2),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -1),
                ),
              ],
            ),
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    // User avatar
                    CircleAvatar(
                      radius: 18,
                      backgroundColor: Colors.greenAccent[700],
                      child: Text(
                        _authService.currentUser?.email?[0].toUpperCase() ?? 'U',
                        style: const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text field
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        maxLines: null,
                        textCapitalization: TextCapitalization.sentences,
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Post button
                    _isPosting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.send,
                              color: Colors.greenAccent[700],
                            ),
                            onPressed: _postComment,
                          ),
                  ],
                ),
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

  void _showDeleteDialog(String commentId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Comment'),
          content: const Text('Are you sure you want to delete this comment?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await _deleteComment(commentId);
              },
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteComment(String commentId) async {
    try {
      // Delete from Firestore
      await FirebaseFirestore.instance
          .collection('comments')
          .doc(commentId)
          .delete();

      // Decrement comment count
      await FirebaseFirestore.instance
          .collection('posts')
          .doc(widget.post.id)
          .update({
        'commentCount': FieldValue.increment(-1),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Comment deleted')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting comment: $e')),
        );
      }
    }
  }
}
