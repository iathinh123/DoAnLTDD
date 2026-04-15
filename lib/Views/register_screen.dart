import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key}); // Thêm const để tránh lỗi đỏ khi gọi từ Login

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController(); // Thêm ô xác nhận mật khẩu
  bool _isPasswordVisible = false;

  Future register() async {

    if (emailController.text.trim().isEmpty || passwordController.text.trim().isEmpty) {
      _showSnackBar("Vui lòng nhập đầy đủ thông tin", Colors.orange);
      return;
    }

    if (passwordController.text != confirmPasswordController.text) {
      _showSnackBar("Mật khẩu xác nhận không khớp", Colors.red);
      return;
    }

    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: emailController.text.trim(),
        password: passwordController.text.trim(),
      );

      if (!mounted) return;
      _showSnackBar("Đăng ký thành công!", Colors.greenAccent);
      Navigator.pop(context); // Quay lại trang Login
    } catch (e) {
      _showSnackBar("Lỗi: $e", Colors.red);
    }
  }

  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.greenAccent),
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


              const Text(
                "TẠO TÀI KHOẢN",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 1.5
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Quản lý thông minh, tài chính vững vàng.",
                style: TextStyle(color: Colors.grey, fontSize: 15),
              ),

              const SizedBox(height: 40),


              _buildLabel("Địa chỉ Email"),
              _buildInputBox(
                controller: emailController,
                hintText: "Nhập email của bạn",
                icon: Icons.email_outlined,
              ),

              const SizedBox(height: 20),


              _buildLabel("Mật khẩu"),
              _buildInputBox(
                controller: passwordController,
                hintText: "Nhập mật khẩu",
                icon: Icons.lock_outline,
                isPassword: true,
              ),

              const SizedBox(height: 20),


              _buildLabel("Xác nhận mật khẩu"),
              _buildInputBox(
                controller: confirmPasswordController,
                hintText: "Nhập lại mật khẩu",
                icon: Icons.shield_outlined,
                isPassword: true,
              ),

              const SizedBox(height: 40),


              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    foregroundColor: Colors.black,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 5,
                    shadowColor: Colors.greenAccent.withOpacity(0.3),
                  ),
                  child: const Text(
                      "ĐĂNG KÝ NGAY",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)
                  ),
                ),
              ),

              const SizedBox(height: 20),


              Center(
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Đã có tài khoản? Đăng nhập",
                    style: TextStyle(color: Colors.grey),
                  ),
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
        border: Border.all(color: Colors.greenAccent.withOpacity(0.4)),
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