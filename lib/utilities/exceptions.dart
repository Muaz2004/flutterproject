// exceptions.dart

/// User-related exceptions
class UserNotFoundException implements Exception {
  final String message;
  UserNotFoundException([this.message = "User not found"]);
  
  @override
  String toString() => "UserNotFoundException: $message";
}

class UserAlreadyExistsException implements Exception {
  final String message;
  UserAlreadyExistsException([this.message = "User already exists"]);
  
  @override
  String toString() => "UserAlreadyExistsException: $message";
}

/// Note-related exceptions
class NoteNotFoundException implements Exception {
  final String message;
  NoteNotFoundException([this.message = "Note not found"]);
  
  @override
  String toString() => "NoteNotFoundException: $message";
}

class CouldNotUpdateNoteException implements Exception {
  final String message;
  CouldNotUpdateNoteException([this.message = "Could not update note"]);
  
  @override
  String toString() => "CouldNotUpdateNoteException: $message";
}

class CouldNotDeleteNoteException implements Exception {
  final String message;
  CouldNotDeleteNoteException([this.message = "Could not delete note"]);
  
  @override
  String toString() => "CouldNotDeleteNoteException: $message";
}

/// Database-related exceptions
class DatabaseAlreadyOpenException implements Exception {
  final String message;
  DatabaseAlreadyOpenException([this.message = "Database already open"]);
  
  @override
  String toString() => "DatabaseAlreadyOpenException: $message";
}

class UnableToGetDocumentsDirectoryException implements Exception {
  final String message;
  UnableToGetDocumentsDirectoryException([this.message = "Could not find documents directory"]);
  
  @override
  String toString() => "UnableToGetDocumentsDirectoryException: $message";
}

class DatabaseIsNotOpenException implements Exception {
  final String message;
  DatabaseIsNotOpenException([this.message = "Database is not open"]);
  
  @override
  String toString() => "DatabaseIsNotOpenException: $message";
}
