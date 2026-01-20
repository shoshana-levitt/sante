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
  final String? userId;

  const ProfileScreen({super.key, this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();
  UserModel? _user;
  bool _isLoading = true;
  int _postCount = 0;
  int _archivedCount = 0;
  late TabController _tabController;

  // Follow state
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadUserData();
    _checkFollowStatus();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  String get _profileUserId {
    return widget.userId ?? _authService.currentUser!.uid;
  }

  bool get _isCurrentUser {
    return _profileUserId == _authService.currentUser?.uid;
  }

  Future<void> _checkFollowStatus() async {
    if (!_isCurrentUser) {
      final currentUserId = _authService.currentUser?.uid;
      if (currentUserId != null) {
        bool following = await _firestoreService.isFollowing(currentUserId, _profileUserId);
        setState(() {
          _isFollowing = following;
        });
      }
    }
  }

  Future<void> _toggleFollow() async {
    final currentUserId = _authService.currentUser?.uid;
    if (currentUserId == null) return;

    if (_isFollowing) {
      // Show unfollow confirmation dialog
      bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Unfollow'),
            content: Text('Unfollow @${_user?.username ?? 'this user'}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Unfollow'),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
    }

    setState(() {
      _isFollowLoading = true;
    });

    try {
      if (_isFollowing) {
        await _firestoreService.unfollowUser(currentUserId, _profileUserId);
        setState(() {
          _isFollowing = false;
        });
      } else {
        await _firestoreService.followUser(currentUserId, _profileUserId);
        setState(() {
          _isFollowing = true;
        });
      }
      // Reload user data to update follower count
      await _loadUserData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isFollowLoading = false;
        });
      }
    }
  }

  Future<void> _loadUserData() async {
    try {
      DocumentSnapshot userDoc = await _firestoreService.getUser(_profileUserId);
      if (userDoc.exists) {
        setState(() {
          _user = UserModel.fromFirestore(userDoc);
        });
      }

      // Get post count (non-archived)
      QuerySnapshot postsSnapshot = await FirebaseFirestore.instance
          .collection('posts')
          .where('userId', isEqualTo: _profileUserId)
          .where('isArchived', isEqualTo: false)
          .get();

      // Get archived count (only for current user)
      int archivedCount = 0;
      if (_isCurrentUser) {
        QuerySnapshot archivedSnapshot = await FirebaseFirestore.instance
            .collection('posts')
            .where('userId', isEqualTo: _profileUserId)
            .where('isArchived', isEqualTo: true)
            .get();
        archivedCount = archivedSnapshot.docs.length;
      }

      setState(() {
        _postCount = postsSnapshot.docs.length;
        _archivedCount = archivedCount;
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
      child: Column(
        children: [
          // Profile header
          Column(
            children: [
              const SizedBox(height: 16),
              // Profile picture and stats
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
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
              // Name, username, and bio (left aligned)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: SizedBox(
                  width: double.infinity, // Force full width
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Left align
                    children: [
                      Text(
                        _user!.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${_user!.username}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      if (_user!.bio.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(_user!.bio),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Edit Profile / Logout button (for current user) OR Follow button (for other users)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: _isCurrentUser
                    ? Row(
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
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isFollowLoading ? null : _toggleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFollowing
                                    ? Colors.grey[300]
                                    : Colors.greenAccent[700],
                                foregroundColor: _isFollowing
                                    ? Colors.black
                                    : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: _isFollowLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : Text(
                                      _isFollowing ? 'Following' : 'Follow',
                                      style: const TextStyle(fontWeight: FontWeight.bold),
                                    ),
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 16),
              const Divider(height: 1),

              // Tabs (only show for current user)
              if (_isCurrentUser)
                TabBar(
                  controller: _tabController,
                  labelColor: Colors.black,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.greenAccent[700],
                  tabs: [
                    Tab(
                      icon: const Icon(Icons.grid_on),
                      text: 'Posts',
                    ),
                    Tab(
                      icon: const Icon(Icons.archive_outlined),
                      text: 'Archived ($_archivedCount)',
                    ),
                  ],
                ),
            ],
          ),

          // Tab views
          Expanded(
            child: _isCurrentUser
                ? TabBarView(
                    controller: _tabController,
                    children: [
                      _buildPostsGrid(isArchived: false),
                      _buildPostsGrid(isArchived: true),
                    ],
                  )
                : _buildPostsGrid(isArchived: false),
          ),
        ],
      ),
    );
  }

  Widget _buildPostsGrid({required bool isArchived}) {
    return StreamBuilder<QuerySnapshot>(
      stream: isArchived
          ? _firestoreService.getArchivedPosts(_profileUserId)
          : _firestoreService.getUserPosts(_profileUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isArchived ? Icons.archive_outlined : Icons.photo_library_outlined,
                  size: 80,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 16),
                Text(
                  isArchived
                      ? 'No archived posts'
                      : (_isCurrentUser ? 'No posts yet' : 'No posts'),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (!isArchived && _isCurrentUser) ...[
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
          );
        }

        List<PostModel> posts = snapshot.data!.docs
            .map((doc) => PostModel.fromFirestore(doc))
            .toList();

        return GridView.builder(
          padding: const EdgeInsets.all(2.0),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2,
            mainAxisSpacing: 2,
          ),
          itemCount: posts.length,
          itemBuilder: (context, index) {
            return GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => PostDetailScreen(post: posts[index]),
                  ),
                ).then((_) => _loadUserData()); // Refresh counts when returning
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
        );
      },
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
