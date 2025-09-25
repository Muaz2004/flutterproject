import 'dart:async';
import 'package:hello_flutter/utilities/exceptions.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';

class NoteServices {
   // ---- Singleton boilerplate ----
  NoteServices._internal(); // private constructor
  static final NoteServices _shared = NoteServices._internal();
  factory NoteServices() => _shared; // factory returns the single instance
  // -------------------------------
  Database? _db;

  List<DatabaseNotes> _notes = [];
  final _notesStreamController = StreamController<List<DatabaseNotes>>.broadcast();//iwill ask both the syntax and extra
  Stream<List<DatabaseNotes>> get allNotes => _notesStreamController.stream;

  Future<void> ensureInitialized() async {
    if (_db == null) {
      await open();
    } 
  }

  Future<DatabaseUser> getOrCreatUser({required String email}) async {
    await ensureInitialized();
    try {
      final user = await getUser(email);
      return user;
    } on UserNotFoundException {
      final createdUser = await createUser(email);
      return createdUser;
    }
  }

  // **Added public method to refresh notes**
  Future<void> refreshNotes() async {
    await _catchNotes();
  }

  Future<void> _catchNotes() async {
    await ensureInitialized();
    final allNotes = await getAllNotes();
    _notes = allNotes.toList();
    _notesStreamController.add(_notes);
  }

  Future<DatabaseNotes> updateNote({
    required DatabaseNotes note,
    required String newText,
  }) async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();
    await getNote(id: note.id);

    final updatedCount = await db.update(
      noteTable,
      {
        'text': newText,
        'is_synced_with_cloud': 0,
      },
      where: 'id = ?',
      whereArgs: [note.id],
    );

    if (updatedCount != 1) {
      throw CouldNotUpdateNoteException();
    } else {
      final updated = await getNote(id: note.id);
      _notes.removeWhere((n) => n.id == updated.id);
      _notes.add(updated);
      _notesStreamController.add(_notes);
      return updated;
    }
  }

  Future<Iterable<DatabaseNotes>> getAllNotes() async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();

    final results = await db.query(noteTable);
    return results.map((row) => DatabaseNotes.fromRow(row));// i will ask the syntax
  }

  Future<DatabaseNotes> getNote({required int id}) async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();

    final results = await db.query(
      noteTable,
      limit: 1,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (results.isEmpty) {
      throw NoteNotFoundException();
    } else {
      final note = DatabaseNotes.fromRow(results.first);// here also syntax only
      _notes.removeWhere((note) => note.id == id);//why we remove and add it again
      _notes.add(note);
      _notesStreamController.add(_notes);
      return note;
    }
  }

  Future<int> deleteAllNotes() async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(noteTable);
    _notes = [];
    _notesStreamController.add(_notes);
    return deletedCount;
  }

  Future<void> deleteNote({required int id}) async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      noteTable,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteNoteException();
    } else {
      _notes.removeWhere((note) => note.id == id);
      _notesStreamController.add(_notes);
    }
  }

  Future<DatabaseNotes> createNote(DatabaseUser owner) async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();

    final dbUser = await getUser(owner.email);//here i think get user returns the user if it is in the 
                             // user table or thre error ma question here is that when throw usernotfound exception how
                             // dbuser and owner compaired? (what is the value of dbuser)in this case?
    if (dbUser != owner) {
      throw UserNotFoundException();
    }

    const text = "";

    final noteId = await db.insert(
      noteTable,
      {
        'user_id': owner.id,
        'text': text,
        'is_synced_with_cloud': 1,
      },
    );

    final note = DatabaseNotes(
      id: noteId,
      userId: owner.id,
      text: text,
      isSyncedWithCloud: true,
    );
    _notes.add(note);
    _notesStreamController.add(_notes);
    return note;
  }

  Future<DatabaseUser> getUser(String email) async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isEmpty) {
      throw UserNotFoundException();
    } else {
      return DatabaseUser.fromRow(results.first);
    }
  }

  Future<DatabaseUser> createUser(String email) async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();
    final results = await db.query(
      userTable,
      limit: 1,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (results.isNotEmpty) {
      throw UserAlreadyExistsException();
    }

    final userId = await db.insert(
      userTable,
      {
        "email": email.toLowerCase(),
      },
    );
    return DatabaseUser(id: userId, email: email);
  }

  Future<void> deleteUser(String email) async {
    await ensureInitialized();
    final db = _getDatabaseOrThrow();
    final deletedCount = await db.delete(
      userTable,
      where: 'email = ?',
      whereArgs: [email.toLowerCase()],
    );

    if (deletedCount != 1) {
      throw CouldNotDeleteNoteException();
    }
  }

  Database _getDatabaseOrThrow() {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      return db;
    }
  }

  Future<void> close() async {
    final db = _db;
    if (db == null) {
      throw DatabaseIsNotOpenException();
    } else {
      await db.close();
      _db = null;
    }
  }

  Future<void> open() async {
    if (_db != null) {
      throw DatabaseAlreadyOpenException();
    }
    try {
      final docsPath = await getApplicationDocumentsDirectory();
      final dbPath = join(docsPath.path, "notes.db");
      final db = await openDatabase(dbPath);
      _db = db;

      const createUserTable = '''
      CREATE TABLE IF NOT EXISTS "user" (
        "id" INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        "email" TEXT NOT NULL UNIQUE
      );
      ''';

      await db.execute(createUserTable);

      const createNoteTable = '''
      CREATE TABLE IF NOT EXISTS "note" (
        "id" INTEGER PRIMARY KEY AUTOINCREMENT,
        "user_id" INTEGER,
        "text" TEXT,
        "is_synced_with_cloud" INTEGER NOT NULL DEFAULT 0,
        FOREIGN KEY("user_id") REFERENCES "user"("id")
      );
      ''';

      await db.execute(createNoteTable);
      await _catchNotes(); // <- fetch notes immediately
    } on MissingPlatformDirectoryException {
      throw UnableToGetDocumentsDirectoryException();
    }
  }
}

// Models and table names (unchanged)
class DatabaseUser {
  final int id;
  final String email;

  const DatabaseUser({required this.id, required this.email});

  factory DatabaseUser.fromRow(Map<String, Object?> map) {//i will ask the syntax here
    return DatabaseUser(
      id: map["id"] as int,
      email: map["email"] as String,
    );
  }

  @override
  String toString() => 'User: $email (id: $id)';

  @override
  bool operator ==(covariant DatabaseUser other) => id == other.id;//what is its usaage? why we overide it ? to which scope the overidng available?

  @override
  int get hashCode => id.hashCode;
}

class DatabaseNotes {
  final int id;
  final int userId;
  final String text;
  final bool isSyncedWithCloud;

  DatabaseNotes({
    required this.id,
    required this.userId,
    required this.text,
    required this.isSyncedWithCloud,
  });

  factory DatabaseNotes.fromRow(Map<String, Object?> map) {
    return DatabaseNotes(
      id: map["id"] as int,
      userId: map["user_id"] as int,
      text: map["text"] as String,
      isSyncedWithCloud: (map["is_synced_with_cloud"] as int) == 1,
    );
  }

  @override
  String toString() {
    return 'Note: id=$id, userId=$userId, text="$text", isSyncedWithCloud=$isSyncedWithCloud';
  }

  @override
  bool operator ==(covariant DatabaseNotes other) => id == other.id;

  @override
  int get hashCode => id.hashCode;
}

const userTable = 'user';
const noteTable = 'note';
// and finally hwt generally the models do what is thier advantage? since am looking almost they are independent of the databse just couldd
// tell me there usage ? by models i mean DatabaseNotes and DatabaseUser  just not specific to this project just in general case how we suppused to use them ? and wha we supposed to use the model and the database?

