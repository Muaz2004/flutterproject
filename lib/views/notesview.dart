import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/services/crud/note_services.dart';
import 'package:hello_flutter/views/edit_note_view.dart';

class NotesView extends StatefulWidget {
  const NotesView({super.key});

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  final NoteServices _notesService = NoteServices();
  DatabaseUser? _user;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // 1) Open DB
      await _notesService.open();

      // 2) Get or create the user
      final user = await _notesService.getOrCreatUser(
        email: FirebaseAuth.instance.currentUser!.email!,
      );

      setState(() {
        _user = user;
        _isLoading = false;
      });

      // 3) Populate the stream AFTER the UI is ready to listen
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notesService.refreshNotes();
      });
    } catch (e, st) {
      debugPrint('Initialization error: $e\n$st');
      setState(() {
        _isLoading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error initializing notes: $e')),
        );
      });
    }
  }

  // Show a confirmation dialog and return true if user confirms deletion
  Future<bool> _showDeleteConfirmationDialog(BuildContext context) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete note'),
        content: const Text('Are you sure you want to delete this note?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return result == true;
  }

  // Called when user taps delete icon
  Future<void> _deleteNoteConfirmed(DatabaseNotes note) async {
    final confirmed = await _showDeleteConfirmationDialog(context);
    if (!confirmed) return;

    try {
      await _notesService.deleteNote(id: note.id);
      // service updates its internal list and emits to the stream, so UI refreshes
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Note deleted')),
      );
    } catch (e) {
      debugPrint('Delete note failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete note: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final user = _user;
    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('User not available')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("My Notes"),
        actions: [
          IconButton(
            tooltip: 'New note',
            icon: const Icon(Icons.note_add),
            onPressed: () async {
              Navigator.of(context).pushNamed('/newnote');
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) async {
              if (value == 'logout') {
                final shouldLogout = await showDialog<bool>(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text("Sign out?"),
                      content: const Text("Are you sure you want to log out?"),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text("Cancel"),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text("Log out"),
                        ),
                      ],
                    );
                  },
                );
                if (shouldLogout == true) {
                  await _notesService.close(); // close DB on logout
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context)
                      .pushNamedAndRemoveUntil('/login', (_) => false);
                }
              }
            },
            itemBuilder: (context) {
              return const [
                PopupMenuItem<String>(
                  value: 'logout',
                  child: Text("Log out"),
                ),
              ];
            },
          ),
        ],
      ),
      body: StreamBuilder<List<DatabaseNotes>>(
        stream: _notesService.allNotes,
        builder: (context, notesSnapshot) {
          if (notesSnapshot.connectionState == ConnectionState.waiting) {
            // stream not yet emitted
            return const Center(child: CircularProgressIndicator());
          }
          if (notesSnapshot.hasError) {
            return Center(child: Text("Error: ${notesSnapshot.error}"));
          }
          final notes = notesSnapshot.data
                  ?.where((note) => note.userId == user.id)
                  .toList() ??
              [];
          if (notes.isEmpty) {
            return const Center(child: Text("No notes available."));
          }
          return ListView.builder(
            itemCount: notes.length,
            itemBuilder: (context, index) {
              final note = notes[index];
              return ListTile(
                title: Text(
                  note.text,
                  maxLines: 1,
                  softWrap: true,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text('id: ${note.id}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  tooltip: 'Delete note',
                  onPressed: () => _deleteNoteConfirmed(note),
                ),
                onTap: () {
                Navigator.of(context).push(
                MaterialPageRoute(
                builder: (context) => EditNoteView(note: note),
              ),
              );
              },

              );
            },
          );
        },
      ),
    );
  }
}
