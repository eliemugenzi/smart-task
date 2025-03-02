import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/components/button_component.dart';
import 'package:smarttask/models/task.dart';

class FilterDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final Priority? selectedPriority;
  final List<String> selectedTags;
  final Function(DateTime?, Priority?, List<String>) onApply; // Modified callback
  final VoidCallback onClear;

  const FilterDialog({
    super.key,
    required this.selectedDate,
    required this.selectedPriority,
    required this.selectedTags,
    required this.onApply,
    required this.onClear,
  });

  @override
  State<FilterDialog> createState() => _FilterDialogState();
}

class _FilterDialogState extends State<FilterDialog> {
  late DateTime? _selectedDate;
  late Priority? _selectedPriority;
  late List<String> _selectedTags;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.selectedDate;
    _selectedPriority = widget.selectedPriority;
    _selectedTags = [...widget.selectedTags];
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _showPriorityFilter(BuildContext dialogContext) {
    showDialog(
      context: dialogContext,
      builder: (context) {
        return AlertDialog(
          title: Text('Select Priority'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: Priority.values.map((priority) {
              return RadioListTile<Priority>(
                title: Text(priority.name.capitalize()),
                value: priority,
                groupValue: _selectedPriority,
                onChanged: (value) {
                  setState(() {
                    _selectedPriority = value;
                  });
                  Navigator.pop(context);
                },
              );
            }).toList(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );
  }

  void _showTagsFilter(BuildContext dialogContext) {
    final TextEditingController tagController = TextEditingController();
    // Use a more comprehensive list of default tags
    List<String> availableTags = ['urgent', 'personal', 'work', 'meeting', 'home', 'important', 'low-priority'];
    List<String> tempSelectedTags = [..._selectedTags]; // Copy current tags
    
    // Add any custom tags that aren't in the default list
    for (String tag in _selectedTags) {
      if (!availableTags.contains(tag)) {
        availableTags.add(tag);
      }
    }

    showDialog(
      context: dialogContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            // This function adds a new tag
            void addNewTag(String value) {
              if (value.isNotEmpty && !availableTags.contains(value)) {
                setDialogState(() {
                  availableTags.add(value);
                  tempSelectedTags.add(value);
                  tagController.clear();
                });
                print('Added tag: $value');
                print('Selected tags: $tempSelectedTags');
              }
            }

            return AlertDialog(
              title: Text('Select Tags'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // List of predefined tags with checkboxes
                    ...availableTags.map((tag) {
                      return CheckboxListTile(
                        title: Text(tag),
                        value: tempSelectedTags.contains(tag),
                        onChanged: (bool? value) {
                          setDialogState(() {
                            if (value == true) {
                              tempSelectedTags.add(tag);
                            } else {
                              tempSelectedTags.remove(tag);
                            }
                          });
                        },
                      );
                    }).toList(),
                    
                    // Custom tag input with button
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: tagController,
                              decoration: InputDecoration(
                                hintText: 'Add custom tag...',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: addNewTag,
                            ),
                          ),
                          SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () {
                              addNewTag(tagController.text);
                            },
                            child: Text('Add'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    // Update the main dialog's state with selected tags
                    setState(() {
                      _selectedTags = tempSelectedTags;
                    });
                    Navigator.pop(context);
                  },
                  child: Text('Apply'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Filter Tasks'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('Completion Date'),
              subtitle: Text(_selectedDate == null
                  ? 'None selected'
                  : DateFormat('yyyy-MM-dd').format(_selectedDate!)),
              onTap: () => _selectDate(context),
            ),
            ListTile(
              title: Text('Priority'),
              subtitle: Text(_selectedPriority?.name.capitalize() ?? 'None selected'),
              onTap: () => _showPriorityFilter(context),
            ),
            ListTile(
              title: Text('Tags'),
              subtitle: Text(_selectedTags.isEmpty ? 'None selected' : _selectedTags.join(', ')),
              onTap: () => _showTagsFilter(context),
            ),
            SizedBox(height: 16),
            CustomButton(
              text: 'Clear Filters',
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                  _selectedPriority = null;
                  _selectedTags = [];
                });
                widget.onClear();
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            // Pass selected values back with the callback
            widget.onApply(_selectedDate, _selectedPriority, _selectedTags);
            Navigator.pop(context);
          },
          child: Text('Apply'),
        ),
      ],
    );
  }
}

extension on String {
  String capitalize() {
    if (this.isEmpty) return this;
    return this[0].toUpperCase() + this.substring(1).toLowerCase();
  }
}