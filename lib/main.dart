import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:hello_flutter/views/email_verification.dart';
import 'package:hello_flutter/views/login_view.dart';
import 'package:hello_flutter/views/newnote.dart';
import 'package:hello_flutter/views/notesview.dart';
import 'package:hello_flutter/views/register_view.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Auth App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      routes: {
        '/login': (context) => const LoginView(),
        '/register': (context) => const RegisterView(),
        '/verify-email': (context) => const VerifyEmailView(),
        '/notes': (context) => const NotesView(),
        '/newnote': (context) => const NewNoteView(),
      },
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    print(user);

    if (user == null) {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/login');
      });
      return const Center(child: Text("Redirecting to login..."));
    } else if (!user.emailVerified) {
      Future.delayed(const Duration(seconds: 0), () {
        Navigator.of(context).pushReplacementNamed('/verify-email');
      });
      return const Center(child: Text("Redirecting to verify email..."));
    } else {
      return const NotesView(); // go to notes view when logged in & verified
    }
  }
}


