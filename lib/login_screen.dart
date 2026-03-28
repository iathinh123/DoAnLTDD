import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'register_screen.dart';
import 'forgot_pass_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập thành công")),
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

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Đăng nhập Google thành công")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Đăng nhập")),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            // EMAIL
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: "Email"),
            ),

            // PASSWORD
            TextField(
              controller: passwordController,
              decoration: InputDecoration(labelText: "Mật khẩu"),
              obscureText: true,
            ),

            SizedBox(height: 20),

            // LOGIN BUTTON
            ElevatedButton(
              onPressed: login,
              child: Text("Đăng nhập"),
            ),

            // GOOGLE LOGIN
            ElevatedButton(
              onPressed: signInWithGoogle,
              child: Text("Đăng nhập bằng Google"),
            ),

            // FORGOT PASSWORD
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => ForgotPasswordScreen()),
                );
              },
              child: Text("Quên mật khẩu?"),
            ),

            // REGISTER
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => RegisterScreen()),
                );
              },
              child: Text("Chưa có tài khoản? Đăng ký"),
            ),
          ],
        ),
      ),
    );
  }
}