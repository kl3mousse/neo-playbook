import 'package:flutter/material.dart';
import '../models/community_note.dart';
import '../services/notes_service.dart';

class AddNoteSheet extends StatefulWidget {
  final String gameId;
  const AddNoteSheet({super.key, required this.gameId});

  @override
  State<AddNoteSheet> createState() => _AddNoteSheetState();
}

class _AddNoteSheetState extends State<AddNoteSheet> {
  final _textController = TextEditingController();
  NoteCategory _category = NoteCategory.tip;
  bool _submitting = false;

  Future<void> _submit() async {
    final text = _textController.text.trim();
    if (text.length < 3) return;

    setState(() => _submitting = true);
    try {
      await NotesService.addNote(
        gameId: widget.gameId,
        category: _category,
        text: text,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        16,
        16,
        16,
        MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add Note',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          // Category selector
          Wrap(
            spacing: 8,
            children: NoteCategory.values.map((cat) {
              return ChoiceChip(
                label: Text(cat.label),
                selected: _category == cat,
                onSelected: (_) => setState(() => _category = cat),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          // Text input
          TextField(
            controller: _textController,
            decoration: const InputDecoration(
              hintText: 'Share a tip, strategy, or combo...',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            maxLength: 500,
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Post Note'),
            ),
          ),
        ],
      ),
    );
  }
}
