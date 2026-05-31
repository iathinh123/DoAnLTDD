import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../Controllers/language_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
const Color moneyLoverGreen = Color(0xFF2DB15D);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final nameController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: const TextStyle(color: Colors.white)),
        backgroundColor: moneyLoverGreen,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Future register() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final name = nameController.text.trim();

    if (emailController.text.trim().isEmpty ||
        passwordController.text.trim().isEmpty ||
        confirmPasswordController.text.trim().isEmpty) {
      _showError(lang.getText("err_empty_field"));
      return;
    }

    if (name.isEmpty) {
      _showError(lang.languageCode == "vi"
          ? "Vui lòng nhập họ và tên"
          : "Please enter your full name");
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showError(lang.getText("err_password_mismatch"));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final credential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      await credential.user?.updateDisplayName(name);
      await credential.user?.reload();

      final uid = credential.user!.uid;
      await FirebaseFirestore.instance
          .collection('NguoiDung')
          .doc(uid)
          .set({
        'name': name,
        'email': emailController.text.trim(),
        'avatarUrl': '',
        'role': 'user',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      _isLoading = false;
      _showSuccess(lang.getText("register_success"));
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() => _isLoading = false);
      String msg;
      switch (e.code) {
        case 'email-already-in-use':
          msg = lang.languageCode == "vi"
              ? "Email này đã được đăng ký"
              : "Email already in use";
          break;
        case 'weak-password':
          msg = lang.languageCode == "vi"
              ? "Mật khẩu phải có ít nhất 6 ký tự"
              : "Password must be at least 6 characters";
          break;
        case 'invalid-email':
          msg = lang.languageCode == "vi"
              ? "Email không hợp lệ"
              : "Invalid email";
          break;
        default:
          msg = lang.getText("err_invalid_login");
      }
      _showError(msg);
    } catch (e) {
      setState(() => _isLoading = false);
      _showError(lang.languageCode == "vi"
          ? "Lỗi hệ thống: $e"
          : "System error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: moneyLoverGreen),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 25),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: size.height * 0.02),
              Text(
                lang.getText("register").toUpperCase(),
                style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 10),
              Text(
                lang.getText("slogan_register"),
                style: const TextStyle(color: Colors.grey, fontSize: 15),
              ),
              const SizedBox(height: 40),
              _buildLabel(lang.getText("Username")),
              _buildInputBox(
                controller: nameController,
                hintText: "Đầy đủ họ và tên",
                icon: Icons.person_outline,
              ),
              const SizedBox(height: 20),
              _buildLabel(lang.getText("email")),
              _buildInputBox(
                controller: emailController,
                hintText: "example@gmail.com",
                icon: Icons.email_outlined,
              ),
              const SizedBox(height: 20),
              _buildLabel(lang.getText("password")),
              _buildInputBox(
                controller: passwordController,
                hintText: lang.getText("password"),
                icon: Icons.lock_outline,
                isPassword: true,
              ),
              const SizedBox(height: 20),
              _buildLabel(lang.getText("confirm_password")),
              _buildInputBox(
                controller: confirmPasswordController,
                hintText: lang.getText("confirm_password"),
                icon: Icons.shield_outlined,
                isPassword: true,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: moneyLoverGreen,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: moneyLoverGreen.withOpacity(0.3),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          lang.getText("register_now").toUpperCase(),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                      ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang.getText("already_have_account"),
                      style: const TextStyle(color: Colors.grey),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        lang.getText("login"),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: moneyLoverGreen,
                            fontSize: 15
                        ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
          text,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)
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
        border: Border.all(color: moneyLoverGreen.withOpacity(0.3)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white),
        obscureText: isPassword ? !_isPasswordVisible : false,
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
          prefixIcon: Icon(icon, color: moneyLoverGreen),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          suffixIcon: isPassword
              ? IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
              color: moneyLoverGreen,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          )
              : null,
        ),
      ),
    );
  }
}