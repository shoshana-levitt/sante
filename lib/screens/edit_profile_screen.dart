// lib/screens/edit_profile_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';
import '../services/storage_service.dart';
import '../services/firestore_service.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;

  const EditProfileScreen({super.key, required this.user});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _usernameController;
  late TextEditingController _bioController;
  final StorageService _storageService = StorageService();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  File? _imageFile;
  bool _isLoading = false;
  String? _currentPhotoUrl;
  String? _usernameError;
  bool _checkingUsername = false;
  String _originalUsername = '';

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _usernameController = TextEditingController(text: widget.user.username);
    _bioController = TextEditingController(text: widget.user.bio);
    _currentPhotoUrl = widget.user.photoUrl;
    _originalUsername = widget.user.username.toLowerCase();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  // Check username availability
  Future<void> _checkUsernameAvailability(String username) async {
    // Don't check if it's the user's current username
    if (username.toLowerCase() == _originalUsername) {
      setState(() {
        _usernameError = null;
        _checkingUsername = false;
      });
      return;
    }

    if (username.isEmpty || username.length < 3) return;

    setState(() {
      _checkingUsername = true;
      _usernameError = null;
    });

    bool isTaken = await _firestoreService.isUsernameTaken(username);

    if (mounted) {
      setState(() {
        _checkingUsername = false;
        if (isTaken) {
          _usernameError = 'This username is already taken';
        }
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    // Check username one more time before saving if it changed
    if (_usernameController.text.trim().toLowerCase() != _originalUsername) {
      bool usernameTaken = await _firestoreService.isUsernameTaken(
        _usernameController.text.trim()
      );

      if (usernameTaken) {
        setState(() {
          _usernameError = 'This username is already taken';
        });
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    try {
      String photoUrl = _currentPhotoUrl ?? '';

      // Upload new profile picture if selected
      if (_imageFile != null) {
        photoUrl = await _storageService.uploadProfilePicture(
          _imageFile!,
          widget.user.id,
        );
      }

      // Update user document
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.user.id)
          .update({
        'name': _nameController.text.trim(),
        'username': _usernameController.text.trim().toLowerCase(),
        'bio': _bioController.text.trim(),
        'photoUrl': photoUrl,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated!')),
        );
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating profile: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          TextButton(
            onPressed: (_isLoading || _checkingUsername) ? null : _saveProfile,
            child: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(
                    'Save',
                    style: TextStyle(
                      color: (_checkingUsername)
                          ? Colors.grey
                          : Colors.greenAccent[700],
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Profile picture
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.greenAccent[700],
                      backgroundImage: _imageFile != null
                          ? FileImage(_imageFile!)
                          : (_currentPhotoUrl?.isNotEmpty ?? false)
                              ? NetworkImage(_currentPhotoUrl!)
                              : null,
                      child: (_imageFile == null &&
                              (_currentPhotoUrl?.isEmpty ?? true))
                          ? Text(
                              widget.user.username[0].toUpperCase(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 40,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.greenAccent[700],
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: _pickImage,
                child: const Text('Change Profile Photo'),
              ),
              const SizedBox(height: 32),

              // Name field
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.badge),
                ),
                textCapitalization: TextCapitalization.words,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Username field with validation
              TextFormField(
                controller: _usernameController,
                decoration: InputDecoration(
                  labelText: 'Username',
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.person),
                  suffixIcon: _checkingUsername
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : _usernameError == null &&
                        _usernameController.text.isNotEmpty &&
                        _usernameController.text.trim().toLowerCase() != _originalUsername
                          ? const Icon(Icons.check_circle, color: Colors.green)
                          : null,
                  errorText: _usernameError,
                  errorMaxLines: 2,
                  helperText: _usernameController.text.trim().toLowerCase() == _originalUsername
                      ? 'Current username'
                      : null,
                ),
                onChanged: (value) {
                  // Debounce the check
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (value == _usernameController.text && value.length >= 3) {
                      _checkUsernameAvailability(value);
                    }
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a username';
                  }
                  if (value.length < 3) {
                    return 'Username must be at least 3 characters';
                  }
                  if (value.contains(' ')) {
                    return 'Username cannot contain spaces';
                  }
                  if (_usernameError != null) {
                    return _usernameError;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Bio field
              TextFormField(
                controller: _bioController,
                maxLines: 4,
                maxLength: 150,
                decoration: const InputDecoration(
                  labelText: 'Bio',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
