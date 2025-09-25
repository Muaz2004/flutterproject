import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/utilities/error_dialoge.dart';


class LoginView extends StatefulWidget {
  const LoginView({Key? key}) : super(key: key);

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    try {
      final res = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print(res);
      final user = res.user;

       if (user != null) {
        
      if (user.emailVerified) {
        // ✅ Success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Login successful!')),
        );
        // ✅ Navigate to NotesView
        Navigator.of(context).pushReplacementNamed('/notes');
      } else {
        // ✅ Redirect unverified users to verify-email page
        Navigator.of(context).pushReplacementNamed('/verify-email');
      }
    }

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'invalid-email':
          showErrorDialog(context, 'Invalid email format.');
          break;
        case 'user-disabled':
          showErrorDialog(context, 'This user has been disabled.');
          break;
        case 'user-not-found':
          showErrorDialog(context, 'No user found with this email.');
          break;
        case 'wrong-password':
          showErrorDialog(context, 'Incorrect password.');
          break;
        case 'too-many-requests':
          showErrorDialog(context, 'Too many attempts. Try again later.');
          break;
        case 'network-request-failed':
          showErrorDialog(context, 'Check your internet connection.');
          break;
        default:
          // ✅ Generic fallback using e.code
          showErrorDialog(context, 'Login failed [${e.code}]: ${e.message}');
      }
    } catch (e) {
      showErrorDialog(context, 'Unexpected error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(hintText: 'Enter email'),
            ),
            TextField(
              controller: _password,
              obscureText: true,
              decoration: const InputDecoration(hintText: 'Enter password'),
            ),
            TextButton(
              onPressed: _login,
              child: const Text('Login'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/register');
              },
              child: const Text(
                "Don't have an account? Register here",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
