// lib/widgets/recipe_form_widget.dart
import 'package:flutter/material.dart';

class RecipeFormWidget extends StatefulWidget {
  final Map<String, dynamic>? initialData;
  final Function(Map<String, dynamic>) onDataChanged;

  const RecipeFormWidget({
    super.key,
    this.initialData,
    required this.onDataChanged,
  });

  @override
  State<RecipeFormWidget> createState() => _RecipeFormWidgetState();
}

class _RecipeFormWidgetState extends State<RecipeFormWidget> {
  late TextEditingController _commentaryController;
  late TextEditingController _cookTimeController;
  late TextEditingController _instructionsController;

  String _selectedDifficulty = 'Easy';
  List<Map<String, dynamic>> _ingredients = [];

  final List<String> _difficultyLevels = [
    'Easy',
    'Intermediate',
    'Difficult',
    'Expert',
  ];

  @override
  void initState() {
    super.initState();
    _commentaryController = TextEditingController(
      text: widget.initialData?['commentary'] ?? '',
    );
    _cookTimeController = TextEditingController(
      text: widget.initialData?['cookTime'] ?? '',
    );
    _instructionsController = TextEditingController(
      text: widget.initialData?['instructions'] ?? '',
    );
    _selectedDifficulty = widget.initialData?['difficulty'] ?? 'Easy';

    // Load existing ingredients if any
    if (widget.initialData?['ingredients'] != null) {
      _ingredients = List<Map<String, dynamic>>.from(
        widget.initialData!['ingredients'].map((e) => Map<String, dynamic>.from(e))
      );
    }
  }

  @override
  void dispose() {
    _commentaryController.dispose();
    _cookTimeController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  void _notifyChange() {
    final data = <String, dynamic>{};

    if (_commentaryController.text.trim().isNotEmpty) {
      data['commentary'] = _commentaryController.text.trim();
    }

    data['difficulty'] = _selectedDifficulty;

    if (_cookTimeController.text.trim().isNotEmpty) {
      data['cookTime'] = _cookTimeController.text.trim();
    }

    if (_ingredients.isNotEmpty) {
      data['ingredients'] = _ingredients;
    }

    if (_instructionsController.text.trim().isNotEmpty) {
      data['instructions'] = _instructionsController.text.trim();
    }

    widget.onDataChanged(data);
  }

  void _addIngredient() {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        onSave: (ingredient) {
          setState(() {
            _ingredients.add(ingredient);
          });
          _notifyChange();
        },
      ),
    );
  }

  void _editIngredient(int index) {
    showDialog(
      context: context,
      builder: (context) => _IngredientDialog(
        initialIngredient: _ingredients[index],
        onSave: (ingredient) {
          setState(() {
            _ingredients[index] = ingredient;
          });
          _notifyChange();
        },
      ),
    );
  }

  void _deleteIngredient(int index) {
    setState(() {
      _ingredients.removeAt(index);
    });
    _notifyChange();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Icon(Icons.restaurant, color: Colors.orange[700]),
              const SizedBox(width: 8),
              Text(
                'Recipe Details',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange[700],
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
              hintText: 'Any notes or thoughts about this recipe?',
            ),
            maxLines: 3,
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),

          // Difficulty Dropdown
          DropdownButtonFormField<String>(
            value: _selectedDifficulty,
            decoration: InputDecoration(
              labelText: 'Difficulty',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.bar_chart),
            ),
            items: _difficultyLevels.map((difficulty) {
              return DropdownMenuItem(
                value: difficulty,
                child: Text(difficulty),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _selectedDifficulty = value;
                });
                _notifyChange();
              }
            },
          ),
          const SizedBox(height: 16),

          // Cook Time
          TextField(
            controller: _cookTimeController,
            decoration: InputDecoration(
              labelText: 'Cook Time',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'e.g., 30 minutes, 1 hour',
              prefixIcon: const Icon(Icons.timer),
            ),
            onChanged: (_) => _notifyChange(),
          ),
          const SizedBox(height: 16),

          // Ingredients Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ingredients',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
              TextButton.icon(
                onPressed: _addIngredient,
                icon: const Icon(Icons.add_circle_outline, size: 18),
                label: const Text('Add'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.orange[700],
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Ingredient List
          if (_ingredients.isNotEmpty)
            ...List.generate(_ingredients.length, (index) {
              final ingredient = _ingredients[index];
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
                    ingredient['name'],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  subtitle: ingredient['amount'] != null
                      ? Text(
                          ingredient['amount'],
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        )
                      : null,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, size: 20, color: Colors.grey[700]),
                        onPressed: () => _editIngredient(index),
                        tooltip: 'Edit',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, size: 20, color: Colors.red),
                        onPressed: () => _deleteIngredient(index),
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
                  Icon(Icons.restaurant, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'No ingredients added yet',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 16),

          // Instructions
          TextField(
            controller: _instructionsController,
            decoration: InputDecoration(
              labelText: 'Instructions',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Step-by-step cooking instructions...',
              prefixIcon: const Icon(Icons.format_list_numbered),
            ),
            maxLines: 5,
            onChanged: (_) => _notifyChange(),
          ),
        ],
      ),
    );
  }
}

// Ingredient Dialog
class _IngredientDialog extends StatefulWidget {
  final Map<String, dynamic>? initialIngredient;
  final Function(Map<String, dynamic>) onSave;

  const _IngredientDialog({
    this.initialIngredient,
    required this.onSave,
  });

  @override
  State<_IngredientDialog> createState() => _IngredientDialogState();
}

class _IngredientDialogState extends State<_IngredientDialog> {
  late TextEditingController _nameController;
  late TextEditingController _amountController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialIngredient?['name'] ?? '',
    );
    _amountController = TextEditingController(
      text: widget.initialIngredient?['amount'] ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _save() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter ingredient name')),
      );
      return;
    }

    final ingredient = <String, dynamic>{
      'name': _nameController.text.trim(),
    };

    if (_amountController.text.trim().isNotEmpty) {
      ingredient['amount'] = _amountController.text.trim();
    }

    widget.onSave(ingredient);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        widget.initialIngredient == null ? 'Add Ingredient' : 'Edit Ingredient',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Ingredient Name *',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'e.g., Flour, Eggs, Salt',
              ),
              textCapitalization: TextCapitalization.words,
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _amountController,
              decoration: InputDecoration(
                labelText: 'Amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                hintText: 'e.g., 2 cups, 3 tbsp, 1/2 tsp',
              ),
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
            backgroundColor: Colors.orange[700],
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
