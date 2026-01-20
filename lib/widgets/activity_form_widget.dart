// lib/widgets/activity_form_widget.dart
import 'package:flutter/material.dart';

class ActivityFormWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const ActivityFormWidget({
    super.key,
    this.initialData,
    required this.onDataChanged,
  });

  @override
  State<ActivityFormWidget> createState() => _ActivityFormWidgetState();
}

class _ActivityFormWidgetState extends State<ActivityFormWidget> {
  late TextEditingController _commentaryController;
  late TextEditingController _activityTypeController;
  late TextEditingController _locationController;
  late TextEditingController _distanceController;

  List<Map<String, dynamic>> _exercises = [];

  @override
  void initState() {
    super.initState();
    _commentaryController = TextEditingController(
      text: widget.initialData?['commentary'] ?? '',
    );
    _activityTypeController = TextEditingController(
      text: widget.initialData?['activityType'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.initialData?['location'] ?? '',
    );
    _distanceController = TextEditingController(
      text: widget.initialData?['distance'] ?? '',
    );

    // Load existing exercises if any
    if (widget.initialData?['exercises'] != null) {
      _exercises = List<Map<String, dynamic>>.from(
        widget.initialData!['exercises'].map((e) => Map<String, dynamic>.from(e))
      );
    }
  }

  @override
  void dispose() {
    _commentaryController.dispose();
    _activityTypeController.dispose();
    _locationController.dispose();
    _distanceController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final data = <String, dynamic>{};

    if (_commentaryController.text.trim().isNotEmpty) {
      data['commentary'] = _commentaryController.text.trim();
    }

    if (_activityTypeController.text.trim().isNotEmpty) {
      data['activityType'] = _activityTypeController.text.trim();
    }

    if (_exercises.isNotEmpty) {
      data['exercises'] = _exercises;
    }

    if (_locationController.text.trim().isNotEmpty) {
      data['location'] = _locationController.text.trim();
    }

    if (_distanceController.text.trim().isNotEmpty) {
      data['distance'] = _distanceController.text.trim();
    }

    widget.onDataChanged(data);
  }

  void _addExercise() {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        onSave: (exercise) {
          setState(() {
            _exercises.add(exercise);
          });
          _notifyChange();
        },
      ),
    );
  }

  void _editExercise(int index) {
    showDialog(
      context: context,
      builder: (context) => _ExerciseDialog(
        initialExercise: _exercises[index],
        onSave: (exercise) {
          setState(() {
            _exercises[index] = exercise;
          });
          _notifyChange();
        },
      ),
    );
  }

  void _deleteExercise(int index) {
    setState(() {
      _exercises.removeAt(index);
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.greenAccent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.fitness_center, color: Colors.greenAccent[700]),
              const SizedBox(width: 8),
              Text(
                'Activity Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.greenAccent[700],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Commentary
          TextField(
            controller: _commentaryController,
            decoration: InputDecoration(
              labelText: 'Commentary',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'How did it go? Any thoughts?',
            ),
            maxLines: 3,
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),

          // Activity Type
          TextField(
            controller: _activityTypeController,
            decoration: InputDecoration(
              labelText: 'Type of Activity',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'e.g., Strength Training, Cardio, Yoga',
              prefixIcon: const Icon(Icons.directions_run),
            ),
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),

          // Exercises Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Exercises',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: _addExercise,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.greenAccent[700],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Exercise List
          if (_exercises.isNotEmpty)
            ...List.generate(_exercises.length, (index) {
              final exercise = _exercises[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                  side: BorderSide(color: Colors.grey[300]!),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  title: Text(
                    exercise['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: Text(
                    [
                      if (exercise['sets'] != null) '${exercise['sets']} sets',
                      if (exercise['reps'] != null) '${exercise['reps']} reps',
                      if (exercise['weight'] != null) '${exercise['weight']} lbs',
                    ].join(' • '),
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 20, color: Colors.grey[700]),
                        onPressed: () => _editExercise(index),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _deleteExercise(index),
                        tooltip: 'Delete',
                      ),
                    ],
                  ),
                ),
              );
            })
          else
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fitness_center, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No exercises added yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Location
          TextField(
            controller: _locationController,
            decoration: InputDecoration(
              labelText: 'Location',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'e.g., Gold\'s Gym, Central Park',
              prefixIcon: const Icon(Icons.location_on),
            ),
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),

          // Distance
          TextField(
            controller: _distanceController,
            decoration: InputDecoration(
              labelText: 'Distance',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'e.g., 5 miles, 10k',
              prefixIcon: const Icon(Icons.straighten),
            ),
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ),
    );
  }
}

// Exercise Dialog
class _ExerciseDialog extends StatefulWidget {
  final Map<String, dynamic>? initialExercise;
  final Function(Map<String, dynamic>) onSave;

  const _ExerciseDialog({
    this.initialExercise,
    required this.onSave,
  });

  @override
  State<_ExerciseDialog> createState() => _ExerciseDialogState();
}

class _ExerciseDialogState extends State<_ExerciseDialog> {
  late TextEditingController _nameController;
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialExercise?['name'] ?? '',
    );
    _setsController = TextEditingController(
      text: widget.initialExercise?['sets']?.toString() ?? '',
    );
    _repsController = TextEditingController(
      text: widget.initialExercise?['reps']?.toString() ?? '',
    );
    _weightController = TextEditingController(
      text: widget.initialExercise?['weight']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _setsController.dispose();
    _repsController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter exercise name')),
      );
      return;
    }

    final exercise = <String, dynamic>{
      'name': _nameController.text.trim(),
    };

    final sets = int.tryParse(_setsController.text);
    if (sets != null) {
      exercise['sets'] = sets;
    }

    final reps = int.tryParse(_repsController.text);
    if (reps != null) {
      exercise['reps'] = reps;
    }

    final weight = double.tryParse(_weightController.text);
    if (weight != null) {
      exercise['weight'] = weight;
    }

    widget.onSave(exercise);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialExercise == null ? 'Add Exercise' : 'Edit Exercise',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Exercise Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'e.g., Bench Press',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    decoration: InputDecoration(
                      labelText: 'Sets',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: '3',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    decoration: InputDecoration(
                      labelText: 'Reps',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      hintText: '10',
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _weightController,
              decoration: InputDecoration(
                labelText: 'Weight (lbs)',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: '135',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.greenAccent[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
