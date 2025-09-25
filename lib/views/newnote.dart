// lib/views/new_note_view.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/services/crud/note_services.dart';

class NewNoteView extends StatefulWidget {
  const NewNoteView({ super.key});

  @override
  State<NewNoteView> createState() => _NewNoteViewState();
}

class _NewNoteViewState extends State<NewNoteView> {
  final NoteServices _notesService = NoteServices(); // singleton
  final TextEditingController _controller = TextEditingController();

  DatabaseNotes? _note; // placeholder note created in DB
  bool _isCreating = true;

  @override
  void initState() {
    super.initState();
    _createEmptyNote();
  }

  Future<void> _createEmptyNote() async {
  final fbUser = FirebaseAuth.instance.currentUser;
  if (fbUser == null || fbUser.email == null) {
    Navigator.of(context).pop(); // no logged-in user → leave the page
    return;
  }

  // Get/create local DB user from the email, then create an empty note
  final owner = await _notesService.getOrCreatUser(email: fbUser.email!);
  final created = await _notesService.createNote(owner);


  setState(() {
    _note = created;
    _controller.text = created.text; // usually empty
    _isCreating = false;
  });
}

 

  // Save or delete logic — called when widget is disposed
  Future<void> _saveOrDeleteNoteOnDispose() async {
    // If we never created the placeholder note, nothing to do
    if (_note == null) return;

    final finalText = _controller.text.trim();

    if (finalText.isEmpty) {
      // delete the placeholder note
      try {
        await _notesService.deleteNote(id: _note!.id);
      } catch (e) {
        debugPrint('Error deleting empty note on dispose: $e');
      }
    } else {
      // save (update) the note with the final text
      try {
        await _notesService.updateNote(note: _note!, newText: finalText);
      } catch (e) {
        debugPrint('Error saving note on dispose: $e');
      }
    }
  }

  @override
  void dispose() {
    // Fire-and-forget the save/delete logic.
    // dispose cannot be async, so we call the async function without awaiting.
    _saveOrDeleteNoteOnDispose();
    _controller.dispose();
  
    super.dispose();
  }

  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: const Text('New Note'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Close',
            style: TextStyle(color: Colors.white),
          ),
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
            ),
          ),
        ),
        const Text(
          'Tip: Leave the page to save. Empty note will be deleted.',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    ),
  );
}

}
