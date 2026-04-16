import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:provider/provider.dart';

import 'register_screen.dart';
import 'forgot_pass_screen.dart';
import '../Controllers/language_provider.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  bool _isPasswordVisible = false;


  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future login() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showError(lang.getText("err_empty_field"));
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {

      _showError(lang.getText("err_invalid_login"));
    } catch (e) {
      _showError("Lỗi hệ thống: $e");
    }
  }

  Future signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
    } catch (e) {
      _showError("Lỗi Google: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            children: [

              Align(
                alignment: Alignment.topRight,
                child: PopupMenuButton<String>(
                  color: const Color(0xFF1E1E1E),
                  onSelected: (value) => lang.changeLanguage(value),
                  icon: const Icon(Icons.language, color: Colors.greenAccent),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "vi", child: Text("Tiếng Việt", style: TextStyle(color: Colors.white))),
                    const PopupMenuItem(value: "en", child: Text("English", style: TextStyle(color: Colors.white))),
                  ],
                ),
              ),

              SizedBox(height: size.height * 0.05),


              const Icon(Icons.account_balance_wallet_rounded, size: 80, color: Colors.greenAccent),
              const SizedBox(height: 15),
              Text(
                lang.getText("login").toUpperCase(),
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 2),
              ),
              const SizedBox(height: 8),

              Text(
                lang.getText("app_description"),
                style: const TextStyle(color: Colors.grey, fontSize: 14),
              ),

              const SizedBox(height: 40),

              _buildInputBox(
                controller: emailController,
                hintText: lang.getText("email"),
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 20),

              _buildInputBox(
                controller: passwordController,
                hintText: lang.getText("password"),
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ForgotPasswordScreen())),
                  child: Text(lang.getText("forgot"), style: const TextStyle(color: Colors.greenAccent, fontSize: 13)),
                ),
              ),

              const SizedBox(height: 15),


              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: Colors.greenAccent.withOpacity(0.4),
                  ),
                  child: Text(lang.getText("login").toUpperCase(), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),

              const SizedBox(height: 20),
              Text(lang.getText("or"), style: const TextStyle(color: Colors.grey)),
              const SizedBox(height: 20),


              SizedBox(
                width: double.infinity,
                height: 55,
                child: OutlinedButton.icon(
                  onPressed: signInWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, color: Colors.white, size: 30),
                  label: Text(
                      lang.getText("google"),
                      style: const TextStyle(color: Colors.white, fontSize: 15)),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    side: const BorderSide(color: Colors.greenAccent),
                  ),
                ),
              ),

              const SizedBox(height: 40),


              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                        lang.getText("no_account"),
                        style: const TextStyle(color: Colors.white70)
                    ),
                    TextButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const RegisterScreen())),
                      child: Text(
                          lang.getText("register_now"),
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.greenAccent,
                              fontSize: 15
                          )
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputBox({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    bool isPassword = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.greenAccent),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.greenAccent),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
        ),
      ),
    );
  }
}