import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider extends ChangeNotifier {
  String _languageCode = "vi";

  String get languageCode => _languageCode;

  Map<String, Map<String, String>> translations = {
    "vi": {
      "login": "Đăng nhập",
      "register": "Đăng ký",
      "email": "Email",
      "password": "Mật khẩu",
      "forgot": "Quên mật khẩu?",
      "google": "Đăng nhập bằng Google",
      "or": "Hoặc",
      "no_account": "Bạn chưa có tài khoản?",
      "register_now": "Đăng ký ngay",
      "Username": "Họ và tên",
      "Fullname": "Đầy đủ họ và tên",
      "ob_title_1": "Cắt giảm những chi phí không cần thiết hiệu quả",
      "ob_title_2": "Tiết kiệm tiền đều đặn hàng tháng để đạt mục tiêu",
      "ob_title_3": "Quản lý tất cả tài khoản, ví tiền ở một nơi duy nhất",

      "app_description": "Quản lý chi tiêu cá nhân",
      "err_empty_field": "Vui lòng không để trống thông tin",
      "err_invalid_login": "Email hoặc mật khẩu không đúng",

      "slogan_register": "Quản lý thông minh, tài chính vững vàng.",
      "confirm_password": "Xác nhận mật khẩu",
      "already_have_account": "Đã có tài khoản?",
      "err_password_mismatch": "Mật khẩu xác nhận không khớp",
      "register_success": "Đăng ký thành công!",

      "forgot_instruction": "Nhập email của bạn để nhận liên kết thiết lập lại mật khẩu mới.",
      "send_request": "Gửi yêu cầu",
      "reset_email_sent": "Đã gửi email khôi phục mật khẩu!",
    },
    "en": {
      "login": "Login",
      "register": "Register",
      "email": "Email",
      "password": "Password",
      "forgot": "Forgot Password?",
      "google": "Login with Google",
      "or": "Or",
      "no_account": "Don't have an account?",
      "register_now": "Register Now",
      "Username" : "Username",
      "Fullname": "Full name",
      "ob_title_1": "Cut down unnecessary expenses effectively",
      "ob_title_2": "Save money regularly every month to reach goals",
      "ob_title_3": "Manage all accounts and wallets in one place",


      "app_description": "Personal Expense Manager",
      "err_empty_field": "Please fill in all fields",
      "err_invalid_login": "Invalid email or password",

      "slogan_register": "Smart management, solid finance.",
      "confirm_password": "Confirm Password",
      "already_have_account": "Already have an account?",
      "err_password_mismatch": "Passwords do not match",
      "register_success": "Registration successful!",

      "forgot_instruction": "Enter your email to receive a password reset link.",
      "send_request": "Send Request",
      "reset_email_sent": "Password reset email sent!",
    }
  };

  String getText(String key) {
    return translations[_languageCode]![key] ?? key;
  }

  Future changeLanguage(String code) async {
    _languageCode = code;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("lang", code);

    notifyListeners();
  }

  Future loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString("lang") ?? "vi";
    notifyListeners();
  }
}