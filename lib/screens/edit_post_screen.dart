// lib/screens/edit_post_screen.dart
import 'package:flutter/material.dart';
import '../models/post_model.dart';
import '../services/firestore_service.dart';
import '../widgets/activity_form_widget.dart';
import '../widgets/recipe_form_widget.dart';

class EditPostScreen extends StatefulWidget {
  final PostModel post;

  const EditPostScreen({super.key, required this.post});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _captionController;
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoading = false;
  String _selectedType = 'freeform';
  Map<String, dynamic>? _activityData;
  Map<String, dynamic>? _recipeData;

  @override
  void initState() {
    super.initState();
    _captionController = TextEditingController(text: widget.post.caption);
    _selectedType = widget.post.type ?? 'freeform';
    _activityData = widget.post.activityData;
    _recipeData = widget.post.recipeData;
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await _firestoreService.updatePost(
        postId: widget.post.id,
        caption: _captionController.text.trim(),
        type: _selectedType,
        activityData: _selectedType == 'activity' ? _activityData : null,
        recipeData: _selectedType == 'meal' ? _recipeData : null,
      );

      if (mounted) {
        // Navigate back and pass success indicator
        Navigator.pop(context, 'success');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating post: $e')),
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
        title: const Text('Edit Post'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            TextButton(
              onPressed: _saveChanges,
              child: const Text(
                'Save',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image preview (not editable)
              Container(
                height: 300,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    children: [
                      Image.network(
                        widget.post.imageUrl,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                      // Overlay to show it's not editable
                      Container(
                        color: Colors.black.withOpacity(0.1),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Photo cannot be changed',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Post type selector
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'freeform',
                    label: Text('Freeform'),
                    icon: Icon(Icons.edit),
                  ),
                  ButtonSegment(
                    value: 'activity',
                    label: Text('Activity'),
                    icon: Icon(Icons.fitness_center),
                  ),
                  ButtonSegment(
                    value: 'meal',
                    label: Text('Meal'),
                    icon: Icon(Icons.restaurant),
                  ),
                ],
                selected: {_selectedType},
                onSelectionChanged: (Set<String> newSelection) {
                  setState(() {
                    _selectedType = newSelection.first;
                    if (_selectedType != 'activity') {
                      _activityData = null;
                    }
                    if (_selectedType != 'meal') {
                      _recipeData = null;
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Caption field
              TextFormField(
                controller: _captionController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'Write a caption...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a caption';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Activity form (only show if type is activity)
              if (_selectedType == 'activity')
                ActivityFormWidget(
                  initialData: _activityData,
                  onDataChanged: (data) {
                    setState(() {
                      _activityData = data;
                    });
                  },
                ),

              // Recipe form (only show if type is meal)
              if (_selectedType == 'meal')
                RecipeFormWidget(
                  initialData: _recipeData,
                  onDataChanged: (data) {
                    setState(() {
                      _recipeData = data;
                    });
                  },
                ),

              const SizedBox(height: 24),

              // Save button (alternative to app bar button)
              ElevatedButton(
                onPressed: _isLoading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.greenAccent[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
