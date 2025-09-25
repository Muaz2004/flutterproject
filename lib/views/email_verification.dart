import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({super.key});

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("verify email"),
      ),
      body: Column(
        children: [
          const Text("we have sent u the verification link in ur email please check it"),
          const Text("if u didnt get the virification link yet click the link between"),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              print(user);
              await user?.sendEmailVerification();
                // ✅ ADDED: tell user that email was sent
               ScaffoldMessenger.of(context).showSnackBar(
               const SnackBar(content: Text('Verification email sent! Please check your inbox.')),
            );
            },
            child: const Text("send email verification"),
          ),
        ],
      ),
    );
  }
}
