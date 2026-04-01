import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'register_screen.dart';
import 'forgot_pass_screen.dart';
import 'language_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  // 🔐 LOGIN EMAIL
  Future login() async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      // 👉 chuyển sang Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  // 🌐 GOOGLE LOGIN
  Future signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser =
      await GoogleSignIn().signIn();

      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);

      // 👉 chuyển sang Home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);

    return Scaffold(
      appBar: AppBar(title: Text(lang.getText("login"))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // 🌐 ĐỔI NGÔN NGỮ
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => lang.changeLanguage("vi"),
                  child: const Text("VI"),
                ),
                TextButton(
                  onPressed: () => lang.changeLanguage("en"),
                  child: const Text("EN"),
                ),
              ],
            ),

            // 📧 EMAIL
            TextField(
              controller: emailController,
              decoration:
              InputDecoration(labelText: lang.getText("email")),
            ),

            // 🔑 PASSWORD
            TextField(
              controller: passwordController,
              decoration:
              InputDecoration(labelText: lang.getText("password")),
              obscureText: true,
            ),

            const SizedBox(height: 20),

            // 🔐 LOGIN
            ElevatedButton(
              onPressed: login,
              child: Text(lang.getText("login")),
            ),

            // 🌐 GOOGLE LOGIN
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: Text(lang.getText("google")),
            ),

            // 🔁 FORGOT PASSWORD
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen()),
                );
              },
              child: Text(lang.getText("forgot")),
            ),

            // 📝 REGISTER
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RegisterScreen()),
                );
              },
              child: Text(lang.getText("register")),
            ),
          ],
        ),
      ),
    );
  }
}