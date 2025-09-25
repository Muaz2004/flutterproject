import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hello_flutter/utilities/error_dialoge.dart';
 

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
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

  Future<void> _register() async {
    final email = _email.text.trim();
    final password = _password.text.trim();

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // ✅ Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration successful! Please verify your email.')),
      );

      // ✅ Navigate to verify email view
      final user = FirebaseAuth.instance.currentUser;
      await user?.sendEmailVerification();
      Navigator.of(context).pushReplacementNamed('/verify-email');

    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          showErrorDialog(context, 'This email is already registered.');
          break;
        case 'invalid-email':
          showErrorDialog(context, 'Please enter a valid email.');
          break;
        case 'operation-not-allowed':
          showErrorDialog(context, 'Email/password sign up not enabled.');
          break;
        case 'weak-password':
          showErrorDialog(context, 'Password should be at least 6 characters.');
          break;
        case 'network-request-failed':
          showErrorDialog(context, 'Check your internet connection.');
          break;
        default:
          // ✅ Generic fallback
          showErrorDialog(context, 'Registration failed [${e.code}]: ${e.message}');
      }
    } catch (e) {
      showErrorDialog(context, 'Unexpected error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
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
              onPressed: _register,
              child: const Text('Register'),
            ),
            const Spacer(),
            TextButton(
              onPressed: () {
                Navigator.pushNamed(context, '/login');
              },
              child: const Text(
                "Already have an account? login here",
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
