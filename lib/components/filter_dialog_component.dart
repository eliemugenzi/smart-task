// components/filter_dialog.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:smarttask/components/button_component.dart';
import 'package:smarttask/models/task.dart';

class FilterDialog extends StatefulWidget {
  final DateTime? selectedDate;
  final Priority? selectedPriority;
  final List<String> selectedTags;
  final VoidCallback onApply;
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
    final TextEditingController _tagController = TextEditingController();
    List<String> availableTags = ['urgent', 'personal', 'work', 'meeting']; // Example tags; customize as needed
    List<String> tempSelectedTags = [..._selectedTags]; // Copy current tags

    showDialog(
      context: dialogContext,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text('Select Tags'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...availableTags.map((tag) {
                    return CheckboxListTile(
                      title: Text(tag),
                      value: tempSelectedTags.contains(tag),
                      onChanged: (bool? value) {
                        setState(() {
                          if (value == true) {
                            tempSelectedTags.add(tag);
                          } else {
                            tempSelectedTags.remove(tag);
                          }
                        });
                      },
                    );
                  }).toList(),
                  TextField(
                    controller: _tagController,
                    decoration: InputDecoration(
                      hintText: 'Add custom tag...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) {
                      if (value.isNotEmpty && !availableTags.contains(value)) {
                        setState(() {
                          availableTags.add(value);
                          tempSelectedTags.add(value);
                        });
                        _tagController.clear();
                      }
                    },
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
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
              onPressed: widget.onClear,
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
            widget.onApply();
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