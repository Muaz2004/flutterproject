// lib/views/edit_note_view.dart
import 'package:flutter/material.dart';
import 'package:hello_flutter/services/crud/note_services.dart';
import 'package:share_plus/share_plus.dart';

class EditNoteView extends StatefulWidget {
  final DatabaseNotes note;
  const EditNoteView({required this.note, super.key});

  @override
  State<EditNoteView> createState() => _EditNoteViewState();
}

class _EditNoteViewState extends State<EditNoteView> {
  final NoteServices _notesService = NoteServices(); // singleton
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    // start with the existing note text so user can read immediately
    _controller = TextEditingController(text: widget.note.text);
  }

  @override
  void dispose() {
    _controller.dispose();
    _onClosePressed();
    super.dispose();
  }

  // Close: save if non-empty (update), delete if empty, then pop.
  Future<void> _onClosePressed() async {
    final text = _controller.text.trim();

    try {
      if (text.isEmpty) {
        // delete note if user cleared the content
        await _notesService.deleteNote(id: widget.note.id);
      } else if (text != widget.note.text) {
        // update only if changed
        await _notesService.updateNote(note: widget.note, newText: text);
      }
    } catch (e) {
      // show error, then still pop (simple beginner-friendly behavior)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Operation failed: $e')),
      );
    }

    Navigator.of(context).pop();
  }

  // Optional delete button in app bar: confirm -> delete -> pop
  Future<void> _onDeletePressed() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text('Delete')),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _notesService.deleteNote(id: widget.note.id);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Delete failed: $e')),
      );
    }

    Navigator.of(context).pop();
  }


  Future<void> _onSharePressed() async {
    final text = _controller.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nothing to share — note is empty!')),
      );
      return;
    }
    await Share.share(text); // 👈 share the note text
  }

  @override
  Widget build(BuildContext context) {
    // Simple UI: show the full note text in a TextField immediately (editable)
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete),
            tooltip: 'Delete note',
            onPressed: _onDeletePressed,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed:_onSharePressed
          ),
          TextButton(
            onPressed: _onClosePressed,
            child: const Text('Close', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              autofocus: true,
              maxLines: null,
              decoration: const InputDecoration(
                hintText: 'Type your note here...',
                contentPadding: EdgeInsets.all(12),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tip: Press Close to save. Clearing text will delete the note.',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
