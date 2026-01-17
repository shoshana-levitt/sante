import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/user_model.dart';
import '../models/post_model.dart';
import 'login_screen.dart';
import 'edit_profile_screen.dart';
import 'post_detail_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String? userId; // If null, show current user's profile

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = true;
  int _postCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String get _profileUserId {
    return widget.userId ?? _authService.currentUser!.uid;
  }

  bool get _isCurrentUser {
    return _profileUserId == _authService.currentUser?.uid;
  }

  Future<void> _loadUserData() async {
    try {
      // Get user data
      DocumentSnapshot userDoc = await _firestoreService.getUser(_profileUserId);
      if (userDoc.exists) {
        setState(() {
          _user = UserModel.fromFirestore(userDoc);
        });
      }

      // Get post count
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _profileUserId)
          .get();

      setState(() {
        _postCount = postsSnapshot.docs.length;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading user data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_user == null) {
      return const Center(child: Text('User not found'));
    }

    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: CustomScrollView(
        slivers: [
          // Profile header
          SliverToBoxAdapter(
            child: Column(
              children: [
                const SizedBox(height: 16),
                // Profile picture, stats, and edit button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      // Profile picture
                      CircleAvatar(
                        radius: 40,
                        backgroundColor: Colors.greenAccent[700],
                        backgroundImage: _user!.photoUrl.isNotEmpty
                            ? NetworkImage(_user!.photoUrl)
                            : null,
                        child: _user!.photoUrl.isEmpty
                            ? Text(
                                _user!.username[0].toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 24),
                      // Stats
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            _buildStatColumn(_postCount.toString(), 'Posts'),
                            _buildStatColumn(
                                _user!.followerCount.toString(), 'Followers'),
                            _buildStatColumn(
                                _user!.followingCount.toString(), 'Following'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Name and bio
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _user!.username,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      if (_user!.bio.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(_user!.bio),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // Edit Profile / Logout button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(user: _user!),
                              ),
                            );
                            if (result == true) {
                              _loadUserData();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey[300]!),
                          ),
                          child: const Text(
                            'Edit Profile',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _handleLogout,
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.red[300]!),
                        ),
                        child: const Icon(Icons.logout, color: Colors.red),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Divider(height: 1),
              ],
            ),
          ),
          // Posts grid
          StreamBuilder<QuerySnapshot>(
            stream: _firestoreService.getUserPosts(_profileUserId),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.photo_library_outlined,
                          size: 80,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _isCurrentUser ? 'No posts yet' : 'No posts',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_isCurrentUser) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Share your first photo!',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                );
              }

              List<PostModel> posts = snapshot.data!.docs
                  .map((doc) => PostModel.fromFirestore(doc))
                  .toList();

              return SliverPadding(
                padding: const EdgeInsets.all(2.0),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 2,
                    mainAxisSpacing: 2,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  PostDetailScreen(post: posts[index]),
                            ),
                          );
                        },
                        child: Image.network(
                          posts[index].imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: Colors.grey[300],
                              child: const Center(
                                child: CircularProgressIndicator(),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[300],
                              child: const Icon(Icons.error),
                            );
                          },
                        ),
                      );
                    },
                    childCount: posts.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label) {
    return Column(
      children: [
        Text(
          count,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
